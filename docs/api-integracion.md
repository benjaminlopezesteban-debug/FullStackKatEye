# API e integración — TiendaKatEye

> Documento vivo. Se reestructura en F6 y se actualiza cada vez que cambia un endpoint o se añade un contract test. La fuente de verdad del contrato es el backend Spring Boot; el frontend consume únicamente este contrato.

## 1. Contrato

- **Base URL:** `/api/v1` (`VITE_API_URL` en desarrollo: `http://localhost:8080/api/v1`).
- **Autenticación:** `Authorization: Bearer <JWT>` en los endpoints protegidos.
- **Idempotencia:** `Idempotency-Key` obligatoria en `POST /checkout` y `POST /pagos/simular`; el reintento de pago reutiliza la clave del pedido.
- **Formato de error:** `ErrorResponse` con `timestamp`, `estado`, `error`, `mensaje` y `ruta`.
- **Imágenes:** la API entrega `imagenUrl` en `ProductoResponse`; el frontend no reconstruye la URL.

| Endpoint | Método | Request | Response OK | Errores |
|---|---|---|---|---|
| `/productos` | GET | Query opcional `categoriaId`, `precioMin`, `precioMax` | `200` `List<ProductoResponse>` | `400` filtros inválidos |
| `/productos/{id}` | GET | Path `id` | `200` `ProductoResponse` | `404` producto no encontrado |
| `/productos/{id}/relacionados` | GET | Path `id` | `200` `List<ProductoResponse>` | `404` producto no encontrado |
| `/categorias` | GET | — | `200` `List<CategoriaResponse>` | `500` |
| `/blogs` | GET | — | `200` `List<EntradaBlogResponse>` | `500` |
| `/blogs/{slug}` | GET | Path `slug` | `200` `EntradaBlogResponse` | `404` entrada no encontrada |
| `/regiones` | GET | — | `200` `List<RegionResponse>` | `500` |
| `/regiones/{codigo}/comunas` | GET | Path `codigo` | `200` `List<ComunaResponse>` | `404` región no encontrada |
| `/auth/registro` | POST | `RegistroRequest` | `201` `TokenResponse` | `400` validación, `409` correo duplicado |
| `/auth/login` | POST | `LoginRequest` | `200` `TokenResponse` | `401` credenciales inválidas |
| `/auth/logout` | POST | Bearer JWT | `200` `{ mensaje }` | `401` no autenticado |
| `/usuarios/me` | GET | Bearer JWT | `200` `UsuarioResponse` | `401` no autenticado |
| `/contacto` | POST | `MensajeContactoRequest` (correo opcional) | `201` `MensajeContactoResponse` | `400` validación |
| `/carritos/validar` | POST | Ítems del carrito | `200` carrito validado con precios del backend | `400` ítem inválido, `409` stock |
| `/checkout` | POST | `CheckoutRequest` + `Idempotency-Key` | `201` `CheckoutResponse` (pedido creado) | `400` validación, `409` stock/idempotencia |
| `/pagos/simular` | POST | `PagoRequest` + `Idempotency-Key` | `201` `PagoResponse` aprobado/rechazado | `400` validación, `404` pedido |
| `/pagos/{numero}/reintentar` | POST | Path `numero`, query `correo` opcional, `Idempotency-Key` | `201` `PagoResponse` | `404` pedido/pago, `409` estado inválido |
| `/pedidos/{numero}` | GET | Path `numero`, Bearer JWT o `correo` de invitado | `200` `PedidoResponse` | `404` pedido no encontrado |

### Imágenes de blog

`EntradaBlogResponse.imagen` es un **nombre de archivo** (por ejemplo `Crema Hidratante Facial.jpg`), no una URL. El frontend lo resuelve con `resolverImagen` desde `src/assets/` y usa `IMG_PLACEHOLDER` si el archivo no existe. La URL de producto sí viene resuelta en `ProductoResponse.imagenUrl`.

## 2. Matriz de contract tests

| Endpoint | Método | Request | Response OK | Errores | Test que lo cubre | Gate que lo exige |
|---|---|---|---|---|---|---|
| `/productos` | GET | `categoriaId`, `precioMin`, `precioMax` | `List<ProductoResponse>` con `imagenUrl` | `400` | `Productos.test.jsx`, `productos.contract.test.js` y `ProductoContractTest` | G2 / G3 |
| `/productos/{id}` | GET | `id` | `ProductoResponse` | `404` | `DetalleProducto.test.jsx` y `ProductoContractTest` | G2 |
| `/productos/{id}/relacionados` | GET | `id` | `List<ProductoResponse>` | `404` | `DetalleProducto.test.jsx` | G2 |
| `/categorias` | GET | — | `List<CategoriaResponse>` | `500` | `Productos.test.jsx` | G2 / G3 |
| `/blogs` | GET | — | `List<EntradaBlogResponse>` | `500` | `Blogs.test.jsx` | G3 |
| `/blogs/{slug}` | GET | `slug` | `EntradaBlogResponse` | `404` | `Blog.test.jsx` | G3 |
| `/regiones` | GET | — | `List<RegionResponse>` | `500` | `Registro.test.jsx` | G3 |
| `/regiones/{codigo}/comunas` | GET | `codigo` | `List<ComunaResponse>` | `404` | `Registro.test.jsx` | G3 |
| `/auth/registro` | POST | `RegistroRequest` | `TokenResponse` | `400`, `409` | `sesion.registro.test.js` + validación backend | G4 |
| `/auth/login` | POST | `LoginRequest` | `TokenResponse` | `401` | `sesion.login.test.js` | G4 |
| `/auth/logout` | POST | Bearer JWT | `{ mensaje }` | `401` | `sesion.logout.test.js` | G4 |
| `/usuarios/me` | GET | Bearer JWT | `UsuarioResponse` | `401` | `sesion.hidratacion.test.js` | G4 |
| `/contacto` | POST | `MensajeContactoRequest` | `MensajeContactoResponse` | `400` | `contacto.test.js` + validación backend | G4 |
| `/carritos/validar` | POST | Ítems | Carrito validado | `400`, `409` | `carrito.validar.test.js` | G5 |
| `/checkout` | POST | `CheckoutRequest` + `Idempotency-Key` | `CheckoutResponse` | `400`, `409` | `contract.checkout.test.js` | G5 |
| `/pagos/simular` | POST | `PagoRequest` + `Idempotency-Key` | `PagoResponse` | `400`, `404` | `contract.pago.test.js` | G5 |
| `/pagos/{numero}/reintentar` | POST | `numero` + `Idempotency-Key` | `PagoResponse` | `404`, `409` | `contract.pago-rechazado.test.js` | G5 |
| `/pedidos/{numero}` | GET | `numero` | `PedidoResponse` | `404` | `contract.checkout.test.js` | G5 |

Reglas:

- Un endpoint sin test aparece como **warning** en G2 o G5, no como fallo, hasta que se cubra.
- Los contract tests usan el cliente HTTP real del frontend contra el backend en modo test o un mock server tipado por OpenAPI; no dependen de MSW.
- MSW sigue siendo válido en tests unitarios de componentes, pero nunca en `src/` de runtime.

## 3. CORS

- **Orígenes permitidos:** `CORS_ORIGEN` (por defecto `http://localhost:5173`; admite lista separada por comas).
- **Métodos:** `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS`.
- **Cabeceras:** `*`.
- **Credenciales:** `allowCredentials = true`.
- **Preflight:** `OPTIONS` sobre `/api/v1/**` responde `200` con `Access-Control-Allow-Origin` para el origen permitido; un origen desconocido recibe `403`.
- **Test que lo cubre:** `CorsIT` (backend), exigido por G2.
- **Producción:** same-origin mediante Nginx; se conservan `Host` y `X-Forwarded-*`.

Verificación manual:

```bash
curl -i -X OPTIONS http://localhost:8080/api/v1/productos \
  -H "Origin: http://localhost:5173" \
  -H "Access-Control-Request-Method: GET"
```

## 4. OpenAPI

Si es viable, `docs/openapi.yaml` se genera en F6 y se valida en `gate-2.sh` con `schemathesis`, `dredd` o equivalente. Si no es viable, esta sección deja el TODO explícito y la matriz sigue siendo la referencia de cobertura.
