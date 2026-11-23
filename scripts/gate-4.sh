#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

STATE_DIR=".gates"
mkdir -p "$STATE_DIR"

log() { printf '[gate-4] %s\n' "$*"; }

if [ ! -f "$STATE_DIR/gate-3.ok" ]; then
  log "Ejecuta primero scripts/gate-3.sh"
  exit 2
fi

log "Revisando deuda técnica para F4"
scripts/check-deuda.sh 4

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

date -u +"%Y-%m-%dT%H:%M:%SZ" > "$STATE_DIR/gate-4.ok"
log "G4 OK"
