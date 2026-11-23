#!/usr/bin/env bash
set -euo pipefail

# Política de espejos:
#   - TiendaKatEye es la fuente de verdad y el único lugar donde se edita el código.
#   - ProyectoWebKatEyes (frontend) y backendProyectoKatEye (backend) son espejos de progreso.
#   - La sincronización se ejecuta al cerrar cada fase, nunca a mitad de una fase.
#   - Este script no commitea ni pushea: deja los cambios para revisión y commit manual.
#   - Si un espejo tiene cambios propios sin commitear, el script aborta para evitar pérdidas.

cd "$(git rev-parse --show-toplevel)"

PARENT_DIR="$(cd .. && pwd)"
FRONT_MIRROR="${KATEYE_FRONT_MIRROR:-$PARENT_DIR/mi-proyecto}"
BACK_MIRROR="${KATEYE_BACK_MIRROR:-$PARENT_DIR/KatEyeBackEnd}"

EXCLUDES=(
  --exclude=.git
  --exclude=node_modules
  --exclude=target
  --exclude=dist
  --exclude=coverage
  --exclude=.env
  --exclude=.env.local
  --exclude=*.zip
)

verificar_espejo() {
  local nombre="$1"
  local ruta="$2"

  if [ ! -d "$ruta/.git" ]; then
    printf 'ERROR: %s no existe o no es un repositorio git: %s\n' "$nombre" "$ruta" >&2
    exit 1
  fi

  if [ -n "$(git -C "$ruta" status --porcelain)" ]; then
    printf 'ERROR: %s tiene cambios sin commitear: %s\n' "$nombre" "$ruta" >&2
    printf 'Reconcilia el espejo antes de sincronizar.\n' >&2
    exit 1
  fi
}

verificar_espejo "frontend" "$FRONT_MIRROR"
verificar_espejo "backend" "$BACK_MIRROR"

printf 'Sincronizando KatEye-Front -> %s\n' "$FRONT_MIRROR"
rsync -a --delete "${EXCLUDES[@]}" KatEye-Front/ "$FRONT_MIRROR"/

printf 'Sincronizando KatEye-Back -> %s\n' "$BACK_MIRROR"
rsync -a --delete "${EXCLUDES[@]}" KatEye-Back/ "$BACK_MIRROR"/

cat <<'EOF'

Espejos actualizados. No se commiteó ni pusheó nada.
Revisa cada espejo, commitea y pushea manualmente:
  - ProyectoWebKatEyes (frontend)
  - backendProyectoKatEye (backend)
EOF
