# Fase F3 — Catálogo, contenido y ubicación

| | |
|---|---|
| **Fase** | F3 |
| **Gate** | G3 |
| **Estado** | Cerrada (commit pendiente) |
| **Documento maestro** | `../../planificacion_desarrollo.md` |

## 1. Contexto

F2 conecta el catálogo principal. Quedan las demás vistas de consulta: inicio, detalle, header, blogs, regiones y comunas. El plan anterior mantenía adaptadores y módulos mock “hasta migrar”, pero ninguna fase los borraba; además filtraba categoría y precio en el cliente sin saber si `GET /productos` era paginado.

Esta fase migra las vistas al DTO real, resuelve los filtros en el servidor y elimina los módulos mock.

## 2. Decisiones

- **H11:** un solo modelo: el contrato del backend; sin adaptadores que perpetúen `imagenes[]`, `precioAnterior` o `categoria`.
- **D13:** las imágenes de blog permanecen en el frontend; `EntradaBlogResponse.imagen` es el nombre de archivo y se resuelve con `resolverImagen`.
- **D2/D16:** tests de catálogo, filtros y selects con Vitest + MSW.
- **D18:** el usuario commitea al cerrar la fase; B3 puede ir en un commit separado.
- **D20:** al finalizar la fase se crea `docs/memoria/mm_devFase3.md`.
- **D22:** el chequeo anti-mocks es de dos capas: `grep` en `src/` sin tests y contract test; MSW solo en tests.

## 3. Cambios a aplicar

1. Completar `Header`, `Blogs` y `Blog`; ajustar `Inicio`, `Productos` y `DetalleProducto` a categorías, filtros de servidor y relacionados.
2. Consumir `GET /categorias` para el filtro de categorías.
3. Consumir `GET /regiones` y `GET /regiones/{codigo}/comunas` para los selects.
4. Enviar los filtros al servidor:
   - `categoriaId`
   - `precioMin`
   - `precioMax`
5. Consumir `GET /productos/{id}/relacionados` para los relacionados.
6. Documentar el contrato de imagen de blog y usar `resolverImagen` con placeholder.
7. Borrar `src/productos.js`, `src/blogs.js` y `src/regiones.js` cuando ninguna vista los importe.
8. Reemplazar el helper de presentación por `src/utils/producto.js` (DTO → props de vista), sin reconstruir el modelo legado.
9. Crear tests de catálogo, filtros, blogs y selects.
10. Endurecer el chequeo anti-mocks:
    - `grep` de `msw`, `setupWorker` y `http.get/post/put/delete` en `KatEye-Front/src`, excluyendo tests;
    - contract test del cliente real que falle si el runtime vuelve a MSW.
11. Crear `docs/memoria/mm_devFase3.md` con los archivos creados y las acciones relevantes, en orden.
12. Ejecutar `scripts/sync-progreso.sh` y dejar los espejos listos para el commit del usuario.

### Gate

1. Crear `scripts/gate-3.sh`:
   - `set -euo pipefail` y `cd "$(git rev-parse --show-toplevel)"`;
   - verificar el prerrequisito de G2; si falta, imprimir “Ejecuta primero scripts/gate-2.sh” y salir con código 2;
   - ejecutar los tests de catálogo y el contract test;
   - aplicar las dos capas anti-mocks: `grep -RInE '(msw|setupWorker|http\.(get|post|put|delete)\()' KatEye-Front/src --include='*.js' --include='*.jsx' --exclude='*.test.*'` (debe devolver vacío) y el contract test del cliente real. G3 falla si cualquiera de las dos capas falla.

## 4. Consecuencias

- Desaparecen las listas hardcodeadas de productos, categorías, regiones y blogs.
- El filtrado deja de duplicarse: el servidor es la autoridad.
- El frontend queda más delgado: vistas + DTO + helper de presentación.
- Los tests que dependían de `productos.js` deben reescribirse contra MSW.
- `GET /productos` no es paginado; si en el futuro lo fuera, habría que ajustar la vista y el contrato.

## 5. Gate G3 — Evidencia

```bash
cd TiendaKatEye
scripts/gate-3.sh

cd KatEye-Front

npm run test:run -- catalogo filtros regiones blogs
npm run test:run -- contract
npm run build

# Capa 1: MSW/HTTP en runtime, sin tests; `! grep` falla si encuentra algo
! grep -RInE '(msw|setupWorker|http\.(get|post|put|delete)\()' src \
  --include='*.js' --include='*.jsx' --exclude='*.test.*'

# Capa 2: el contract test debe fallar si el runtime vuelve a MSW
npm run test:run -- contract
```

Resultado esperado:

- Tests de catálogo, filtros, regiones/comunas y blogs en verde.
- `npm run build` correcto.
- El `grep` no encuentra MSW ni `http.*` en `src/` fuera de tests.
- `scripts/gate-3.sh` verifica G2 y falla si aparece MSW en `src/` o si el contract test falla.
- El contract test del cliente real está verde; si falla, G3 falla.
- Sin imports de `productos.js`, `blogs.js` o `regiones.js` en vistas, contexto o componentes.
- `docs/memoria/mm_devFase3.md` existe y describe los archivos y acciones.

## 6. Registro de ejecución

- **Fecha:** 2026-11-22
- **Autor:** Benjamín López
- **Comandos ejecutados:** `npm run test:coverage`; `scripts/check-deuda.sh 3`; `scripts/gate-3.sh`; `scripts/sync-progreso.sh`.
- **Resultado:** G3 en verde (`exit 0`). Anti-mocks vacío, contract test verde, 79 tests verdes, cobertura 52.32/48.18/48.03/50.77 y build correcto. Evidencia en `.gates/gate-3.ok`.
- **Desviaciones:** `SesionProvider`/`usuarios.js` siguen simulados (DT-07, F4); checkout/pagos simulados (DT-14, F5); N+1 de imágenes/ofertas (DT-13, F6); OpenAPI pendiente (DT-06).
- **Memoria:** `docs/memoria/mm_devFase3.md`
- **Commit sugerido:** `refactor: migra catálogo, blogs y ubicación a la API`
- **Commit realizado:** pendiente (lo realiza el usuario)

## 7. Pendientes para la siguiente fase

- Confirmar que ningún test importa los módulos borrados.
- Confirmar que el contrato de imagen de blog está documentado.
- Verificar que los filtros se envían al servidor y no se recalculan en el cliente.
- Confirmar que el `grep` anti-mocks no encuentra MSW ni `http.*` en `src/` fuera de tests.
- Confirmar que el contract test falla si se reintroduce MSW en runtime (verificar manualmente y revertir).
- Confirmar que los espejos quedaron sincronizados con F2+F3 y que el usuario los commitea y pushea.
