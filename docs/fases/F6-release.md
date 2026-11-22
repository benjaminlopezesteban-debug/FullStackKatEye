# Fase F6 — Docker completo, documentación y release

| | |
|---|---|
| **Fase** | F6 |
| **Gate** | G6 |
| **Estado** | Planificada |
| **Documento maestro** | `../../planificacion_desarrollo.md` |

## 1. Contexto

Con el flujo de compra cerrado, falta el entorno reproducible y la documentación de entrega. El plan anterior no tenía healthcheck del backend, Nginx resolvía `backend` al arrancar y los puertos estaban fijos; además, la documentación de la pauta (ERS, manual, APIs, cobertura) no aparecía en ninguna fase.

Esta fase deja `TiendaKatEye` listo como entorno único de evaluación y actualiza la documentación de entrega.

## 2. Decisiones

- **D4:** `TiendaKatEye` es el entorno único de evaluación.
- **D14:** producción same-origin vía Nginx, conservando `Host` y `X-Forwarded-*`.
- **D19:** Docker mínimo viable ahora; resolver DNS, gzip y caché quedan como hardening posterior.
- **D18:** el usuario commitea al cerrar la fase.

## 3. Cambios a aplicar

### Docker y Nginx

1. Agregar healthcheck al backend:
   ```yaml
   healthcheck:
     test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
     interval: 10s
     timeout: 5s
     retries: 5
   ```
   Agregar `curl` a la imagen del backend o usar un healthcheck compatible con la JRE (`eclipse-temurin:21-jre` no lo incluye por defecto).
2. En el frontend, usar `depends_on: backend: condition: service_healthy`.
3. Nginx:
   ```nginx
   location /api/ { proxy_pass http://backend:8080; }
   location /img/ { proxy_pass http://backend:8080; }
   location /     { try_files $uri /index.html; }

   proxy_set_header Host $http_host;
   proxy_set_header X-Forwarded-Proto $scheme;
   proxy_set_header X-Forwarded-Host $http_host;
   ```
4. `vite.config.js` lee `BACKEND_PORT` con `loadEnv`; scripts y smoke usan la misma variable.
5. Confirmar que el compose raíz levanta `db`, `backend` y `frontend` con la red `kateye-net`.

### Documentación

1. Actualizar `README.md`:
   - requisitos;
   - variables de `.env`;
   - cómo levantar el entorno;
   - cómo probar CORS;
   - cómo forzar el rechazo de pago;
   - enlaces a los repositorios.
2. Crear/actualizar:
   - `docs/ERS-v2.md`
   - `docs/manual-usuario.md`
   - `docs/api-integracion.md`
   - `docs/cobertura.md`
3. Agregar Swagger/OpenAPI si la pauta vigente lo exige.
4. Actualizar `docs/ARQUITECTURA.md` con el árbol final.

### Release

1. Ejecutar `docker compose up --build`.
2. Ejecutar el smoke completo.
3. Ejecutar `gitleaks`.
4. Ejecutar la cobertura final.
5. Revisar que cada fase tenga su documento cerrado.

## 4. Consecuencias

- El entorno se levanta con un solo comando y el frontend espera a que el backend esté sano.
- Nginx conserva el origen y evita el 403 de CORS en producción.
- La entrega incluye ERS, manual, APIs, integración y cobertura.
- El hardening de Nginx (resolver dinámico, gzip, caché) queda documentado como siguiente paso.
- El usuario realiza el commit final.

## 5. Gate G6 — Evidencia

```bash
cd TiendaKatEye

docker compose config
docker compose up --build -d
docker compose ps

curl -i http://localhost:8080/actuator/health
curl -i http://localhost/api/v1/productos
curl -I http://localhost/img/productos/kat-004.jpg

gitleaks detect --source .

cd KatEye-Front
npm run test:coverage
npm run build
```

Smoke completo:

1. Catálogo con imágenes.
2. Detalle y relacionados.
3. Carrito persistente.
4. Checkout aprobado.
5. Checkout rechazado y reintento.
6. Contacto.
7. Preflight CORS.

## 6. Registro de ejecución

- **Fecha:**
- **Autor:**
- **Comandos ejecutados:**
- **Resultado:**
- **Desviaciones:**
- **Commit sugerido:** `chore: cierra Docker, documentación y release`
- **Commit realizado:**

## 7. Pendientes posteriores (fuera de la iteración)

- Cookie `httpOnly` para el token.
- Resolver DNS dinámico, gzip y caché de assets en Nginx.
- Panel de administración.
- Recuperación de contraseña en la interfaz.
- Rutas `/ofertas`, `/categorias` y `/mis-pedidos`, si la pauta las exige.
- Refresh token y revocación de sesión.
