#!/usr/bin/env bash
set -euo pipefail

API_URL="${API_URL:-http://localhost:8080/api/v1}"
STAMP="$(date +%s)-$$"
TMP_CHECKOUT="$(mktemp)"

cleanup() { rm -f "$TMP_CHECKOUT"; }
trap cleanup EXIT

log() { printf '[smoke] %s\n' "$*"; }

json_field() {
  local campo="$1"
  node -e '
    const fs = require("fs");
    const data = JSON.parse(fs.readFileSync(0, "utf8"));
    if (!(process.argv[1] in data)) process.exit(1);
    process.stdout.write(String(data[process.argv[1]]));
  ' "$campo"
}

productos="$(curl -fsS "$API_URL/productos")"
PRODUCTO_ID="$(node -e '
  const fs = require("fs");
  const data = JSON.parse(fs.readFileSync(0, "utf8"));
  const producto = data
    .filter(item => item.activo && item.stock > 0)
    .sort((a, b) => b.stock - a.stock)[0];
  if (!producto) process.exit(1);
  process.stdout.write(String(producto.id));
' <<< "$productos")"

cat > "$TMP_CHECKOUT" <<EOF
{"items":[{"productoId":$PRODUCTO_ID,"cantidad":1}],"tipoEntrega":"RETIRO","contactoNombre":"Smoke Test","contactoCorreo":"smoke@gmail.com","contactoTelefono":"912345678","metodoPago":"TARJETA"}
EOF

checkout="$(curl -fsS -X POST "$API_URL/checkout" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: smoke-checkout-$STAMP" \
  --data @"$TMP_CHECKOUT")"
PEDIDO_ID="$(json_field pedidoId <<< "$checkout")"
NUMERO="$(json_field numero <<< "$checkout")"
log "pedido $NUMERO creado (id $PEDIDO_ID)"

pago="$(curl -fsS -X POST "$API_URL/pagos/simular" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: smoke-pago-$STAMP" \
  --data "{\"pedidoId\":$PEDIDO_ID,\"metodo\":\"TARJETA\"}")"
ESTADO_PAGO="$(json_field estado <<< "$pago")"

if [ "$ESTADO_PAGO" != "RECHAZADA" ]; then
  log "ERROR: se esperaba RECHAZADA y se obtuvo $ESTADO_PAGO"
  exit 1
fi
log "pago rechazado como se esperaba"

reintento="$(curl -fsS -X POST "$API_URL/pagos/$NUMERO/reintentar?correo=smoke@gmail.com" \
  -H "Idempotency-Key: smoke-retry-$STAMP")"
ESTADO_REINTENTO="$(json_field estado <<< "$reintento")"

if [ "$ESTADO_REINTENTO" != "RECHAZADA" ]; then
  log "ERROR: el reintento debía volver a rechazar y devolvió $ESTADO_REINTENTO"
  exit 1
fi
log "reintento respondió $ESTADO_REINTENTO sobre el mismo pedido"

pedido="$(curl -fsS "$API_URL/pedidos/$NUMERO/invitado?correo=smoke@gmail.com")"
ESTADO_PEDIDO="$(json_field estado <<< "$pedido")"

if [ "$ESTADO_PEDIDO" != "PAGO_RECHAZADO" ]; then
  log "ERROR: el pedido $NUMERO quedó en estado $ESTADO_PEDIDO"
  exit 1
fi
log "pedido $NUMERO en estado $ESTADO_PEDIDO"
log "smoke de checkout rechazado y reintento OK"
