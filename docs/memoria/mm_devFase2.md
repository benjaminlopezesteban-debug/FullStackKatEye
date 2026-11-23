# Memoria de desarrollo — Fase 2

| | |
|---|---|
| **Fase** | F2 |
| **Gate** | G2 |
| **Estado** | Cerrada (commit pendiente del usuario) |
| **Documento de fase** | `../fases/F2-rebanada-vertical.md` |

## Objetivo de la fase

Conectar el catálogo real del backend con el frontend: `ProductoResponse.imagenUrl`, imágenes servidas desde el volumen `media`, CORS demostrado con `CorsIT`, cliente Axios central, primeras vistas (`Inicio`, `Productos`, `DetalleProducto`) consumiendo la API y contract tests de `GET /productos`.

## Archivos creados y modificados (en orden)

| # | Archivo | Acción | Qué hace |
|---|---|---|---|
| 1 | `KatEye-Back/.../producto/dto/ProductoResponse.java` | Modificado | Agrega `imagenUrl` al contrato de producto. |
| 2 | `KatEye-Back/.../producto/service/ProductoService.java` | Modificado | Puebla `imagenUrl` desde la primera imagen del producto. |
| 3 | `KatEye-Back/.../productoimagen/repository/ProductoImagenRepository.java` | Modificado | Agrega `findFirstByProductoIdOrderByOrdenAsc`. |
| 4 | `KatEye-Back/katEye/src/main/resources/application.yml` | Modificado | Recursos estáticos para `/app/media` y `../media`; `forward-headers-strategy=framework`. |
| 5 | `docker-compose.yml` | Modificado | Monta `./KatEye-Back/media:/app/media` en el backend. |
| 6 | `KatEye-Back/media/img/productos/` | Creado | Cuatro imágenes reales: `kat-002`, `kat-004`, `kat-005` y `kat-014`. |
| 7 | `KatEye-Back/.../shared/config/CorsIT.java` | Creado | Preflight permitido (200 + ACAO) y origen desconocido (403). |
| 8 | `KatEye-Back/.../producto/controller/ProductoContractTest.java` | Creado | Contrato JSON de `GET /productos` con `imagenUrl`. |
| 9 | `scripts/check-imagenes.sh` | Creado | Reconciliación entre productos del seed, imágenes reales y excepciones `onError`. |
| 10 | `scripts/check-deuda.sh` | Creado | Falla si hay deuda abierta cuya fase objetivo ya venció. |
| 11 | `docs/deuda-tecnica.md` | Creado | Registro de deuda con impacto, fase objetivo y estado. |
| 12 | `KatEye-Front/package.json` y `package-lock.json` | Modificados | Agrega `axios`. |
| 13 | `KatEye-Front/.env.development` y `.env.production` | Creados | URLs de API y assets por entorno. |
| 14 | `KatEye-Front/src/api/client.js` | Creado | Cliente Axios único, Bearer token y normalización de errores/401. |
| 15 | `KatEye-Front/src/api/errors.js` | Creado | Normaliza `ErrorResponse`. |
| 16 | `KatEye-Front/src/api/urlAsset.js` | Creado | Resuelve rutas relativas con `VITE_ASSETS_URL`. |
| 17 | `KatEye-Front/src/api/endpoints/` | Creado | Endpoints de productos, categorías, blogs y regiones/comunas. |
| 18 | `KatEye-Front/src/hooks/useApi.js` | Creado | Hook `data`, `loading`, `error` y `refetch`. |
| 19 | `KatEye-Front/src/views/Inicio.jsx`, `Productos.jsx`, `DetalleProducto.jsx` | Modificados | Consumen la API real con estados de carga/error y filtros de servidor. |
| 20 | `KatEye-Front/src/components/TarjetaProducto.jsx`, `TarjetaRelacionada.jsx`, `FilaProducto.jsx`, `Precio.jsx`, `PanelCarrito.jsx`, `ResumenPedido.jsx` | Modificados | Soportan `imagenUrl`, `precioFinal`, `categoriaNombre` y `onError`. |
| 21 | `KatEye-Front/src/utils/imagenes.js` y `src/utils/producto.js` | Modificados/Creado | Resuelven imágenes de API y helpers de categoría/precio. |
| 22 | `KatEye-Front/src/carrito.js` y `src/context/CarritoProvider.jsx` | Modificados | Guardan snapshot del producto para sobrevivir a la carga asíncrona. |
| 23 | `KatEye-Front/src/test/Productos.test.jsx`, `DetalleProducto.test.jsx`, `client.test.js`, `urlAsset.test.js` | Creados/Modificados | Tests de catálogo, detalle, cliente y assets. |
| 24 | `KatEye-Front/src/test/contract/productos.contract.test.js` | Creado | Contract test con cliente real y servidor HTTP tipado, sin MSW. |
| 25 | `scripts/gate-2.sh`, `scripts/generar-cobertura.sh` | Creados | Gate de F2 y generación única de `docs/cobertura.md`. |
| 26 | `docs/cobertura.md`, `docs/api-integracion.md`, `docs/ARQUITECTURA.md`, `README.md`, `docs/fases/INDICE.md` | Modificados | Cobertura, matriz de contract tests, deuda y documentación. |

## Acciones relevantes (en orden)

1. Se agregó `imagenUrl` al DTO y se pobló desde `producto_imagen`; se configuraron los recursos estáticos y el volumen de `media`.
2. Se copiaron las cuatro imágenes reales y se creó `check-imagenes.sh`; la reconciliación da 4 reales y 11 excepciones.
3. Se crearon `CorsIT` y `ProductoContractTest`; ambos pasan con Maven.
4. Se instaló Axios y se creó la capa `src/api` con cliente, errores, `urlAsset` y endpoints.
5. Se migraron `Inicio`, `Productos` y `DetalleProducto` a la API; los filtros de categoría y precio se envían al servidor.
6. Se adaptaron componentes, carrito y panel para consumir `imagenUrl`/`precioFinal` sin romper los tests legados.
7. Se crearon los tests de cliente, catálogo, detalle, assets y contrato. La suite queda en **12 archivos / 64 tests verdes**.
8. Se creó el registro de deuda y su verificación; `scripts/check-deuda.sh 2` devuelve 0 deudas vencidas.
9. Se ejecutó `scripts/gate-2.sh` con exit 0 y se regeneró `docs/cobertura.md`.

## Evidencia del gate

- Comando ejecutado: `scripts/gate-2.sh`
- Resultado: **exit 0**. `CorsIT` y `ProductoContractTest` verdes, 64 tests de frontend verdes, cobertura líneas 33.14 %, ramas 37.70 %, funciones 28.87 %, sentencias 31.87 %, build correcto y reconciliación de imágenes OK.
- Artefacto o salida guardada: `.gates/gate-2.ok` → `2026-11-23T01:54:40Z`; `docs/cobertura.md`.
- Preflight real: omitido porque el backend no estaba levantado; `CorsIT` cubre el preflight en el gate.

## Desviaciones y pendientes

- **Umbrales de cobertura:** subieron de 21/28/22/21 a 33/37/28/31; deben seguir subiendo hasta 80/70.
- **Preflight real:** se omite si el backend no está levantado; para la evidencia manual, ejecutar `docker compose up -d` y `curl` del preflight.
- **Espejos:** no se sincronizaron porque conservan cambios de F1 sin commitear. Registrado como DT-12; el usuario debe commitear los espejos y ejecutar `make sync`.
- **OpenAPI:** no se generó; queda DT-06 con la matriz como referencia.
- **Carrito:** guarda snapshot del producto (DT-08) hasta que F5 revise el carrito.
- **Rendimiento:** `listar` resuelve oferta e imagen por producto (DT-13, N+1) hasta optimizar en F6.
- **Header y categorías legadas:** DT-09, a resolver en F3.
- **Pendiente:** revisar y commitear el cierre de F2.
