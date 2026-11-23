#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

STATE_DIR=".gates"
mkdir -p "$STATE_DIR"

log() { printf '[gate-5] %s\n' "$*"; }

if [ ! -f "$STATE_DIR/gate-4.ok" ]; then
  log "Ejecuta primero scripts/gate-4.sh"
  exit 2
fi

log "Revisando deuda técnica para F5"
scripts/check-deuda.sh 5

log "Ejecutando gate-lint"
scripts/gate-lint.sh

log "Ejecutando tests del backend"
mvn -q test -f KatEye-Back/katEye/pom.xml

log "Ejecutando tests del frontend con cobertura"
(
  cd KatEye-Front
  npm run test:coverage
)

log "Regenerando docs/cobertura.md"
scripts/generar-cobertura.sh

log "Compilando el frontend"
(
  cd KatEye-Front
  npm run build >/dev/null
)

log "Preparando entorno de rechazo"
tmp_env="$(mktemp)"
sed \
  -e 's/^JWT_SECRET=.*/JWT_SECRET=smoke-secret-0123456789abcdef0123456789abcdef/' \
  -e 's/^BACKEND_PORT=.*/BACKEND_PORT=18080/' \
  .env.example > "$tmp_env"

compose=(
  docker compose
  --env-file "$tmp_env"
  -f docker-compose.yml
  -f docker-compose.rechazo.yml
)

cleanup() {
  log "Limpiando contenedores y huérfanos"
  "${compose[@]}" down --remove-orphans >/dev/null 2>&1 || true
  rm -f "$tmp_env"
}
trap cleanup EXIT

log "Levantando db y backend con el override de rechazo"
"${compose[@]}" up --build -d db backend

log "Esperando al backend"
for intento in $(seq 1 90); do
  if curl -fsS "http://localhost:18080/actuator/health" >/dev/null 2>&1; then
    break
  fi
  if [ "$intento" -eq 90 ]; then
    log "ERROR: el backend no respondió a tiempo"
    exit 1
  fi
  sleep 2
done

log "Ejecutando smoke de checkout rechazado y reintento"
API_URL="http://localhost:18080/api/v1" scripts/smoke-checkout.sh

date -u +"%Y-%m-%dT%H:%M:%SZ" > "$STATE_DIR/gate-5.ok"
log "G5 OK"
