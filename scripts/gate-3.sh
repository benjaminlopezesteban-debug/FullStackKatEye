#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

STATE_DIR=".gates"
mkdir -p "$STATE_DIR"

log() { printf '[gate-3] %s\n' "$*"; }

if [ ! -f "$STATE_DIR/gate-2.ok" ]; then
  log "Ejecuta primero scripts/gate-2.sh"
  exit 2
fi

log "Revisando deuda técnica para F3"
scripts/check-deuda.sh 3

log "Reconciliando imágenes de producto"
scripts/check-imagenes.sh

log "Ejecutando gate-lint"
scripts/gate-lint.sh

log "Capa 1 anti-mocks: MSW/HTTP en runtime"
if grep -RInE '(msw|setupWorker|http\.(get|post|put|delete)\()' KatEye-Front/src \
  --include='*.js' --include='*.jsx' --exclude-dir=test --exclude='*.test.*'; then
  log "ERROR: MSW o HTTP directo encontrado en src/ de runtime"
  exit 1
fi

log "Capa 2 anti-mocks: contract test del cliente real"
(
  cd KatEye-Front
  npm run test:run -- contract
)

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

date -u +"%Y-%m-%dT%H:%M:%SZ" > "$STATE_DIR/gate-3.ok"
log "G3 OK"
