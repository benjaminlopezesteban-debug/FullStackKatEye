# Fase F0 — Repositorios, secretos y orquestación

| | |
|---|---|
| **Fase** | F0 |
| **Gate** | G0 |
| **Estado** | Planificada |
| **Documento maestro** | `../../planificacion_desarrollo.md` |

## 1. Contexto

El plan anterior copiaba el frontend y el backend con `rsync --exclude='.git'` y luego inicializaba un repositorio nuevo. Eso destruía el historial de desarrollo, que la pauta usa en la ronda de preguntas, y mezclaba la migración MySQL con la integración nueva. Además, el `.gitignore` no estaba definido y `application.yml` contenía valores por defecto para el JWT y la base de datos.

Esta fase deja los repositorios de entrega listos y crea el esqueleto del **entorno único de evaluación** (`TiendaKatEye`), sin copiar código y sin tocar `kateyefullStack`.

## 2. Decisiones

- **D4:** `TiendaKatEye` es el repositorio de orquestación y el entorno único de evaluación; contiene compose, README y documentación, y referencia `KatEye-Front` y `KatEye-Back` como submódulos.
- **D12:** los repositorios de entrega son `ProyectoWebKatEyes` y `backendProyectoKatEye`; conservan su historial y su remoto. `kateyefullStack` no forma parte de la entrega.
- **D15:** secretos fuera del código; `.env` obligatorio; `gitleaks` en el gate.
- **D18:** los commits los realiza el usuario al cerrar la fase.

## 3. Cambios a aplicar

1. En cada repositorio de entrega:
   - Verificar `git status`.
   - Si hay cambios pendientes, crear la rama `pre-integracion` y dejarlos listos para que el usuario los commitee con un mensaje claro.
   - Verificar que el remoto de GitHub está configurado y actualizado.
2. En `TiendaKatEye`:
   - Crear `.gitignore` explícito: `.env`, `.env.*` (excepto `.env.example`), `*.local`, `target/`, `node_modules/`, `dist/`, `*.zip`, `.idea/`.
   - Crear `.env.example` con variables obligatorias y valores de ejemplo, sin secretos reales: `MYSQL_DATABASE`, `MYSQL_USER`, `SPRING_DATASOURCE_PASSWORD`, `MYSQL_ROOT_PASSWORD`, `JWT_SECRET`, `CORS_ORIGEN`, `PAGO_SIMULADO`, `BACKEND_PORT`.
   - Crear `README.md` con información para el usuario y despliegue.
   - Crear `docs/ARQUITECTURA.md`, `docs/fases/INDICE.md` y los siete documentos de fase.
   - Agregar los submódulos `KatEye-Front` y `KatEye-Back`.
   - Crear `KatEye-DB/README.md` e `init/` opcional.
   - Crear `docker-compose.yml` mínimo con `db`, `backend`, `frontend`, red `kateye-net`, `BACKEND_PORT` y `CORS_ORIGEN`.
   - Crear `docker-compose.rechazo.yml` con `KATEYE_PAGO_SIMULADO_RESULTADO=RECHAZADA`.
3. En `KatEye-Back`:
   - Neutralizar el `docker-compose.yml` legado (renombrarlo como legado o dejarlo fuera de la orquestación).
   - Quitar los valores por defecto de `JWT_SECRET` y `SPRING_DATASOURCE_PASSWORD` en `application.yml`.
   - Ajustar el compose para exigir `${JWT_SECRET:?defina JWT_SECRET en .env}`.
4. Crear `scripts/gate-0.sh` y la base de `scripts/gate-6.sh`.

## 4. Consecuencias

- Se conserva el historial git de ambos proyectos y la evidencia para la ronda de preguntas.
- Desaparecen los riesgos de copia con `rsync` y de repositorio anidado.
- El entorno de evaluación queda en un solo repositorio, pero el código sigue viviendo en sus repositorios independientes.
- El usuario debe definir `.env` antes de levantar el compose; el arranque falla si falta `JWT_SECRET`.
- La reorganización se limita a compose, README y documentación: no se mueve código de aplicación.

## 5. Gate G0 — Evidencia

```bash
cd TiendaKatEye

docker compose config
gitleaks detect --source .

git submodule status
git log --oneline -5

mvn -DskipTests package -f KatEye-Back/katEye/pom.xml
cd KatEye-Front && npm ci && npm run build
```

Resultado esperado:

- `docker compose config` válido.
- `gitleaks` sin hallazgos.
- Submódulos en la revisión esperada.
- Historial visible en ambos repositorios.
- Build de backend y frontend correcto.

## 6. Registro de ejecución

- **Fecha:**
- **Autor:**
- **Comandos ejecutados:**
- **Resultado:**
- **Desviaciones:**
- **Commit sugerido:** `chore: prepara repositorio de orquestación y secretos`
- **Commit realizado:**

## 7. Pendientes para la siguiente fase

- Confirmar que `.env` existe y no está versionado.
- Confirmar que los builds dejan artefactos en `target/` y `dist/`, ambos ignorados.
- Verificar que el README explica cómo levantar el entorno.
