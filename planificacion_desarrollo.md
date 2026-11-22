# Planificación — TiendaKatEye (v2 corregida)

| | |
|---|---|
| **Proyecto** | KatEye / TiendaKatEye |
| **Versión** | 2.0 — plan corregido según `informe-evaluacion-planificacion.md` |
| **Fecha** | 2026-11-21 |
| **Estado** | Plan aprobado para ejecución por fases |
| **Alcance** | Conciliar el frontend React con el backend Spring Boot, integrar el checkout real, preparar el repositorio de orquestación como entorno único de evaluación y documentar cada fase |
| **Documentos de referencia** | `informe-evaluacion-planificacion.md`, `docs/ARQUITECTURA.md`, anexo de la Evaluación 3, `KatEye-Back/docs/proyecto/ARQUITECTURA_BACKEND.md` |

---

## 0. Glosario

| Término | Significado en este plan |
|---|---|
| **Alternativa A** | Conciliar el frontend existente con el backend: conservar vistas, estilos y navegación; no rehacer la SPA. |
| **Ejecución híbrida** | Conservar la mayoría de las vistas y reescribir solo los módulos de sesión, carrito, checkout y pago. |
| **Gate (Gx)** | Verificación ejecutable al cerrar la fase Fx. No se avanza si el gate falla. |
| **Rebanada vertical** | Funcionalidad completa de punta a punta (axios + CORS + catálogo visible) antes de ampliar el resto de entidades. |
| **Submódulo** | Repositorio independiente enlazado desde el repositorio de orquestación. |
| **Idempotency-Key** | Cabecera que evita duplicar pedidos o pagos cuando el cliente reintenta una operación. |
| **Mock** | Dato o módulo simulado local que debe desaparecer cuando la vista consume la API. |
| **Entorno único de evaluación** | `TiendaKatEye` levanta los tres contenedores con `docker compose up --build`; es el entorno que se presenta. |

---

## 1. Resumen ejecutivo

El backend ya está implementado sobre MySQL 8.4 LTS como monolito modular Spring Boot. Expone una API REST versionada en `/api/v1`, autenticación JWT, catálogo, blogs, regiones/comunas, contacto, checkout para invitados, pagos simulados y pedidos con estados.

El frontend real es `mi-proyecto` (repositorio `ProyectoWebKatEyes`): una SPA React 19 + Vite + Bootstrap con una capa de datos simulada en archivos JavaScript. Esa capa se reemplaza por clientes HTTP; las vistas, los estilos y la navegación se conservan.

La decisión sigue siendo **conciliar, no rehacer**, pero con cuatro cambios de fondo respecto de la versión anterior:

1. **El checkout real se integra en esta iteración.** No se mantiene un checkout simulado local que nunca llega al backend.
2. **El historial git se conserva.** No se copia con `rsync` ni se inicializa un repositorio nuevo sobre una copia; se usan repositorios independientes y submódulos.
3. **CORS se demuestra.** En desarrollo el navegador habla cross-origin con Spring; en producción Nginx conserva el origen.
4. **Cada fase deja documentación.** Un archivo por fase con contexto, decisiones, cambios y consecuencias, más `docs/ARQUITECTURA.md` con los árboles ASCII.

Las pruebas del frontend usan **Vitest** como marco general, con jsdom, Testing Library y MSW. El backend mantiene JUnit 5 + Spring Boot Test.

---

## 2. Decisiones cerradas

| ID | Decisión |
|---|---|
| **D1** | Alternativa A con ejecución híbrida: conciliar el frontend existente; conservar vistas, estilos y navegación; reescribir sesión, carrito, checkout y pago. |
| **D2** | Pruebas del frontend con **Vitest** + jsdom + Testing Library + MSW + cobertura. Pruebas del backend con JUnit 5 + Spring Boot Test. |
| **D3** | Imágenes de producto en el backend, en un volumen externo `media/img/productos/`, con una sola fuente de verdad: la URL que entrega la API. |
| **D4** | `TiendaKatEye` es el repositorio de orquestación y el **entorno único de evaluación**. Contiene compose, README, documentación y los submódulos `KatEye-Front` y `KatEye-Back`; `KatEye-DB` es una carpeta del mismo repositorio. |
| **D5** | Se mantiene `react-router-dom` 7.18.5 en esta iteración. No se cambia de versión. |
| **D6** | El carrito se conserva hasta que el backend confirma la creación del pedido (`POST /checkout` responde 2xx). |
| **D7** | El correo de contacto es **opcional**, alineado con las reglas del curso. |
| **D8** | Validación de correo en login/registro: solo `@duoc.cl`, `@profesor.duoc.cl` y `@gmail.com`. Contraseña de **4 a 10 caracteres**. |
| **D9** | Token JWT en `localStorage` (`kateye_token`) con mitigaciones: prohibido `dangerouslySetInnerHTML` con contenido del backend, CSP en Nginx, interceptor central ante 401 y expiración documentada. |
| **D10** | El rechazo de pago se fuerza en el backend con `KATEYE_PAGO_SIMULADO_RESULTADO=RECHAZADA`, mediante `docker-compose.rechazo.yml`. |
| **D11** | El checkout real se integra en esta iteración (F5). No queda checkout ni pago simulado local. |
| **D12** | Los repositorios de entrega son independientes: `ProyectoWebKatEyes` (frontend) y `backendProyectoKatEye` (backend). `TiendaKatEye` los referencia como submódulos y se presenta como entorno único de evaluación. El repositorio raíz `kateyefullStack` no forma parte de la entrega. |
| **D13** | Solo las imágenes de producto pasan al backend. Logo, hero y blogs permanecen en el frontend, con el contrato de `imagen` documentado. |
| **D14** | CORS real en desarrollo (cross-origin) y same-origin en producción mediante Nginx. |
| **D15** | Secretos fuera del código: `${JWT_SECRET}` y `${SPRING_DATASOURCE_PASSWORD}` sin valor por defecto; `.env` obligatorio; `gitleaks` en los gates G0 y G6. |
| **D16** | MSW intercepta a nivel de red. ESLint prohíbe `fetch` y la importación de `axios` fuera de `src/api/client.js`. |
| **D17** | `Idempotency-Key` es obligatoria en `POST /checkout` y `POST /pagos/simular`; el backend la declara `required = true` y la documenta. |
| **D18** | **Los commits los realiza el usuario al cerrar cada fase.** El plan solo define el mensaje sugerido y el punto de commit; no se automatizan commits. |
| **D19** | Docker: se aplica el mínimo viable ahora (healthcheck del backend, `depends_on: service_healthy`, puerto compartido y cabecera `Host`). Resolver DNS, gzip y caché de assets quedan como hardening posterior. |

### Correcciones técnicas

- **`react-router-doom` no existe en npm.** Se usa `react-router-dom`, que ya está instalado en `mi-proyecto` (`^7.18.5`). En esta iteración se mantiene ese paquete como único punto de importación y se documenta en el README.
- **No se modifican las migraciones V1–V6.** Las URLs semilla ya apuntan a `/img/productos/{codigo}.jpg`; los archivos se sirven desde el volumen `media/img/productos/`.
- **`Idempotency-Key` es obligatoria en la práctica.** `IdempotenciaService` lanza `SolicitudInvalidaException` si falta; el controlador debe declararla `required = true` para que el contrato coincida con el comportamiento.
- **El carrito se vacía al crear el pedido**, no al aprobar el pago. Si el pago es rechazado, el pedido ya existe y se reintenta con `POST /pagos/{numero}/reintentar`.
- **`GET /productos` devuelve una lista, no una página.** Los filtros de categoría y precio se resuelven en el servidor con `categoriaId`, `precioMin` y `precioMax`; no se duplica el filtrado en el cliente.
- **El backend agregará `imagenUrl` en `ProductoResponse` en F2** para que el frontend no reconstruya la URL con `codigo.toLowerCase()`.

### Hallazgos del informe y tratamiento

| Hallazgo | Tratamiento en este plan | Fase |
|---|---|---|
| **H1** Checkout y pago diferidos | Checkout real en F5; se elimina la simulación local, se usa `Idempotency-Key` y se reintenta sobre el mismo pedido | F5 |
| **H2** Pérdida del historial git | Repos independientes + submódulos; ramas `pre-integracion`; sin `rsync`; el usuario commitea por fase | F0 |
| **H3** CORS no demostrado | Cross-origin real en desarrollo; `CorsIT`; Nginx conserva `Host`; `server.forward-headers-strategy=framework` | F2 |
| **H4** Secretos en repositorio público | `.gitignore` explícito; secretos sin default; `gitleaks`; rotación si hubo exposición | F0 |
| **H5** Validaciones divergentes | Dominios del curso, contraseña 4–10 y contacto opcional en frontend y backend | F4 |
| **H6** Imágenes con doble fuente de verdad | Volumen externo, `imagenUrl` desde la API, sin placeholders falsos, tabla de reconciliación y script | F2 |
| **H7** Inconsistencias internas | Gates G0–G6, glosario, decisiones cerradas, `$PROYECTOS`, un archivo por fase y `docs/ARQUITECTURA.md` | F0–F6 |
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
| `TiendaKatEye/` | Contiene este plan, el informe y la documentación base; todavía no tiene código, compose ni submódulos |
| `ProyectoWebKatEyes` / `mi-proyecto` | Repositorio git independiente, limpio, con historial y remoto en GitHub |
| `backendProyectoKatEye` / `KatEyeBackEnd` | Repositorio git independiente, limpio, con historial y remoto en GitHub |
| `kateyefullStack` | Repositorio raíz del workspace; no es parte de la entrega y no se modifica |
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
TiendaKatEye/                      ← repo de orquestación y entorno único de evaluación
├── docker-compose.yml             ← db, backend, frontend; red kateye-net
├── docker-compose.rechazo.yml     ← override para forzar pago rechazado
├── .env.example                   ← sin secretos reales; variables obligatorias
├── README.md                      ← información para el usuario y despliegue
├── scripts/                       ← gates y smoke
├── docs/
│   ├── ARQUITECTURA.md            ← árboles ASCII y flujos
│   ├── fases/                     ← INDICE.md + F0…F6
│   ├── ERS-v2.md
│   ├── cobertura.md
│   ├── api-integracion.md
│   └── manual-usuario.md
├── KatEye-Front/   (submódulo)    ← repo existente; Dockerfile + nginx.conf propios
├── KatEye-Back/    (submódulo)    ← repo existente; imágenes en media/img/productos
└── KatEye-DB/                     ← README (+ init opcional); Flyway sigue siendo el dueño del esquema
```

El `README.md` de la raíz es el documento para el usuario y el despliegue; el índice y la plantilla de la documentación por fase viven en `docs/fases/INDICE.md`.

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
| **R1** | Pérdida o duplicación del historial git | `git log` con un solo commit o repo raíz trackeando el backend | Repos independientes + submódulos; ramas `pre-integracion`; no usar `rsync`; no tocar `kateyefullStack` | Restaurar desde GitHub o desde el zip de respaldo |
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
| **R15** | Documentación desactualizada | Árbol o decisiones divergen del código | Actualizar `docs/ARQUITECTURA.md` y el archivo de fase en cada gate | Revisión obligatoria en G6 |

---

## 6. Pre-flight obligatorio

Antes de tocar código:

- Confirmar que se trabaja en los repositorios de entrega: `ProyectoWebKatEyes`, `backendProyectoKatEye` y `TiendaKatEye`.
- No modificar `kateyefullStack` ni usar su copia del backend como fuente de verdad.
- Ejecutar `git -C KatEye-Front status` y `git -C KatEye-Back status`; si hay cambios pendientes, dejarlos listos en una rama `pre-integracion` para que el usuario los commitee antes de enlazarlos.
- Crear un `zip` de respaldo de ambos proyectos fuera del árbol de trabajo.
- Verificar `java -version` (Java 21), `node -v` (20.19+ o 22.12+), `npm -v`, `mvn -v` (3.8+) y `docker compose version`.
- Verificar `gitleaks version`.
- Verificar que los puertos 8080, 80 y 3306 estén libres con `ss -ltnp` y `docker ps`.
- Confirmar espacio libre suficiente.
- Ejecutar `npm ci` y `mvn -DskipTests package` en los proyectos antes de editar.
- Confirmar que `TiendaKatEye` es el único entorno de evaluación y que los commits los hará el usuario al cerrar cada fase.

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

---

## 9. Matriz de trazabilidad con la pauta

| Requisito | Fase | Gate | Evidencia |
|---|---|---|---|
| Enlaces públicos de frontend y backend | F0 | G0 | Repos independientes, remotos y submódulos |
| Historial de cambios en GitHub | F0–F6 | G0–G6 | Un commit del usuario por fase, con mensaje claro |
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

---

## 10. Fases de ejecución

Cada fase tiene su documento en `docs/fases/`. El documento se completa con el **registro de ejecución** al cerrar el gate. Los commits los realiza el usuario; el mensaje sugerido se indica en cada fase.

### F0 — Repositorios, secretos y orquestación

**Documento:** `docs/fases/F0-estructura.md`

**Objetivo:** dejar los repositorios de entrega listos, sin copiar código y sin perder historial, y crear el esqueleto del entorno único de evaluación.

**Tareas**
- Verificar y, si hay cambios pendientes, dejarlos listos en una rama `pre-integracion` de `ProyectoWebKatEyes` y `backendProyectoKatEye` para que el usuario los commitee.
- Crear `TiendaKatEye` como repositorio de orquestación; no copiar código con `rsync`.
- Crear `.gitignore`, `.env.example`, `README.md` (información de usuario y despliegue), `docs/ARQUITECTURA.md` y `docs/fases/INDICE.md`.
- Agregar submódulos `KatEye-Front` y `KatEye-Back`; crear `KatEye-DB/README.md` e `init/` opcional.
- Crear el compose raíz mínimo: `db`, `backend` y `frontend`; red `kateye-net`; `BACKEND_PORT` y `CORS_ORIGEN`.
- Neutralizar el `docker-compose.yml` legado de `KatEye-Back`.
- Sacar los secretos del código: `${JWT_SECRET}` y `${SPRING_DATASOURCE_PASSWORD}` sin default; compose con `${JWT_SECRET:?defina JWT_SECRET en .env}`.
- Crear `scripts/gate-0.sh` y `scripts/gate-6.sh` (o equivalentes) para ejecutar los gates.

**Gate G0**
- `docker compose config` válido.
- `gitleaks detect --source .` sin hallazgos.
- `mvn -DskipTests package` en `KatEye-Back/katEye`.
- `npm ci && npm run build` en `KatEye-Front`.
- `git submodule status` correcto y `git log` con historial de ambos proyectos.
- Commit sugerido: `chore: prepara repositorio de orquestación y secretos`.

### F1 — Baseline de pruebas y reglas de lint

**Documento:** `docs/fases/F1-pruebas.md`

**Objetivo:** recuperar la red de seguridad antes de refactorizar y dejar Vitest operativo.

**Tareas**
- Agregar `vitest`, `jsdom`, `@testing-library/react`, `@testing-library/jest-dom`, `@testing-library/user-event`, `msw` y `@vitest/coverage-v8`.
- Agregar scripts `test`, `test:run` y `test:coverage`.
- Configurar Vitest en `vite.config.js`: entorno jsdom, `setupFiles`, cobertura.
- Configurar ESLint: prohibir `fetch` y `axios` fuera de `src/api/client.js`.
- Ejecutar la suite existente y documentar fallos de baseline.
- Crear `src/test/mocks/` con los handlers base de MSW.

**Gate G1**
- `npm run test:run` ejecuta la suite.
- `npm run test:coverage` genera `coverage/`.
- `npm run build` funciona.
- Commit sugerido: `test: agrega Vitest, MSW y baseline de pruebas`.

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

**Gate G2**
- `CorsIT` verde.
- Preflight `curl` contra `/api/v1/productos` con `Origin: http://localhost:5173` devuelve 200 y `Access-Control-Allow-Origin`.
- Test MSW de `client.js` verde.
- Catálogo visible con imágenes del backend.
- Commit sugerido: `feat: conecta catálogo con axios y CORS real`.

### F3 — Catálogo, contenido y ubicación

**Documento:** `docs/fases/F3-catalogo.md`

**Objetivo:** eliminar los datos simulados de las vistas de consulta.

**Tareas**
- Completar `Header`, `Blogs` y `Blog`; ajustar `Inicio`, `Productos` y `DetalleProducto` a categorías, filtros de servidor y relacionados.
- Categorías desde `GET /categorias`; regiones y comunas desde `GET /regiones` y `GET /regiones/{codigo}/comunas`.
- Filtros de categoría y precio en servidor (`categoriaId`, `precioMin`, `precioMax`); relacionados desde `/productos/{id}/relacionados`.
- Borrar `productos.js`, `blogs.js` y `regiones.js` y sus imports.
- Documentar el contrato de imágenes de blog (`imagen` como nombre de archivo).

**Gate G3**
- Tests de catálogo, filtros, blogs y selects.
- `grep -rE "from ['\"].*/(productos|blogs|regiones)" src` sin resultados en vistas/contexto.
- `npm run build` funciona.
- Commit sugerido: `refactor: migra catálogo, blogs y ubicación a la API`.

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

**Gate G4**
- Tests de registro, login, logout, sesión persistente y contacto.
- Tests de validación en frontend y backend.
- Test del interceptor 401.
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

**Gate G5**
- Tests de carrito, checkout, idempotencia, pago aprobado, pago rechazado y reintento.
- Smoke de rechazo con `KATEYE_PAGO_SIMULADO_RESULTADO=RECHAZADA`.
- El carrito se vacía solo cuando el backend confirma la creación del pedido.
- Commit sugerido: `feat: integra carrito y checkout real con reintento de pago`.

### F6 — Docker completo, documentación y release

**Documento:** `docs/fases/F6-release.md`

**Objetivo:** cerrar la iteración con un entorno reproducible y la documentación de entrega.

**Tareas**
- Healthcheck del backend con `/actuator/health`; `depends_on: service_healthy` en el frontend. Agregar `curl` a la imagen o usar un healthcheck compatible con la JRE.
- Nginx con `proxy_set_header Host $http_host`, `X-Forwarded-Proto`, `X-Forwarded-Host` y proxy de `/api` e `/img`.
- `vite.config.js` lee `BACKEND_PORT` con `loadEnv`; scripts y smoke usan la misma variable.
- Actualizar `README.md` con despliegue, variables y pruebas.
- Crear/actualizar `docs/ERS-v2.md`, `docs/manual-usuario.md`, `docs/api-integracion.md` y `docs/cobertura.md`.
- Agregar Swagger/OpenAPI si la pauta vigente lo exige.
- Ejecutar `docker compose up --build` y el smoke completo.
- Ejecutar `gitleaks` y la cobertura final.

**Gate G6**
- `docker compose up --build` levanta los tres contenedores.
- Smoke: catálogo, imágenes, carrito, checkout aprobado, checkout rechazado, reintento y contacto.
- Preflight CORS correcto.
- `gitleaks` limpio.
- Documentos de entrega actualizados.
- Commit sugerido: `chore: cierra Docker, documentación y release`.

---

## 11. Orden de ejecución

```text
G0 repositorios, secretos y orquestación
 → G1 Vitest, MSW y baseline
 → G2 axios + CORS + catálogo (rebanada vertical)
 → G3 catálogo, contenido y ubicación
 → G4 sesión, registro y contacto
 → G5 carrito, checkout real y pagos
 → G6 Docker, documentación y release
```

No se avanza de gate si el anterior falla. El usuario commitea al cerrar cada fase. Los repositorios originales no se copian ni se mueven.

---

## 12. Verificación y smoke

```bash
cd TiendaKatEye

docker compose config
docker compose up -d db backend

curl -i http://localhost:8080/actuator/health
curl -i http://localhost:8080/api/v1/productos
curl -I http://localhost:8080/img/productos/kat-004.jpg

# CORS real
curl -i -X OPTIONS http://localhost:8080/api/v1/productos \
  -H "Origin: http://localhost:5173" \
  -H "Access-Control-Request-Method: GET"

cd KatEye-Front
npm run test:run
npm run test:coverage
npm run build
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
- El historial git de ambos proyectos está intacto; no hay secretos en ningún commit (`gitleaks` limpio).
- Las validaciones de frontend y backend son idénticas y están alineadas con la pauta.
- Ningún módulo mock permanece en el árbol; hay un único modelo de datos.
- Los tests de cada fase están en verde y existe documento de cobertura.
- Los gates están numerados G0–G6 = F0–F6 y cada fase tiene su documento en `docs/fases/`.
- `docs/ARQUITECTURA.md` contiene los árboles ASCII actualizados.
- `README.md` explica cómo levantar los tres contenedores, probar CORS y forzar el rechazo de pago.
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
- `KatEye-Back/docs/proyecto/ARQUITECTURA_BACKEND.md` — arquitectura del backend.
- `KatEye-Back/docs/proyecto/plan_desarrollo.md` — plan del backend.
- Anexo de la Evaluación 3 — requisitos de entrega, repositorios, documentación y pruebas.

> Las rutas `KatEye-Back/` y `KatEye-Front/` corresponden a los submódulos del repositorio de orquestación. En el estado actual el backend está en `KatEyeBackEnd/` y el frontend en `mi-proyecto/`; F0 los monta con esos nombres.
