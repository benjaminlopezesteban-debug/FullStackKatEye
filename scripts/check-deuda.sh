#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

LEDGER="docs/deuda-tecnica.md"
fase="${1:-${KATEYE_FASE:-}}"

if ! [[ "$fase" =~ ^[0-6]$ ]]; then
  printf 'Uso: scripts/check-deuda.sh <fase 0-6>\n' >&2
  exit 2
fi

if [ ! -f "$LEDGER" ]; then
  printf 'ERROR: falta %s\n' "$LEDGER" >&2
  exit 1
fi

trim() {
  local valor="$1"
  valor="${valor#"${valor%%[![:space:]]*}"}"
  valor="${valor%"${valor##*[![:space:]]}"}"
  printf '%s' "$valor"
}

abiertas=0
vencidas=0

while IFS='|' read -r _ id origen descripcion impacto objetivo estado _; do
  id="$(trim "$id")"
  [ -z "$id" ] && continue

  estado="$(trim "$estado")"
  [ "$estado" = "Abierta" ] || continue

  abiertas=$((abiertas + 1))
  objetivo="$(trim "$objetivo")"

  if [[ "$objetivo" =~ ^F([0-6])$ ]]; then
    objetivo_num="${BASH_REMATCH[1]}"
    if [ "$objetivo_num" -le "$fase" ]; then
      printf 'DEUDA VENCIDA: %s (objetivo F%s, fase actual F%s): %s\n' \
        "$id" "$objetivo_num" "$fase" "$(trim "$descripcion")" >&2
      vencidas=$((vencidas + 1))
    fi
  fi
done < <(grep '^| DT-' "$LEDGER")

printf 'Deuda abierta: %s; vencida en F%s: %s\n' "$abiertas" "$fase" "$vencidas"

if [ "$vencidas" -gt 0 ]; then
  exit 1
fi
