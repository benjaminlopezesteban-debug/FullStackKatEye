# Fase F2 — Rebanada vertical: Axios, CORS y catálogo

| | |
|---|---|
| **Fase** | F2 |
| **Gate** | G2 |
| **Estado** | Planificada |
| **Documento maestro** | `../../planificacion_desarrollo.md` |

## 1. Contexto

El plan anterior dejaba el catálogo conectado al final y dedicaba F0 a infraestructura. La pauta evalúa la integración frontend–backend; por eso el primer hito visible debe ser una rebanada vertical: el navegador pide el catálogo a Spring con Axios, CORS se demuestra y las imágenes se sirven desde el backend.

Esta fase también resuelve el problema de imágenes: el plan anterior mapeaba 4 de 15 códigos, copiaba 11 placeholders como si fueran fotos reales y reconstruía la URL con `codigo.toLowerCase()`, creando dos fuentes de verdad.

## 2. Decisiones

- **D3:** imágenes de producto en el backend, en un volumen externo; la API entrega `imagenUrl`.
- **D14:** CORS real en desarrollo (cross-origin) y same-origin en producción.
- **D2/D16:** pruebas con Vitest + MSW; backend con JUnit + MockMvc.
- **D18:** el usuario commitea al cerrar la fase.

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

## 4. Consecuencias

- El catálogo deja de depender de `productos.js`.
- CORS queda demostrado con un test y con el navegador, no solo configurado.
- Las imágenes se cambian sin recompilar el backend y hay una sola fuente de verdad.
- El frontend necesita el backend levantado para mostrar el catálogo; los tests usan MSW.
- `ProductoResponse` cambia; cualquier consumidor debe usar `imagenUrl`.

## 5. Gate G2 — Evidencia

```bash
cd KatEye-Back
mvn test -Dtest=CorsIT

curl -i -X OPTIONS http://localhost:8080/api/v1/productos \
  -H "Origin: http://localhost:5173" \
  -H "Access-Control-Request-Method: GET"

curl -I http://localhost:8080/img/productos/kat-004.jpg

cd ../KatEye-Front
npm run test:run -- client
npm run build
```

Resultado esperado:

- `CorsIT` verde.
- Preflight con `Access-Control-Allow-Origin: http://localhost:5173`.
- Imagen `kat-004.jpg` responde 200.
- Test MSW de `client.js` verde.
- Catálogo visible en el navegador con imágenes del backend.

## 6. Registro de ejecución

- **Fecha:**
- **Autor:**
- **Comandos ejecutados:**
- **Resultado:**
- **Desviaciones:**
- **Commit sugerido:** `feat: conecta catálogo con axios y CORS real`
- **Commit realizado:**

## 7. Pendientes para la siguiente fase

- Confirmar que `VITE_ASSETS_URL` se usa también para las imágenes de detalle.
- Confirmar que no queda ninguna URL de imagen construida con `codigo.toLowerCase()` en el frontend.
- Revisar la tabla de reconciliación y el script de imágenes.
