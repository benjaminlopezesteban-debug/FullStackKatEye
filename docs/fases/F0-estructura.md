# Fase F0 — Repositorios, historial importado, secretos y entorno unificado

| | |
|---|---|
| **Fase** | F0 |
| **Gate** | G0 |
| **Estado** | Cerrada (commit pendiente) |
| **Documento maestro** | `../../planificacion_desarrollo.md` |

## 1. Contexto

El plan anterior trataba `TiendaKatEye` como un repositorio de orquestación con submódulos: el código seguía viviendo en `ProyectoWebKatEyes` y `backendProyectoKatEye`, y la entrega final no quedaba unificada. La dirección corregida es la **Solución A** del informe: `TiendaKatEye` es el repositorio único de entrega y debe contener el código y el historial de ambas partes.

`TiendaKatEye` ya existe como repositorio git con remoto `FullStackKatEye.git` y un commit de documentación. Esta fase importa el frontend y el backend en `KatEye-Front/` y `KatEye-Back/`, conserva sus historias con `git filter-repo` y deja los repositorios independientes como espejos de progreso.

## 2. Decisiones

- **D4:** `TiendaKatEye` es el repositorio unificado y el entorno único de evaluación; contiene el código de `KatEye-Front/` y `KatEye-Back/`, el compose, la documentación y `KatEye-DB/`.
- **D12:** `TiendaKatEye` es la entrega final; `ProyectoWebKatEyes` y `backendProyectoKatEye` quedan como espejos de progreso. El trabajo se hace en el monorepo y se sincroniza al cerrar cada fase.
- **D15:** secretos fuera del código; `.env` obligatorio; `gitleaks` en el gate.
- **D18:** los commits los realiza el usuario; las correcciones B1, B5, B6 y B8 pueden ir en commits separados.
- **D20:** al finalizar la fase se crea `docs/memoria/mm_devFase0.md`.
- **D21:** los gates son idempotentes: `set -euo pipefail`, `cd` a la raíz, prerrequisito del gate anterior y `trap` de limpieza en G6.
- **D23:** `Makefile` con targets de gates y hook `pre-push`; `sync-progreso.sh` documenta la política de espejos.

## 3. Cambios a aplicar

1. Crear un `zip` de respaldo de `mi-proyecto` y `KatEyeBackEnd` fuera del árbol de trabajo.
2. En cada repositorio independiente:
   - Verificar `git status` y la rama `master`.
   - Si hay cambios pendientes, crear la rama `pre-integracion` y dejarlos listos para que el usuario los commitee.
   - Verificar que el remoto de GitHub está configurado y actualizado.
3. Instalar `git filter-repo`:
   ```bash
   pipx install git-filter-repo
   git filter-repo --version
   ```
   Si no se puede instalar, usar `git subtree add` como alternativa (ver paso 5).
4. Clonar y reescribir las rutas en un directorio temporal:
   ```bash
   git clone <url-frontend> /tmp/kateye-integracion/frontend
   git clone <url-backend>  /tmp/kateye-integracion/backend

   git -C /tmp/kateye-integracion/frontend filter-repo --to-subdirectory-filter KatEye-Front
   git -C /tmp/kateye-integracion/backend  filter-repo --to-subdirectory-filter KatEye-Back
   ```
5. Fusionar el historial en `TiendaKatEye`:
   ```bash
   cd TiendaKatEye
   git remote add frontend-integracion /tmp/kateye-integracion/frontend
   git remote add backend-integracion  /tmp/kateye-integracion/backend
   git fetch --all
   git merge --allow-unrelated-histories frontend-integracion/master
   git merge --allow-unrelated-histories backend-integracion/master
   ```
   Alternativa sin `filter-repo`:
   ```bash
   git subtree add --prefix=KatEye-Front <url-frontend> master
   git subtree add --prefix=KatEye-Back  <url-backend>  master
   ```
6. Verificar que el código y el historial estén presentes:
   ```bash
   git log --oneline -- KatEye-Front | head -5
   git log --oneline -- KatEye-Back  | head -5
   ls KatEye-Front KatEye-Back
   ```
7. Configurar los remotos de los espejos como referencia para la alternativa `git subtree push`:
   ```bash
   git remote add frontend https://github.com/benjaminlopezesteban-debug/ProyectoWebKatEyes.git
   git remote add backend  https://github.com/benjaminlopezesteban-debug/backendProyectoKatEye.git
   ```
   `scripts/sync-progreso.sh` trabaja con las rutas locales de los espejos; los remotos quedan para la alternativa `git subtree push`.
8. Crear o actualizar los archivos base del repositorio:
   - `.gitignore` explícito: `.env`, `.env.*` (excepto `.env.example`), `*.local`, `target/`, `node_modules/`, `dist/`, `*.zip`, `.idea/`.
   - `.env.example` con `MYSQL_DATABASE`, `MYSQL_USER`, `SPRING_DATASOURCE_PASSWORD`, `MYSQL_ROOT_PASSWORD`, `JWT_SECRET`, `CORS_ORIGEN`, `KATEYE_PAGO_SIMULADO_RESULTADO=APROBADA` y `BACKEND_PORT`, sin secretos reales. Incluir un comentario que explique el override de rechazo.
   - `README.md` con información para el usuario, despliegue y la sección “Fuente de verdad y espejos”.
   - `docs/ARQUITECTURA.md`, `docs/fases/INDICE.md` y `docs/memoria/PLANTILLA.md`.
   - `KatEye-DB/README.md` e `init/` opcional.
   - `docker-compose.yml` mínimo con `db`, `backend`, `frontend`, red `kateye-net`, `BACKEND_PORT` y `CORS_ORIGEN`.
   - `docker-compose.rechazo.yml` con `KATEYE_PAGO_SIMULADO_RESULTADO=RECHAZADA`.
9. En `KatEye-Back`:
   - Neutralizar el `docker-compose.yml` legado.
   - Quitar los valores por defecto de `JWT_SECRET` y `SPRING_DATASOURCE_PASSWORD` en `application.yml`.
   - Ajustar el compose raíz para exigir `${JWT_SECRET:?defina JWT_SECRET en .env}`.
10. Crear `scripts/gate-0.sh`, `scripts/gate-6.sh` y `scripts/sync-progreso.sh`:
    - `set -euo pipefail` y `cd "$(git rev-parse --show-toplevel)"` al inicio;
    - verificación del gate anterior con salida 2 y mensaje “Ejecuta primero scripts/gate-(N-1).sh”;
    - `gate-6.sh` con `trap 'docker compose down --remove-orphans' EXIT`;
    - `gate-0.sh` valida `docker compose config` y el override con una copia temporal de `.env.example` a `.env`;
    - `sync-progreso.sh` empieza con un comentario de política: monorepo canónico, espejos de solo lectura, cuándo se sincroniza.
11. Crear `Makefile` con targets `gate-0`…`gate-6`, `gate-lint`, `gate-all`, `sync`, `up`, `down` y `test`; los gates aún no implementados fallan con un mensaje explícito.
12. Crear `docs/memoria/mm_devFase0.md` con:
    - los archivos creados o modificados, en orden;
    - las acciones relevantes, en orden;
    - una descripción breve de qué hace cada archivo o acción;
    - la evidencia del gate y las desviaciones.

## 4. Consecuencias

- `TiendaKatEye` contiene el código y el historial de frontend y backend, no solo punteros.
- La entrega final queda unificada en `FullStackKatEye`.
- Los repositorios independientes conservan su historial y se actualizan como espejos para la evaluación de progreso.
- El usuario debe definir `.env` antes de levantar el compose; el arranque falla si falta `JWT_SECRET`.
- La importación no usa `rsync`; `rsync` queda reservado para sincronizar los espejos, siempre excluyendo `.git`, `node_modules`, `target`, `dist` y `.env`.

## 5. Gate G0 — Evidencia

```bash
cd TiendaKatEye

# Compose en copia limpia
cp .env.example .env
docker compose config
docker compose -f docker-compose.yml -f docker-compose.rechazo.yml config

gitleaks detect --source .

git log --oneline -- KatEye-Front | head -5
git log --oneline -- KatEye-Back  | head -5
git remote -v
bash -n scripts/*.sh
test -f Makefile && make -n gate-0
grep -q '^KATEYE_PAGO_SIMULADO_RESULTADO=APROBADA' .env.example
test -f docs/memoria/mm_devFase0.md && echo "memoria F0 OK"

mvn -DskipTests package -f KatEye-Back/katEye/pom.xml
(cd KatEye-Front && npm ci && npm run build)
```

Resultado esperado:

- `docker compose config` y el override son válidos con una copia limpia de `.env.example`.
- `gitleaks` sin hallazgos.
- El historial de ambos proyectos es visible por subdirectorio.
- Los remotos `origin`, `frontend` y `backend` están configurados.
- `scripts/*.sh` pasa la verificación de sintaxis y los gates tienen prerrequisitos.
- `Makefile` existe y `make -n gate-0` no falla.
- `.env.example` contiene `KATEYE_PAGO_SIMULADO_RESULTADO=APROBADA`.
- `docs/memoria/mm_devFase0.md` existe y describe los archivos y acciones.
- Build de backend y frontend correcto.

## 6. Registro de ejecución

- **Fecha:** 2026-11-22
- **Autor:** Benjamín López
- **Comandos ejecutados:** `pipx install git-filter-repo`; clones en `/tmp/opencode/kateye-integracion/`; `git filter-repo --to-subdirectory-filter`; dos `git merge --allow-unrelated-histories`; `scripts/gate-0.sh`.
- **Resultado:** G0 en verde (`exit 0`). Compose y override válidos con `.env.example`, gitleaks sin hallazgos, historial de frontend y backend visible por subdirectorio, `Makefile` y memoria presentes, build de backend y frontend correcto. Evidencia en `.gates/gate-0.ok`.
- **Desviaciones:** el `Dockerfile`/`nginx.conf` del frontend quedan para F6; la validación de compose usa `--env-file` con una copia temporal de `.env.example` para no pisar `.env`.
- **Commit sugerido:** `chore: unifica frontend y backend con historial importado`
- **Commit realizado:** pendiente (lo realiza el usuario)

## 7. Pendientes para la siguiente fase

- Confirmar que `.env` existe y no está versionado.
- Confirmar que `KatEye-Front/` y `KatEye-Back/` tienen código y no solo archivos de configuración.
- Confirmar que `scripts/sync-progreso.sh` deja los espejos listos sin commitear automáticamente y que su comentario de política coincide con el README.
- Verificar que el README explica cómo clonar el repo unificado, sin `--recurse-submodules`, y contiene “Fuente de verdad y espejos”.
- Confirmar que `Makefile` y `scripts/gate-0.sh` comparten los mismos comandos de validación.
- Confirmar que todas las variables usadas por `docker-compose.yml` y `docker-compose.rechazo.yml` están en `.env.example`.
