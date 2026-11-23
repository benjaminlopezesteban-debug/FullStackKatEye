# Arquitectura — TiendaKatEye

| | |
|---|---|
| **Proyecto** | KatEye / TiendaKatEye |
| **Versión** | 1.1 |
| **Fecha** | 2026-11-21 |
| **Ámbito** | Repositorio unificado, frontend React, backend Spring Boot y base MySQL |
| **Documento maestro** | `../planificacion_desarrollo.md` |

---

## 1. Propósito

Este documento describe la arquitectura objetivo de la entrega y sirve como mapa para un tercero. Los árboles marcados como **objetivo** todavía no existen; los marcados como **actual** reflejan el código de partida. El árbol se actualiza al cerrar cada fase (ver §12).

Principios:

1. **Conciliar, no rehacer:** se conservan vistas, estilos y navegación del frontend.
2. **El backend es la fuente de verdad:** precios, stock, totales, estados y permisos se calculan en el servidor.
3. **Un solo modelo de datos en el frontend:** las vistas consumen los DTO del backend; no hay adaptadores que perpetúen el modelo legado.
4. **Un solo flujo de compra:** no conviven checkout simulado y checkout real.
5. **Un solo repositorio de entrega:** `TiendaKatEye`/`FullStackKatEye` contiene el código y el historial importado de frontend y backend; los repositorios independientes son espejos de progreso.
6. **Cada fase deja evidencia y memoria:** gate ejecutable, documento en `docs/fases/` y `docs/memoria/mm_devFaseX.md`.

---

## 2. Topología de repositorios

```text
GitHub
├── FullStackKatEye             ← entrega final unificada (directorio local TiendaKatEye)
│   ├── KatEye-Front/           ← código + historial importado de ProyectoWebKatEyes
│   ├── KatEye-Back/            ← código + historial importado de backendProyectoKatEye
│   └── KatEye-DB/              ← esquema, README e init opcional
├── ProyectoWebKatEyes          ← espejo de progreso del frontend
└── backendProyectoKatEye       ← espejo de progreso del backend
```

`kateyefullStack` (repositorio raíz del workspace) **no** forma parte de la entrega y no se modifica.

Los commits los realiza el usuario al cerrar cada fase; el plan solo sugiere el mensaje. `TiendaKatEye` es la fuente de verdad; los espejos se actualizan con `scripts/sync-progreso.sh`.

---

## 3. Árbol del repositorio unificado

```text
TiendaKatEye/
├── .gitignore                       # .env, target/, node_modules/, dist/, *.zip, .idea/
├── .env.example                     # variables obligatorias, sin secretos reales
├── docker-compose.yml               # db + backend + frontend; red kateye-net
├── docker-compose.rechazo.yml       # override: KATEYE_PAGO_SIMULADO_RESULTADO=RECHAZADA
├── README.md                        # información para el usuario y despliegue
├── Makefile                         # gate-0…gate-6, gate-lint, gate-all, sync, up, down, test
├── scripts/
│   ├── gate-0.sh                    # compose config + gitleaks + builds + historial importado
│   ├── gate-1.sh                    # lint + vitest + coverage + build
│   ├── gate-2.sh                    # CorsIT + preflight + contract test + catálogo
│   ├── gate-3.sh                    # tests catálogo + grep anti-mocks + contract test
│   ├── gate-4.sh                    # tests sesión/validación/contacto
│   ├── gate-5.sh                    # tests carrito/checkout/pago (override de rechazo)
│   ├── gate-6.sh                    # compose up + smoke + gitleaks + docs
│   ├── gate-lint.sh                 # ESLint + Prettier + linter del backend (transversal)
│   ├── install-hooks.sh             # instala .git/hooks/pre-push
│   ├── sync-progreso.sh             # espeja KatEye-Front/Back en los repos independientes
│   └── smoke-cors.sh                # preflight CORS por curl
├── docs/
│   ├── ARQUITECTURA.md              # este documento
│   ├── fases/
│   │   ├── INDICE.md                # índice y plantilla
│   │   ├── F0-estructura.md
│   │   ├── F1-pruebas.md
│   │   ├── F2-rebanada-vertical.md
│   │   ├── F3-catalogo.md
│   │   ├── F4-sesion.md
│   │   ├── F5-checkout.md
│   │   └── F6-release.md
│   ├── memoria/
│   │   ├── PLANTILLA.md             # formato de mm_devFaseX.md
│   │   └── mm_devFase0.md … mm_devFase6.md
│   ├── ERS-v2.md
│   ├── cobertura.md
│   ├── api-integracion.md
│   └── manual-usuario.md
├── KatEye-Front/                    # código + historial de ProyectoWebKatEyes
├── KatEye-Back/                     # código + historial de backendProyectoKatEye
└── KatEye-DB/
    ├── README.md
    └── init/                        # opcional; Flyway sigue siendo el dueño del esquema
```

### Contenedores

| Contenedor | Build / imagen | Puerto | Responsabilidad |
|---|---|---|---|
| `kateye-db` | `mysql:8.4` | solo red interna | Datos, volumen y healthcheck |
| `kateye-backend` | `./KatEye-Back/katEye` | `${BACKEND_PORT:-8080}` | API Spring Boot, Flyway, JWT |
| `kateye-frontend` | `./KatEye-Front` | `80:80` | SPA React servida por Nginx y proxy `/api` e `/img` |

### Sincronización de espejos

`TiendaKatEye` es la fuente de verdad. Al cerrar cada fase, `scripts/sync-progreso.sh`:

1. Verifica que los espejos no tengan cambios sin commitear.
2. Copia `KatEye-Front/` → `ProyectoWebKatEyes/` y `KatEye-Back/` → `backendProyectoKatEye/`, excluyendo `.git`, `node_modules`, `target`, `dist` y `.env`.
3. Deja los cambios listos para que el usuario los revise, commitee y pushee en cada espejo.

El script no commitea ni pushea automáticamente. Si un espejo tiene cambios propios, el script aborta; se reconcilia el espejo antes de reintentar.

---

## 4. Árbol del frontend (objetivo)

```text
KatEye-Front/
├── Dockerfile                       # build Vite + Nginx
├── nginx.conf                       # SPA, /api y /img → backend
├── package.json                     # scripts test/test:run/test:coverage/build
├── vite.config.js                   # React + Vitest + loadEnv(BACKEND_PORT)
├── .env.development                 # VITE_API_URL=http://localhost:8080/api/v1
├── .env.production                  # VITE_API_URL=/api/v1
├── .env.example
├── public/
│   └── img/                         # assets estáticos propios (si se necesitan)
└── src/
    ├── main.jsx                     # BrowserRouter + providers
    ├── App.jsx                      # layout y rutas
    ├── api/
    │   ├── client.js                # instancia axios, baseURL, Authorization, 401
    │   ├── errors.js                # normalización de ErrorResponse
    │   ├── urlAsset.js              # VITE_ASSETS_URL + ruta
    │   └── endpoints/
    │       ├── productos.js
    │       ├── categorias.js
    │       ├── blogs.js
    │       ├── regiones.js
    │       ├── comunas.js
    │       ├── usuarios.js
    │       ├── contacto.js
    │       ├── checkout.js
    │       └── pagos.js
    ├── hooks/
    │   ├── useApi.js                # data, loading, error, refetch
    │   └── useFormulario.js
    ├── context/
    │   ├── CarritoContext.js
    │   ├── CarritoProvider.jsx      # reglas + localStorage kateye_carrito_v2
    │   ├── SesionContext.js
    │   └── SesionProvider.jsx       # kateye_token + /usuarios/me
    ├── services/
    │   └── carrito.js               # reglas puras del carrito
    ├── utils/
    │   ├── formatearPrecio.js
    │   ├── producto.js              # presentación DTO → vista
    │   ├── imagenes.js              # resolverImagen + placeholder
    │   └── idempotencia.js          # nuevaIdempotencyKey con fallback
    ├── components/
    │   ├── Header.jsx
    │   ├── Footer.jsx
    │   ├── PanelCarrito.jsx
    │   ├── CarritoFlotante.jsx
    │   ├── TarjetaProducto.jsx
    │   ├── FilaProducto.jsx
    │   ├── Precio.jsx
    │   ├── CampoFormulario.jsx
    │   ├── ResumenPedido.jsx
    │   ├── ConfirmacionPedido.jsx
    │   └── PagoFallido.jsx          # reintento con número de pedido
    ├── views/
    │   ├── Inicio.jsx
    │   ├── Productos.jsx
    │   ├── DetalleProducto.jsx
    │   ├── Checkout.jsx
    │   ├── Blogs.jsx
    │   ├── Blog.jsx
    │   ├── Nosotros.jsx
    │   ├── Contacto.jsx
    │   ├── IniciarSesion.jsx
    │   └── Registro.jsx
    ├── assets/
    │   ├── Logo.jpg
    │   ├── Tienda.jpg
    │   └── blogs/                   # imágenes de blog (contrato: nombre de archivo)
    └── test/
        ├── setup.js
        ├── mocks/
        │   ├── handlers.js          # MSW
        │   └── server.js
        ├── carrito.test.js
        ├── validaciones.test.js
        ├── client.test.js
        ├── checkout.test.jsx
        └── ...
```

### Flujo de una petición

```text
Vista/Componente
   │  usa useApi()
   ▼
hooks/useApi.js
   │  llama a un endpoint
   ▼
api/endpoints/*.js
   │  usa la instancia única
   ▼
api/client.js  ──axios──▶  Spring Boot /api/v1
   │
   ├─ adjunta Authorization: Bearer <token> si existe
   ├─ normaliza errores a ErrorResponse
   └─ ante 401 limpia token y sesión
```

---

## 5. Árbol del backend (actual + cambios de la iteración)

```text
KatEye-Back/                         # código importado de backendProyectoKatEye
├── .env.example                     # sin secretos reales
├── docker-compose.yml               # legado: no se usa en el monorepo
├── docs/proyecto/
│   ├── ARQUITECTURA_BACKEND.md
│   ├── plan_desarrollo.md
│   ├── requirements.md
│   └── modeloNegocio.sql
├── media/
│   └── img/productos/               # volumen externo (nuevo)
│       ├── kat-002.jpg
│       ├── kat-004.jpg
│       ├── kat-005.jpg
│       └── kat-014.jpg
└── katEye/
    ├── Dockerfile
    ├── pom.xml
    └── src/
        ├── main/
        │   ├── java/com/example/katEye/
        │   │   ├── KatEyeApplication.java
        │   │   ├── shared/
        │   │   │   ├── config/CorsConfig.java
        │   │   │   ├── security/{SecurityConfig,JwtService,JwtAuthFilter,Rol,SecurityUtils}.java
        │   │   │   ├── idempotency/{IdempotenciaService,ClaveIdempotencia,...}.java
        │   │   │   ├── exception/{GlobalExceptionHandler,ErrorResponse,...}.java
        │   │   │   ├── event/{PagoAprobadoEvent,PagoRechazadoEvent,ItemEvento}.java
        │   │   │   └── dto/{ApiResponse,PageResponse}.java
        │   │   ├── modulos/
        │   │   │   ├── ubicacion/{region,comuna}
        │   │   │   ├── usuarios/{auth,usuario,rol,recuperacion,intentoacceso}
        │   │   │   ├── catalogo/{producto,categoria,productoimagen,oferta,movimientostock}
        │   │   │   ├── carrito/{carrito,carritoitem}
        │   │   │   ├── pedidos/{pedido,pedidoproducto,historial}
        │   │   │   ├── pagos/pago
        │   │   │   ├── facturacion/{venta,boleta,detalleboleta}
        │   │   │   └── contenido/{entradablog,mensajecontacto}
        │   │   └── orquestador/checkout/{controller,dto,service}
        │   └── resources/
        │       ├── application.yml          # secretos por variable de entorno
        │       ├── db/migration/V1…V6.sql   # no se editan
        │       └── static/                  # sin imágenes de producto
        └── test/java/com/example/katEye/
            ├── KatEyeApplicationTests.java
            └── shared/config/CorsIT.java    # nuevo en F2
```

### Cambios de backend previstos

| Cambio | Fase | Motivo |
|---|---|---|
| `${JWT_SECRET}` y `${SPRING_DATASOURCE_PASSWORD}` sin default | F0 | H4: secretos fuera del código |
| `ProductoResponse.imagenUrl` | F2 | H6: una sola fuente de verdad para imágenes |
| `spring.web.resources.static-locations=file:/app/media/,file:../media/,classpath:/static/` | F2 | H6: imágenes fuera del JAR |
| `server.forward-headers-strategy=framework` | F2 | H3: CORS y cabeceras de proxy |
| `CorsIT` | F2 | H3: evidencia automatizada de CORS |
| `Idempotency-Key` con `required = true` | F5 | H1: contrato coherente con el comportamiento |
| Validación de dominios y contraseña 4–10 | F4 | H5: alinear con el curso |
| Correo de contacto opcional | F4 | H5: alinear con el curso |

---

## 6. Base de datos

```text
KatEye-DB/
├── README.md                        # dueño del esquema: Flyway
└── init/                            # opcional: charset o zona horaria
```

- El esquema y los datos semilla viven en `KatEye-Back/katEye/src/main/resources/db/migration/V1…V6.sql`.
- **No se editan las migraciones aplicadas.** Si hace falta un cambio, se agrega una migración nueva.
- `spring.jpa.hibernate.ddl-auto=validate`; Flyway es la fuente de verdad.
- El contenedor de base de datos no publica el puerto 3306 al host.

---

## 7. Desarrollo y producción

### Desarrollo

```text
┌─────────────────────┐        Axios cross-origin        ┌─────────────────────┐
│ React + Vite :5173  │ ───────────────────────────────▶ │ Spring Boot :8080   │
│                     │                                  │ /api/v1             │
│ VITE_API_URL=       │                                  │ CORS_ORIGEN=        │
│ http://localhost:   │                                  │ http://localhost:   │
│ 8080/api/v1         │                                  │ 5173                │
│                     │        GET /img/productos/*.jpg  │                     │
│ VITE_ASSETS_URL=    │ ───────────────────────────────▶ │ media/img/productos │
│ http://localhost:8080                                  │                     │
└─────────────────────┘                                  └─────────────────────┘
```

- El navegador exhibe un CORS real: `Origin: http://localhost:5173`.
- `CorsIT` y `scripts/smoke-cors.sh` demuestran el preflight sin depender del navegador.

### Producción (Docker)

```text
┌──────────────┐        ┌──────────────────────────────┐
│  Navegador   │ ─────▶ │ Nginx :80                    │
└──────────────┘        │  ├─ /        → SPA estática  │
                        │  ├─ /api/*   → backend:8080  │
                        │  └─ /img/*   → backend:8080  │
                        └──────────────┬───────────────┘
                                       │ proxy_set_header Host $http_host
                                       ▼
                        ┌──────────────────────────────┐
                        │ Spring Boot :8080            │
                        │ server.forward-headers-      │
                        │ strategy=framework           │
                        └──────────────────────────────┘
```

Nginx conserva el origen original para que Spring trate la petición como same-origin y no aplique la validación CORS de producción.

---

## 8. Contratos clave

### Producto

```json
{
  "id": 4,
  "codigo": "KAT-004",
  "nombre": "Base Líquida HD",
  "descripcion": "Cobertura media modulable con acabado natural.",
  "precio": 15990,
  "precioOferta": 13990,
  "precioFinal": 13990,
  "stock": 30,
  "stockCritico": 5,
  "categoriaId": 2,
  "categoriaNombre": "Maquillaje",
  "activo": true,
  "imagenUrl": "/img/productos/kat-004.jpg"
}
```

`imagenUrl` se agrega en F2. El frontend la resuelve con `urlAsset` y no la reconstruye.

### Checkout

```json
{
  "items": [{ "productoId": 4, "cantidad": 2 }],
  "tipoEntrega": "DESPACHO",
  "contactoNombre": "Ana Pérez",
  "contactoCorreo": "ana@gmail.com",
  "contactoTelefono": "+56 9 1234 5678",
  "direccion": "Av. Siempre Viva 742",
  "regionCodigo": "13",
  "comunaCodigo": "13101",
  "metodoPago": "TARJETA"
}
```

Respuesta `201`:

```json
{
  "pedidoId": 12,
  "numero": "20261121-0001",
  "total": 27980,
  "estado": "PENDIENTE_PAGO"
}
```

Cabecera obligatoria: `Idempotency-Key`.

### Pago

```json
{ "pedidoId": 12, "metodo": "TARJETA" }
```

Respuesta:

```json
{
  "id": 7,
  "pedidoId": 12,
  "numeroPedido": "20261121-0001",
  "monto": 27980,
  "estado": "APROBADO",
  "codigoRespuesta": "00",
  "motivo": null,
  "referenciaExterna": "SIM-..."
}
```

Reintento: `POST /api/v1/pagos/{numero}/reintentar?correo=...` con `Idempotency-Key`.

### Error

```json
{
  "estado": 400,
  "error": "Bad Request",
  "mensaje": "El header Idempotency-Key es obligatorio",
  "campos": { "correo": "Ingresa un correo válido." }
}
```

---

## 9. Flujo de imágenes

```text
Flyway V4
  └─ producto_imagen.url = /img/productos/kat-004.jpg
        │
        ▼
ProductoService
  └─ ProductoResponse.imagenUrl = /img/productos/kat-004.jpg
        │
        ▼
Frontend
  ├─ urlAsset(imagenUrl)  →  http://localhost:8080/img/productos/kat-004.jpg (dev)
  │                          /img/productos/kat-004.jpg (prod)
  └─ onError              →  IMG_PLACEHOLDER
```

- El backend sirve `/img/**` desde `file:/app/media/` y `classpath:/static/`.
- No hay placeholders `kat-00X.jpg` falsos: lo que falta lo cubre `onError`.
- La tabla de reconciliación y el script de verificación viven en el plan y en `docs/fases/F2-rebanada-vertical.md`.

---

## 10. Flujo de autenticación

```text
Registro/Login
   │  POST /api/v1/auth/registro | /auth/login
   ▼
TokenResponse { token, usuario }
   │
   ├─ guarda token en localStorage (kateye_token)
   └─ guarda usuario en el contexto de sesión
        │
        ▼
api/client.js
   └─ adjunta Authorization: Bearer <token>
        │
        ▼
401  →  limpia token + sesión + redirige a /iniciar-sesion
```

Mitigaciones de XSS: no `dangerouslySetInnerHTML` con contenido del backend, CSP en Nginx y expiración documentada del JWT.

---

## 11. Estrategia de pruebas

```text
Frontend
├── Vitest + jsdom
├── Testing Library (componentes y vistas)
├── MSW (red: baseURL, Authorization, Idempotency-Key, ErrorResponse)
└── coverage (docs/cobertura.md)

Backend
├── JUnit 5 + Spring Boot Test
├── MockMvc (CorsIT, validaciones, checkout, pagos)
└── Testcontainers (si se incorpora en una fase posterior)

Integración
├── scripts/smoke-cors.sh
├── docker-compose.rechazo.yml
└── smoke manual documentado en README.md
```

Cada gate G1–G5 incluye la suite de su fase. No se concentran todos los tests en F6.

---

## 12. Documentación por fase

| Fase | Documento | Qué registra |
|---|---|---|
| F0 | `docs/fases/F0-estructura.md` | Historial importado, secretos y compose mínimo |
| F1 | `docs/fases/F1-pruebas.md` | Vitest, MSW, ESLint y baseline |
| F2 | `docs/fases/F2-rebanada-vertical.md` | Axios, CORS, catálogo e imágenes |
| F3 | `docs/fases/F3-catalogo.md` | Catálogo, blogs, ubicación y borrado de mocks |
| F4 | `docs/fases/F4-sesion.md` | Sesión JWT, registro, contacto y validaciones |
| F5 | `docs/fases/F5-checkout.md` | Carrito, checkout real, pagos y reintento |
| F6 | `docs/fases/F6-release.md` | Docker, documentación y release |

Cada documento se completa con el **registro de ejecución** al cerrar el gate. El índice y la plantilla están en `docs/fases/INDICE.md`.

Cada fase produce además `docs/memoria/mm_devFaseX.md`, la memoria del desarrollo: archivos creados o modificados y acciones relevantes, en orden, con una descripción breve. La plantilla está en `docs/memoria/PLANTILLA.md`.

---

## 13. Índice de decisiones

| ID | Decisión | Documento |
|---|---|---|
| D1 | Alternativa A con ejecución híbrida | Plan §2 |
| D2 | Vitest + jsdom + Testing Library + MSW | Plan §2, §8 |
| D3 | Imágenes de producto en backend, volumen externo | Plan §7 |
| D4 | `TiendaKatEye` como repositorio unificado y entorno único de evaluación | Plan §2, §4 |
| D5 | `react-router-dom` 7.18.5 | Plan §2 |
| D6 | Carrito hasta confirmación del backend | Plan §2 |
| D7 | Correo de contacto opcional | Plan §2 |
| D8 | Dominios del curso y contraseña 4–10 | Plan §2 |
| D9 | JWT en `localStorage` con mitigaciones | Plan §2, §10 |
| D10 | Rechazo con `KATEYE_PAGO_SIMULADO_RESULTADO` | Plan §2, §10 |
| D11 | Checkout real en esta iteración | Plan §2, §10 |
| D12 | Monorepo + espejos de progreso | Plan §2, §4 |
| D13 | Solo imágenes de producto al backend | Plan §2, §7 |
| D14 | CORS real en desarrollo | Plan §2, §7 |
| D15 | Secretos fuera del código | Plan §2, §5 |
| D16 | MSW y ESLint restrictivo | Plan §2, §8 |
| D17 | `Idempotency-Key` obligatoria | Plan §2, §8 |
| D18 | Commits del usuario por fase | Plan §2, §11 |
| D19 | Docker mínimo ahora; hardening posterior | Plan §2, §10 |
| D20 | Memoria `mm_devFaseX.md` al cerrar cada fase | Plan §2, §10 |

---

## 14. Regla de actualización

Al cerrar cada fase:

1. Actualizar el árbol de este documento si cambió la estructura.
2. Actualizar el documento de la fase con el registro de ejecución.
3. Crear `docs/memoria/mm_devFaseX.md` con archivos y acciones en orden.
4. Verificar que el gate correspondiente quedó documentado.
5. Ejecutar `scripts/sync-progreso.sh` y dejar los espejos listos para el commit del usuario.
6. No avanzar a la siguiente fase si el gate falla.
