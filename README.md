# TiendaKatEye — entorno de integración

Tienda de cosméticos KatEye. Este repositorio es el **entorno único de evaluación**: reúne el frontend React, el backend Spring Boot y la base MySQL, y permite levantar los tres contenedores con Docker Compose.

El código de aplicación vive **dentro de este repositorio unificado**, con el historial de ambos proyectos importado:

| Componente | Repositorio de origen | Carpeta local |
|---|---|---|
| Frontend React + Vite + Nginx | `ProyectoWebKatEyes` | `KatEye-Front/` |
| Backend Spring Boot + Flyway | `backendProyectoKatEye` | `KatEye-Back/` |
| Base de datos | — | `KatEye-DB/` |

Los repositorios `ProyectoWebKatEyes` y `backendProyectoKatEye` se conservan como **espejos de progreso**. El trabajo se hace en este repositorio y, al cerrar cada fase, `scripts/sync-progreso.sh` deja los cambios listos para commitear y pushear en cada espejo.

## Documentación

| Documento | Contenido |
|---|---|
| [`planificacion_desarrollo.md`](planificacion_desarrollo.md) | Plan maestro, decisiones, riesgos y fases |
| [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md) | Arquitectura, árboles ASCII y flujos |
| [`docs/fases/INDICE.md`](docs/fases/INDICE.md) | Índice y plantilla de la documentación por fase |
| [`docs/memoria/PLANTILLA.md`](docs/memoria/PLANTILLA.md) | Plantilla de la memoria de desarrollo por fase |
| [`docs/api-integracion.md`](docs/api-integracion.md) | Contrato, matriz de contract tests y CORS |
| [`informe-evaluacion-planificacion.md`](informe-evaluacion-planificacion.md) | Evaluación del plan anterior |

## Requisitos

- Docker Engine 24+ y Docker Compose v2.
- Git.
- Para desarrollo local sin Docker:
  - Java 21.
  - Node.js 20.19+ o 22.12+.
  - Maven 3.8+.
- `gitleaks` para el control de secretos (recomendado).

## Puesta en marcha

1. Clonar el repositorio unificado:

   ```bash
   git clone https://github.com/benjaminlopezesteban-debug/FullStackKatEye.git TiendaKatEye
   cd TiendaKatEye
   ```

   El código de `KatEye-Front/` y `KatEye-Back/` viene incluido en el mismo repositorio; no hay submódulos que inicializar.

2. Crear el archivo de variables de entorno:

   ```bash
   cp .env.example .env
   ```

   Editar `.env` y definir, como mínimo:

   ```bash
   MYSQL_DATABASE=kateye
   MYSQL_USER=kateye
   SPRING_DATASOURCE_PASSWORD=<definir>
   MYSQL_ROOT_PASSWORD=<definir>
   JWT_SECRET=<definir-un-secreto-largo>
   CORS_ORIGEN=http://localhost:5173
   KATEYE_PAGO_SIMULADO_RESULTADO=APROBADA
   BACKEND_PORT=8080
   KATEYE_PEDIDO_EXPIRACION_MINUTOS=30
   KATEYE_PEDIDO_ZONA_HORARIA=America/Santiago
   ```

   No versionar `.env`. El compose asigna `MYSQL_PASSWORD` desde `SPRING_DATASOURCE_PASSWORD` y no arranca si falta `JWT_SECRET`.

3. Levantar el entorno:

   ```bash
   docker compose up --build -d
   docker compose ps
   ```

4. Abrir la aplicación:

   - Frontend: <http://localhost>
   - API: <http://localhost/api/v1>
   - Salud del backend: `http://localhost:${BACKEND_PORT:-8080}/actuator/health`

## Desarrollo local

`TiendaKatEye` es la fuente de verdad. El trabajo se hace aquí y los gates se ejecutan con el `Makefile`:

```bash
make up          # docker compose up --build -d
make down        # docker compose down --remove-orphans
make gate-0      # gate de la fase F0 (equivalente a scripts/gate-0.sh)
make gate-3      # gate de la fase F3
make gate-all    # ejecuta gate-0 … gate-6 en orden
make gate-lint   # ESLint + Prettier + linter del backend
make sync        # scripts/sync-progreso.sh
make test        # suites de frontend y backend
```

Convención de gates:

- Cada `make gate-N` delega en `scripts/gate-N.sh`, que verifica el gate anterior y sale con código 2 si falta.
- `scripts/gate-lint.sh` es transversal y se ejecuta al inicio de `gate-1` y en el hook `pre-push`.
- `scripts/install-hooks.sh` instala `.git/hooks/pre-push`; el hook ejecuta `gate-lint` y el gate de la fase actual (detectada por la rama `fase-N` o por la variable `KATEYE_FASE`; si no se detecta, ejecuta `gate-lint` y avisa).

```bash
scripts/install-hooks.sh
```

## Comandos útiles

| Comando | Qué hace |
|---|---|
| `docker compose up --build -d` | Construye y levanta los tres contenedores |
| `make up` / `make down` | Atajos de `docker compose` con limpieza de huérfanos |
| `make gate-all` | Ejecuta todos los gates en orden |
| `make gate-N` | Ejecuta el gate de la fase N |
| `make gate-lint` | ESLint + Prettier + linter del backend |
| `docker compose logs -f backend` | Sigue los logs del backend |
| `docker compose down` | Detiene los contenedores |
| `docker compose down -v` | Detiene y borra el volumen de MySQL |
| `cd KatEye-Front && npm run dev` | Frontend en desarrollo con Vite (`:5173`) |
| `cd KatEye-Front && npm run test:run` | Pruebas del frontend con Vitest |
| `cd KatEye-Front && npm run test:coverage` | Cobertura del frontend |
| `mvn test -f KatEye-Back/katEye/pom.xml` | Pruebas del backend |
| `scripts/sync-progreso.sh` | Espeja los cambios en los repositorios independientes |
| `git log --oneline -- KatEye-Front` | Historial importado del frontend |
| `git log --oneline -- KatEye-Back` | Historial importado del backend |

## Desarrollo con CORS real

En desarrollo el navegador habla directamente con Spring en `http://localhost:8080`, por lo que CORS se ejercita de verdad. El backend necesita una base MySQL accesible en `localhost:3306`; si no la tienes, usa el backend en Docker (`docker compose up -d db backend`).

```bash
# Terminal 1: backend
cd KatEye-Back/katEye
./mvnw spring-boot:run

# Terminal 2: frontend
cd KatEye-Front
npm ci
npm run dev
```

El frontend usa `.env.development`:

```bash
VITE_API_URL=http://localhost:8080/api/v1
VITE_ASSETS_URL=http://localhost:8080
```

Verificar el preflight:

```bash
curl -i -X OPTIONS http://localhost:8080/api/v1/productos \
  -H "Origin: http://localhost:5173" \
  -H "Access-Control-Request-Method: GET"
```

Debe responder `200` con `Access-Control-Allow-Origin: http://localhost:5173`.

## Forzar el rechazo de pago

El resultado del pago simulado lo decide el backend. Para probar la pantalla de pago fallido y el reintento:

```bash
docker compose -f docker-compose.yml -f docker-compose.rechazo.yml up -d backend
```

Luego:

1. Agregar productos al carrito.
2. Ir a checkout y confirmar la compra.
3. El pedido se crea y el pago se rechaza.
4. Usar **Reintentar pago**: se reintenta sobre el mismo pedido, sin crear otro.

Para volver al flujo aprobado:

```bash
docker compose up -d backend
```

## Pruebas

| Nivel | Comando | Herramienta |
|---|---|---|
| Frontend | `cd KatEye-Front && npm run test:run` | Vitest + jsdom + Testing Library + MSW |
| Cobertura | `cd KatEye-Front && npm run test:coverage` | Vitest coverage |
| Backend | `mvn test -f KatEye-Back/katEye/pom.xml` | JUnit 5 + Spring Boot Test |
| CORS | `scripts/smoke-cors.sh` | `curl` |

## Fuente de verdad y espejos

`TiendaKatEye` es la fuente de verdad. Al cerrar cada fase:

```bash
scripts/sync-progreso.sh
```

El script copia `KatEye-Front/` y `KatEye-Back/` a los espejos, excluyendo `.git`, `node_modules`, `target`, `dist`, `coverage` y `.env`. No commitea ni pushea: deja los cambios para que los revises y los commitees en cada espejo. Si un espejo tiene cambios propios sin commitear, el script se detiene para evitar pérdidas.

Por defecto usa los espejos locales `../mi-proyecto` (frontend) y `../KatEyeBackEnd` (backend). Puedes apuntar a otras rutas con:

```bash
KATEYE_FRONT_MIRROR=/ruta/ProyectoWebKatEyes \
KATEYE_BACK_MIRROR=/ruta/backendProyectoKatEye \
scripts/sync-progreso.sh
```

## Memoria de desarrollo

Al finalizar cada fase se crea `docs/memoria/mm_devFaseX.md`. Allí se registran, en orden, los archivos creados o modificados y las acciones relevantes, con una descripción breve de qué hace cada uno. La plantilla está en `docs/memoria/PLANTILLA.md`.

## Secretos

- No se versionan `.env`, `.env.*` (salvo `.env.example`), `*.local`, `target/`, `node_modules/`, `dist/` ni `*.zip`.
- `JWT_SECRET` y las contraseñas de MySQL se definen en `.env`.
- Antes de publicar, ejecutar:

  ```bash
  gitleaks detect --source .
  ```

- Si un secreto estuvo expuesto en un commit, **rotarlo** (cambiar contraseña y generar otro `JWT_SECRET`) además de limpiar el historial.

## Estructura del repositorio

```text
TiendaKatEye/
├── Makefile                       # targets gate-0…gate-6, gate-lint, gate-all, sync, up, down, test
├── docker-compose.yml
├── docker-compose.rechazo.yml
├── .env.example
├── README.md
├── planificacion_desarrollo.md
├── informe-evaluacion-planificacion.md
├── scripts/
│   ├── gate-0.sh … gate-6.sh
│   ├── gate-lint.sh
│   ├── install-hooks.sh
│   ├── sync-progreso.sh
│   └── smoke-cors.sh
├── docs/
│   ├── ARQUITECTURA.md
│   ├── api-integracion.md
│   ├── fases/
│   └── memoria/
├── KatEye-Front/   # código + historial de ProyectoWebKatEyes
├── KatEye-Back/    # código + historial de backendProyectoKatEye
└── KatEye-DB/
```

## Fases

| Fase | Contenido | Gate |
|---|---|---|
| F0 | Historial importado, secretos y entorno unificado | G0 |
| F1 | Vitest, MSW y baseline | G1 |
| F2 | Axios, CORS y catálogo | G2 |
| F3 | Catálogo, contenido y ubicación | G3 |
| F4 | Sesión, registro y contacto | G4 |
| F5 | Carrito, checkout real y pagos | G5 |
| F6 | Docker, documentación y release | G6 |

Cada fase tiene su documento en `docs/fases/` y su memoria en `docs/memoria/mm_devFaseX.md`. Los commits los realiza el usuario al cerrar cada fase.

## Solución de problemas

| Síntoma | Causa probable | Acción |
|---|---|---|
| El backend no arranca | Falta `JWT_SECRET` en `.env` | Definirlo y volver a levantar |
| `403 Invalid CORS request` en producción | Nginx no conserva el `Host` | Revisar `proxy_set_header Host $http_host` |
| Imagen 404 | Falta el archivo en `KatEye-Back/media/img/productos/` | Agregarlo o dejarlo cubierto por `onError` |
| El carrito aparece vacío | Falla `GET /productos` | Revisar el backend y la consola del navegador |
| `vitest: not found` | Faltan dependencias | `cd KatEye-Front && npm ci` |
| `KatEye-Front/` o `KatEye-Back/` vacíos | Clonaste una versión con submódulos | Clonar `FullStackKatEye` completo; no usar `--recurse-submodules` |
| MySQL no está sano | Variables o volumen | Revisar `docker compose logs db` |

## Autores

Vicente Cuevas y Benjamín López.
