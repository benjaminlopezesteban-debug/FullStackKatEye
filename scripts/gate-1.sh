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
node - <<'NODE'
const fs = require("fs");

const resumen = JSON.parse(
  fs.readFileSync("KatEye-Front/coverage/coverage-summary.json", "utf8"),
).total;
const pct = (metrica) => `${metrica.pct.toFixed(2)}%`;

const contenido = `> Generado automáticamente por scripts/gate-1.sh. No editar a mano.

# Cobertura del frontend

| Métrica | Cobertura | Cubierto | Total |
|---|---|---|---|
| Líneas | ${pct(resumen.lines)} | ${resumen.lines.covered} | ${resumen.lines.total} |
| Ramas | ${pct(resumen.branches)} | ${resumen.branches.covered} | ${resumen.branches.total} |
| Funciones | ${pct(resumen.functions)} | ${resumen.functions.covered} | ${resumen.functions.total} |
| Sentencias | ${pct(resumen.statements)} | ${resumen.statements.covered} | ${resumen.statements.total} |

## Umbrales

Los umbrales de F1 son el baseline real: líneas 21, ramas 28, funciones 22 y sentencias 21.
El objetivo del plan es subirlos por fase hasta líneas ≥ 80 y ramas ≥ 70. Si bajan, \`gate-1.sh\` falla.
`;

fs.writeFileSync("docs/cobertura.md", contenido);
NODE

log "Compilando el frontend"
(
  cd KatEye-Front
  npm run build >/dev/null
)

date -u +"%Y-%m-%dT%H:%M:%SZ" > "$STATE_DIR/gate-1.ok"
log "G1 OK"
