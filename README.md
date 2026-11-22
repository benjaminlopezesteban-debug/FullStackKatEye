# TiendaKatEye — entorno de integración

Tienda de cosméticos KatEye. Este repositorio es el **entorno único de evaluación**: reúne el frontend React, el backend Spring Boot y la base MySQL, y permite levantar los tres contenedores con Docker Compose.

El código de aplicación vive en sus repositorios independientes, enlazados como submódulos:

| Componente | Repositorio | Carpeta local |
|---|---|---|
| Frontend React + Vite + Nginx | `ProyectoWebKatEyes` | `KatEye-Front/` |
| Backend Spring Boot + Flyway | `backendProyectoKatEye` | `KatEye-Back/` |
| Base de datos | — | `KatEye-DB/` |

## Documentación

| Documento | Contenido |
|---|---|
| [`planificacion_desarrollo.md`](planificacion_desarrollo.md) | Plan maestro, decisiones, riesgos y fases |
| [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md) | Arquitectura, árboles ASCII y flujos |
| [`docs/fases/INDICE.md`](docs/fases/INDICE.md) | Índice y plantilla de la documentación por fase |
| [`informe-evaluacion-planificacion.md`](informe-evaluacion-planificacion.md) | Evaluación del plan anterior |

## Requisitos

- Docker Engine 24+ y Docker Compose v2.
- Git con soporte de submódulos.
- Para desarrollo local sin Docker:
  - Java 21.
  - Node.js 20.19+ o 22.12+.
  - Maven 3.8+.
- `gitleaks` para el control de secretos (recomendado).

## Puesta en marcha

1. Clonar el repositorio con submódulos:

   ```bash
   git clone --recurse-submodules <url-de-TiendaKatEye>
   cd TiendaKatEye
   ```

   Si ya está clonado:

   ```bash
   git submodule update --init --recursive
   ```

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
   PAGO_SIMULADO=APROBADA
   BACKEND_PORT=8080
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

## Comandos útiles

| Comando | Qué hace |
|---|---|
| `docker compose up --build -d` | Construye y levanta los tres contenedores |
| `docker compose logs -f backend` | Sigue los logs del backend |
| `docker compose down` | Detiene los contenedores |
| `docker compose down -v` | Detiene y borra el volumen de MySQL |
| `cd KatEye-Front && npm run dev` | Frontend en desarrollo con Vite (`:5173`) |
| `cd KatEye-Front && npm run test:run` | Pruebas del frontend con Vitest |
| `cd KatEye-Front && npm run test:coverage` | Cobertura del frontend |
| `mvn test -f KatEye-Back/katEye/pom.xml` | Pruebas del backend |

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
├── docker-compose.yml
├── docker-compose.rechazo.yml
├── .env.example
├── README.md
├── planificacion_desarrollo.md
├── informe-evaluacion-planificacion.md
├── scripts/
├── docs/
│   ├── ARQUITECTURA.md
│   └── fases/
├── KatEye-Front/   (submódulo)
├── KatEye-Back/    (submódulo)
└── KatEye-DB/
```

## Fases

| Fase | Contenido | Gate |
|---|---|---|
| F0 | Repositorios, secretos y orquestación | G0 |
| F1 | Vitest, MSW y baseline | G1 |
| F2 | Axios, CORS y catálogo | G2 |
| F3 | Catálogo, contenido y ubicación | G3 |
| F4 | Sesión, registro y contacto | G4 |
| F5 | Carrito, checkout real y pagos | G5 |
| F6 | Docker, documentación y release | G6 |

Cada fase tiene su documento en `docs/fases/`. Los commits los realiza el usuario al cerrar cada fase.

## Solución de problemas

| Síntoma | Causa probable | Acción |
|---|---|---|
| El backend no arranca | Falta `JWT_SECRET` en `.env` | Definirlo y volver a levantar |
| `403 Invalid CORS request` en producción | Nginx no conserva el `Host` | Revisar `proxy_set_header Host $http_host` |
| Imagen 404 | Falta el archivo en `KatEye-Back/media/img/productos/` | Agregarlo o dejarlo cubierto por `onError` |
| El carrito aparece vacío | Falla `GET /productos` | Revisar el backend y la consola del navegador |
| `vitest: not found` | Faltan dependencias | `cd KatEye-Front && npm ci` |
| MySQL no está sano | Variables o volumen | Revisar `docker compose logs db` |

## Autores

Vicente Cuevas y Benjamín López.
