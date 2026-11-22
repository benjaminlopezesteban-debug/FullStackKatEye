# Informe de evaluación — Planificación de conciliación Frontend ↔ Backend (TiendaKatEye)

| | |
|---|---|
| **Documento evaluado** | `PLANIFICACION.md` (2026-11-20, 425 líneas) |
| **Fecha del informe** | 2026-11-21 |
| **Criterios** | Coherencia · Errores críticos · Deuda técnica · Buenas prácticas de arquitectura · Legibilidad por un tercero |

---

## 0. Alcance y límites de la evaluación

**Fuentes usadas:** el texto de `PLANIFICACION.md`, el anexo de la Evaluación 2 (PDF) y los archivos del proyecto HTML/JS original (`carrito.js`, `validaciones.js`, `data.js`, README).

**Lo que no tuve:** el código del backend Spring Boot, el código del frontend React (`mi-proyecto`) ni la pauta específica de esta fase. Los puntos que dependen de ellos están marcados **[verificar]**. Donde cito exigencias del curso, vienen del anexo de la Evaluación 2; confírmalas contra la pauta vigente.

**Escala de severidad**

| Nivel | Significado |
|---|---|
| 🔴 Crítico | Puede invalidar la entrega, perder evidencia o romper el sistema |
| 🟠 Alto | Genera defectos silenciosos, incumple requisitos o impide que un tercero ejecute el plan |
| 🟡 Medio | Deuda técnica o riesgo que crece con el tiempo |
| 🟢 Bajo | Pulido; la corrección es obvia |

---

## 1. Veredicto

**No ejecutar el plan tal cual.** La base es sólida (conciliar en vez de rehacer, capa API centralizada, Flyway como fuente de verdad, riesgos con rollback). Pero tiene **3 problemas críticos** y varias contradicciones internas que, de ejecutarse, producirían un resultado que funciona en demostración y falla en la evaluación: el flujo de compra no queda integrado, el historial de commits desaparece y CORS nunca se demuestra.

| Criterio | Estado actual | Con los ajustes de este informe |
|---|---|---|
| Coherencia | Media-baja: contradicciones entre decisiones, reglas y verificaciones (H1, H7) | Alta |
| Errores críticos | Riesgo alto: historial git, secretos, CORS frágil (H2, H3, H4) | Bajo |
| Deuda técnica | Alta: simulación local, adaptadores y mocks que no se eliminan (H1, H11) | Baja |
| Buenas prácticas | Media: buena capa API; faltan tests por fase y gestión de secretos (H4, H12) | Alta |
| Legibilidad por un tercero | Media: estructura clara, pero IDs de gates inconsistentes y decisiones sin definir (H7) | Alta |

### Fortalezas a conservar

- Decisión de **conciliar, no rehacer**: preserva vistas, estilos y navegación.
- **Flyway como única fuente de verdad** del esquema y la regla de no editar V1–V6.
- Capa API separada (`client`, `errors`, `adapters`, `endpoints`, `useApi`).
- Matriz de riesgos con señal, mitigación y rollback, y pre-flight antes de tocar código.
- Detectar el error de tipeo `react-router-doom` y no cambiar de versión en la iteración.
- En producción, un único origen vía Nginx; evita exponer el backend directamente al navegador.

---

## 2. Resumen de hallazgos

| # | Hallazgo | Severidad | Criterio principal |
|---|---|---|---|
| H1 | Checkout y pago reales diferidos; simulación local con contradicciones | 🔴 | Coherencia, deuda |
| H2 | Se pierde el historial git de ambos proyectos | 🔴 | Errores críticos |
| H3 | CORS nunca se ejercita en desarrollo y es frágil en Docker | 🔴 | Errores críticos |
| H4 | Riesgo de publicar secretos en un repositorio público | 🟠 | Buenas prácticas |
| H5 | Validaciones de correo y contraseña divergen del requerimiento del curso | 🟠 | Coherencia |
| H6 | Estrategia de imágenes: mapeo parcial, acople al JAR y doble fuente de verdad | 🟠 | Coherencia, deuda |
| H7 | Inconsistencias internas del documento (gates, decisiones abiertas, nombres) | 🟠 | Legibilidad |
| H8 | Sin trazabilidad con la pauta (axios, tests, vistas nuevas, cobertura) | 🟠 | Coherencia |
| H9 | Prioridades invertidas: más infraestructura que integración | 🟠 | Coherencia |
| H10 | Carrito: reglas de negocio no portadas y caché sin refresco | 🟡 | Errores críticos |
| H11 | Capa de datos: adaptadores perpetúan el modelo legado; mocks no se borran; paginación sin definir | 🟡 | Deuda |
| H12 | Pruebas concentradas al final y herramienta sin decidir | 🟡 | Buenas prácticas |
| H13 | JWT en `localStorage` sin mitigaciones definidas | 🟡 | Buenas prácticas |
| H14 | Docker/Nginx: orden de arranque, resolución DNS y puertos fijos | 🟡 | Errores críticos |
| H15 | Hallazgos menores | 🟢 | Varios |

---

## 3. Hallazgos críticos 🔴

### H1 — Checkout y pago reales diferidos; simulación local con contradicciones

**Evidencia**

- D11, F5 y F7 dejan el checkout y el pago reales fuera de la iteración y mantienen `pedidos.js`, `pagos.js` y `PagoFallido` locales. El resultado es un catálogo real con un pedido que **nunca llega al backend**: no se registra en la base, no descuenta stock, no tiene número de pedido real.
- El backend ya expone `POST /checkout`, `POST /pagos/simular`, reintento de pago y estados de pedido. Se integra todo salvo lo que da sentido a la tienda.
- El anexo de la Evaluación 2 incluye las vistas de compra (checkout, compra exitosa, pago fallido), pide autocompletar los datos si el usuario tiene sesión y exige presentar el desarrollo "integrado con el backend". F5 no contempla el autocompletado. **[verificar con la pauta vigente]**
- **Tres definiciones del ciclo de vida del carrito:** D6 ("persistente hasta completar el pago"), la corrección técnica ("se vacía al crear el pedido, no al aprobar el pago") y la definición de terminado ("hasta completar la simulación").
- **Verificación imposible:** el paso 6 del smoke y D10 usan `KATEYE_PAGO_SIMULADO_RESULTADO=RECHAZADA`, que configura el resultado en el **backend**. Pero F5 prohíbe llamar a `/pagos/simular`, así que esa variable no tiene efecto. Y si se pretendiera leerla en el frontend, Vite solo expone variables con prefijo `VITE_`.
- **Deuda creada a propósito:** helper de `Idempotency-Key` sin uso, bandera `VITE_CHECKOUT_MODE` y módulos locales que F7 tendrá que borrar. R12 ("se mezclan checkout simulado y real") es un riesgo que el propio plan introduce.

**Impacto:** el flujo más importante del negocio queda sin integrar, la verificación del rechazo de pago no puede pasar y se escribe código que ya nace para borrarse.

**Solución A — Integrar el checkout real ahora (mover F7 a F5)**

1. `api/endpoints/checkout.js` con `crearPedido(payload, idempotencyKey)`, `simularPago(numero, idempotencyKey)` y `reintentarPago(numero)`.
2. En `Checkout`, generar la `Idempotency-Key` una vez por intento de compra (`useRef`) y reutilizarla en reintentos por fallo de red; generar otra solo si cambia el contenido del carrito.
3. Autocompletar el formulario con `GET /usuarios/me` cuando hay sesión.
4. Vaciar el carrito cuando `POST /checkout` responde 2xx (regla del backend). Si el pago es rechazado, el pedido ya existe: `PagoFallido` ofrece reintentar con `POST /pagos/{numero}/reintentar`, no crear otro pedido. El ciclo de vida del carro persiste hasta aprobar el pago.  
5. Eliminar `pedidos.js`, `pagos.js` y la bandera `VITE_CHECKOUT_MODE`.
6. Probar el rechazo reiniciando el backend con `KATEYE_PAGO_SIMULADO_RESULTADO=RECHAZADA` (documentar un `docker-compose.rechazo.yml` de override en el README).

**Solución B — Mantener la simulación, pero aislada tras una interfaz**

1. Un único punto de entrada `services/checkout/index.js` con el contrato `crearPedido(carrito, cliente) → Promise<{ numero, total, estado }>`.
2. Dos implementaciones, `simulado.js` y `http.js`, elegidas en un solo lugar por `VITE_CHECKOUT_MODE`.
3. Tests de contrato compartidos que ambas implementaciones deben pasar.
4. Marcar el modo simulado como `@deprecated` con fecha de retiro.
5. Corregir el smoke 6: en modo simulado el rechazo se fuerza con `VITE_PAGO_SIMULADO_RESULTADO`, no con la variable del backend.
6. Unificar la regla del carrito (ver resultado óptimo).

**Resultado óptimo: Solución A.** El backend ya existe, las vistas ya existen y la parte nueva es una capa delgada de endpoints. Queda un solo flujo, sin código simulado, y D6 se reescribe: *"El carrito se conserva hasta que el backend confirma la creación del pedido."* Además, alinear el backend: si `Idempotency-Key` es obligatoria en la práctica, declararla `required = true` en el controlador y en la documentación OpenAPI en vez de dejarla "opcional" (hoy el contrato dice una cosa y el comportamiento otra).

---

### H2 — Se pierde el historial git de ambos proyectos

**Evidencia**

- R2, §5 y §6 copian con `rsync --exclude='.git'` y hacen `git init` nuevo; el "primer commit" ocurre tras el Gate G0.
- El anexo de la Evaluación 2 exige el enlace a un **GitHub público del proyecto frontend** y una ronda de preguntas sobre **los cambios realizados en GitHub** durante el desarrollo. Un único commit inicial elimina esa evidencia. **[verificar con la pauta vigente]**
- Ambos proyectos tienen cambios sin commit (§3). El plan los copia "tal cual", de modo que quedarían congelados en un primer commit sin mensajes ni autoría por cambio, mezclando la migración MySQL, el frontend y la estructura nueva.
- El plan modifica el `.gitignore` de un "repositorio raíz" que no describe en ningún otro punto, aunque afirma no tocar los originales (R1).

**Impacto:** pérdida irreversible de trazabilidad de desarrollo, y un repositorio inicial difícil de auditar.

**Solución A — Monorepo con historial importado**

1. En cada proyecto original, crear una rama `pre-integracion` y **commitear** los cambios pendientes (la copia de seguridad previa es un `zip` fuera del árbol).
2. En un **clon** de cada repositorio, reescribir las rutas:
   ```bash
   git filter-repo --to-subdirectory-filter KatEye-Front   # en el clon del frontend
   git filter-repo --to-subdirectory-filter KatEye-Back    # en el clon del backend

   ```
3. Revisar que ambos clones Front-Back, que las configuraciones esten correctas, compilaciones y test. 

4. En `TiendaKatEye`: `git remote add` de cada clon y `git merge --allow-unrelated-histories`. (`git subtree add` es más simple, pero deja el historial sin prefijo de carpeta.)

**Solución B — Repositorios independientes + repositorio de orquestación**

1. `mi-proyecto` y `KatEyeBackEnd` siguen siendo repositorios, cada uno con su historial y su remoto de GitHub. Los cambios de integración entran en ramas `feature/integracion-api`.
2. `TiendaKatEye` contiene únicamente `docker-compose.yml`, `.env.example`, README y documentación, y referencia ambos proyectos como submódulos:
   ```bash
   git submodule add <url-frontend> KatEye-Front
   git submodule add <url-backend>  KatEye-Back
   ```
3. `Dockerfile` y `nginx.conf` del frontend viven en el repositorio del frontend.

**Resultado óptimo: Solución B.** Mantiene intacto el repositorio que se entrega y se evalúa, no reescribe hashes y elimina la necesidad de la copia con `rsync`, por lo que desaparecen R1, R2, R14 y R15 y se simplifica F0. El directorio unificado (D4) se conserva; D12 cambia a "repositorio de orquestación". Si el docente exige un solo enlace con todo el código, usar A.

---

### H3 — CORS nunca se ejercita en desarrollo y es frágil en Docker

**Evidencia**

- **Desarrollo:** el proxy de Vite hace que el navegador solo hable con `localhost:5173`. Con `VITE_API_URL=/api/v1`, **ninguna petición es cross-origin**: la configuración CORS del backend queda sin uso y sin evidencia, aunque es un requisito de la pauta (axios + CORS).
- **Producción (Nginx):** por defecto Nginx reescribe la cabecera `Host` a `backend:8080`. Spring ve entonces un `Origin: http://localhost` distinto del `Host` y **aplica la validación CORS**, con una lista fija (`CORS_ORIGEN=http://localhost:5173,http://localhost`). Si R3 obliga a mover el frontend a otro puerto (p. ej. 8081), los `POST` responden **403 "Invalid CORS request"**. El plan no lo anticipa.
- `urlImagenProducto` devuelve rutas relativas (`/img/...`): solo funcionan con el proxy. Si se pasa a modo cross-origin para demostrar CORS, las imágenes se piden a `:5173` y fallan.

**Impacto:** requisito de la pauta sin evidencia verificable y un 403 intermitente según el puerto elegido.

**Solución A — Cross-origin real en desarrollo; same-origin en producción**

1. Variables por entorno:
   ```bash
   # .env.development
   VITE_API_URL=http://localhost:8080/api/v1
   VITE_ASSETS_URL=http://localhost:8080
   # .env.production
   VITE_API_URL=/api/v1
   VITE_ASSETS_URL=
   ```
2. Helper único `urlAsset(ruta) => `${import.meta.env.VITE_ASSETS_URL ?? ""}${ruta}``, usado también para las imágenes.
3. Backend: `CORS_ORIGEN=http://localhost:5173` y, con Spring Security, `.cors(...)` + `OPTIONS` permitido (ver respuesta anterior sobre la configuración).
4. Nginx conserva el origen original para que Spring lo trate como same-origin:
   ```nginx
   proxy_set_header Host $http_host;
   proxy_set_header X-Forwarded-Proto $scheme;
   proxy_set_header X-Forwarded-Host $http_host;
   ```
   y en `application.properties`: `server.forward-headers-strategy=framework`.
5. Evidencia automatizada. Prueba de integración en el backend:
   ```java
   @SpringBootTest @AutoConfigureMockMvc
   class CorsIT {
     @Autowired MockMvc mvc;
     @Test void preflightPermiteOrigenConfigurado() throws Exception {
       mvc.perform(options("/api/v1/productos")
           .header("Origin", "http://localhost:5173")
           .header("Access-Control-Request-Method", "GET"))
          .andExpect(status().isOk())
          .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:5173"));
     }
     @Test void preflightRechazaOrigenDesconocido() throws Exception {
       mvc.perform(options("/api/v1/productos")
           .header("Origin", "http://malo.example")
           .header("Access-Control-Request-Method", "GET"))
          .andExpect(status().isForbidden());
     }
   }
   ```
   y en el smoke: `curl -i -X OPTIONS http://localhost:8080/api/v1/productos -H "Origin: http://localhost:5173" -H "Access-Control-Request-Method: GET"`.

**Solución B — Mantener proxy en desarrollo y demostrar CORS con un perfil aparte**

1. Se conserva el proxy de Vite y Nginx como están, más el `proxy_set_header Host $http_host` del punto A4.
2. Un script `scripts/smoke-cors.sh` y el test `CorsIT` prueban el preflight sin navegador.
3. El README explica que CORS se configura igualmente como defensa en profundidad y para despliegues con dominios separados.

**Resultado óptimo: Solución A.** El navegador exhibe un CORS real en desarrollo (la pauta lo pide), producción sigue sin fricciones vía Nginx y el test automático protege la regresión. B solo si el docente acepta evidencia por `curl`.

---

## 4. Hallazgos altos 🟠

### H4 — Riesgo de publicar secretos en un repositorio público

**Evidencia**

- Solo existe `.env.example`. El contenido del `.gitignore` nuevo **no está definido** (la única instrucción es agregar `TiendaKatEye/` al de la raíz).
- El `rsync` del frontend no excluye `dist/` ni `.env*`; el del backend no excluye `.env` ni `*.log`.
- Los "cambios MySQL sin commit" se copian tal cual; es probable que incluyan credenciales de base de datos en `application.properties` o en el compose original **[verificar]**.
- El plan no menciona el secreto de firma del JWT ni su origen. El anexo exige repositorio público.

**Solución A — Sacar los secretos del código y verificarlo con una herramienta**

1. `application.properties` usa `${DB_PASSWORD}` y `${JWT_SECRET}` **sin valor por defecto**.
2. `.gitignore` explícito: `.env`, `.env.*` (excepto `.env.example`), `*.local`, `target/`, `node_modules/`, `dist/`, `*.zip`, `.idea/`.
3. El Gate G0 incluye `gitleaks detect --source .` sobre el repositorio antes del primer push.

**Solución B — Fallar rápido en Docker y rotar lo que ya se expuso**

1. En el compose, variables obligatorias: `JWT_SECRET: ${JWT_SECRET:?defina JWT_SECRET en .env}`; sin ellas el contenedor ni arranca.
2. Si algún secreto ya estuvo en un commit, **rotarlo** (cambiar contraseña y generar otro `JWT_SECRET`) en lugar de intentar solo borrarlo del historial.

**Resultado óptimo: A + B en capas.** El código no contiene secretos, el compose exige definirlos y el gate lo comprueba.

---

### H5 — Validaciones de correo y contraseña divergen del requerimiento del curso

**Evidencia**

| Regla | Curso (`validaciones.js`, VALIDACIONES.txt) | Plan |
|---|---|---|
| Dominio de correo (login/registro) | Solo `@duoc.cl`, `@profesor.duoc.cl`, `@gmail.com` | **D8:** cualquier correo válido |
| Correo en contacto | Opcional (el propio código lo comenta: "NO es obligatorio en el enunciado") | **D7:** obligatorio |
| Contraseña | 4 a 10 caracteres | 4 a 72 "caracteres" |

Además, bcrypt limita a **72 bytes**, no a 72 caracteres: una contraseña con `ñ` o tildes cuenta más de un byte.

**Impacto:** si la pauta repite las reglas del curso, se pierde puntaje por una decisión que parece de conveniencia del backend.

**Solución A — Alinear con el curso**

1. Backend con Bean Validation: `@Pattern` para los dominios, `@Size(min = 4, max = 10)` para la contraseña y correo de contacto `@Nullable`.
2. Frontend con constantes idénticas y mapeo de los errores por campo del `ErrorResponse` a cada input.
3. Una prueba en cada lado con los mismos casos válidos/inválidos.

**Solución B — Mantener D7/D8 como desviación documentada**

1. Registrar un ADR con el texto de la pauta citado, la razón y quién lo autorizó.
2. Si se mantiene el máximo 72, validarlo en **bytes UTF-8** en frontend y backend.

**Resultado óptimo: A**, salvo autorización expresa del docente. El cliente valida por experiencia de usuario, el servidor es la autoridad y ambos comparten las mismas reglas.

---

### H6 — Estrategia de imágenes: mapeo parcial, acople al JAR y doble fuente de verdad

**Evidencia**

- Solo 4 de 15 códigos tienen asset real; el resto recibe un placeholder copiado como `kat-00X.jpg`. El catálogo original (`data.js`) tiene **9** imágenes de producto; el plan mapea 4 y **no explica** qué pasa con las otras 5.
- El mapeo es manual y no se contrasta con los nombres reales del backend. Un emparejamiento erróneo no produce error: muestra la foto de otro producto. **[verificar]**
- Las seeds ya contienen la URL de la imagen, pero `urlImagenProducto` la **reconstruye** con `codigo.toLowerCase()`: dos fuentes de verdad.
- Los archivos placeholder parecen imágenes reales; el frontend ya tiene `onError → IMG_PLACEHOLDER`, así que son redundantes.
- Las imágenes viven en `static/` dentro del JAR: cambiar una foto exige recompilar y reconstruir la imagen del backend.
- D13: los blogs vienen de la API (F3) pero sus imágenes quedan en el frontend sin definir cómo se enlazan.

**Solución A — Imágenes en un directorio externo del backend (volumen)**

1. `spring.web.resources.static-locations=file:/app/media/,classpath:/static/` y un volumen `./KatEye-Back/media:/app/media` en el compose.
2. El frontend usa el campo de URL que entrega la API, sin reconstruirlo. Si el DTO no lo expone, se agrega al DTO.
3. Se eliminan los 11 archivos placeholder: lo que falta lo cubre `onError`.
4. Tabla de reconciliación `15 códigos ↔ nombre (de la API) ↔ asset` y un script que falla si un producto no tiene imagen ni excepción declarada.

**Solución B — Imágenes en el contenedor del frontend**

1. `public/img/productos/` servido por Nginx con caché larga; el backend solo guarda la ruta.
2. Mismo punto 2, 3 y 4 de A.
3. Revierte D3/D13 y complica la futura subida de imágenes desde un panel de administración.

**Resultado óptimo: A.** Respeta D3, no recompila el backend por una foto, deja una sola fuente de verdad y detecta los emparejamientos erróneos. Para los blogs, agregar el campo de imagen al DTO (o un mapeo por `slug`) y documentarlo.

---

### H7 — Inconsistencias internas del documento

**Evidencia**

- **Gates:** F0 → "G0/G10", F1 → "G8", F2 → "G5/G4", F3 y F4 sin identificador, F5 → "G7/G9"; la sección 9 usa G0–G6 con otro significado. Un tercero no puede saber qué gate hay que cumplir en cada fase.
- D1 dice "Alternativa A con ejecución híbrida", pero el documento **nunca define** qué es la alternativa A ni qué es "híbrida".
- Sección 2 se titula "Decisiones cerradas", pero F6 deja abierto "MSW o mock de Axios" y F5 "si se agrega un flag".
- F0 excluye `App.test.js` y `setupTests.js` del `rsync`, y F6 los "elimina": una de las dos tareas sobra.
- R3 hace configurable `BACKEND_PORT`, pero el proxy de Vite y los `curl` de la sección 10 fijan `localhost:8080`.
- La sección 6 contiene una ruta absoluta personal (`/home/benja/...`).
- Cuatro convenciones de nombre conviven: `TiendaKatEye`, `KatEye-Back/katEye`, `KatEye-bb.dd` y `mi-proyecto`.

**Solución A — Edición editorial del mismo documento**

1. Renumerar los gates **G0–G6 = F0–F6**, cada uno con "comandos → resultado esperado".
2. Agregar un glosario inicial (Alternativa A, ejecución híbrida, gate, adaptador).
3. Cerrar o mover a "Pendientes" las decisiones abiertas; eliminar las tareas duplicadas.
4. Sustituir rutas y puertos fijos por variables (`$PROYECTOS`, `${BACKEND_PORT}`).

**Solución B — Dividir el documento por propósito**

1. `PLAN.md` (qué y cuándo, con gates), `docs/adr/` (una decisión por archivo: contexto, decisión, consecuencias) y `README` (comandos).
2. Convertir los gates en scripts ejecutables (`scripts/gate-N.sh` o `make gate-N`) para que la verificación no dependa de la lectura.

**Resultado óptimo: A ahora, y B solo para las decisiones con consecuencias reales (D2, D3, D9, D11).** Ganas legibilidad sin multiplicar archivos.

---

### H8 — Sin trazabilidad con la pauta

| Requisito | Cobertura en el plan | Brecha |
|---|---|---|
| Axios en las solicitudes HTTP | Se crea `client.js`, pero **ninguna tarea** instala `axios` ni verifica que todo HTTP lo use | Agregar tarea y gate |
| CORS | Configurado, nunca demostrado | Ver H3 |
| Pruebas | D2 elige **Vitest**; el anexo de la Evaluación 2 menciona **Jasmine y Karma** | Confirmar qué exige la pauta actual |
| Documento de cobertura del testing | No hay `--coverage` ni informe | Agregar |
| Vistas nuevas (Categorías, Ofertas, compra exitosa/fallida) | §12 deja `/ofertas` y `/categorias` fuera de alcance; la compra queda simulada (H1) | Confirmar con la pauta |
| Autocompletar checkout con sesión | No contemplado | Ver H1 |
| ERS actualizado | No aparece en ninguna fase | Agregar tarea documental |

**Solución A — Matriz de trazabilidad dentro del plan**

Tabla pauta → fase → gate → evidencia, revisada antes de empezar y al cerrar cada fase.

**Solución B — Reglas verificables por herramienta**

1. ESLint que prohíbe `fetch` y la importación de `axios` fuera de `src/api/client.js`:
   ```js
   rules: {
     "no-restricted-globals": ["error", "fetch"],
     "no-restricted-imports": ["error", { paths: ["axios"] }]
   }
   // override: permitir axios solo en src/api/client.js
   ```
2. `vitest run --coverage` con umbral mínimo y salida guardada para el documento de cobertura.

**Resultado óptimo: A + B.** La matriz dice qué se exige; ESLint y la cobertura lo hacen cumplir.

---

### H9 — Prioridades invertidas: más infraestructura que integración

**Evidencia:** F0 completa, 5 de los 15 riesgos (R1, R2, R13, R14, R15) y las decisiones D4, D12 y D13 existen únicamente por la reorganización de carpetas, repositorios y contenedores, mientras el flujo que se evalúa (checkout, H1) queda diferido. El plan ocupa 425 líneas antes de la primera línea de integración.

Lo señalo directamente: es el patrón de dedicar más esfuerzo a planificar y reestructurar que a entregar la funcionalidad pendiente. La reorganización no es un requisito de la pauta; la integración sí.

**Solución A — Invertir el orden: rebanada vertical primero**

1. Con las carpetas actuales: `axios` + CORS real + `GET /productos` mostrando el catálogo. Ese es el primer hito.
2. Después, el resto de entidades; la reorganización de contenedores al final.

**Solución B — Limitar la reorganización en tiempo y alcance**

1. Si se reorganiza, reducir F0 a: ramas, commits pendientes, compose raíz y README. Sin renombrar ni mover código.
2. Fijar una duración máxima y no avanzar a F1 hasta cerrarla.

**Resultado óptimo: A, apoyado en la Solución B de H2.** Con submódulos, la reorganización se reduce a un `docker-compose.yml` y un README; el primer entregable visible es el catálogo conectado.

---

## 5. Hallazgos medios 🟡

### H10 — Carrito: reglas de negocio no portadas y caché sin refresco

**Evidencia**

- El plan persiste `{id, cantidad}` pero no define lo que el `carrito.js` original ya resolvía: máximo por línea (10 unidades), descarte de productos inexistentes, precio siempre desde el catálogo y no desde lo guardado.
- Con `CatalogoProvider` como caché global y sin política de refresco, el carrito puede mostrar precios o stock obsoletos distintos de lo que el backend cobrará.
- Si `/productos` falla, el carrito aparecería vacío sin error.
- El carrito usa `id`; las imágenes usan `codigo`. **[verificar]** cuál identificador consume `POST /checkout`.

**Solución A — Reglas explícitas en `CarritoProvider`**

1. Al montar, reconciliar con el catálogo: descartar líneas inexistentes, limitar a `[1, min(10, stock)]`, tomar precios del catálogo vigente.
2. Estados visibles de `cargando` y `error`.
3. Versionar la clave de almacenamiento (`kateye_carrito_v2`) para no leer formatos antiguos.

**Solución B — El backend como autoridad al pagar**

1. Al enviar `POST /checkout`, el backend recalcula precio y stock; el frontend muestra las diferencias antes de confirmar.
2. La reconciliación local queda solo como mejora de experiencia.

**Resultado óptimo: A en F5 y B activo con el checkout real (H1-A).** Se usa un único identificador en todo el flujo.

---

### H11 — Capa de datos: adaptadores perpetúan el modelo legado; mocks no se borran; paginación sin definir

**Evidencia**

- R5 propone adaptadores y "no borrar módulos antiguos hasta migrar", pero **ninguna fase los borra** (F6 solo elimina restos de Create React App). La definición de terminado exige que ninguna vista use datos simulados; no exige que los archivos desaparezcan.
- Los adaptadores mantendrían indefinidamente la forma antigua (`imagenes[]`, `precioAnterior`, etc.) sobre un contrato nuevo.
- F3 filtra categoría y precio **en el cliente** sin definir si `GET /productos` es paginado **[verificar]**. Si devuelve una página (`Page`), los filtros, los productos relacionados y la resolución del carrito verían solo la primera. El diseño del backend contempla dos filtros de búsqueda en servidor, así que el filtrado se duplicaría.

**Solución A — Un solo modelo: el contrato del backend**

1. Migrar las vistas al DTO real, definido con typedefs JSDoc.
2. Borrar los módulos mock con un gate: `grep -r "data/mocks" src` sin resultados.
3. Definir la paginación: pedir un `size` suficiente o usar filtros de servidor (`?categoria=&min=&max=`).

**Solución B — Adaptadores confinados con fecha de caducidad**

1. Mantenerlos en `api/adapters.js` con tests de contrato y un `TODO` con fecha.
2. Deuda controlada, no eliminada.

**Resultado óptimo: A.** Un único modelo, sin capas de traducción y sin código muerto.

---

### H12 — Pruebas concentradas al final y herramienta sin decidir

**Evidencia:** F6 reúne los tests nuevos después de refactorizar F2–F5, cuyos gates son manuales. "MSW o mock de Axios" queda abierto. No hay cobertura (H8).

**Solución A — Pruebas por fase; MSW como decisión cerrada**

1. Cada gate incluye su suite verde: F2 (`client`, `errors`, interceptores), F3 (catálogo, regiones), F4 (sesión, contacto), F5 (carrito, checkout).
2. MSW intercepta a nivel de red: valida `baseURL`, cabecera `Authorization`, `Idempotency-Key` y mapeo de errores sin acoplarse a la implementación de Axios.

**Solución B — Mantener F6 con humo automatizado por gate**

1. Scripts `curl` por fase (como los de §10) como red mínima mientras los tests llegan al final.

**Resultado óptimo: A.** Los tests se escriben cuando el código está fresco y la regresión se detecta en la fase que la causó.

---

### H13 — JWT en `localStorage` sin mitigaciones definidas

**Evidencia:** D9 guarda el token en `localStorage` y §12 difiere la cookie `httpOnly`. Es una decisión válida para v1, pero el plan no define mitigaciones de XSS (los blogs vienen de la API), la expiración ni la política ante 401.

**Solución A — Mantener `localStorage` con mitigaciones**

1. Prohibir `dangerouslySetInnerHTML` con contenido del backend.
2. CSP en Nginx (`default-src 'self'`).
3. Interceptor central: ante 401 limpia el token y el estado de sesión; el `Authorization` se adjunta solo a la `baseURL` propia.
4. Documentar expiración del JWT y la gestión de su secreto (H4).

**Solución B — Cookie `httpOnly` + `SameSite`**

1. En producción, front y API comparten origen vía Nginx, así que es viable.
2. Requiere estrategia CSRF, `withCredentials` en Axios y `allowCredentials(true)` con origen explícito (lo que se cruza con H3).

**Resultado óptimo: A en esta iteración** (coherente con el interceptor Bearer que pide la pauta) y un ADR que deje B como siguiente paso.

---

### H14 — Docker/Nginx: orden de arranque, resolución DNS y puertos fijos

**Evidencia**

- El frontend `depends_on: backend` sin condición de salud, y el backend no define healthcheck (la base de datos sí).
- Nginx resuelve `backend` al arrancar; si el contenedor del backend se recrea, devuelve 502 hasta reiniciar Nginx.
- El fragmento de Nginx no tiene cabeceras de proxy, compresión ni caché de assets.
- `BACKEND_PORT` es configurable pero el proxy de Vite y los `curl` usan 8080 fijo.
- El pre-flight verifica el puerto 3306: confirmar que MySQL no se publica al host si solo lo usa el backend. **[verificar]**

**Solución A — Endurecimiento completo**

1. Healthcheck del backend con `/actuator/health` y `depends_on: condition: service_healthy` en el frontend.
2. Nginx con `resolver 127.0.0.11 valid=10s;` y `proxy_pass` con variable, cabeceras `Host/X-Forwarded-*`, gzip y caché larga para assets con hash.
3. `vite.config.js` lee `BACKEND_PORT` con `loadEnv`.

**Solución B — Mínimo viable**

1. Solo healthcheck del backend y una variable única de puerto compartida por Vite y los `curl`.

**Resultado óptimo: B ahora (resuelve los errores reales) y A cuando se acerque el despliegue.**

---

## 6. Hallazgos menores 🟢

| # | Hallazgo | Corrección |
|---|---|---|
| H15.1 | En React Router v7, `react-router-dom` queda como reexportación; la guía de migración recomienda importar desde `react-router` | Elegir un único paquete de importación y fijarlo en el README (D5 no cambia de versión) |
| H15.2 | Nombres: `KatEye-bb.dd`, `KatEye-Back/katEye` (doble nivel), `mi-proyecto` | `KatEye-DB`; evitar la carpeta anidada |
| H15.3 | Ruta absoluta personal en §6 | Variable `$PROYECTOS` |
| H15.4 | `rsync` del frontend sin `dist/` ni `.env*`; del backend sin `.env`, `*.log`, `.idea` | Ampliar los excludes (o eliminar el `rsync`, H2-B) |
| H15.5 | Pre-flight no verifica la versión de Java | Agregar `java -version` |
| H15.6 | Modificación del `.gitignore` de un repositorio raíz no descrito | Eliminarla con H2-B |
| H15.7 | `crypto.randomUUID()` exige contexto seguro; en `http://<IP-LAN>` no existe | Helper con alternativa de respaldo |
| H15.8 | F0 excluye `App.test.js`/`setupTests.js` y F6 los elimina | Dejar solo una de las dos tareas |

Aquí la corrección es única y obvia, por eso no se ofrecen dos alternativas.

---

## 7. Resultado óptimo global

### 7.1 Arquitectura objetivo

```text
TiendaKatEye/                      ← repositorio de orquestación (sin copiar código)
├── docker-compose.yml             ← db, backend, frontend; red kateye-net
├── .env.example                   ← sin secretos reales; variables obligatorias
├── README.md                      ← cómo levantar todo + cómo probar CORS y rechazo de pago
├── docs/                          ← PLAN.md, ERS v2, informe de cobertura, ADR (D2, D3, D9, D11)
├── KatEye-Front/   (submódulo)    ← repo existente; Dockerfile + nginx.conf propios
├── KatEye-Back/    (submódulo)    ← repo existente; imágenes en volumen
└── KatEye-DB/                     ← README (+ init opcional); Flyway sigue siendo el dueño del esquema
```

```text
DESARROLLO                                     PRODUCCIÓN (Docker)
React :5173  ──Axios (cross-origin)──▶ Spring :8080     Navegador ─▶ Nginx :80 ─┬─▶ SPA estática
        (CORS real, evidenciado por test)                                       ├─▶ /api → backend
                                                                                └─▶ /img → backend
```

### 7.2 Fases corregidas

| Fase | Contenido | Gate (ejecutable y con tests de la fase) |
|---|---|---|
| **F0** | Commits pendientes en ramas `pre-integracion`; `.gitignore` y secretos; repo de orquestación con submódulos; compose mínimo | `docker compose config`, `gitleaks`, builds de ambos proyectos |
| **F1** | Vitest + jsdom + cobertura + ESLint (`no-restricted-*`); baseline de la suite | Suite ejecuta; `npm run build` |
| **F2** | **Rebanada vertical:** `axios`, `client.js`, CORS real, `GET /productos`, imágenes por `urlAsset` | `CorsIT` verde, preflight por `curl`, test MSW de `client`, catálogo visible |
| **F3** | Categorías, blogs, regiones y comunas; modelo único del backend; borrar mocks | `grep` de mocks sin resultados; tests de catálogo |
| **F4** | Sesión JWT, registro, contacto; validaciones alineadas con el curso y el backend | Tests de validación en ambos lados; interceptor 401 |
| **F5** | Carrito con reglas + **checkout real** + pago + fallo/reintento + autocompletado | Rechazo con `KATEYE_PAGO_SIMULADO_RESULTADO=RECHAZADA`; carrito se vacía al crear el pedido |
| **F6** | Docker completo, healthchecks, ERS v2, informe de cobertura, smoke | `docker compose up --build` + smoke completo |

### 7.3 Definición de terminado corregida

- Todo HTTP del frontend pasa por `src/api/client.js` (Axios); ESLint lo impone.
- CORS verificado con test automatizado y con navegador en desarrollo.
- Checkout, pago, rechazo y reintento funcionan contra el backend; no queda código simulado.
- El carrito se conserva hasta que el backend confirma la creación del pedido.
- Historial git de ambos proyectos intacto; sin secretos en ningún commit (`gitleaks` limpio).
- Validaciones de frontend y backend idénticas y alineadas con la pauta.
- Ningún módulo mock en el árbol; un único modelo de datos.
- Tests por fase en verde y documento de cobertura generado.
- Gates numerados G0–G6 = F0–F6; decisiones relevantes con ADR.
- README: levantar los tres contenedores, probar CORS y forzar el rechazo de pago.

### 7.4 Cambios mínimos al `PLANIFICACION.md` actual (en orden de prioridad)

1. Mover F7 (checkout real) a F5 y reescribir D6 y D10 (H1).
2. Reemplazar la copia con `rsync` por submódulos y ramas de integración (H2).
3. Definir CORS real en desarrollo y corregir la cabecera `Host` de Nginx (H3).
4. Definir `.gitignore`, secretos y el gate `gitleaks` (H4).
5. Alinear D7/D8 con la pauta (H5).
6. Resolver imágenes con tabla de reconciliación y volumen (H6).
7. Renumerar gates, definir "Alternativa A" y cerrar decisiones abiertas (H7).
8. Agregar la matriz de trazabilidad y la tarea de instalar `axios` (H8).
9. Reordenar para entregar la rebanada vertical primero (H9).
