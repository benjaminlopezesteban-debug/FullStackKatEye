#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

HOOK=".git/hooks/pre-push"

cat > "$HOOK" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

scripts/gate-lint.sh

fase="${KATEYE_FASE:-}"
if [ -z "$fase" ]; then
  rama="$(git rev-parse --abbrev-ref HEAD)"
  if [[ "$rama" =~ ^fase-([0-6])$ ]]; then
    fase="${BASH_REMATCH[1]}"
  fi
fi

if [ -n "$fase" ]; then
  if [ -x "scripts/gate-$fase.sh" ]; then
    "scripts/gate-$fase.sh"
  else
    echo "pre-push: scripts/gate-$fase.sh no está implementado todavía." >&2
    exit 1
  fi
else
  echo "pre-push: define KATEYE_FASE o usa una rama fase-N para ejecutar el gate de la fase."
fi
EOF

chmod +x "$HOOK"
printf 'Hook instalado en %s\n' "$HOOK"
