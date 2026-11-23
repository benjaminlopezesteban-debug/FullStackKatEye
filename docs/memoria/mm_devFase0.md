# Memoria de desarrollo — Fase 0

| | |
|---|---|
| **Fase** | F0 |
| **Gate** | G0 |
| **Estado** | Cerrada (commit pendiente del usuario) |
| **Documento de fase** | `../fases/F0-estructura.md` |

## Objetivo de la fase

Unificar `TiendaKatEye` como repositorio de entrega y entorno único de evaluación: importar el código y el historial de frontend y backend, dejar los repositorios independientes como espejos de progreso, eliminar los secretos por defecto y crear el compose, los scripts base y el `Makefile` que sostienen los gates.

## Archivos creados y modificados (en orden)

| # | Archivo | Acción | Qué hace |
|---|---|---|---|
| 1 | `KatEye-Front/` | Importado | Código e historial de `ProyectoWebKatEyes` reescritos bajo `KatEye-Front/` con `git filter-repo`. |
| 2 | `KatEye-Back/` | Importado | Código e historial de `backendProyectoKatEye` reescritos bajo `KatEye-Back/` con `git filter-repo`. |
| 3 | `.gitignore` | Creado | Excluye `.env`, builds, `node_modules`, `dist`, `*.zip`, `.idea`, `.gates` y artefactos locales. |
| 4 | `.env.example` | Creado | Inventario canónico de variables, sin secretos reales y con `KATEYE_PAGO_SIMULADO_RESULTADO=APROBADA`. |
| 5 | `docker-compose.yml` | Creado | `db`, `backend` y `frontend` en `kateye-net`; exige `JWT_SECRET` y `SPRING_DATASOURCE_PASSWORD`. |
| 6 | `docker-compose.rechazo.yml` | Creado | Override que fuerza `KATEYE_PAGO_SIMULADO_RESULTADO=RECHAZADA`. |
| 7 | `KatEye-DB/README.md` | Creado | Aclara que Flyway es el dueño del esquema y el volumen conserva los datos. |
| 8 | `KatEye-Back/docker-compose.yml` | Modificado | Compose legado neutralizado; apunta al compose raíz. |
| 9 | `KatEye-Back/.env.example` | Modificado | Inventario legado neutralizado; remite al `.env.example` raíz. |
| 10 | `KatEye-Back/katEye/src/main/resources/application.yml` | Modificado | `SPRING_DATASOURCE_PASSWORD` y `JWT_SECRET` sin valores por defecto. |
| 11 | `KatEye-Back/katEye.zip` | Destrackeado | Se deja de versionar; queda en disco e ignorado por `*.zip`. |
| 12 | `scripts/gate-0.sh` | Creado | Valida compose con `.env.example`, gitleaks, historial, Makefile, memoria y builds. |
| 13 | `scripts/gate-6.sh` | Creado | Prerrequisito G5, `trap` de limpieza, compose up, smoke, gitleaks y docs. |
| 14 | `scripts/sync-progreso.sh` | Creado | Sincroniza frontend/backend a los espejos con `rsync` sin commitear ni pushear. |
| 15 | `Makefile` | Creado | Targets `gate-0…gate-6`, `gate-lint`, `gate-all`, `sync`, `up`, `down` y `test`. |
| 16 | `README.md` | Modificado | Repositorio unificado, espejos, desarrollo local, comandos y estructura. |
| 17 | `docs/ARQUITECTURA.md`, `docs/fases/`, `docs/api-integracion.md`, `planificacion_desarrollo.md` | Modificados | Correcciones B1–B8 y árbol/Makefile/gates actualizados. |

## Acciones relevantes (en orden)

1. Se verificó que `mi-proyecto` y `KatEyeBackEnd` estaban limpios en `master`, con sus remotos de GitHub configurados.
2. Se instaló `git-filter-repo` con `pipx install git-filter-repo` (2.47.0).
3. Se clonaron ambos repositorios en `/tmp/opencode/kateye-integracion/` y se reescribieron sus rutas con `--to-subdirectory-filter`.
4. Se añadieron los historiales a `TiendaKatEye` con dos merges `--allow-unrelated-histories`; el historial de ambos proyectos queda visible por subdirectorio.
5. Se registraron los remotos `frontend` y `backend` como referencia para los espejos; `origin` sigue siendo `FullStackKatEye.git`.
6. Se crearon `.gitignore`, `.env.example`, los dos compose y `KatEye-DB/README.md`.
7. Se neutralizó el compose y el `.env.example` legados del backend y se quitaron los defaults de `JWT_SECRET` y `SPRING_DATASOURCE_PASSWORD`.
8. Se destrackeó `KatEye-Back/katEye.zip` y se agregó `*.zip` al `.gitignore`.
9. Se crearon `gate-0.sh`, `gate-6.sh`, `sync-progreso.sh` y `Makefile`; los gates de fases futuras fallan con un mensaje explícito.
10. Se actualizó el README con “Desarrollo local”, “Fuente de verdad y espejos”, comandos y estructura.

## Evidencia del gate

- Comando ejecutado: `scripts/gate-0.sh`
- Resultado: **exit 0**. Compose y override válidos con `.env.example`, gitleaks sin hallazgos, historial de ambos proyectos visible, `Makefile` y memoria presentes, build de backend y frontend correcto.
- Artefacto o salida guardada: `.gates/gate-0.ok` → `2026-11-22T23:48:58Z`.

## Desviaciones y pendientes

- **Desviación:** `docker-compose.yml` declara `build: ./KatEye-Front`, pero el `Dockerfile` y `nginx.conf` del frontend se crean en F6 (Docker completo). G0 solo valida `docker compose config`, no construye esa imagen.
- **Desviación:** la validación de compose usa `docker compose --env-file` con una copia temporal de `.env.example` en lugar de sobrescribir `.env`, para que el gate sea idempotente y no pise secretos locales.
- **Herramientas:** se instalaron `git-filter-repo` 2.47.0 con `pipx` y `gitleaks` 8.30.1 en `~/.local/bin` para poder ejecutar la importación y G0.
- **Pendiente:** los gates G1–G5 y `scripts/gate-lint.sh` se implementan en sus fases.
- **Pendiente:** el hook `pre-push` y `scripts/install-hooks.sh` se crean en F1.
- **Pendiente:** el usuario debe definir `.env` real y commitear el cierre de F0.
