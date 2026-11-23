# Deuda técnica — TiendaKatEye

> Registro vivo. Cada desviación detectada en una fase se anota aquí con su **fase objetivo**. Al abrir y cerrar una fase se ejecuta `scripts/check-deuda.sh <fase>`; si hay deuda **Abierta** cuya fase objetivo ya venció, el gate de esa fase falla. Cerrar una deuda exige cambiarla a **Resuelta** y dejar la evidencia en la memoria de la fase.

| ID | Origen | Descripción | Impacto | Fase objetivo | Estado |
|---|---|---|---|---|---|
| DT-01 | F0 | Falta `Dockerfile` y `nginx.conf` del frontend; el compose declara `build: ./KatEye-Front`. | La imagen del frontend no se puede construir hasta F6. | F6 | Abierta |
| DT-02 | F1 | Cobertura por debajo de líneas 80 / ramas 70; los umbrales arrancan en el baseline real. | Módulos sin cubrir pueden romperse sin aviso. | F6 | Abierta |
| DT-03 | F1 | `src/App.test.js` (andamiaje CRA) quedaba excluido de Vitest; se retiró junto con el andamiaje CRA. | Se pierde un test del `App.js` legado, que no es la app real. | F3 | Resuelta |
| DT-04 | F1 | El “linter” del backend es `mvn test-compile`; no hay Spotless/Checkstyle. | El estilo del backend no se verifica automáticamente. | F6 | Abierta |
| DT-05 | F1 | Prettier solo revisa archivos nuevos y de configuración. | El formato de los archivos legados no se verifica. | F6 | Abierta |
| DT-06 | F2 | No se generó `docs/openapi.yaml`; la matriz de contract tests es la referencia. | No hay validación automática del spec OpenAPI. | F6 | Abierta |
| DT-07 | F2 | `SesionProvider` y `usuarios.js` estaban simulados. | Se reemplazaron por `/auth/*` y `/usuarios/me` en F4. | F4 | Resuelta |
| DT-08 | F2 | El carrito guarda un snapshot del producto para sobrevivir a la carga asíncrona del catálogo. | Duplicación temporal de datos hasta que F5 revise el carrito. | F5 | Abierta |
| DT-09 | F2 | El Header usaba categorías legadas; ahora consume `GET /categorias` y enlaza por slug. | La navegación por categoría del backend se completa en F3. | F3 | Resuelta |
| DT-10 | F2 | Solo 4 productos tienen imagen real; 11 se cubren con `onError`. | El catálogo muestra placeholders hasta contar con assets reales. | F6 | Abierta |
| DT-11 | F2 | `Inicio` no tenía test propio; se agregó `Inicio.test.jsx` con MSW. | Menor cobertura de la vista de inicio. | F3 | Resuelta |
| DT-12 | F2 | Los espejos `mi-proyecto` y `KatEyeBackEnd` conservaban cambios de F1 sin commitear. | Riesgo de deriva entre monorepo y espejos. | F3 | Resuelta |
| DT-13 | F2 | `ProductoService.listar` resuelve oferta e imagen por producto (N+1). | Latencia creciente si el catálogo aumenta. | F6 | Abierta |
| DT-14 | F3 | El checkout y los pagos del frontend siguen simulados. | El flujo real de compra llega en F5. | F5 | Abierta |
| DT-15 | F4 | `mensaje_contacto.correo` sigue `NOT NULL`; el correo opcional se guarda como cadena vacía. | Reportes y consultas deben tratar `''` como “sin correo”. | F6 | Abierta |
