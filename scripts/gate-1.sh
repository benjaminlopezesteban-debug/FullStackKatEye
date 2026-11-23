#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

STATE_DIR=".gates"
mkdir -p "$STATE_DIR"

log() { printf '[gate-1] %s\n' "$*"; }

if [ ! -f "$STATE_DIR/gate-0.ok" ]; then
  log "Ejecuta primero scripts/gate-0.sh"
  exit 2
fi

log "Ejecutando gate-lint"
scripts/gate-lint.sh

log "Ejecutando tests con cobertura"
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

date -u +"%Y-%m-%dT%H:%M:%SZ" > "$STATE_DIR/gate-1.ok"
log "G1 OK"
