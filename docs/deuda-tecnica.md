# Deuda técnica — TiendaKatEye

> Registro vivo. Cada desviación detectada en una fase se anota aquí con su **fase objetivo**. Al abrir y cerrar una fase se ejecuta `scripts/check-deuda.sh <fase>`; si hay deuda **Abierta** cuya fase objetivo ya venció, el gate de esa fase falla. Cerrar una deuda exige cambiarla a **Resuelta** y dejar la evidencia en la memoria de la fase.

| ID | Origen | Descripción | Impacto | Fase objetivo | Estado |
|---|---|---|---|---|---|
| DT-01 | F0 | Falta `Dockerfile` y `nginx.conf` del frontend; el compose declara `build: ./KatEye-Front`. | La imagen del frontend no se puede construir hasta F6. | F6 | Abierta |
| DT-02 | F1 | Cobertura por debajo de líneas 80 / ramas 70; los umbrales arrancan en el baseline real. | Módulos sin cubrir pueden romperse sin aviso. | F6 | Abierta |
| DT-03 | F1 | `src/App.test.js` (andamiaje CRA) queda excluido de Vitest. | Se pierde un test del `App.js` legado, que no es la app real. | F3 | Abierta |
| DT-04 | F1 | El “linter” del backend es `mvn test-compile`; no hay Spotless/Checkstyle. | El estilo del backend no se verifica automáticamente. | F6 | Abierta |
| DT-05 | F1 | Prettier solo revisa archivos nuevos y de configuración. | El formato de los archivos legados no se verifica. | F6 | Abierta |
| DT-06 | F2 | No se generó `docs/openapi.yaml`; la matriz de contract tests es la referencia. | No hay validación automática del spec OpenAPI. | F6 | Abierta |
| DT-07 | F2 | `SesionProvider`, `usuarios.js`, checkout y pagos siguen simulados en el frontend. | La sesión y el checkout reales llegan en F4/F5. | F5 | Abierta |
| DT-08 | F2 | El carrito guarda un snapshot del producto para sobrevivir a la carga asíncrona del catálogo. | Duplicación temporal de datos hasta que F5 revise el carrito. | F5 | Abierta |
| DT-09 | F2 | El Header usa categorías legadas y el filtro por URL se resuelve por nombre o id. | La navegación por categoría del backend se completa en F3. | F3 | Abierta |
| DT-10 | F2 | Solo 4 productos tienen imagen real; 11 se cubren con `onError`. | El catálogo muestra placeholders hasta contar con assets reales. | F6 | Abierta |
| DT-11 | F2 | `Inicio` no tiene test propio; la cobertura del catálogo se concentra en `Productos` y detalle. | Menor cobertura de la vista de inicio. | F3 | Abierta |
| DT-12 | F2 | Los espejos `mi-proyecto` y `KatEyeBackEnd` conservan cambios de F1 sin commitear; `sync-progreso.sh` no puede sincronizar F2 hasta que el usuario los commitee. | Riesgo de deriva entre monorepo y espejos. | F3 | Abierta |
| DT-13 | F2 | `ProductoService.listar` resuelve oferta e imagen por producto (N+1). | Latencia creciente si el catálogo aumenta. | F6 | Abierta |
