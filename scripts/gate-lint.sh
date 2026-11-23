#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

log() { printf '[gate-lint] %s\n' "$*"; }

if [ ! -d KatEye-Front/node_modules ]; then
  log "Instalando dependencias del frontend"
  (cd KatEye-Front && npm ci --no-audit --no-fund)
fi

log "ESLint (frontend)"
(
  cd KatEye-Front
  npx eslint "src/**/*.{js,jsx}" "eslint.config.js" "vite.config.js"
)

log "Prettier (archivos nuevos y de configuración)"
(
  cd KatEye-Front
  targets=(package.json vite.config.js eslint.config.js src/test/setup.js src/test/mocks)
  if [ -d src/api ]; then
    targets+=(src/api)
  fi
  npx prettier --check "${targets[@]}"
)

log "Compilación del backend (verificación mínima)"
mvn -q -DskipTests test-compile -f KatEye-Back/katEye/pom.xml

log "gate-lint OK"
