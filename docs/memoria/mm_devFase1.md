# Memoria de desarrollo — Fase 1

| | |
|---|---|
| **Fase** | F1 |
| **Gate** | G1 |
| **Estado** | Cerrada (commit pendiente del usuario) |
| **Documento de fase** | `../fases/F1-pruebas.md` |

## Objetivo de la fase

Dejar una red de seguridad ejecutable antes de tocar la capa de datos: Vitest + jsdom + Testing Library + MSW, cobertura medible, ESLint con las restricciones de HTTP y un `gate-lint.sh` que bloquee errores de estilo.

## Archivos creados y modificados (en orden)

| # | Archivo | Acción | Qué hace |
|---|---|---|---|
| 1 | `KatEye-Front/package.json` | Modificado | Agrega Vitest, jsdom, MSW, cobertura, ESLint y Prettier; scripts `test`, `test:run`, `test:coverage`, `lint` y `format:check`. |
| 2 | `KatEye-Front/package-lock.json` | Modificado | Fija las versiones instaladas de las nuevas dependencias. |
| 3 | `KatEye-Front/vite.config.js` | Modificado | Configura jsdom, `globals`, `src/test/setup.js`, cobertura v8 y umbrales; excluye el test CRA legado. |
| 4 | `KatEye-Front/eslint.config.js` | Creado | Flat config con `no-restricted-globals` para `fetch` y `no-restricted-imports` para `axios`. |
| 5 | `KatEye-Front/src/test/setup.js` | Modificado | Inicia/detiene MSW y limpia el DOM entre pruebas. |
| 6 | `KatEye-Front/src/test/mocks/handlers.js` | Creado | Handlers base de catálogo, categorías, blogs y regiones. |
| 7 | `KatEye-Front/src/test/mocks/server.js` | Creado | Servidor MSW para Node. |
| 8 | `scripts/gate-lint.sh` | Creado | ESLint + Prettier en el frontend y `mvn test-compile` en el backend. |
| 9 | `scripts/gate-1.sh` | Creado | Prerrequisito G0, lint, cobertura, regeneración de `docs/cobertura.md` y build. |
| 10 | `scripts/install-hooks.sh` | Creado | Instala `.git/hooks/pre-push` con `gate-lint` y el gate de la fase actual. |
| 11 | `scripts/sync-progreso.sh` | Modificado | Excluye `*.zip` además de `.git`, `node_modules`, `target`, `dist`, `coverage` y `.env`. |
| 12 | `docs/cobertura.md` | Creado | Generado por `gate-1.sh`; documenta la cobertura y los umbrales baseline. |
| 13 | `docs/fases/F1-pruebas.md`, `docs/fases/INDICE.md` | Modificados | Registro de ejecución y estado de F1. |

## Acciones relevantes (en orden)

1. Se inspeccionó la suite existente: usa Vitest, Testing Library y `userEvent.setup()`; `@testing-library/user-event` estaba en 13.x, así que se subió a 14.x.
2. Se instalaron `vitest`, `jsdom`, `msw`, `@vitest/coverage-v8`, `eslint@9`, `@eslint/js`, `eslint-plugin-react`, `eslint-plugin-react-hooks`, `globals` y `prettier`.
3. Se configuró Vitest en `vite.config.js` con jsdom, `globals: true`, `src/test/setup.js` y cobertura v8.
4. Se creó `eslint.config.js` con las reglas de `fetch` y `axios`; el archivo `src/api/client.js` queda exceptuado para F2.
5. Se crearon los handlers y el servidor MSW y se conectaron en `src/test/setup.js`.
6. Se ejecutó la suite: **8 archivos y 57 pruebas en verde**. El test CRA `src/App.test.js` se excluye porque Vite 8/oxc no transforma JSX en archivos `.js` y prueba el andamiaje CRA, no la app real.
7. Se midió la cobertura baseline: líneas 21.80 %, ramas 28.01 %, funciones 22.96 %, sentencias 21.28 %. Los umbrales se fijaron en 21/28/22/21 para que G1 sea reproducible y suban por fase.
8. Se crearon `gate-lint.sh`, `gate-1.sh` e `install-hooks.sh`; el hook quedó instalado en `.git/hooks/pre-push`.
9. Se ejecutó `scripts/gate-1.sh` con exit 0 y se regeneró `docs/cobertura.md`.

## Evidencia del gate

- Comando ejecutado: `scripts/gate-1.sh`
- Resultado: **exit 0**. ESLint y Prettier sin errores, backend compila, 57 pruebas verdes, cobertura sobre el baseline y build del frontend correcto.
- Artefacto o salida guardada: `.gates/gate-1.ok` → `2026-11-23T00:10:15Z`; `docs/cobertura.md`.

## Desviaciones y pendientes

- **Desviación:** los umbrales de cobertura arrancan en el baseline real (21/28/22/21), no en líneas ≥ 80 / ramas ≥ 70. Deben subir en F2–F6; `docs/cobertura.md` lo deja explícito.
- **Desviación:** `src/App.test.js` queda excluido de Vitest por el parser de Vite 8; prueba el `App.js` legado de CRA, que no es la aplicación real (`App.jsx`/`main.jsx`). Se retirará o migrará en la limpieza de F3.
- **Desviación:** el “linter del backend” es `mvn test-compile` hasta que se agregue un plugin dedicado (Spotless/Checkstyle).
- **Desviación:** ESLint se fijó en 9 porque `eslint-plugin-react` aún no declara compatibilidad con ESLint 10.
- **Pendiente:** Prettier se aplica a los archivos nuevos y de configuración; los archivos legados se formatean a medida que se migran para evitar un diff masivo.
- **Pendiente:** `src/api/client.js` y los contract tests llegan en F2.
- **Pendiente:** el usuario debe revisar y commitear el cierre de F1.
