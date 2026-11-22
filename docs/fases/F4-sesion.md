# Fase F4 — Sesión, registro y contacto

| | |
|---|---|
| **Fase** | F4 |
| **Gate** | G4 |
| **Estado** | Planificada |
| **Documento maestro** | `../../planificacion_desarrollo.md` |

## 1. Contexto

El frontend simula usuarios en `usuarios.js` y el backend ya expone JWT, registro, login, logout y `/usuarios/me`. Las validaciones divergen: el curso exige dominios `@duoc.cl`, `@profesor.duoc.cl` y `@gmail.com`, contraseña de 4 a 10 caracteres y correo de contacto opcional; el backend acepta cualquier correo y contraseñas de 4 a 72.

Esta fase conecta la sesión real, alinea las validaciones en ambos lados y hace que el contacto llegue a la base.

## 2. Decisiones

- **D7:** correo de contacto opcional.
- **D8:** dominios del curso y contraseña 4–10.
- **D9:** token en `localStorage` con mitigaciones (CSP, sin `dangerouslySetInnerHTML`, interceptor 401, expiración documentada).
- **D18:** el usuario commitea al cerrar la fase.

## 3. Cambios a aplicar

### Backend

1. Alinear `RegistroRequest` y `LoginRequest` con los dominios permitidos.
2. Cambiar la contraseña a `@Size(min = 4, max = 10)`.
3. Hacer opcional el correo de `MensajeContactoRequest` (mantener `@Email` y `@Size` si viene).
4. Agregar tests de validación para los casos válidos e inválidos.

### Frontend

1. Reescribir `SesionProvider`:
   - `kateye_token` en `localStorage`;
   - `GET /usuarios/me` al hidratar;
   - login, registro y logout reales;
   - limpieza de token y estado ante 401.
2. Migrar `IniciarSesion` y `Registro` a los endpoints reales.
3. Cambiar el select de comuna a `comunaCodigo` y `regionCodigo`.
4. Migrar `Contacto` a `POST /contacto`; el correo es opcional.
5. Borrar `usuarios.js` cuando ninguna vista lo importe.
6. Documentar la expiración del JWT y la mitigación de XSS.
7. Crear tests de sesión, validación, interceptor 401 y contacto.

## 4. Consecuencias

- La sesión deja de ser simulada y sobrevive a recargas con el token.
- El backend y el frontend comparten las mismas reglas de validación.
- El contacto queda registrado en la base.
- El usuario debe volver a iniciar sesión si el token expira o el backend responde 401.
- La cookie `httpOnly` queda fuera de alcance; se documenta como siguiente paso.

## 5. Gate G4 — Evidencia

```bash
cd KatEye-Back
mvn test

cd ../KatEye-Front
npm run test:run -- sesion validaciones contacto
npm run build
```

Resultado esperado:

- Tests de backend y frontend en verde.
- Registro, login, logout y sesión persistente funcionan contra la API.
- El contacto queda registrado en la base.
- El interceptor 401 limpia la sesión.

## 6. Registro de ejecución

- **Fecha:**
- **Autor:**
- **Comandos ejecutados:**
- **Resultado:**
- **Desviaciones:**
- **Commit sugerido:** `feat: integra sesión JWT, registro y contacto`
- **Commit realizado:**

## 7. Pendientes para la siguiente fase

- Confirmar que `usuarios.js` ya no se importa.
- Confirmar que las reglas de validación coinciden en frontend y backend.
- Verificar que el checkout puede leer `/usuarios/me` para autocompletar.
