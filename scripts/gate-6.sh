#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

STATE_DIR=".gates"
mkdir -p "$STATE_DIR"

log() { printf '[gate-6] %s\n' "$*"; }

if [ ! -f "$STATE_DIR/gate-5.ok" ]; then
  log "Ejecuta primero scripts/gate-5.sh"
  exit 2
fi

cleanup() {
  log "Limpiando contenedores y huérfanos"
  docker compose down --remove-orphans >/dev/null 2>&1 || true
}
trap cleanup EXIT

log "Validando docker-compose.yml"
docker compose config >/dev/null

log "Levantando el entorno"
docker compose up --build -d

log "Esperando al backend"
for intento in $(seq 1 60); do
  if curl -fsS "http://localhost:${BACKEND_PORT:-8080}/actuator/health" >/dev/null 2>&1; then
    break
  fi
  if [ "$intento" -eq 60 ]; then
    log "ERROR: el backend no respondió a tiempo"
    exit 1
  fi
  sleep 2
done

log "Smoke mínimo"
curl -fsS "http://localhost/api/v1/productos" >/dev/null
curl -fsSI "http://localhost/img/productos/kat-004.jpg" >/dev/null || true

log "Ejecutando gitleaks"
gitleaks detect --source . --no-banner --redact

log "Verificando documentación de cierre"
test -f docs/memoria/mm_devFase6.md
test -f docs/api-integracion.md

date -u +"%Y-%m-%dT%H:%M:%SZ" > "$STATE_DIR/gate-6.ok"
log "G6 OK"
