# Memoria de desarrollo — Fase 5

| | |
|---|---|
| **Fase** | F5 |
| **Gate** | G5 |
| **Estado** | Cerrada (commit pendiente del usuario) |
| **Documento de fase** | `../fases/F5-checkout.md` |

## Objetivo de la fase

Cerrar el flujo de compra contra el backend: carrito reconciliado con el catálogo, checkout real con `Idempotency-Key`, pago simulado aprobado/rechazado y reintento sobre el mismo pedido. Eliminar el checkout y los pagos locales.

## Archivos creados y modificados (en orden)

| # | Archivo | Acción | Qué hace |
|---|---|---|---|
| 1 | `KatEye-Back/.../checkout/controller/CheckoutController.java` | Modificado | `Idempotency-Key` obligatoria. |
| 2 | `KatEye-Back/.../pagos/pago/controller/PagoController.java` | Modificado | `Idempotency-Key` obligatoria en simular y reintentar. |
| 3 | `KatEye-Back/.../pedidos/pedido/repository/PedidoRepository.java` | Modificado | Reemplaza `pg_advisory_xact_lock` (Postgres) por `GET_LOCK`/`RELEASE_LOCK` de MySQL. |
| 4 | `KatEye-Back/.../pedidos/pedido/service/PedidoService.java` | Modificado | Adquiere y libera el bloqueo de MySQL al generar el número de pedido. |
| 5 | `KatEye-Front/src/carrito.js` | Modificado | Clave `kateye_carrito_v2`, límite por stock, reconciliación y migración del carrito legado. |
| 6 | `KatEye-Front/src/context/CarritoProvider.jsx` | Modificado | Reconcilia con `GET /productos`, expone `cargando` y `error`. |
| 7 | `KatEye-Front/src/api/endpoints/checkout.js` | Creado | `crearPedido` y `obtenerPedido` con `Idempotency-Key`. |
| 8 | `KatEye-Front/src/api/endpoints/pagos.js` | Creado | `simularPago`, `reintentarPago`, `obtenerPago`, `listarPagos`. |
| 9 | `KatEye-Front/src/views/Checkout.jsx` | Modificado | Checkout real: validación, regiones/comunas, idempotencia, pago y reintento. |
| 10 | `KatEye-Front/src/components/PagoFallido.jsx` | Modificado | Muestra número de pedido, reintento y error de red. |
| 11 | `KatEye-Front/src/components/ConfirmacionPedido.jsx` | Modificado | Acepta `correo` directo del pago. |
| 12 | `KatEye-Front/src/components/PanelCarrito.jsx`, `BotonAgregar.jsx`, `src/views/DetalleProducto.jsx` | Modificados | Límite `min(10, stock)` en la UI. |
| 13 | `KatEye-Front/src/validaciones.js` | Modificado | Checkout exige `regionCodigo` y `comunaCodigo`. |
| 14 | `KatEye-Front/src/pedidos.js`, `src/pagos.js` | Eliminados | Ya no hay checkout/pago locales. |
| 15 | `KatEye-Front/src/test/carrito.test.js` | Creado | Reconciliación, stock, migración y precios. |
| 16 | `KatEye-Front/src/test/Checkout.test.jsx` | Creado | Checkout aprobado, rechazo, reintento, fallos y carrito. |
| 17 | `KatEye-Front/src/test/PagoFallido.test.jsx` | Modificado | Nuevo contrato de la pantalla de rechazo. |
| 18 | `KatEye-Front/vite.config.js` | Modificado | `testTimeout` y umbrales 87/70/79/85. |
| 19 | `scripts/smoke-checkout.sh` | Creado | Smoke real: checkout, pago rechazado, reintento y estado final. |
| 20 | `scripts/gate-5.sh` | Creado | Prerrequisito G4, deuda, lint, tests, cobertura, build y Docker con override. |
| 21 | `docs/api-integracion.md` | Modificado | Matriz de checkout/pagos, flujo de compra e idempotencia. |
| 22 | `docs/deuda-tecnica.md` | Modificado | DT-02, DT-08 y DT-14 resueltas. |
| 23 | `KatEye-Front/README.md` | Modificado | Sin datos simulados; claves `kateye_carrito_v2` y `kateye_token`. |
| 24 | `docs/fases/F5-checkout.md`, `docs/fases/INDICE.md`, `docs/cobertura.md`, `docs/memoria/mm_devFase5.md` | Modificados/Creado | Registro, estado y evidencia de F5. |

## Acciones relevantes (en orden)

1. Se hicieron obligatorias las cabeceras `Idempotency-Key` en checkout, pago y reintento.
2. El smoke de Docker descubrió que el backend usaba `pg_advisory_xact_lock` (PostgreSQL) sobre MySQL; se reemplazó por `GET_LOCK`/`RELEASE_LOCK` antes de continuar.
3. El carrito pasó a `kateye_carrito_v2`, reconcilia con el catálogo al montar, descarta productos inválidos y limita por stock.
4. Se crearon los endpoints de checkout/pagos y se reescribió `Checkout` con claves de idempotencia por operación, pago y reintento.
5. Se eliminaron `pedidos.js`, `pagos.js`, `VITE_CHECKOUT_MODE` y el interruptor de fallo local.
6. Se agregaron tests de carrito, checkout aprobado/rechazado/reintento y fallos de red; la suite queda en **22 archivos / 111 tests verdes**.
7. Se ejecutó `scripts/gate-5.sh` con exit 0, incluido el smoke real contra Docker con el override de rechazo.
8. Se sincronizaron los espejos con los cambios de F5.

## Evidencia del gate

- Comando ejecutado: `scripts/gate-5.sh`
- Resultado: **exit 0**. Backend en verde, 111 tests de frontend verdes, cobertura líneas 87.50 %, ramas 70.35 %, funciones 79.76 %, sentencias 85.26 %, build correcto y smoke Docker OK.
- Smoke: pedido `20261123-0002`, pago `RECHAZADA`, reintento sobre el mismo pedido y estado final `PAGO_RECHAZADO`; contenedores limpiados por el `trap`.
- Artefacto o salida guardada: `.gates/gate-5.ok` → `2026-11-23T03:36:53Z`; `docs/cobertura.md`.
- Umbrales: 87/70/79/85, en `vite.config.js`. Se alcanzó el objetivo de líneas ≥ 80 y ramas ≥ 70.

## Desviaciones y pendientes

- **Backend:** se corrigió el bloqueo de numeración para MySQL; era un defecto latente que el smoke expuso.
- **Tipo de entrega:** el formulario fija `DESPACHO`; no hay selector `RETIRO` en la UI, aunque el backend lo soporta.
- **Cobertura:** DT-02 resuelta con 87.50 % líneas y 70.35 % ramas.
- **Pendientes F6:** DT-01 (Dockerfile/nginx del frontend), DT-04 (linter backend), DT-05 (Prettier global), DT-06 (OpenAPI), DT-10 (imágenes faltantes), DT-13 (N+1), DT-15 (correo de contacto `NOT NULL`).
- **Espejos:** sincronizados con F5; el usuario debe revisar, commitear y pushear.
- **Pendiente:** revisar y commitear el cierre de F5.
