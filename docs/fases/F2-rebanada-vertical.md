# Fase F2 — Rebanada vertical: Axios, CORS y catálogo

| | |
|---|---|
| **Fase** | F2 |
| **Gate** | G2 |
| **Estado** | Cerrada (commit pendiente) |
| **Documento maestro** | `../../planificacion_desarrollo.md` |

## 1. Contexto

El plan anterior dejaba el catálogo conectado al final y dedicaba F0 a infraestructura. La pauta evalúa la integración frontend–backend; por eso el primer hito visible debe ser una rebanada vertical: el navegador pide el catálogo a Spring con Axios, CORS se demuestra y las imágenes se sirven desde el backend.

Esta fase también resuelve el problema de imágenes: el plan anterior mapeaba 4 de 15 códigos, copiaba 11 placeholders como si fueran fotos reales y reconstruía la URL con `codigo.toLowerCase()`, creando dos fuentes de verdad.

## 2. Decisiones

- **D3:** imágenes de producto en el backend, en un volumen externo; la API entrega `imagenUrl`.
- **D14:** CORS real en desarrollo (cross-origin) y same-origin en producción.
- **D2/D16:** pruebas con Vitest + MSW; backend con JUnit + MockMvc.
- **D18:** el usuario commitea al cerrar la fase; B3 y B7 pueden ir en commits separados.
- **D20:** al finalizar la fase se crea `docs/memoria/mm_devFase2.md`.
- **D22:** el contract test del cliente HTTP real es bloqueante; MSW queda para tests unitarios.

## 3. Cambios a aplicar

### Backend

1. Agregar `ProductoResponse.imagenUrl` y poblarlo desde la primera imagen del producto.
2. Configurar recursos estáticos:
   ```yaml
   spring:
     web:
       resources:
         static-locations: file:/app/media/,classpath:/static/
   ```
3. Agregar el volumen en el compose raíz:
   ```yaml
   backend:
     volumes:
       - ./KatEye-Back/media:/app/media
   ```
4. Mover las 4 imágenes reales a `KatEye-Back/media/img/productos/`:
   - `kat-002.jpg`
   - `kat-004.jpg`
   - `kat-005.jpg`
   - `kat-014.jpg`

   Estos emparejamientos son aproximados. Si el nombre o el color no coinciden con el producto de la API, se deja `onError` y se retira el asset.
5. No crear placeholders `kat-00X.jpg` que simulen imágenes reales; eliminar los que existan. Los faltantes se cubren con `onError`.
6. Agregar `server.forward-headers-strategy=framework` en `application.yml`.
7. Crear `CorsIT` con dos casos:
   - preflight desde `http://localhost:5173` → 200 y `Access-Control-Allow-Origin`;
   - preflight desde un origen desconocido → 403.
8. Crear el script de reconciliación de imágenes: falla si un producto no tiene imagen ni excepción declarada.
9. Crear un contract test de `GET /productos` contra el backend en modo test o un mock server tipado; validar la forma de `ProductoResponse`.
10. Si es viable, generar `docs/openapi.yaml` y validar en `gate-2.sh` con `schemathesis`, `dredd` o equivalente; si no, dejar el TODO explícito en `docs/api-integracion.md`.

### Frontend

1. Instalar `axios`.
2. Crear `.env.development`:
   ```bash
   VITE_API_URL=http://localhost:8080/api/v1
   VITE_ASSETS_URL=http://localhost:8080
   ```
3. Crear `.env.production`:
   ```bash
   VITE_API_URL=/api/v1
   VITE_ASSETS_URL=
   ```
4. Crear `src/api/client.js`:
   - instancia única de Axios;
   - `baseURL` desde `VITE_API_URL`;
   - interceptor de request para `Authorization: Bearer <token>`;
   - interceptor de response para normalizar `ErrorResponse` y limpiar la sesión ante 401.
5. Crear `src/api/errors.js`, `src/api/urlAsset.js` y `src/api/endpoints/` para productos, categorías, blogs, regiones y comunas.
6. Crear `src/hooks/useApi.js` con `data`, `loading`, `error` y `refetch`.
7. Migrar `Inicio`, `Productos` y `DetalleProducto` al catálogo real.
8. Usar `urlAsset` para las imágenes y `onError` para el placeholder.
9. Crear el test MSW de `client.js` y el test de catálogo.
10. Crear el contract test de `GET /productos` que use el cliente HTTP real; no debe depender de MSW.
11. Crear `docs/memoria/mm_devFase2.md` con los archivos creados y las acciones relevantes, en orden.
12. Ejecutar `scripts/sync-progreso.sh` y dejar ambos espejos listos para el commit del usuario.

### Gate

1. Crear `scripts/gate-2.sh`:
   - `set -euo pipefail` y `cd "$(git rev-parse --show-toplevel)"`;
   - verificar el prerrequisito de G1; si falta, imprimir “Ejecuta primero scripts/gate-1.sh” y salir con código 2;
   - ejecutar `scripts/check-deuda.sh 2` y `scripts/check-imagenes.sh`;
   - ejecutar `CorsIT`, el contrato, los tests de catálogo y el contract test;
   - validar `docs/openapi.yaml` si existe; si no, reportar el TODO de la matriz como warning.

### Deuda técnica

1. Registrar en `docs/deuda-tecnica.md` las desviaciones de F2 (carrito con snapshot, OpenAPI pendiente, imágenes faltantes, Header legado, test de Inicio).
2. Ejecutar `scripts/check-deuda.sh 2`; no debe haber deuda vencida para F2.

## 4. Consecuencias

- El catálogo deja de depender de `productos.js`.
- CORS queda demostrado con un test y con el navegador, no solo configurado.
- Las imágenes se cambian sin recompilar el backend y hay una sola fuente de verdad.
- El frontend necesita el backend levantado para mostrar el catálogo; los tests usan MSW.
- `ProductoResponse` cambia; cualquier consumidor debe usar `imagenUrl`.

## 5. Gate G2 — Evidencia

```bash
cd TiendaKatEye
scripts/gate-2.sh
scripts/check-deuda.sh 2
scripts/check-imagenes.sh

cd KatEye-Back
mvn test

curl -i -X OPTIONS http://localhost:8080/api/v1/productos \
  -H "Origin: http://localhost:5173" \
  -H "Access-Control-Request-Method: GET"

curl -I http://localhost:8080/img/productos/kat-004.jpg

cd ../KatEye-Front
npm run test:run -- client
npm run test:run -- contract
npm run build

# Si existe el spec, validarlo
test -f ../docs/openapi.yaml && echo "validar OpenAPI en gate-2.sh" || echo "OpenAPI TODO en docs/api-integracion.md"
```

Resultado esperado:

- `CorsIT` verde.
- `scripts/gate-2.sh` verifica G1 y falla si el contract test o el preflight no pasan.
- Preflight con `Access-Control-Allow-Origin: http://localhost:5173`.
- Imagen `kat-004.jpg` responde 200.
- Test MSW de `client.js` verde.
- Contract test de `GET /productos` verde; si falla, G2 falla.
- `scripts/check-imagenes.sh` no reporta productos sin imagen ni excepción.
- `scripts/check-deuda.sh 2` no reporta deuda vencida para F2.
- Si existe `docs/openapi.yaml`, la validación del spec pasa; si no, la matriz deja el TODO.
- Catálogo visible en el navegador con imágenes del backend.
- `docs/memoria/mm_devFase2.md` existe y describe los archivos y acciones.

## 6. Registro de ejecución

- **Fecha:** 2026-11-22
- **Autor:** Benjamín López
- **Comandos ejecutados:** `npm install axios`; `mvn test -Dtest=CorsIT,ProductoContractTest`; `npm run test:coverage`; `scripts/check-imagenes.sh`; `scripts/check-deuda.sh 2`; `scripts/gate-2.sh`.
- **Resultado:** G2 en verde (`exit 0`). `CorsIT` y `ProductoContractTest` verdes, 64 tests de frontend verdes, cobertura 33.14/37.70/28.87/31.87 y build correcto. Evidencia en `.gates/gate-2.ok`.
- **Desviaciones:** preflight real omitido porque el backend no estaba levantado; espejos no sincronizados por cambios de F1 sin commitear (DT-12); OpenAPI pendiente (DT-06); carrito con snapshot (DT-08).
- **Memoria:** `docs/memoria/mm_devFase2.md`
- **Commit sugerido:** `feat: conecta catálogo con axios y CORS real`
- **Commit realizado:** pendiente (lo realiza el usuario)

## 7. Pendientes para la siguiente fase

- Confirmar que `VITE_ASSETS_URL` se usa también para las imágenes de detalle.
- Confirmar que no queda ninguna URL de imagen construida con `codigo.toLowerCase()` en el frontend.
- Revisar la tabla de reconciliación y el script de imágenes.
- Confirmar que el contract test de `GET /productos` no usa MSW y que su fallo rompe G2.
- Confirmar si `docs/openapi.yaml` es viable; si no, dejar el TODO en `docs/api-integracion.md`.
- Commitear los espejos con los cambios de F1 y ejecutar `make sync` para cerrar DT-12.
- Resolver en F3 las deudas DT-03, DT-09 y DT-11 antes de ejecutar `scripts/check-deuda.sh 3`.
