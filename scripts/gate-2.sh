#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

STATE_DIR=".gates"
mkdir -p "$STATE_DIR"

log() { printf '[gate-2] %s\n' "$*"; }

if [ ! -f "$STATE_DIR/gate-1.ok" ]; then
  log "Ejecuta primero scripts/gate-1.sh"
  exit 2
fi

log "Revisando deuda técnica para F2"
scripts/check-deuda.sh 2

log "Reconciliando imágenes de producto"
scripts/check-imagenes.sh

log "Ejecutando gate-lint"
scripts/gate-lint.sh

log "Ejecutando tests del backend (CorsIT + contrato)"
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

if curl -fsS "http://localhost:${BACKEND_PORT:-8080}/actuator/health" >/dev/null 2>&1; then
  log "Verificando preflight CORS real"
  cabeceras="$(curl -sS -D - -o /dev/null \
    -X OPTIONS "http://localhost:${BACKEND_PORT:-8080}/api/v1/productos" \
    -H "Origin: http://localhost:5173" \
    -H "Access-Control-Request-Method: GET")"
  if ! grep -qi '^access-control-allow-origin: http://localhost:5173' <<< "$cabeceras"; then
    log "ERROR: el preflight no devolvió Access-Control-Allow-Origin"
    exit 1
  fi
else
  log "ADVERTENCIA: backend no levantado; preflight real omitido (CorsIT cubre CORS)"
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "$STATE_DIR/gate-2.ok"
log "G2 OK"
