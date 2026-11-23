# Memoria de desarrollo — Fase 3

| | |
|---|---|
| **Fase** | F3 |
| **Gate** | G3 |
| **Estado** | Cerrada (commit pendiente del usuario) |
| **Documento de fase** | `../fases/F3-catalogo.md` |

## Objetivo de la fase

Completar el catálogo y el contenido contra la API: Header con categorías reales, Blogs/Blog desde `GET /blogs`, selects de región/comuna desde `GET /regiones`, filtros y relacionados en el servidor, y eliminación de los módulos mock legados. Cerrar las deudas DT-03, DT-09, DT-11 y DT-12.

## Archivos creados y modificados (en orden)

| # | Archivo | Acción | Qué hace |
|---|---|---|---|
| 1 | `KatEye-Front/src/components/Header.jsx` | Modificado | Consume `GET /categorias` y enlaza por `slug`; ya no usa la lista legada. |
| 2 | `KatEye-Front/src/views/Blogs.jsx` | Modificado | Consume `GET /blogs` con estados de carga/error y placeholder de imagen. |
| 3 | `KatEye-Front/src/views/Blog.jsx` | Modificado | Consume `GET /blogs/{slug}`, renderiza bloques y resuelve la imagen local. |
| 4 | `KatEye-Front/src/views/Registro.jsx` | Modificado | Regiones y comunas desde `GET /regiones` y `GET /regiones/{codigo}/comunas`. |
| 5 | `KatEye-Front/src/carrito.js` | Modificado | Elimina la dependencia de `productos.js`; usa el snapshot del producto. |
| 6 | `KatEye-Front/src/productos.js`, `blogs.js`, `regiones.js` | Eliminados | Ya no quedan consumidores; el contrato es la API. |
| 7 | `KatEye-Front/src/App.js`, `App.test.js`, `App.css`, `index.js`, `logo.svg`, `reportWebVitals.js`, `setupTests.js` | Eliminados | Andamiaje CRA muerto; cierra DT-03. |
| 8 | `KatEye-Front/vite.config.js` | Modificado | Quita la exclusión del test CRA y los excludes de archivos eliminados; sube umbrales a 52/48/47/50. |
| 9 | `KatEye-Front/src/test/Header.test.jsx` | Modificado | Categorías API por MSW y enlaces por slug. |
| 10 | `KatEye-Front/src/test/Inicio.test.jsx` | Creado | Cubre la vista de inicio; cierra DT-11. |
| 11 | `KatEye-Front/src/test/Blogs.test.jsx`, `Blog.test.jsx` | Creados | Listado y detalle de blogs con MSW, bloques y errores. |
| 12 | `KatEye-Front/src/test/Registro.test.jsx` | Creado | Carga de regiones/comunas y limpieza al cambiar de región. |
| 13 | `scripts/gate-3.sh` | Creado | Prerrequisito G2, deuda, anti-mocks en dos capas, tests, cobertura y build. |
| 14 | `scripts/gate-lint.sh` | Modificado | Prettier incluye los tests nuevos de F3. |
| 15 | `scripts/generar-cobertura.sh` | Modificado | Umbrales actuales y mención de G3. |
| 16 | `docs/deuda-tecnica.md` | Modificado | DT-03, DT-09, DT-11 y DT-12 marcadas como Resueltas; DT-07 se acota a F4 y se agrega DT-14 (checkout/pagos en F5). |
| 17 | `docs/api-integracion.md` | Modificado | Matriz de blogs/regiones y contrato de imagen de blog. |
| 18 | `docs/fases/F3-catalogo.md`, `docs/fases/INDICE.md`, `docs/cobertura.md`, `docs/memoria/mm_devFase3.md` | Modificados/Creado | Registro, estado y evidencia de F3. |

## Acciones relevantes (en orden)

1. El Header pasó de una lista fija a `GET /categorias`; los enlaces usan el slug y `Productos` lo resuelve.
2. Blogs y Blog consumen la API; la imagen sigue siendo un nombre de archivo local resuelto por `resolverImagen` con `IMG_PLACEHOLDER`.
3. Registro carga regiones y comunas desde la API; al cambiar de región se limpia la comuna.
4. Se eliminaron `productos.js`, `blogs.js`, `regiones.js` y el andamiaje CRA; `carrito.js` quedó sin dependencia del catálogo estático.
5. Se actualizaron/crearon los tests de Header, Inicio, Blogs, Blog y Registro. La suite queda en **16 archivos / 79 tests verdes**.
6. Se ejecutó `scripts/check-deuda.sh 3`: 0 deudas vencidas. Se marcaron como resueltas DT-03, DT-09, DT-11 y DT-12.
7. Se ejecutó `scripts/gate-3.sh` con exit 0: anti-mocks vacío, contract test verde, cobertura sobre los nuevos umbrales y build correcto.
8. Se sincronizaron los espejos con `scripts/sync-progreso.sh`; quedaron con los cambios de F2+F3 listos para el commit del usuario.

## Evidencia del gate

- Comando ejecutado: `scripts/gate-3.sh`
- Resultado: **exit 0**. Capa 1 anti-mocks vacía, contract test verde, 79 tests verdes, cobertura líneas 52.32 %, ramas 48.18 %, funciones 48.03 %, sentencias 50.77 %, build correcto.
- Artefacto o salida guardada: `.gates/gate-3.ok` → `2026-11-23T02:21:47Z`; `docs/cobertura.md`.
- Umbrales: 52/48/47/50, en `vite.config.js`.

## Desviaciones y pendientes

- **DT-07:** `SesionProvider` y `usuarios.js` siguen simulados; F4 los conecta a la API.
- **DT-14:** checkout y pagos simulados; F5.
- **Migración de carrito:** los carritos guardados antes de F2 sin snapshot de producto se descartan al hidratar; es una migración única, no una pérdida recurrente.
- **DT-13:** `listar` sigue con N+1 de oferta/imagen; F6.
- **DT-05:** Prettier solo revisa archivos nuevos y de configuración; el resto se formatea al migrarse.
- **DT-06:** OpenAPI pendiente; la matriz de `docs/api-integracion.md` es la referencia.
- **Espejos:** sincronizados con F2+F3; el usuario debe revisar, commitear y pushear cada espejo.
- **Pendiente:** revisar y commitear el cierre de F3.
