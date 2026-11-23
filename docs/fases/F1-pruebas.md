# Fase F1 — Baseline de pruebas y reglas de lint

| | |
|---|---|
| **Fase** | F1 |
| **Gate** | G1 |
| **Estado** | Cerrada (commit pendiente) |
| **Documento maestro** | `../../planificacion_desarrollo.md` |

## 1. Contexto

El frontend tiene pruebas escritas en `src/test/`, pero `package.json` no declara Vitest ni un script para ejecutarlas. Tampoco hay cobertura ni una regla que impida usar `fetch` o `axios` fuera de la capa API. Sin esa red de seguridad, refactorizar F2–F5 produce defectos silenciosos.

Esta fase instala **Vitest** como marco general, configura MSW y deja ESLint con las restricciones que el resto de fases necesitan.

## 2. Decisiones

- **D2:** Vitest + jsdom + Testing Library + MSW + cobertura para el frontend; JUnit 5 para el backend.
- **D16:** MSW intercepta a nivel de red; ESLint prohíbe `fetch` y `axios` fuera de `src/api/client.js`.
- **D18:** el usuario commitea al cerrar la fase; B2, B4 y B8 pueden ir en commits separados.
- **D20:** al finalizar la fase se crea `docs/memoria/mm_devFase1.md`.
- **D22:** cobertura y lint son bloqueantes; los contract tests se incorporan desde F2.
- **D23:** `Makefile` y `pre-push` forman parte de la ergonomía de gates.

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
   - umbrales: líneas ≥ 80, branches ≥ 70; si el baseline real es menor, documentar el valor ajustado y subirlo por fase.
4. Configurar ESLint:
   - `no-restricted-globals: ["error", "fetch"]`
   - `no-restricted-imports: ["error", { paths: ["axios"] }]`
   - excepción para `src/api/client.js`
5. Crear `scripts/gate-lint.sh`:
   - ESLint + `prettier --check` en `KatEye-Front`;
   - linter del backend según stack (`spotless`/`checkstyle` o equivalente);
   - exit != 0 ante errores.
6. Crear `scripts/gate-1.sh`:
   - `set -euo pipefail` y `cd "$(git rev-parse --show-toplevel)"`;
   - verificar el prerrequisito de G0; si falta, imprimir “Ejecuta primero scripts/gate-0.sh” y salir con código 2;
   - invocar `scripts/gate-lint.sh` al inicio;
   - ejecutar `npm run test:coverage` con los umbrales y regenerar `docs/cobertura.md`.
7. Regenerar `docs/cobertura.md` desde `gate-1.sh`; el archivo debe empezar con “> Generado automáticamente por scripts/gate-1.sh. No editar a mano.”.
8. Crear `scripts/install-hooks.sh` e instalar `.git/hooks/pre-push` con `gate-lint.sh` y el gate de la fase actual (rama `fase-N` o variable `KATEYE_FASE`).
9. Ejecutar la suite existente y documentar los fallos de baseline.
10. Crear `src/test/mocks/handlers.js` y `src/test/mocks/server.js` con los handlers base.
11. Crear `docs/memoria/mm_devFase1.md` con los archivos creados y las acciones relevantes, en orden.
12. Ejecutar `scripts/sync-progreso.sh` y dejar `ProyectoWebKatEyes` listo para el commit del usuario.

## 4. Consecuencias

- La suite queda ejecutable antes de tocar la capa de datos.
- La cobertura se vuelve medible y se puede guardar como evidencia.
- ESLint impide que una vista llame directamente a `fetch` o importe `axios`.
- Los tests existentes que dependen de módulos mock deberán migrarse en F3–F5; el baseline documenta cuáles fallan.

## 5. Gate G1 — Evidencia

```bash
cd TiendaKatEye

scripts/gate-1.sh
scripts/gate-lint.sh
test -f scripts/install-hooks.sh
make -n gate-1
head -1 docs/cobertura.md

cd KatEye-Front
npm run test:run
npm run test:coverage
npm run build
```

Resultado esperado:

- La suite ejecuta y el resultado queda registrado.
- `npm run test:coverage` aplica los umbrales y falla si no se cumplen.
- `coverage/` y `docs/cobertura.md` se generan; el documento lleva el encabezado automático.
- `npm run build` funciona.
- `scripts/gate-lint.sh` termina con exit 0.
- `scripts/gate-1.sh` verifica G0, ejecuta lint y cobertura, y falla si no se cumplen los umbrales.
- `scripts/install-hooks.sh` existe y el `pre-push` queda documentado.
- `make -n gate-1` no falla.
- ESLint no reporta imports de `axios` fuera de `src/api/client.js` (la capa aún no existe; la regla queda preparada).
- `docs/memoria/mm_devFase1.md` existe y describe los archivos y acciones.

## 6. Registro de ejecución

- **Fecha:** 2026-11-22
- **Autor:** Benjamín López
- **Comandos ejecutados:** instalación de dependencias con `npm install -D`; `scripts/install-hooks.sh`; `scripts/gate-1.sh`.
- **Resultado:** G1 en verde (`exit 0`). ESLint y Prettier sin errores, backend compila, 57 pruebas en 8 archivos, cobertura baseline (líneas 21.80 %, ramas 28.01 %, funciones 22.96 %, sentencias 21.28 %) y build del frontend correcto. Evidencia en `.gates/gate-1.ok`.
- **Desviaciones:** umbrales ajustados al baseline (21/28/22/21) y no a 80/70; `src/App.test.js` se excluye por JSX en `.js` con Vite 8; el linter del backend es `mvn test-compile` hasta agregar Spotless/Checkstyle.
- **Memoria:** `docs/memoria/mm_devFase1.md`
- **Commit sugerido:** `test: agrega Vitest, MSW y baseline de pruebas`
- **Commit realizado:** pendiente (lo realiza el usuario)

## 7. Pendientes para la siguiente fase

- Confirmar que `src/test/setup.js` carga jest-dom y limpia el DOM.
- Confirmar que los handlers de MSW cubren al menos `GET /productos`.
- Documentar los tests de baseline que fallan y por qué.
- Confirmar que `docs/cobertura.md` se regenera desde `gate-1.sh` y no se edita a mano.
- Confirmar que el umbral de cobertura es alcanzable con el baseline real; si se ajusta, dejar el valor y la justificación en la memoria.
- Confirmar que `gate-lint.sh` y el hook `pre-push` usan los mismos comandos.
- Confirmar que `ProyectoWebKatEyes` recibió los cambios de la fase sin perder su historial.
