# Fase F6 — Docker completo, documentación y release

| | |
|---|---|
| **Fase** | F6 |
| **Gate** | G6 |
| **Estado** | Planificada |
| **Documento maestro** | `../../planificacion_desarrollo.md` |

## 1. Contexto

Con el flujo de compra cerrado, falta el entorno reproducible y la documentación de entrega. El plan anterior no tenía healthcheck del backend, Nginx resolvía `backend` al arrancar y los puertos estaban fijos; además, la documentación de la pauta (ERS, manual, APIs, cobertura) no aparecía en ninguna fase.

Esta fase deja `TiendaKatEye`/`FullStackKatEye` listo como repositorio unificado y entorno único de evaluación, con los espejos de progreso actualizados, y cierra la documentación de entrega.

## 2. Decisiones

- **D4:** `TiendaKatEye` es el repositorio unificado y el entorno único de evaluación.
- **D14:** producción same-origin vía Nginx, conservando `Host` y `X-Forwarded-*`.
- **D19:** Docker mínimo viable ahora; resolver DNS, gzip y caché quedan como hardening posterior.
- **D18:** el usuario commitea al cerrar la fase.
- **D20:** al finalizar la fase se crea `docs/memoria/mm_devFase6.md`.

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
   - `docs/cobertura.md`
   - `docs/api-integracion.md` con tres secciones: (1) contrato —endpoints, DTOs, códigos de error y orígenes CORS permitidos—; (2) **Matriz de contract tests** con columnas `Endpoint | Método | Request | Response OK | Errores | Test que lo cubre | Gate que lo exige`, una fila por endpoint (catálogo, sesión, contacto, carrito, checkout, pago y pago rechazado); (3) **CORS** con orígenes permitidos, preflight y credenciales. Los endpoints sin test quedan como warning explícito hasta cubrirse.
3. Generar `docs/openapi.yaml` si es viable y validarlo en `gate-2.sh` con `schemathesis`, `dredd` o equivalente. Si no es viable, dejar el TODO explícito en la matriz de `docs/api-integracion.md`.
4. Actualizar `docs/ARQUITECTURA.md` con el árbol final.

### Gates y ergonomía

1. Endurecer `scripts/gate-6.sh`:
   - `set -euo pipefail` y `cd "$(git rev-parse --show-toplevel)"`;
   - verificar el prerrequisito de G5; si falta, imprimir “Ejecuta primero scripts/gate-5.sh” y salir con código 2;
   - `trap 'docker compose down --remove-orphans' EXIT`;
   - ser idempotente: dos ejecuciones seguidas dejan el entorno limpio y devuelven exit 0.
2. Verificar que `Makefile` expone `gate-all` y que `scripts/install-hooks.sh` instala el `pre-push` con `gate-lint` y el gate de la fase actual.
3. Actualizar el `README.md` con la sección “Desarrollo local” (`make up`, `make gate-N`, `make gate-all`) y “Fuente de verdad y espejos”.

### Release

1. Ejecutar `docker compose up --build`.
2. Ejecutar el smoke completo.
3. Ejecutar `gitleaks`.
4. Ejecutar la cobertura final.
5. Verificar que `FullStackKatEye` contiene el código de `KatEye-Front/` y `KatEye-Back/`, no solo documentación.
6. Ejecutar `scripts/sync-progreso.sh` y dejar ambos espejos listos para el commit final del usuario.
7. Revisar que cada fase tenga su documento y su memoria cerrados.
8. Ejecutar `scripts/gate-6.sh` dos veces seguidas y confirmar exit 0 sin contenedores huérfanos.
9. Ejecutar `make gate-all` y guardar la evidencia de exit 0.
10. Crear `docs/memoria/mm_devFase6.md` con los archivos creados y las acciones relevantes, en orden, y un resumen final con: qué se cambió, qué gates se vieron afectados y la evidencia de exit 0 de `make gate-all`.

## 4. Consecuencias

- El entorno se levanta con un solo comando y el frontend espera a que el backend esté sano.
- Nginx conserva el origen y evita el 403 de CORS en producción.
- La entrega incluye ERS, manual, APIs, integración y cobertura.
- El hardening de Nginx (resolver dinámico, gzip, caché) queda documentado como siguiente paso.
- El usuario realiza el commit final.

## 5. Gate G6 — Evidencia

```bash
cd TiendaKatEye

scripts/gate-6.sh
scripts/gate-6.sh
make gate-all
test -f scripts/install-hooks.sh
test -f docs/api-integracion.md

docker compose config
docker compose up --build -d
docker compose ps

curl -i http://localhost:8080/actuator/health
curl -i http://localhost/api/v1/productos
curl -I http://localhost/img/productos/kat-004.jpg

gitleaks detect --source .

git log --oneline -- KatEye-Front | head -5
git log --oneline -- KatEye-Back  | head -5
test -f docs/memoria/mm_devFase6.md && echo "memoria F6 OK"

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

Resultado esperado:

- Los tres contenedores levantan y el backend responde sano.
- `scripts/gate-6.sh` se ejecuta dos veces seguidas con exit 0 y sin contenedores huérfanos.
- `make gate-all` devuelve exit 0 en estado limpio.
- `docs/api-integracion.md` tiene la matriz completa; los endpoints sin test quedan como warning explícito.
- El smoke completo pasa.
- `gitleaks` limpio.
- El historial importado es visible por subdirectorio.
- `docs/memoria/mm_devFase6.md` existe y describe los archivos y acciones.
- Los espejos `ProyectoWebKatEyes` y `backendProyectoKatEye` quedaron listos para el commit final.

## 6. Registro de ejecución

- **Fecha:**
- **Autor:**
- **Comandos ejecutados:**
- **Resultado:**
- **Desviaciones:**
- **Memoria:** `docs/memoria/mm_devFase6.md`
- **Commit sugerido:** `chore: cierra Docker, documentación y release`
- **Commit realizado:**

## 7. Pendientes posteriores (fuera de la iteración)

- Cookie `httpOnly` para el token.
- Resolver DNS dinámico, gzip y caché de assets en Nginx.
- Panel de administración.
- Recuperación de contraseña en la interfaz.
- Rutas `/ofertas`, `/categorias` y `/mis-pedidos`, si la pauta las exige.
- Refresh token y revocación de sesión.
- Automatizar la sincronización de espejos dentro de un pipeline de CI.
