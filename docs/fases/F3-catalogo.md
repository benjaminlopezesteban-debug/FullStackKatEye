# Fase F3 — Catálogo, contenido y ubicación

| | |
|---|---|
| **Fase** | F3 |
| **Gate** | G3 |
| **Estado** | Planificada |
| **Documento maestro** | `../../planificacion_desarrollo.md` |

## 1. Contexto

F2 conecta el catálogo principal. Quedan las demás vistas de consulta: inicio, detalle, header, blogs, regiones y comunas. El plan anterior mantenía adaptadores y módulos mock “hasta migrar”, pero ninguna fase los borraba; además filtraba categoría y precio en el cliente sin saber si `GET /productos` era paginado.

Esta fase migra las vistas al DTO real, resuelve los filtros en el servidor y elimina los módulos mock.

## 2. Decisiones

- **H11:** un solo modelo: el contrato del backend; sin adaptadores que perpetúen `imagenes[]`, `precioAnterior` o `categoria`.
- **D13:** las imágenes de blog permanecen en el frontend; `EntradaBlogResponse.imagen` es el nombre de archivo y se resuelve con `resolverImagen`.
- **D2/D16:** tests de catálogo, filtros y selects con Vitest + MSW.
- **D18:** el usuario commitea al cerrar la fase.

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

## 4. Consecuencias

- Desaparecen las listas hardcodeadas de productos, categorías, regiones y blogs.
- El filtrado deja de duplicarse: el servidor es la autoridad.
- El frontend queda más delgado: vistas + DTO + helper de presentación.
- Los tests que dependían de `productos.js` deben reescribirse contra MSW.
- `GET /productos` no es paginado; si en el futuro lo fuera, habría que ajustar la vista y el contrato.

## 5. Gate G3 — Evidencia

```bash
cd KatEye-Front

npm run test:run -- catalogo filtros regiones blogs
npm run build

# No debe haber imports de mocks en vistas o contexto
grep -rE "from ['\"].*/(productos|blogs|regiones)" src/views src/context src/components || true
```

Resultado esperado:

- Tests de catálogo, filtros, regiones/comunas y blogs en verde.
- `npm run build` correcto.
- Sin imports de `productos.js`, `blogs.js` o `regiones.js` en vistas, contexto o componentes.

## 6. Registro de ejecución

- **Fecha:**
- **Autor:**
- **Comandos ejecutados:**
- **Resultado:**
- **Desviaciones:**
- **Commit sugerido:** `refactor: migra catálogo, blogs y ubicación a la API`
- **Commit realizado:**

## 7. Pendientes para la siguiente fase

- Confirmar que ningún test importa los módulos borrados.
- Confirmar que el contrato de imagen de blog está documentado.
- Verificar que los filtros se envían al servidor y no se recalculan en el cliente.
