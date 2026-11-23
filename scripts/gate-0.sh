#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

STATE_DIR=".gates"
mkdir -p "$STATE_DIR"

log() { printf '[gate-0] %s\n' "$*"; }

if [ ! -f .env.example ]; then
  log "ERROR: falta .env.example"
  exit 1
fi

tmp_env="$(mktemp)"
cleanup() { rm -f "$tmp_env"; }
trap cleanup EXIT
cp .env.example "$tmp_env"

log "Validando docker-compose.yml con .env.example"
docker compose --env-file "$tmp_env" config >/dev/null

log "Validando override de rechazo"
docker compose --env-file "$tmp_env" \
  -f docker-compose.yml -f docker-compose.rechazo.yml config >/dev/null

log "Verificando que .env no esté versionado"
if git ls-files --error-unmatch .env >/dev/null 2>&1; then
  log "ERROR: .env está versionado"
  exit 1
fi

if ! command -v gitleaks >/dev/null 2>&1; then
  log "ERROR: gitleaks no está instalado; instálalo para completar G0"
  exit 2
fi

log "Ejecutando gitleaks"
gitleaks detect --source . --no-banner --redact

log "Verificando historial importado"
git log --oneline -- KatEye-Front | head -5
git log --oneline -- KatEye-Back | head -5

log "Verificando remotos"
git remote -v

log "Verificando sintaxis de scripts"
bash -n scripts/*.sh

log "Verificando Makefile"
test -f Makefile
make -n gate-0 >/dev/null

log "Verificando .env.example"
grep -q '^KATEYE_PAGO_SIMULADO_RESULTADO=APROBADA' .env.example

log "Verificando memoria de F0"
test -f docs/memoria/mm_devFase0.md

log "Compilando backend"
mvn -q -DskipTests package -f KatEye-Back/katEye/pom.xml

log "Instalando y compilando frontend"
(
  cd KatEye-Front
  npm ci --no-audit --no-fund >/dev/null
  npm run build >/dev/null
)

date -u +"%Y-%m-%dT%H:%M:%SZ" > "$STATE_DIR/gate-0.ok"
log "G0 OK"
