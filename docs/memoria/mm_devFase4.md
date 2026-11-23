# Memoria de desarrollo — Fase 4

| | |
|---|---|
| **Fase** | F4 |
| **Gate** | G4 |
| **Estado** | Cerrada (commit pendiente del usuario) |
| **Documento de fase** | `../fases/F4-sesion.md` |

## Objetivo de la fase

Reemplazar la sesión simulada del frontend por la API real: registro, login, logout y `/usuarios/me` con JWT; alinear las validaciones de correo/contraseña entre frontend y backend; hacer opcional el correo de contacto y enviar el formulario a `POST /contacto`. Cerrar DT-07.

## Archivos creados y modificados (en orden)

| # | Archivo | Acción | Qué hace |
|---|---|---|---|
| 1 | `KatEye-Back/.../usuario/dto/RegistroRequest.java` | Modificado | Dominios permitidos y contraseña de 4 a 10. |
| 2 | `KatEye-Back/.../auth/dto/LoginRequest.java` | Modificado | Dominios permitidos en el login. |
| 3 | `KatEye-Back/.../mensajecontacto/dto/MensajeContactoRequest.java` | Modificado | Correo opcional y dominio permitido si viene. |
| 4 | `KatEye-Back/.../mensajecontacto/service/MensajeContactoService.java` | Modificado | Guarda `""` cuando el correo opcional no viene. |
| 5 | `KatEye-Back/.../shared/validation/ValidacionRequestTest.java` | Creado | Casos válidos e inválidos de registro, login y contacto. |
| 6 | `KatEye-Front/src/api/endpoints/usuarios.js` | Creado | Login, registro, logout y perfil. |
| 7 | `KatEye-Front/src/api/endpoints/contacto.js` | Creado | `POST /contacto`. |
| 8 | `KatEye-Front/src/api/client.js` | Modificado | Ante 401 borra el token y emite `kateye:sesion-expirada`. |
| 9 | `KatEye-Front/src/context/SesionProvider.jsx` | Modificado | Token en `kateye_token`, hidratación con `/usuarios/me`, login/registro/logout reales. |
| 10 | `KatEye-Front/src/views/IniciarSesion.jsx` | Modificado | Login real con estado de envío y error de API. |
| 11 | `KatEye-Front/src/views/Registro.jsx` | Modificado | Registro real con `regionCodigo`/`comunaCodigo` y errores de API. |
| 12 | `KatEye-Front/src/views/Contacto.jsx` | Modificado | Envía a `POST /contacto`; correo opcional. |
| 13 | `KatEye-Front/src/views/Checkout.jsx` | Modificado | Usa `comunaNombre` del usuario para autocompletar. |
| 14 | `KatEye-Front/src/validaciones.js` | Modificado | Reglas de registro por `regionCodigo`/`comunaCodigo`. |
| 15 | `KatEye-Front/src/usuarios.js` | Eliminado | Ya no queda sesión simulada. |
| 16 | `KatEye-Front/src/test/SesionProvider.test.jsx` | Creado | Hidratación, login, registro, logout y 401. |
| 17 | `KatEye-Front/src/test/IniciarSesion.test.jsx` | Creado | Login UI, error de API y dominio inválido. |
| 18 | `KatEye-Front/src/test/Contacto.test.jsx` | Creado | Envío, correo opcional, error y dominio inválido. |
| 19 | `KatEye-Front/src/test/validaciones.test.js` | Creado | Dominios, contraseña 4–10 y contacto opcional. |
| 20 | `KatEye-Front/src/test/client.test.js` | Modificado | Verifica el evento `kateye:sesion-expirada`. |
| 21 | `KatEye-Front/vite.config.js`, `scripts/generar-cobertura.sh` | Modificados | Umbrales 73/60/66/72 y texto de cobertura. |
| 22 | `scripts/gate-4.sh` | Creado | Prerrequisito G3, deuda, lint, backend, cobertura y build. |
| 23 | `scripts/gate-lint.sh` | Modificado | Prettier incluye los tests de F4. |
| 24 | `docs/api-integracion.md` | Modificado | Matriz de auth/contacto y sección de sesión/JWT. |
| 25 | `docs/deuda-tecnica.md` | Modificado | DT-07 resuelta; DT-15 (correo opcional como `""`). |
| 26 | `docs/fases/F4-sesion.md`, `docs/fases/INDICE.md`, `docs/cobertura.md`, `docs/memoria/mm_devFase4.md` | Modificados/Creado | Registro, estado y evidencia de F4. |

## Acciones relevantes (en orden)

1. Se alinearon las validaciones del backend con los dominios del curso y contraseña 4–10; el contacto acepta correo omitido.
2. Se agregó `ValidacionRequestTest` y se ejecutaron los tests del backend en verde.
3. Se creó la capa de endpoints de usuarios/contacto y se reescribió `SesionProvider` con token, hidratación y logout reales.
4. Se migraron `IniciarSesion`, `Registro` y `Contacto` a la API; se eliminó `usuarios.js`. El login acepta además `@kateye.cl` para no bloquear la cuenta administradora sembrada en V3.
5. Se actualizaron los tests de sesión, login, contacto, validaciones y el interceptor 401. La suite queda en **20 archivos / 99 tests verdes**.
6. Se ejecutó `scripts/check-deuda.sh 4`: 0 deudas vencidas; DT-07 marcada como Resuelta.
7. Se ejecutó `scripts/gate-4.sh` con exit 0; se regeneró `docs/cobertura.md`.
8. Se sincronizaron los espejos con los cambios de F4.

## Evidencia del gate

- Comando ejecutado: `scripts/gate-4.sh`
- Resultado: **exit 0**. Backend en verde, 99 tests de frontend verdes, cobertura líneas 73.62 %, ramas 60.74 %, funciones 66.81 %, sentencias 72.11 %, build correcto.
- Artefacto o salida guardada: `.gates/gate-4.ok` → `2026-11-23T02:49:29Z`; `docs/cobertura.md`.
- Umbrales: 73/60/66/72, en `vite.config.js`.

## Desviaciones y pendientes

- **DT-15:** `mensaje_contacto.correo` sigue `NOT NULL`; el correo opcional se guarda como `""`. Queda para F6.
- **DT-14:** checkout y pagos siguen simulados; F5.
- **DT-13:** `listar` mantiene N+1 de oferta/imagen; F6.
- **DT-06/DT-05:** OpenAPI y Prettier global siguen pendientes; F6.
- **Seguridad:** JWT en `localStorage` con mitigaciones documentadas; cookie `httpOnly` queda fuera de esta iteración.
- **Espejos:** sincronizados con F4; el usuario debe revisar, commitear y pushear.
- **Pendiente:** revisar y commitear el cierre de F4.
