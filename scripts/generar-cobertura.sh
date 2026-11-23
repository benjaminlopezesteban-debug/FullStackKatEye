#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

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

Los umbrales se ajustan al baseline de cada fase y deben subir hasta líneas ≥ 80 y ramas ≥ 70.
Valores actuales en \`vite.config.js\`: líneas 73, ramas 60, funciones 66 y sentencias 72.
Si la cobertura baja de esos valores, \`gate-1.sh\` a \`gate-4.sh\` fallan.
`;

fs.writeFileSync("docs/cobertura.md", contenido);
NODE
