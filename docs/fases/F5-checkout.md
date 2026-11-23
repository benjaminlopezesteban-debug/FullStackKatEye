# Fase F5 — Carrito, checkout real y pagos

| | |
|---|---|
| **Fase** | F5 |
| **Gate** | G5 |
| **Estado** | Cerrada (commit pendiente) |
| **Documento maestro** | `../../planificacion_desarrollo.md` |

## 1. Contexto

El plan anterior difería el checkout y el pago reales a un “F7 backlog”. El resultado era un catálogo real con un pedido que nunca llegaba al backend: no se registraba en la base, no descontaba stock y no tenía número real. Además, el carrito no portaba las reglas del `carrito.js` original y la verificación del rechazo usaba una variable del backend que el frontend no llamaba.

Esta fase cierra el flujo de compra contra el backend, sin simulación local, y elimina el código que nacía para borrarse.

## 2. Decisiones

- **D6:** el carrito se conserva hasta que `POST /checkout` responde 2xx.
- **D10:** el rechazo se fuerza en el backend con `KATEYE_PAGO_SIMULADO_RESULTADO=RECHAZADA` y `docker-compose.rechazo.yml`.
- **D11:** checkout real en esta iteración; no queda checkout simulado.
- **D17:** `Idempotency-Key` obligatoria en checkout y pago.
- **D18:** el usuario commitea al cerrar la fase; B1 y B7 pueden ir en commits separados.
- **D20:** al finalizar la fase se crea `docs/memoria/mm_devFase5.md`.
- **D21:** `gate-5.sh` usa el override de rechazo y limpia el entorno con `trap`.
- **D22:** los contract tests de checkout, pago y reintento son bloqueantes.

## 3. Cambios a aplicar

### Backend

1. Declarar `Idempotency-Key` con `required = true` en `CheckoutController` y `PagoController`.
2. Documentar la cabecera en la documentación de APIs.
3. Confirmar que `POST /checkout` vacía el carrito cuando usa `carritoId` o los ítems del usuario.
4. Verificar que el rechazo deja el pedido en `PAGO_RECHAZADO` y que `POST /pagos/{numero}/reintentar` funciona.

### Frontend

1. `CarritoProvider`:
   - reconciliar con el catálogo al montar;
   - descartar productos inexistentes;
   - limitar a `[1, min(10, stock)]`;
   - tomar precios del catálogo vigente;
   - exponer estados de carga y error;
   - usar la clave `kateye_carrito_v2`.
2. Crear `src/api/endpoints/checkout.js` y `pagos.js`:
   - `crearPedido(payload, idempotencyKey)`
   - `simularPago(pedidoId, metodo, idempotencyKey)`
   - `reintentarPago(numero, correo, idempotencyKey)`
   - `obtenerPedido(numero)`
3. `Checkout`:
   - generar `Idempotency-Key` una vez por intento con `useRef`;
   - reutilizarla en reintentos por fallo de red;
   - regenerarla solo si cambia el contenido del carrito;
   - autocompletar con `GET /usuarios/me` cuando hay sesión;
   - mapear `tipoEntrega`, `metodoPago`, `regionCodigo`, `comunaCodigo` e `items` con `productoId`;
   - agregar un selector `DESPACHO`/`RETIRO` o fijar `DESPACHO` si el formulario siempre pide dirección;
   - vaciar el carrito cuando `POST /checkout` responde 2xx.
4. `PagoFallido`:
   - recibir el número de pedido;
   - reintentar con `POST /pagos/{numero}/reintentar`;
   - no crear otro pedido.
5. Eliminar `src/pedidos.js`, `src/pagos.js` local, `VITE_CHECKOUT_MODE` y la casilla `simularFallo`.
6. Crear `docker-compose.rechazo.yml`.
7. Crear tests de carrito, checkout, idempotencia, pago aprobado, rechazo y reintento.
8. Crear contract tests de checkout, pago aprobado, pago rechazado y reintento contra el backend en modo test o mock server tipado.
9. Crear `scripts/gate-5.sh` con `set -euo pipefail`, prerrequisito de G4, `trap 'docker compose down --remove-orphans' EXIT` y el override `docker compose -f docker-compose.yml -f docker-compose.rechazo.yml`.
10. Crear `docs/memoria/mm_devFase5.md` con los archivos creados y las acciones relevantes, en orden.
11. Ejecutar `scripts/sync-progreso.sh` y dejar los espejos listos para el commit del usuario.

## 4. Consecuencias

- El pedido se registra en la base, descuenta stock y obtiene un número real.
- El carrito se vacía solo cuando el backend confirma la creación del pedido.
- Un pago rechazado no pierde el pedido: se reintenta sobre el mismo número.
- Desaparece el código simulado y el riesgo de mezclar ambos flujos.
- El frontend depende de que el backend esté disponible para comprar; los tests usan MSW.

## 5. Gate G5 — Evidencia

```bash
cd TiendaKatEye

scripts/gate-5.sh

cd KatEye-Front
npm run test:run -- carrito checkout pago idempotencia
npm run test:run -- contract
npm run build

cd ..
docker compose -f docker-compose.yml -f docker-compose.rechazo.yml up -d backend

# Smoke manual: comprar y verificar PAGO_RECHAZADO + reintento
```

Resultado esperado:

- Tests de carrito, checkout, pago y reintento en verde.
- Contract tests de checkout, pago y reintento verdes.
- Checkout aprobado con pedido real y carrito vacío.
- Checkout rechazado con pedido existente y reintento funcional.
- `Idempotency-Key` presente en las peticiones.
- `gate-5.sh` usa el override y deja el entorno limpio con `trap`; el smoke real crea pedido, rechaza pago y reintenta.
- Sin imports de `pedidos.js` o `pagos.js` local.
- `scripts/check-deuda.sh 5` no reporta deuda vencida para F5.
- `docs/memoria/mm_devFase5.md` existe y describe los archivos y acciones.

## 6. Registro de ejecución

- **Fecha:** 2026-11-22
- **Autor:** Benjamín López
- **Comandos ejecutados:** `mvn test`; `npm run test:coverage`; `scripts/check-deuda.sh 5`; `scripts/gate-5.sh`; `scripts/sync-progreso.sh`.
- **Resultado:** G5 en verde (`exit 0`). 111 tests de frontend verdes, cobertura 87.50/70.35/79.76/85.26, build correcto y smoke Docker con pedido rechazado + reintento. Evidencia en `.gates/gate-5.ok`.
- **Desviaciones:** se corrigió el bloqueo PostgreSQL por `GET_LOCK` de MySQL; el formulario fija `DESPACHO` y no ofrece `RETIRO`; imágenes, OpenAPI, linter backend, Prettier global, N+1 y correo de contacto `NOT NULL` quedan para F6.
- **Memoria:** `docs/memoria/mm_devFase5.md`
- **Commit sugerido:** `feat: integra carrito y checkout real con reintento de pago`
- **Commit realizado:** pendiente (lo realiza el usuario)

## 7. Pendientes para la siguiente fase

- Confirmar que el carrito se vacía solo tras 2xx.
- Confirmar que el rechazo no crea un segundo pedido.
- Verificar que el README documenta `docker-compose.rechazo.yml`.
- Revisar que no queda ninguna referencia a `VITE_CHECKOUT_MODE`.
- Confirmar que los espejos recibieron los cambios de la fase.
