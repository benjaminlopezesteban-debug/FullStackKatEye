#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

SEED="KatEye-Back/katEye/src/main/resources/db/migration/V4__seed_catalogo.sql"
DIR="KatEye-Back/media/img/productos"

REALES=(KAT-002 KAT-004 KAT-005 KAT-014)
EXCEPCIONES=(KAT-001 KAT-003 KAT-006 KAT-007 KAT-008 KAT-009 KAT-010 KAT-011 KAT-012 KAT-013 KAT-015)

en_lista() {
  local buscado="$1"
  shift
  local item
  for item in "$@"; do
    if [ "$item" = "$buscado" ]; then
      return 0
    fi
  done
  return 1
}

fallos=0

for codigo in $(grep -oE "'KAT-[0-9]{3}'" "$SEED" | tr -d "'" | sort -u); do
  archivo="$DIR/$(printf '%s' "$codigo" | tr '[:upper:]' '[:lower:]').jpg"

  if [ -f "$archivo" ]; then
    if ! en_lista "$codigo" "${REALES[@]}"; then
      printf 'ERROR: %s tiene archivo pero no está declarado como real\n' "$codigo" >&2
      fallos=1
    fi
  elif ! en_lista "$codigo" "${EXCEPCIONES[@]}"; then
    printf 'ERROR: %s no tiene imagen ni excepción declarada\n' "$codigo" >&2
    fallos=1
  fi
done

for codigo in "${REALES[@]}"; do
  archivo="$DIR/$(printf '%s' "$codigo" | tr '[:upper:]' '[:lower:]').jpg"
  if [ ! -f "$archivo" ]; then
    printf 'ERROR: falta la imagen %s\n' "$archivo" >&2
    fallos=1
  fi
done

if [ "$fallos" -ne 0 ]; then
  exit 1
fi

printf 'Reconciliación de imágenes OK: %s reales y %s excepciones.\n' "${#REALES[@]}" "${#EXCEPCIONES[@]}"
