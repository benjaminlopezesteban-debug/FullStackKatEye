# Planificación — TiendaKatEye (v2 corregida)

| | |
|---|---|
| **Proyecto** | KatEye / TiendaKatEye |
| **Versión** | 2.1 — repositorio unificado, espejos de progreso y memoria por fase |
| **Fecha** | 2026-11-21 |
| **Estado** | Plan aprobado para ejecución por fases |
| **Alcance** | Conciliar el frontend React con el backend Spring Boot, integrar el checkout real, unificar frontend, backend y base de datos en `TiendaKatEye` como entorno único de evaluación y documentar cada fase |
| **Documentos de referencia** | `informe-evaluacion-planificacion.md`, `docs/ARQUITECTURA.md`, anexo de la Evaluación 3, `KatEye-Back/docs/proyecto/ARQUITECTURA_BACKEND.md` |

---

## 0. Glosario

| Término | Significado en este plan |
|---|---|
| **Alternativa A** | Conciliar el frontend existente con el backend: conservar vistas, estilos y navegación; no rehacer la SPA. |
| **Ejecución híbrida** | Conservar la mayoría de las vistas y reescribir solo los módulos de sesión, carrito, checkout y pago. |
| **Gate (Gx)** | Verificación ejecutable al cerrar la fase Fx. No se avanza si el gate falla. |
| **Rebanada vertical** | Funcionalidad completa de punta a punta (axios + CORS + catálogo visible) antes de ampliar el resto de entidades. |
| **Parte del monorepo** | `KatEye-Front/` o `KatEye-Back/` dentro de `TiendaKatEye`; contienen el código real y el historial importado del repositorio independiente. |
| **Repositorio espejo** | `ProyectoWebKatEyes` o `backendProyectoKatEye`; conservan el historial de progreso y se actualizan desde el monorepo al cerrar cada fase. |
| **Memoria de desarrollo** | `docs/memoria/mm_devFaseX.md`: archivo que registra, en orden, los archivos creados y las acciones relevantes de cada fase. |
| **Idempotency-Key** | Cabecera que evita duplicar pedidos o pagos cuando el cliente reintenta una operación. |
| **Mock** | Dato o módulo simulado local que debe desaparecer cuando la vista consume la API. |
| **Entorno único de evaluación** | `TiendaKatEye` contiene el código unificado y levanta los tres contenedores con `docker compose up --build`; es el entorno que se presenta. |

---

## 1. Resumen ejecutivo

El backend ya está implementado sobre MySQL 8.4 LTS como monolito modular Spring Boot. Expone una API REST versionada en `/api/v1`, autenticación JWT, catálogo, blogs, regiones/comunas, contacto, checkout para invitados, pagos simulados y pedidos con estados.

El frontend real es `mi-proyecto` (repositorio `ProyectoWebKatEyes`): una SPA React 19 + Vite + Bootstrap con una capa de datos simulada en archivos JavaScript. Esa capa se reemplaza por clientes HTTP; las vistas, los estilos y la navegación se conservan.

La decisión sigue siendo **conciliar, no rehacer**, pero con cuatro cambios de fondo respecto de la versión anterior:

1. **El checkout real se integra en esta iteración.** No se mantiene un checkout simulado local que nunca llega al backend.
2. **El historial git se conserva y se unifica.** Se clonan los repositorios, se reescriben sus rutas con `git filter-repo` y se fusionan en `TiendaKatEye`; no se usa `rsync` para importar. Los repositorios independientes quedan como espejos de progreso.
3. **CORS se demuestra.** En desarrollo el navegador habla cross-origin con Spring; en producción Nginx conserva el origen.
4. **Cada fase deja documentación y memoria.** Un archivo por fase con contexto, decisiones, cambios y consecuencias; un `docs/memoria/mm_devFaseX.md` con los archivos creados y las acciones relevantes en orden; y `docs/ARQUITECTURA.md` con los árboles ASCII.

Las pruebas del frontend usan **Vitest** como marco general, con jsdom, Testing Library y MSW. El backend mantiene JUnit 5 + Spring Boot Test.

---

## 2. Decisiones cerradas

| ID | Decisión |
|---|---|
| **D1** | Alternativa A con ejecución híbrida: conciliar el frontend existente; conservar vistas, estilos y navegación; reescribir sesión, carrito, checkout y pago. |
| **D2** | Pruebas del frontend con **Vitest** + jsdom + Testing Library + MSW + cobertura. Pruebas del backend con JUnit 5 + Spring Boot Test. |
| **D3** | Imágenes de producto en el backend, en un volumen externo `media/img/productos/`, con una sola fuente de verdad: la URL que entrega la API. |
| **D4** | `TiendaKatEye` es el repositorio unificado y el **entorno único de evaluación**. Contiene compose, README, documentación, `KatEye-DB/` y el código de `KatEye-Front/` y `KatEye-Back/` con su historial importado. |
| **D5** | Se mantiene `react-router-dom` 7.18.5 en esta iteración. No se cambia de versión. |
| **D6** | El carrito se conserva hasta que el backend confirma la creación del pedido (`POST /checkout` responde 2xx). |
| **D7** | El correo de contacto es **opcional**, alineado con las reglas del curso. |
| **D8** | Validación de correo en login/registro: solo `@duoc.cl`, `@profesor.duoc.cl` y `@gmail.com`. Contraseña de **4 a 10 caracteres**. |
| **D9** | Token JWT en `localStorage` (`kateye_token`) con mitigaciones: prohibido `dangerouslySetInnerHTML` con contenido del backend, CSP en Nginx, interceptor central ante 401 y expiración documentada. |
| **D10** | El rechazo de pago se fuerza en el backend con `KATEYE_PAGO_SIMULADO_RESULTADO=RECHAZADA`, mediante `docker-compose.rechazo.yml`. |
| **D11** | El checkout real se integra en esta iteración (F5). No queda checkout ni pago simulado local. |
| **D12** | `TiendaKatEye` es la entrega final unificada. Los repositorios independientes `ProyectoWebKatEyes` y `backendProyectoKatEye` se conservan como **espejos de progreso**: el trabajo se hace en `TiendaKatEye` y, al cerrar cada fase, `scripts/sync-progreso.sh` prepara los cambios para que el usuario los commitee y pushee en cada espejo. El repositorio raíz `kateyefullStack` no forma parte de la entrega. |
| **D13** | Solo las imágenes de producto pasan al backend. Logo, hero y blogs permanecen en el frontend, con el contrato de `imagen` documentado. |
| **D14** | CORS real en desarrollo (cross-origin) y same-origin en producción mediante Nginx. |
| **D15** | Secretos fuera del código: `${JWT_SECRET}` y `${SPRING_DATASOURCE_PASSWORD}` sin valor por defecto; `.env` obligatorio; `gitleaks` en los gates G0 y G6. |
| **D16** | MSW intercepta a nivel de red. ESLint prohíbe `fetch` y la importación de `axios` fuera de `src/api/client.js`. |
| **D17** | `Idempotency-Key` es obligatoria en `POST /checkout` y `POST /pagos/simular`; el backend la declara `required = true` y la documenta. |
| **D18** | **Los commits los realiza el usuario.** Convención: un commit de fase; para las correcciones B1–B8, un commit por bloque con el mensaje `chore(gates): Bn — <resumen>`. El plan solo sugiere mensajes y puntos de commit; no se automatizan commits. |
| **D19** | Docker: se aplica el mínimo viable ahora (healthcheck del backend, `depends_on: service_healthy`, puerto compartido y cabecera `Host`). Resolver DNS, gzip y caché de assets quedan como hardening posterior. |
| **D20** | Al finalizar cada fase debe existir `docs/memoria/mm_devFaseX.md`. Es la memoria del desarrollo: registra en orden los archivos creados o modificados y las acciones relevantes, con una descripción breve de qué hace cada uno. Se completa durante la fase y se cierra al terminarla. |
| **D21** | Los gates son idempotentes y auditables: `set -euo pipefail`, `cd` a la raíz del repo, verificación del gate anterior con salida 2 y `trap` de limpieza en G5/G6. G6 debe poder ejecutarse dos veces seguidas sin dejar contenedores huérfanos. |
| **D22** | La calidad es bloqueante: cobertura con umbral que falla, `scripts/gate-lint.sh` obligatorio y contract tests de los endpoints críticos. MSW queda solo en tests, nunca en `src/` de runtime. |
| **D23** | `Makefile` y hook `pre-push` son parte de la ergonomía: `make gate-0…gate-6`, `gate-lint`, `gate-all`, `sync`, `up`, `down` y `test`; el hook ejecuta lint y el gate de la fase actual. |

### Correcciones de auditoría (B1–B8)

Estas correcciones se incorporan a las fases existentes; no crean fases ni gates nuevos. `scripts/gate-lint.sh` es transversal y se documenta en `docs/fases/INDICE.md`.

| Bloque | Cambio | Fase / gate | Evidencia |
|---|---|---|---|
| **B1** | Gates idempotentes: prerrequisito del gate anterior, `set -euo pipefail`, `cd` a la raíz y `trap` de limpieza en G5/G6. | F0, F5, F6 / G0, G5, G6 | `gate-6.sh` dos veces con exit 0 y sin contenedores huérfanos; `gate-5.sh` usa el override de rechazo. |
| **B2** | Cobertura bloqueante: líneas ≥ 80 y branches ≥ 70, ajustadas al baseline y documentadas; `docs/cobertura.md` se regenera desde `gate-1.sh`. | F1 / G1 | `gate-1.sh` falla si baja del umbral; encabezado “Generado automáticamente…”. |
| **B3** | Anti-mocks en dos capas: `grep` de MSW/HTTP en runtime y contract test del cliente real. | F2, F3 / G2, G3 | `grep` vacío en `src/` (excluyendo tests) y contract test verde. |
| **B4** | Lint bloqueante con ESLint + Prettier en frontend y linter del backend. | F1 / G1 | `scripts/gate-lint.sh` exit 0; se invoca al inicio de G1 y en `pre-push`. |
| **B5** | Fuente de verdad y espejos: README y comentario de política en `sync-progreso.sh`. | F0, F6 / G0, G6 | README y script coherentes con `docs/ARQUITECTURA.md`. |
| **B6** | `.env.example` completo y validado, incluido `KATEYE_PAGO_SIMULADO_RESULTADO=APROBADA`; compose validado en entorno limpio. | F0 / G0 | `docker compose config` y el override pasan con solo `.env.example` copiado a `.env`. |
| **B7** | Matriz de contract tests en `docs/api-integracion.md`; OpenAPI si es viable. | F2, F5, F6 / G2, G5, G6 | Cada endpoint crítico tiene test y gate; los no cubiertos se reportan como warning. |
| **B8** | `Makefile` con targets de gates y `scripts/install-hooks.sh` para `pre-push`. | F0, F1, F6 / G0, G1, G6 | `make gate-all` exit 0 en estado limpio; hook documentado en README. |

Mensajes de commit sugeridos por bloque: `chore(gates): B1 — idempotencia y limpieza`, `B2 — umbral de cobertura`, `B3 — anti-mocks y contract test`, `B4 — gate de lint`, `B5 — fuente de verdad y espejos`, `B6 — .env.example validado`, `B7 — matriz de contract tests`, `B8 — Makefile y pre-push`.

### Correcciones técnicas

- **`react-router-doom` no existe en npm.** Se usa `react-router-dom`, que ya está instalado en `mi-proyecto` (`^7.18.5`). En esta iteración se mantiene ese paquete como único punto de importación y se documenta en el README.
- **No se modifican las migraciones V1–V6.** Las URLs semilla ya apuntan a `/img/productos/{codigo}.jpg`; los archivos se sirven desde el volumen `media/img/productos/`.
- **`Idempotency-Key` es obligatoria en la práctica.** `IdempotenciaService` lanza `SolicitudInvalidaException` si falta; el controlador debe declararla `required = true` para que el contrato coincida con el comportamiento.
- **El carrito se vacía al crear el pedido**, no al aprobar el pago. Si el pago es rechazado, el pedido ya existe y se reintenta con `POST /pagos/{numero}/reintentar`.
- **`GET /productos` devuelve una lista, no una página.** Los filtros de categoría y precio se resuelven en el servidor con `categoriaId`, `precioMin` y `precioMax`; no se duplica el filtrado en el cliente.
- **El backend agregará `imagenUrl` en `ProductoResponse` en F2** para que el frontend no reconstruya la URL con `codigo.toLowerCase()`.
- **`TiendaKatEye` ya es un repositorio git** con remoto `FullStackKatEye.git` y un commit de documentación. F0 no lo crea: importa el código y el historial de ambos proyectos.
- **`git filter-repo` no está instalado** en el entorno actual; `pipx` sí. F0 lo instala o usa `git subtree add` como alternativa.

### Hallazgos del informe y tratamiento

| Hallazgo | Tratamiento en este plan | Fase |
|---|---|---|
| **H1** Checkout y pago diferidos | Checkout real en F5; se elimina la simulación local, se usa `Idempotency-Key` y se reintenta sobre el mismo pedido | F5 |
| **H2** Pérdida del historial git | Monorepo con historial importado (`git filter-repo` + merge); ramas `pre-integracion`; sin `rsync` para importar; espejos de progreso; el usuario commitea por fase | F0 |
| **H3** CORS no demostrado | Cross-origin real en desarrollo; `CorsIT`; Nginx conserva `Host`; `server.forward-headers-strategy=framework` | F2 |
| **H4** Secretos en repositorio público | `.gitignore` explícito; secretos sin default; `gitleaks`; rotación si hubo exposición | F0 |
| **H5** Validaciones divergentes | Dominios del curso, contraseña 4–10 y contacto opcional en frontend y backend | F4 |
| **H6** Imágenes con doble fuente de verdad | Volumen externo, `imagenUrl` desde la API, sin placeholders falsos, tabla de reconciliación y script | F2 |
| **H7** Inconsistencias internas | Gates G0–G6, glosario, decisiones cerradas, `$PROYECTOS`, un archivo por fase, `mm_devFaseX.md` y `docs/ARQUITECTURA.md` | F0–F6 |
| **H8** Sin trazabilidad con la pauta | Matriz de trazabilidad, tarea de `axios`, ESLint restrictivo, cobertura, ERS y documentación de APIs | F1/F6 |
| **H9** Prioridades invertidas | F0 mínimo y F2 como rebanada vertical; Docker completo al final | F0–F6 |
| **H10** Carrito sin reglas | Reconciliación con catálogo, límite 10, precios del backend, `kateye_carrito_v2` y estados de carga/error | F5 |
| **H11** Adaptadores y mocks | Sin adaptadores; DTO real; borrado de módulos mock; filtros en servidor | F3 |
| **H12** Tests al final | Tests por fase; Vitest + MSW; gates con suite verde | F1–F5 |
| **H13** JWT sin mitigaciones | CSP, sin `dangerouslySetInnerHTML`, interceptor 401 y expiración documentada | F4/F6 |
| **H14** Docker frágil | Healthcheck, `depends_on: service_healthy`, `BACKEND_PORT` y cabecera `Host`; hardening posterior | F6 |
| **H15** Hallazgos menores | Router único, `KatEye-DB`, `$PROYECTOS`, `java -version`, fallback de UUID y una sola tarea para restos de CRA | F0–F6 |

---

## 3. Estado de partida

| Elemento | Estado real |
|---|---|
| `TiendaKatEye/` | Repositorio git propio con remoto `FullStackKatEye.git` y un commit de documentación; todavía no contiene el código, el compose ni `KatEye-DB/` |
| `ProyectoWebKatEyes` / `mi-proyecto` | Repositorio git independiente, limpio, en `master`, con historial y remoto en GitHub; será espejo de progreso |
| `backendProyectoKatEye` / `KatEyeBackEnd` | Repositorio git independiente, limpio, en `master`, con historial y remoto en GitHub; será espejo de progreso |
| `kateyefullStack` | Repositorio raíz del workspace; no es parte de la entrega y no se modifica |
| `git filter-repo` | No está instalado; `pipx` sí está disponible. F0 lo instala o usa `git subtree add` como alternativa |
| Backend | Monolito modular Spring Boot 4.1.2 / Java 21; MySQL 8.4; Flyway V1–V6 |
| Frontend | React 19 + Vite + Bootstrap; capa de datos en `productos.js`, `blogs.js`, `regiones.js`, `usuarios.js`, `pedidos.js`, `pagos.js` |
| Vitest | Tests escritos en `src/test/`, pero sin dependencia ni scripts en `package.json` |
| Imágenes | `KatEyeBackEnd/katEye/src/main/resources/static` está vacío; el frontend tiene 9 imágenes locales |
| Validaciones | Backend: correo `@Email` cualquiera y contraseña 4–72. Frontend: dominios del curso y contraseña 4–10 |
| Imágenes en API | `ProductoResponse` no expone la URL de la imagen; `ProductoImagenResponse` sí existe |
| Compose | `KatEyeBackEnd/docker-compose.yml` es legado y apunta a `./frontend`; se neutraliza en F0 |
| Secretos | `application.yml` tiene valores por defecto para JWT y base de datos; `.env.example` contiene un secreto de ejemplo |
| Idempotencia | El servicio la exige, pero el controlador la declara opcional |

---

## 4. Arquitectura objetivo

La arquitectura completa, con árboles ASCII y diagramas de despliegue, vive en **`docs/ARQUITECTURA.md`**. Resumen:

```text
TiendaKatEye/                      ← repo unificado y entorno único de evaluación
├── docker-compose.yml             ← db, backend, frontend; red kateye-net
├── docker-compose.rechazo.yml     ← override para forzar pago rechazado
├── .env.example                   ← sin secretos reales; variables obligatorias
├── README.md                      ← información para el usuario y despliegue
├── scripts/                       ← gates, smoke y sincronización de espejos
├── docs/
│   ├── ARQUITECTURA.md            ← árboles ASCII y flujos
│   ├── fases/                     ← INDICE.md + F0…F6
│   ├── memoria/                   ← PLANTILLA.md + mm_devFase0…6.md
│   ├── ERS-v2.md
│   ├── cobertura.md
│   ├── api-integracion.md
│   └── manual-usuario.md
├── KatEye-Front/                  ← código + historial importado de ProyectoWebKatEyes
├── KatEye-Back/                   ← código + historial importado de backendProyectoKatEye
└── KatEye-DB/                     ← README (+ init opcional); Flyway sigue siendo el dueño del esquema
```

El `README.md` de la raíz es el documento para el usuario y el despliegue; el índice y la plantilla de la documentación por fase viven en `docs/fases/INDICE.md`; la memoria de cada fase vive en `docs/memoria/mm_devFaseX.md`.

### Sincronización de espejos

`TiendaKatEye` es la fuente de verdad. Al cerrar cada fase, `scripts/sync-progreso.sh`:

1. Verifica que los espejos no tengan cambios sin commitear.
2. Copia `KatEye-Front/` → `ProyectoWebKatEyes/` y `KatEye-Back/` → `backendProyectoKatEye/`, excluyendo `.git`, `node_modules`, `target`, `dist` y `.env`.
3. Deja los cambios listos para que el usuario los revise, commitee y pushee en cada espejo.

El script no commitea ni pushea automáticamente. La alternativa `git subtree push` queda documentada, pero el flujo recomendado es el espejo por script porque tolera mejor los merges del frontend.

```text
DESARROLLO
React :5173  ──Axios cross-origin──▶  Spring :8080
     │                                   │
     └── GET /img/productos/*.jpg ──────▶ (VITE_ASSETS_URL=http://localhost:8080)
CORS real: Origin http://localhost:5173

PRODUCCIÓN (Docker)
Navegador ─▶ Nginx :80 ─┬─▶ SPA estática
                        ├─▶ /api/* ─▶ backend:8080
                        └─▶ /img/* ─▶ backend:8080
Nginx conserva Host ($http_host) y X-Forwarded-*; Spring lo trata como same-origin.
```

---

## 5. Riesgos y mitigaciones

| ID | Riesgo | Señal | Mitigación | Rollback |
|---|---|---|---|---|
| **R1** | Pérdida o duplicación del historial git | `git log` con un solo commit o repo raíz trackeando el backend | Clonar + `git filter-repo` + merge en `TiendaKatEye`; ramas `pre-integracion`; no usar `rsync` para importar; no tocar `kateyefullStack` | Restaurar desde GitHub o desde el zip de respaldo |
| **R2** | Secretos publicados en un repositorio público | `gitleaks` con hallazgos; `.env` versionado | `.gitignore` explícito; `${JWT_SECRET}` y `${SPRING_DATASOURCE_PASSWORD}` sin default; compose `${JWT_SECRET:?}`; rotar si hubo exposición | Rotar secreto y, si es necesario, limpiar el historial |
| **R3** | CORS no demostrado o 403 en Docker | Preflight falla; `403 Invalid CORS request` | Cross-origin en desarrollo; `CorsIT`; Nginx con `Host $http_host`; `server.forward-headers-strategy=framework` | Volver al proxy same-origin |
| **R4** | Puerto 8080 ocupado | `docker compose up` falla | `BACKEND_PORT` en compose, Vite con `loadEnv` y scripts | Volver al puerto anterior |
| **R5** | Imágenes 404 o mal emparejadas | 404 o foto de otro producto | Volumen `media/img/productos`; `imagenUrl` desde la API; tabla de reconciliación; `onError` | Placeholder local `onError` |
| **R6** | Flyway falla por editar migraciones aplicadas | Checksum mismatch al arrancar | No editar V1–V6; nueva migración solo si es imprescindible | Restaurar migraciones originales |
| **R7** | Carrito con precios o stock obsoletos | Total local distinto del backend | Reconciliar con el catálogo al montar; precios del backend; `kateye_carrito_v2`; estados de carga y error | Restaurar `CarritoProvider` anterior |
| **R8** | La sesión se rompe al migrar a JWT | Usuario nulo tras login; 401 inesperado | `/usuarios/me`; interceptor 401; token en `kateye_token` | Volver temporalmente a sesión local |
| **R9** | Tests no ejecutables | `vitest: not found` | Instalar Vitest, jsdom y MSW en F1; correr baseline | No avanzar de gate |
| **R10** | Falta `Idempotency-Key` | 400 en checkout o pago | Helper `nuevaIdempotencyKey()` con fallback; `useRef` por intento | Reintentar con una clave nueva |
| **R11** | Se mezclan checkout simulado y real | Llamadas accidentales a módulos locales | Eliminar `pedidos.js` y `pagos.js`; sin flag `VITE_CHECKOUT_MODE`; ESLint | Revertir imports |
| **R12** | Build Docker con rutas viejas | `build: ./frontend` falla | Compose raíz con contextos `./KatEye-Back/katEye` y `./KatEye-Front` | Usar el compose del repositorio correspondiente |
| **R13** | Tests acoplados a la implementación de Axios | Tests frágiles al refactorizar | MSW a nivel de red; no mockear Axios | Reescribir el test contra el contrato HTTP |
| **R14** | `crypto.randomUUID()` no disponible en HTTP LAN | Error al generar la clave | Helper con alternativa de respaldo | Generar clave con `Math.random` y timestamp |
| **R15** | Documentación desactualizada | Árbol o decisiones divergen del código | Actualizar `docs/ARQUITECTURA.md`, el archivo de fase y `mm_devFaseX.md` en cada gate | Revisión obligatoria en G6 |
| **R16** | Los espejos de progreso divergen del monorepo | Cambios en `ProyectoWebKatEyes` o `backendProyectoKatEye` que no están en `TiendaKatEye` | `TiendaKatEye` es la fuente de verdad; `sync-progreso.sh` aborta si el espejo tiene cambios sin commitear; revisar antes de sincronizar | Reconciliar manualmente y volver a sincronizar |
| **R17** | Gates no idempotentes o contenedores huérfanos | `gate-6.sh` falla en la segunda ejecución o quedan contenedores | Prerrequisito del gate anterior, `trap` de limpieza y `docker compose down --remove-orphans`; ejecutar G6 dos veces | Bajar el entorno y corregir el gate antes de avanzar |
| **R18** | Cobertura o lint no bloqueantes | El gate pasa aunque baje la cobertura o haya errores de estilo | Umbral explícito en `gate-1.sh`; `gate-lint.sh` con exit != 0; ambos obligatorios | Ajustar el baseline documentado o corregir el código |
| **R19** | MSW reaparece en runtime | `grep` encuentra `msw` o `setupWorker` en `src/` | Chequeo de dos capas y contract test; MSW solo en `src/test/` | Retirar el mock y volver a ejecutar G3 |
| **R20** | Variables de compose fuera de `.env.example` | `docker compose config` falla en máquina limpia | Inventario de variables, `.env.example` completo y validación con copia temporal | Completar `.env.example` y repetir G0 |

---

## 6. Pre-flight obligatorio

Antes de tocar código:

- Confirmar que se trabaja en `TiendaKatEye` (remoto `FullStackKatEye.git`) y que `KatEye-Front/` y `KatEye-Back/` se importarán desde `ProyectoWebKatEyes` y `backendProyectoKatEye`.
- No modificar `kateyefullStack` ni usar su copia del backend como fuente de verdad.
- Ejecutar `git -C mi-proyecto status` y `git -C KatEyeBackEnd status`; si hay cambios pendientes, dejarlos listos en una rama `pre-integracion` para que el usuario los commitee antes de importarlos.
- Crear un `zip` de respaldo de ambos proyectos fuera del árbol de trabajo.
- Verificar `git filter-repo --version`; si falta, instalar con `pipx install git-filter-repo` o usar `git subtree add` como alternativa.
- Verificar `java -version` (Java 21), `node -v` (20.19+ o 22.12+), `npm -v`, `mvn -v` (3.8+) y `docker compose version`.
- Verificar `gitleaks version`.
- Verificar que los puertos 8080, 80 y 3306 estén libres con `ss -ltnp` y `docker ps`.
- Confirmar espacio libre suficiente.
- Ejecutar `npm ci` y `mvn -DskipTests package` en los proyectos antes de editar.
- Confirmar que `TiendaKatEye` es el único entorno de evaluación, que los repositorios independientes son espejos de progreso y que los commits los hará el usuario al cerrar cada fase.

---

## 7. Estrategia de imágenes

Las imágenes de producto se sirven desde el backend, en un volumen externo:

```text
KatEye-Back/media/img/productos/
├── kat-002.jpg
├── kat-004.jpg
├── kat-005.jpg
├── kat-014.jpg
└── (las demás se cubren con onError)
```

Backend:

```yaml
spring:
  web:
    resources:
      static-locations: file:/app/media/,classpath:/static/
```

Compose:

```yaml
backend:
  volumes:
    - ./KatEye-Back/media:/app/media
```

La API entrega la URL en `ProductoResponse.imagenUrl`; el frontend no la reconstruye:

```js
export function urlAsset(ruta) {
  return `${import.meta.env.VITE_ASSETS_URL ?? ""}${ruta}`;
}
```

### Tabla de reconciliación

| Código | Nombre en la API | Asset local | Destino |
|---|---|---|---|
| KAT-001 | Sérum Vitamina C | — | `onError` |
| KAT-002 | Crema Hidratante Ácido Hialurónico | `Crema Hidratante Facial.jpg` | `media/img/productos/kat-002.jpg` |
| KAT-003 | Protector Solar SPF50 | — | `onError` |
| KAT-004 | Base Líquida HD | `Base líquida mate.jpg` | `media/img/productos/kat-004.jpg` |
| KAT-005 | Labial Mate Terracota | `Labial Mate Rosa Nude.jpg` | `media/img/productos/kat-005.jpg` |
| KAT-006 | Paleta Sombras Nude | — | `onError` |
| KAT-007 | Eau de Parfum Floral | — | `onError` |
| KAT-008 | Perfume Amaderado Intenso | — | `onError` |
| KAT-009 | Eau de Toilette Cítrica | — | `onError` |
| KAT-010 | Shampoo Reparación Intensa | — | `onError` |
| KAT-011 | Mascarilla Capilar Keratina | — | `onError` |
| KAT-012 | Aceite Capilar Argán | — | `onError` |
| KAT-013 | Esponja de Maquillaje | — | `onError` |
| KAT-014 | Brocha Difuminadora | `Set de Brochas.jpg` | `media/img/productos/kat-014.jpg` |
| KAT-015 | Neceser Beauty | — | `onError` |

Los emparejamientos KAT-002, KAT-004, KAT-005 y KAT-014 son **aproximados**: si el nombre o el color no coinciden con el producto de la API, se deja `onError` y se retira el asset. Los cinco assets locales que no se usan en el catálogo (`Brillo Labial Hidratante.jpg`, `Corrector Cremoso.jpg`, `Delineador Líquido Negro.jpg`, `Esmalte Gel Lila.jpg`, `Máscara de Pestañas Volumen.jpg`) no se copian al backend; se conservan solo si otra vista los usa.

No se crean placeholders `kat-00X.jpg` que simulen imágenes reales; los faltantes se cubren con `onError`. Un script de verificación falla si un producto no tiene imagen ni excepción declarada en esta tabla.

**Blogs:** `EntradaBlogResponse.imagen` contiene el nombre de archivo; el frontend lo resuelve con `resolverImagen` desde `src/assets/`. Si no existe, se usa el placeholder. El contrato se documenta en `docs/ARQUITECTURA.md`.

---

## 8. Estrategia de pruebas

| Nivel | Herramienta | Alcance |
|---|---|---|
| Frontend, lógica pura | Vitest | Reglas del carrito, validaciones, helpers de presentación y `urlAsset` |
| Frontend, componentes/vistas | Vitest + jsdom + Testing Library | Renderizado, estados de carga/error, formularios, checkout |
| Frontend, HTTP | Vitest + MSW | `client.js`, `baseURL`, `Authorization`, `Idempotency-Key` y mapeo de `ErrorResponse` |
| Cobertura | `vitest run --coverage` | Informe en `coverage/` y documento `docs/cobertura.md` |
| Backend | JUnit 5 + Spring Boot Test + MockMvc | `CorsIT`, validaciones, checkout, pagos, idempotencia |
| Smoke | `scripts/` + `curl` | CORS, catálogo, imágenes, checkout, rechazo, reintento, contacto |

Reglas:

- Cada gate incluye la suite de su fase; no se concentran todos los tests al final.
- MSW es la única forma de simular HTTP; no se mockea Axios directamente.
- ESLint prohíbe `fetch` y `axios` fuera de `src/api/client.js`.
- El backend conserva sus pruebas JUnit; Vitest es el marco del frontend.
- La cobertura es bloqueante: líneas ≥ 80 y branches ≥ 70, ajustadas al baseline real y documentadas en `docs/cobertura.md`.
- `scripts/gate-lint.sh` ejecuta ESLint + Prettier en el frontend y el linter del backend; un error de estilo falla el gate.
- Los contract tests validan el cliente HTTP real contra el backend en modo test o contra un mock server tipado; no sustituyen a MSW en tests unitarios.
- El chequeo anti-mocks es de dos capas: `grep` en `src/` (sin tests) y contract test; MSW solo puede vivir en `src/test/`.
- Los gates se ejecutan con `set -euo pipefail`, desde la raíz del repo, y verifican el gate anterior; G5/G6 limpian el entorno con `trap`.
- `.env.example` es el inventario canónico de variables; G0 valida ambos compose en una copia limpia.

---

## 9. Matriz de trazabilidad con la pauta

| Requisito | Fase | Gate | Evidencia |
|---|---|---|---|
| Enlaces públicos de frontend y backend | F0 | G0 | Repositorios espejo, remotos y sincronización documentada |
| Repositorio final unificado con todo el código | F0 | G0 | `FullStackKatEye` con `KatEye-Front/` y `KatEye-Back/` commiteados, no punteros |
| Historial de cambios en GitHub | F0–F6 | G0–G6 | Historial importado + un commit del usuario por fase en el monorepo y en los espejos |
| Axios en toda comunicación HTTP | F2 | G2 | `src/api/client.js` + ESLint restrictivo |
| CORS configurado y demostrado | F2 | G2 | `CorsIT`, preflight `curl`, navegador en desarrollo |
| Catálogo desde el backend | F2–F3 | G2–G3 | Tests MSW y smoke |
| Imágenes de producto desde el backend | F2 | G2 | 15 URLs verificadas, `onError`, tabla de reconciliación |
| Categorías, regiones y comunas | F3 | G3 | Tests de catálogo y selects |
| Autenticación JWT, registro y logout | F4 | G4 | Tests de sesión y `/usuarios/me` |
| Validaciones alineadas con el curso | F4 | G4 | Tests en frontend y backend |
| Formulario de contacto | F4 | G4 | `POST /contacto` y registro en base |
| Carrito con reglas de negocio | F5 | G5 | Tests de carrito y reconciliación |
| Checkout real, pago, rechazo y reintento | F5 | G5 | MSW, `docker-compose.rechazo.yml`, smoke |
| Autocompletado del checkout con sesión | F5 | G5 | Test con `/usuarios/me` |
| Pruebas por fase | F1–F5 | G1–G5 | Suites verdes en cada gate |
| Documento de cobertura | F1 y F6 | G1, G6 | `coverage/` y `docs/cobertura.md` |
| Docker con tres contenedores | F6 | G6 | `docker compose up --build` |
| ERS v2, manual de usuario, APIs e integración | F6 | G6 | `docs/ERS-v2.md`, `docs/manual-usuario.md`, `docs/api-integracion.md` |
| Swagger/OpenAPI | F6 | G6 | `springdoc` si la pauta vigente lo exige |
| Sin secretos en el repositorio | F0 y F6 | G0, G6 | `gitleaks` limpio |
| Gates idempotentes y reproducibles | F0, F5, F6 | G0, G5, G6 | Prerrequisitos, `trap`, `docker compose down --remove-orphans`; G6 dos veces |
| Cobertura con umbral bloqueante | F1 | G1 | `gate-1.sh` falla bajo líneas ≥ 80 / branches ≥ 70 |
| Lint bloqueante | F1 | G1 | `scripts/gate-lint.sh` exit 0; ESLint + Prettier + linter backend |
| Contract tests de endpoints críticos | F2, F3, F5 | G2, G3, G5 | Cliente real o mock server tipado; matriz en `docs/api-integracion.md` |
| MSW fuera del runtime | F3 | G3 | `grep` en `src/` sin tests + contract test |
| `.env.example` completo y validado | F0 | G0 | Compose y override pasan con copia limpia de `.env.example` |
| Makefile y hook `pre-push` | F0, F1, F6 | G0, G1, G6 | `make gate-all`; `scripts/install-hooks.sh` |
| Memoria de desarrollo por fase | F0–F6 | G0–G6 | `docs/memoria/mm_devFaseX.md` con archivos y acciones en orden |
| Progreso visible en repositorios independientes | F0–F6 | G0–G6 | `scripts/sync-progreso.sh` y commits del usuario en cada espejo |

---

## 10. Fases de ejecución

Cada fase tiene su documento en `docs/fases/`. El documento se completa con el **registro de ejecución** al cerrar el gate. Además, al finalizar cada fase debe existir `docs/memoria/mm_devFaseX.md` con la memoria del desarrollo. Los commits los realiza el usuario; el mensaje sugerido se indica en cada fase.

### Memoria de desarrollo (`mm_devFaseX.md`)

Cada fase produce un archivo `docs/memoria/mm_devFaseX.md` (por ejemplo, `mm_devFase0.md`). Se abre durante la ejecución y se cierra al finalizar la fase; el archivo final debe existir al cerrar el gate. Formato:

```markdown
# Memoria de desarrollo — Fase X

## Objetivo de la fase
## Archivos creados y modificados (en orden)
| # | Archivo | Acción | Qué hace |
|---|---|---|---|
| 1 | `ruta/archivo` | Creado / Modificado | Descripción breve |
## Acciones relevantes (en orden)
1. Acción, comando o decisión y su resultado.
## Evidencia del gate
## Desviaciones y pendientes
```

La plantilla vive en `docs/memoria/PLANTILLA.md`.

### F0 — Repositorios, historial importado, secretos y entorno unificado

**Documento:** `docs/fases/F0-estructura.md`

**Objetivo:** convertir `TiendaKatEye` en el repositorio unificado con el código y el historial de frontend y backend, dejar los secretos fuera del código y crear el esqueleto del entorno único de evaluación.

**Tareas**
- Verificar y, si hay cambios pendientes, dejarlos listos en una rama `pre-integracion` de `ProyectoWebKatEyes` y `backendProyectoKatEye` para que el usuario los commitee.
- Crear un `zip` de respaldo de ambos proyectos fuera del árbol de trabajo.
- Instalar `git filter-repo` con `pipx install git-filter-repo` o usar `git subtree add` como alternativa.
- Clonar ambos repositorios en un directorio temporal y reescribir sus rutas:
  ```bash
  git clone <url-frontend> /tmp/kateye-integracion/frontend
  git clone <url-backend>  /tmp/kateye-integracion/backend
  git -C /tmp/kateye-integracion/frontend filter-repo --to-subdirectory-filter KatEye-Front
  git -C /tmp/kateye-integracion/backend  filter-repo --to-subdirectory-filter KatEye-Back
  ```
- Fusionar el historial en `TiendaKatEye`:
  ```bash
  cd TiendaKatEye
  git remote add frontend-integracion /tmp/kateye-integracion/frontend
  git remote add backend-integracion  /tmp/kateye-integracion/backend
  git fetch --all
  git merge --allow-unrelated-histories frontend-integracion/master
  git merge --allow-unrelated-histories backend-integracion/master
  ```
- Verificar que el código y el historial estén presentes con `git log -- KatEye-Front` y `git log -- KatEye-Back`.
- Configurar los remotos `frontend` y `backend` hacia GitHub como referencia para la alternativa `git subtree push`; `sync-progreso.sh` usa las rutas locales de los espejos.
- Crear o actualizar `.gitignore`, `.env.example`, `README.md` (información de usuario y despliegue), `docs/ARQUITECTURA.md`, `docs/fases/INDICE.md` y `docs/memoria/PLANTILLA.md`.
- Crear `KatEye-DB/README.md` e `init/` opcional.
- Crear el compose raíz mínimo: `db`, `backend` y `frontend`; red `kateye-net`; `BACKEND_PORT` y `CORS_ORIGEN`.
- Neutralizar el `docker-compose.yml` legado de `KatEye-Back`.
- Sacar los secretos del código: `${JWT_SECRET}` y `${SPRING_DATASOURCE_PASSWORD}` sin default; compose con `${JWT_SECRET:?defina JWT_SECRET en .env}`.
- Crear `.env.example` con todas las variables del compose, incluida `KATEYE_PAGO_SIMULADO_RESULTADO=APROBADA` y un comentario del override de rechazo.
- Crear `scripts/gate-0.sh`, `scripts/gate-6.sh` y `scripts/sync-progreso.sh`.
- Dotar a los gates de `set -euo pipefail`, `cd "$(git rev-parse --show-toplevel)"`, verificación del gate anterior con salida 2 y mensajes claros; `gate-6.sh` incluye `trap 'docker compose down --remove-orphans' EXIT`.
- Añadir a `gate-0.sh` la validación de `docker compose config` y del override con una copia temporal de `.env.example` a `.env`.
- Añadir al inicio de `scripts/sync-progreso.sh` la política de fuente de verdad y espejos.
- Añadir al README la sección “Fuente de verdad y espejos”.
- Crear `Makefile` con targets `gate-0`…`gate-6`, `gate-lint`, `gate-all`, `sync`, `up`, `down` y `test`; los gates aún no implementados fallan con un mensaje explícito.
- Crear `docs/memoria/mm_devFase0.md` con los archivos y las acciones de la fase.

**Gate G0**
- `docker compose config` válido en una copia limpia de `.env.example` a `.env`.
- `docker compose -f docker-compose.yml -f docker-compose.rechazo.yml config` válido con la misma copia.
- `gitleaks detect --source .` sin hallazgos.
- `mvn -DskipTests package` en `KatEye-Back/katEye`.
- `npm ci && npm run build` en `KatEye-Front`.
- `git log --oneline -- KatEye-Front | head -5` y `git log --oneline -- KatEye-Back | head -5` muestran historial importado.
- `bash -n scripts/*.sh` sin errores de sintaxis.
- `test -f Makefile` y `make -n gate-0` sin errores.
- `grep -q '^KATEYE_PAGO_SIMULADO_RESULTADO=APROBADA' .env.example`.
- `docs/memoria/mm_devFase0.md` existe y describe los archivos y acciones.
- Commit de fase sugerido: `chore: unifica frontend y backend con historial importado`.
- Si se aplican B1, B5, B6 y B8 en esta fase, dividir en commits por bloque según la tabla de correcciones de auditoría.

### F1 — Baseline de pruebas y reglas de lint

**Documento:** `docs/fases/F1-pruebas.md`

**Objetivo:** recuperar la red de seguridad antes de refactorizar y dejar Vitest operativo.

**Tareas**
- Agregar `vitest`, `jsdom`, `@testing-library/react`, `@testing-library/jest-dom`, `@testing-library/user-event`, `msw` y `@vitest/coverage-v8`.
- Agregar scripts `test`, `test:run` y `test:coverage`.
- Configurar Vitest en `vite.config.js`: entorno jsdom, `setupFiles`, cobertura.
- Configurar ESLint: prohibir `fetch` y `axios` fuera de `src/api/client.js`.
- Definir umbrales de cobertura en `gate-1.sh`: líneas ≥ 80 y branches ≥ 70; si el baseline real es menor, documentar el valor ajustado y subirlo por fase.
- Regenerar `docs/cobertura.md` desde `gate-1.sh` con el encabezado “Generado automáticamente por scripts/gate-1.sh. No editar a mano.”.
- Crear `scripts/gate-lint.sh` con ESLint + Prettier en `KatEye-Front` y el linter del backend; invocarlo al inicio de `gate-1.sh`.
- Crear `scripts/install-hooks.sh` e instalar `.git/hooks/pre-push` con lint y el gate de la fase actual.
- Ejecutar la suite existente y documentar fallos de baseline.
- Crear `src/test/mocks/` con los handlers base de MSW.
- Crear `docs/memoria/mm_devFase1.md`.
- Ejecutar `scripts/sync-progreso.sh` y dejar `ProyectoWebKatEyes` listo para el commit del usuario.

**Gate G1**
- `npm run test:run` ejecuta la suite.
- `npm run test:coverage` aplica los umbrales y falla si no se cumplen.
- `scripts/gate-lint.sh` termina con exit 0.
- `docs/cobertura.md` existe y empieza con el encabezado de generación automática.
- `test -f scripts/install-hooks.sh` y `make -n gate-1` sin errores.
- `npm run build` funciona.
- `docs/memoria/mm_devFase1.md` existe y describe los archivos y acciones.
- Commit de fase sugerido: `test: agrega Vitest, MSW y baseline de pruebas`.
- Si se aplican B2, B4 y B8, dividir en commits por bloque.

### F2 — Rebanada vertical: Axios, CORS y catálogo

**Documento:** `docs/fases/F2-rebanada-vertical.md`

**Objetivo:** demostrar la integración completa de punta a punta con el catálogo antes de ampliar el resto de entidades.

**Tareas**
- Instalar `axios`.
- Backend: agregar `CorsIT` (origen permitido y origen rechazado); `server.forward-headers-strategy=framework`; `ProductoResponse.imagenUrl`; `spring.web.resources.static-locations` con el volumen; mover las 4 imágenes reales a `media/img/productos/`.
- Frontend: `.env.development` con `VITE_API_URL=http://localhost:8080/api/v1` y `VITE_ASSETS_URL=http://localhost:8080`; `.env.production` con `/api/v1` y vacío.
- Crear `src/api/client.js`, `errors.js`, `urlAsset.js`, `endpoints/productos.js`, `categorias.js`, `blogs.js`, `regiones.js`, `comunas.js` y `hooks/useApi.js`.
- Migrar `Inicio`, `Productos` y `DetalleProducto` al catálogo real, con `onError` para imágenes.
- Crear el script de reconciliación de imágenes.
- Crear un contract test de `GET /productos` que use el cliente HTTP real contra el backend en modo test o contra un mock server tipado; validar forma de la respuesta y errores.
- Si es viable, generar `docs/openapi.yaml` y validar en `gate-2.sh` con `schemathesis`, `dredd` o equivalente; si no, dejar el TODO explícito en `docs/api-integracion.md`.
- Crear `docs/memoria/mm_devFase2.md`.
- Ejecutar `scripts/sync-progreso.sh` y dejar ambos espejos listos para el commit del usuario.

**Gate G2**
- `CorsIT` verde.
- Preflight `curl` contra `/api/v1/productos` con `Origin: http://localhost:5173` devuelve 200 y `Access-Control-Allow-Origin`.
- Test MSW de `client.js` verde.
- Contract test de `GET /productos` verde.
- Si existe `docs/openapi.yaml`, la validación del spec pasa; si no, la matriz deja el TODO.
- Catálogo visible con imágenes del backend.
- `docs/memoria/mm_devFase2.md` existe y describe los archivos y acciones.
- Commit de fase sugerido: `feat: conecta catálogo con axios y CORS real`.
- Si se aplican B3 y B7, dividir en commits por bloque.

### F3 — Catálogo, contenido y ubicación

**Documento:** `docs/fases/F3-catalogo.md`

**Objetivo:** eliminar los datos simulados de las vistas de consulta.

**Tareas**
- Completar `Header`, `Blogs` y `Blog`; ajustar `Inicio`, `Productos` y `DetalleProducto` a categorías, filtros de servidor y relacionados.
- Categorías desde `GET /categorias`; regiones y comunas desde `GET /regiones` y `GET /regiones/{codigo}/comunas`.
- Filtros de categoría y precio en servidor (`categoriaId`, `precioMin`, `precioMax`); relacionados desde `/productos/{id}/relacionados`.
- Borrar `productos.js`, `blogs.js` y `regiones.js` y sus imports.
- Documentar el contrato de imágenes de blog (`imagen` como nombre de archivo).
- Endurecer el chequeo anti-mocks en dos capas: `grep` de MSW/HTTP en `KatEye-Front/src` (excluyendo tests) y contract test del cliente real.
- Crear `docs/memoria/mm_devFase3.md`.
- Ejecutar `scripts/sync-progreso.sh` y dejar los espejos listos para el commit del usuario.

**Gate G3**
- Tests de catálogo, filtros, blogs y selects.
- `grep -RInE '(msw|setupWorker|http\.(get|post|put|delete)\()' KatEye-Front/src --include='*.js' --include='*.jsx' --exclude='*.test.*'` sin resultados.
- Contract test del cliente real verde; si falla, G3 falla.
- `npm run build` funciona.
- `docs/memoria/mm_devFase3.md` existe y describe los archivos y acciones.
- Commit de fase sugerido: `refactor: migra catálogo, blogs y ubicación a la API`.
- Si se aplica B3, dividir en commit por bloque.

### F4 — Sesión, registro y contacto

**Documento:** `docs/fases/F4-sesion.md`

**Objetivo:** autenticación real, registro y formulario de contacto funcional.

**Tareas**
- `SesionProvider` con `kateye_token`, `GET /usuarios/me`, login, registro y logout.
- Alinear validaciones en backend y frontend: dominios del curso, contraseña 4–10 y correo de contacto opcional.
- `Registro` con región y comuna por código; `Contacto` con `POST /contacto`.
- Interceptor 401: limpiar token y estado de sesión.
- Borrar `usuarios.js`.
- Documentar expiración del JWT y la mitigación de XSS/CSP.
- Crear `docs/memoria/mm_devFase4.md`.
- Ejecutar `scripts/sync-progreso.sh` y dejar los espejos listos para el commit del usuario.

**Gate G4**
- Tests de registro, login, logout, sesión persistente y contacto.
- Tests de validación en frontend y backend.
- Test del interceptor 401.
- `docs/memoria/mm_devFase4.md` existe y describe los archivos y acciones.
- Commit sugerido: `feat: integra sesión JWT, registro y contacto`.

### F5 — Carrito, checkout real y pagos

**Documento:** `docs/fases/F5-checkout.md`

**Objetivo:** cerrar el flujo de compra contra el backend, sin simulación local.

**Tareas**
- `CarritoProvider`: reconciliar con el catálogo, descartar productos inexistentes, limitar a `[1, min(10, stock)]`, precios desde el backend, estados de carga/error y clave `kateye_carrito_v2`.
- Crear `src/api/endpoints/checkout.js` y `pagos.js`: `crearPedido`, `simularPago`, `reintentarPago`, `obtenerPedido`.
- `Checkout`: generar `Idempotency-Key` una vez por intento con `useRef`; reutilizarla en reintentos de red; regenerarla si cambia el carrito.
- Autocompletar el formulario con `GET /usuarios/me` cuando hay sesión.
- Mapear el formulario a `CheckoutRequest`: `tipoEntrega`, `metodoPago`, `regionCodigo`, `comunaCodigo` e `items` con `productoId`. Agregar un selector `DESPACHO`/`RETIRO` o fijar `DESPACHO` si el formulario siempre pide dirección.
- Vaciar el carrito cuando `POST /checkout` responde 2xx.
- `PagoFallido`: reintentar con `POST /pagos/{numero}/reintentar`, sin crear otro pedido.
- Eliminar `pedidos.js`, `pagos.js` local, la bandera `VITE_CHECKOUT_MODE` y la casilla `simularFallo`.
- Crear `docker-compose.rechazo.yml` y documentar el rechazo en el README.
- Crear contract tests de checkout, pago aprobado, pago rechazado y reintento contra el backend en modo test o mock server tipado.
- Crear `scripts/gate-5.sh` con `set -euo pipefail`, prerrequisito de G4, `trap 'docker compose down --remove-orphans' EXIT` y el override `docker compose -f docker-compose.yml -f docker-compose.rechazo.yml`.
- Crear `docs/memoria/mm_devFase5.md`.
- Ejecutar `scripts/sync-progreso.sh` y dejar los espejos listos para el commit del usuario.

**Gate G5**
- Tests de carrito, checkout, idempotencia, pago aprobado, pago rechazado y reintento.
- Contract tests de checkout, pago y reintento verdes.
- Smoke de rechazo con `KATEYE_PAGO_SIMULADO_RESULTADO=RECHAZADA` usando el override y limpieza con `trap`.
- El carrito se vacía solo cuando el backend confirma la creación del pedido.
- `docs/memoria/mm_devFase5.md` existe y describe los archivos y acciones.
- Commit de fase sugerido: `feat: integra carrito y checkout real con reintento de pago`.
- Si se aplican B1 y B7, dividir en commits por bloque.

### F6 — Docker completo, documentación y release

**Documento:** `docs/fases/F6-release.md`

**Objetivo:** cerrar la iteración con un entorno reproducible y la documentación de entrega.

**Tareas**
- Healthcheck del backend con `/actuator/health`; `depends_on: service_healthy` en el frontend. Agregar `curl` a la imagen o usar un healthcheck compatible con la JRE.
- Nginx con `proxy_set_header Host $http_host`, `X-Forwarded-Proto`, `X-Forwarded-Host` y proxy de `/api` e `/img`.
- `vite.config.js` lee `BACKEND_PORT` con `loadEnv`; scripts y smoke usan la misma variable.
- Actualizar `README.md` con despliegue, variables, pruebas, “Fuente de verdad y espejos” y “Desarrollo local” (`make up`, `make gate-N`, `make gate-all`).
- Crear/actualizar `docs/ERS-v2.md`, `docs/manual-usuario.md`, `docs/api-integracion.md` y `docs/cobertura.md`.
- Reestructurar `docs/api-integracion.md` con contrato, matriz de contract tests y sección CORS; si es viable, generar `docs/openapi.yaml`.
- Agregar Swagger/OpenAPI si la pauta vigente lo exige.
- Endurecer `scripts/gate-6.sh` con prerrequisito de G5, `trap 'docker compose down --remove-orphans' EXIT` e idempotencia para ejecutarlo dos veces.
- Asegurar que `Makefile` expone `gate-all` y que `scripts/install-hooks.sh` instala el `pre-push`.
- Verificar que `FullStackKatEye` contiene el código de `KatEye-Front/` y `KatEye-Back/`, no solo documentación.
- Ejecutar `docker compose up --build`, el smoke completo, `make gate-all`, `gitleaks` y la cobertura final.
- Ejecutar `scripts/sync-progreso.sh` y dejar ambos espejos listos para el commit final del usuario.
- Crear `docs/memoria/mm_devFase6.md` con el resumen de B1–B8 y la evidencia de `make gate-all`.

**Gate G6**
- `docker compose up --build` levanta los tres contenedores.
- Smoke: catálogo, imágenes, carrito, checkout aprobado, checkout rechazado, reintento y contacto.
- Preflight CORS correcto.
- `make gate-all` termina con exit 0 en estado limpio.
- `scripts/gate-6.sh` se ejecuta dos veces seguidas con exit 0 y sin contenedores huérfanos.
- `gitleaks` limpio.
- `docs/api-integracion.md` tiene la matriz completa; los endpoints sin test quedan como warning explícito.
- `git log --oneline -- KatEye-Front` y `git log --oneline -- KatEye-Back` muestran el historial importado.
- `docs/memoria/mm_devFase6.md` existe y describe los archivos y acciones.
- Documentos de entrega actualizados.
- Commit de fase sugerido: `chore: cierra Docker, documentación y release`.
- Si se aplican B1, B7 y B8, dividir en commits por bloque.

---

## 11. Orden de ejecución

```text
G0 historial importado, secretos y entorno unificado
 → G1 Vitest, MSW y baseline
 → G2 axios + CORS + catálogo (rebanada vertical)
 → G3 catálogo, contenido y ubicación
 → G4 sesión, registro y contacto
 → G5 carrito, checkout real y pagos
 → G6 Docker, documentación y release
```

No se avanza de gate si el anterior falla. Las correcciones B1–B8 se distribuyen en F0, F1, F2, F3, F5 y F6; `gate-lint.sh` es transversal y no crea una fase nueva. El usuario commitea al cerrar cada fase o por bloque cuando aplique B1–B8. En cada fase se crea `docs/memoria/mm_devFaseX.md` y se ejecuta `scripts/sync-progreso.sh` para dejar los espejos de progreso listos para el commit del usuario. `TiendaKatEye` es la fuente de verdad; los repositorios independientes no se editan directamente.

---

## 12. Verificación y smoke

```bash
cd TiendaKatEye

# Entorno limpio y compose
cp .env.example .env
docker compose config
docker compose -f docker-compose.yml -f docker-compose.rechazo.yml config
docker compose up -d db backend

curl -i http://localhost:8080/actuator/health
curl -i http://localhost:8080/api/v1/productos
curl -I http://localhost:8080/img/productos/kat-004.jpg

# CORS real
curl -i -X OPTIONS http://localhost:8080/api/v1/productos \
  -H "Origin: http://localhost:5173" \
  -H "Access-Control-Request-Method: GET"

# Calidad
make gate-all
scripts/gate-lint.sh
scripts/gate-6.sh
scripts/gate-6.sh

cd KatEye-Front
npm run test:run
npm run test:coverage
npm run build

cd ..
grep -RInE '(msw|setupWorker|http\.(get|post|put|delete)\()' KatEye-Front/src \
  --include='*.js' --include='*.jsx' --exclude='*.test.*' || true
git log --oneline -- KatEye-Front | head -5
git log --oneline -- KatEye-Back  | head -5
test -f docs/memoria/mm_devFase0.md && echo "memoria F0 OK"
test -f docs/memoria/mm_devFase6.md && echo "memoria F6 OK"
```

Smoke manual:

1. Catálogo con productos e imágenes del backend.
2. Detalle de producto y relacionados.
3. Agregar al carrito, recargar y comprobar persistencia.
4. Checkout con sesión: datos autocompletados.
5. Checkout aprobado: pedido real, número del backend y carrito vacío.
6. Checkout rechazado con `docker compose -f docker-compose.yml -f docker-compose.rechazo.yml up -d backend`; reintentar el pago.
7. Contacto con correo opcional.
8. Preflight CORS desde el navegador y desde `curl`.

---

## 13. Definición de terminado

- Todo HTTP del frontend pasa por `src/api/client.js`; ESLint lo impone.
- CORS verificado con `CorsIT` y con el navegador en desarrollo.
- Checkout, pago, rechazo y reintento funcionan contra el backend; no queda código simulado.
- El carrito se conserva hasta que el backend confirma la creación del pedido.
- El historial git de ambos proyectos está importado y visible en `TiendaKatEye`; no hay secretos en ningún commit (`gitleaks` limpio).
- Las validaciones de frontend y backend son idénticas y están alineadas con la pauta.
- Ningún módulo mock permanece en el árbol; hay un único modelo de datos.
- Los tests de cada fase están en verde y existe documento de cobertura.
- La cobertura respeta los umbrales (líneas ≥ 80, branches ≥ 70 o baseline documentado) y `gate-1.sh` falla si baja.
- `scripts/gate-lint.sh` termina con exit 0; ESLint, Prettier y el linter del backend están integrados.
- Los contract tests de catálogo, checkout, pago y reintento están verdes; `docs/api-integracion.md` tiene la matriz completa.
- `grep` no encuentra MSW ni `http.*` en `src/` fuera de tests; el contract test lo respalda.
- `.env.example` contiene todas las variables, incluida `KATEYE_PAGO_SIMULADO_RESULTADO=APROBADA`, y ambos compose validan en una copia limpia.
- `make gate-all` devuelve exit 0 y `gate-6.sh` se ejecuta dos veces sin dejar contenedores huérfanos.
- `Makefile` y `scripts/install-hooks.sh` están documentados en el README.
- Los gates están numerados G0–G6 = F0–F6 y cada fase tiene su documento en `docs/fases/`.
- Cada fase tiene su `docs/memoria/mm_devFaseX.md` con archivos y acciones en orden.
- `FullStackKatEye` contiene el código de `KatEye-Front/` y `KatEye-Back/` con su historial, no solo documentación.
- Los repositorios espejo quedaron actualizados al cierre de cada fase.
- `docs/ARQUITECTURA.md` contiene los árboles ASCII actualizados.
- `README.md` explica cómo clonar el repo unificado, levantar los tres contenedores, probar CORS y forzar el rechazo de pago.
- El usuario realizó un commit por fase con un mensaje claro.

---

## 14. Fuera de alcance en esta iteración

- Cookie `httpOnly` para el token (queda documentado como siguiente paso).
- Panel de administración.
- Recuperación de contraseña en la interfaz.
- Carrito server-side.
- Rutas nuevas del ERS (`/ofertas`, `/categorias`, `/mis-pedidos`, 404 propia), salvo que la pauta vigente las exija.
- Resolver DNS dinámico de Nginx, gzip y caché larga de assets (hardening posterior).
- Refresh token y revocación de sesión.
- Migración de todos los imports a `react-router`; en esta iteración se mantiene `react-router-dom`.

---

## 15. Referencias

- `informe-evaluacion-planificacion.md` — evaluación del plan anterior y hallazgos H1–H15.
- `docs/ARQUITECTURA.md` — arquitectura objetivo, árboles ASCII y flujos.
- `docs/fases/INDICE.md` — índice y plantilla de los documentos de fase.
- `docs/api-integracion.md` — contrato, matriz de contract tests y CORS.
- `docs/memoria/PLANTILLA.md` — plantilla de la memoria de desarrollo por fase.
- `Makefile` y `scripts/` — gates, lint, sincronización de espejos y hooks.
- `KatEye-Back/docs/proyecto/ARQUITECTURA_BACKEND.md` — arquitectura del backend.
- `KatEye-Back/docs/proyecto/plan_desarrollo.md` — plan del backend.
- Anexo de la Evaluación 3 — requisitos de entrega, repositorios, documentación y pruebas.

> Las rutas `KatEye-Back/` y `KatEye-Front/` corresponden a directorios del monorepo `TiendaKatEye`, con el código y el historial importado. En el estado actual el backend está en `KatEyeBackEnd/` y el frontend en `mi-proyecto/`; F0 los importa con esos nombres. Los repositorios independientes quedan como espejos de progreso.
