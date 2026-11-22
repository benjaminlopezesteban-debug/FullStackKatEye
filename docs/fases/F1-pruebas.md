# Fase F1 — Baseline de pruebas y reglas de lint

| | |
|---|---|
| **Fase** | F1 |
| **Gate** | G1 |
| **Estado** | Planificada |
| **Documento maestro** | `../../planificacion_desarrollo.md` |

## 1. Contexto

El frontend tiene pruebas escritas en `src/test/`, pero `package.json` no declara Vitest ni un script para ejecutarlas. Tampoco hay cobertura ni una regla que impida usar `fetch` o `axios` fuera de la capa API. Sin esa red de seguridad, refactorizar F2–F5 produce defectos silenciosos.

Esta fase instala **Vitest** como marco general, configura MSW y deja ESLint con las restricciones que el resto de fases necesitan.

## 2. Decisiones

- **D2:** Vitest + jsdom + Testing Library + MSW + cobertura para el frontend; JUnit 5 para el backend.
- **D16:** MSW intercepta a nivel de red; ESLint prohíbe `fetch` y `axios` fuera de `src/api/client.js`.
- **D18:** el usuario commitea al cerrar la fase.

## 3. Cambios a aplicar

1. Agregar dependencias de desarrollo:
   - `vitest`
   - `jsdom`
   - `@testing-library/react`
   - `@testing-library/jest-dom`
   - `@testing-library/user-event`
   - `msw`
   - `@vitest/coverage-v8`
2. Agregar scripts en `package.json`:
   - `test`
   - `test:run`
   - `test:coverage`
3. Configurar Vitest en `vite.config.js`:
   - entorno `jsdom`
   - `setupFiles: ["src/test/setup.js"]`
   - cobertura con salida en `coverage/`
4. Configurar ESLint:
   - `no-restricted-globals: ["error", "fetch"]`
   - `no-restricted-imports: ["error", { paths: ["axios"] }]`
   - excepción para `src/api/client.js`
5. Ejecutar la suite existente y documentar los fallos de baseline.
6. Crear `src/test/mocks/handlers.js` y `src/test/mocks/server.js` con los handlers base.

## 4. Consecuencias

- La suite queda ejecutable antes de tocar la capa de datos.
- La cobertura se vuelve medible y se puede guardar como evidencia.
- ESLint impide que una vista llame directamente a `fetch` o importe `axios`.
- Los tests existentes que dependen de módulos mock deberán migrarse en F3–F5; el baseline documenta cuáles fallan.

## 5. Gate G1 — Evidencia

```bash
cd KatEye-Front

npm run test:run
npm run test:coverage
npm run build
```

Resultado esperado:

- La suite ejecuta y el resultado queda registrado.
- `coverage/` se genera.
- `npm run build` funciona.
- ESLint no reporta imports de `axios` fuera de `src/api/client.js` (la capa aún no existe; la regla queda preparada).

## 6. Registro de ejecución

- **Fecha:**
- **Autor:**
- **Comandos ejecutados:**
- **Resultado:**
- **Desviaciones:**
- **Commit sugerido:** `test: agrega Vitest, MSW y baseline de pruebas`
- **Commit realizado:**

## 7. Pendientes para la siguiente fase

- Confirmar que `src/test/setup.js` carga jest-dom y limpia el DOM.
- Confirmar que los handlers de MSW cubren al menos `GET /productos`.
- Documentar los tests de baseline que fallan y por qué.
