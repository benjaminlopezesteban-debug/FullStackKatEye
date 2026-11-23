# Documentación por fase — TiendaKatEye

Este directorio contiene un documento por cada fase de ejecución. Cada archivo registra **contexto, decisiones, cambios a aplicar, consecuencias y la evidencia del gate**. Al cerrar una fase se completa la sección **Registro de ejecución** con lo que realmente se hizo.

Cada fase produce además `docs/memoria/mm_devFaseX.md`, la memoria del desarrollo: archivos creados o modificados y acciones relevantes, en orden, con una descripción breve. La plantilla está en [`../memoria/PLANTILLA.md`](../memoria/PLANTILLA.md).

| Fase | Documento | Memoria | Gate | Estado |
|---|---|---|---|---|
| F0 | [F0-estructura.md](F0-estructura.md) | `../memoria/mm_devFase0.md` | G0 | Cerrada (commit pendiente) |
| F1 | [F1-pruebas.md](F1-pruebas.md) | `../memoria/mm_devFase1.md` | G1 | Cerrada (commit pendiente) |
| F2 | [F2-rebanada-vertical.md](F2-rebanada-vertical.md) | `../memoria/mm_devFase2.md` | G2 | Cerrada (commit pendiente) |
| F3 | [F3-catalogo.md](F3-catalogo.md) | `../memoria/mm_devFase3.md` | G3 | Cerrada (commit pendiente) |
| F4 | [F4-sesion.md](F4-sesion.md) | `../memoria/mm_devFase4.md` | G4 | Planificada |
| F5 | [F5-checkout.md](F5-checkout.md) | `../memoria/mm_devFase5.md` | G5 | Planificada |
| F6 | [F6-release.md](F6-release.md) | `../memoria/mm_devFase6.md` | G6 | Planificada |

## Scripts transversales y correcciones

- **`scripts/gate-lint.sh`** es transversal: no pertenece a una fase nueva. Se ejecuta al inicio de `gate-1.sh` y en el hook `pre-push`; ESLint + Prettier en `KatEye-Front` y el linter del backend deben terminar con exit 0.
- **`Makefile`** expone `gate-0`…`gate-6`, `gate-lint`, `gate-all`, `sync`, `up`, `down` y `test`.
- **`scripts/install-hooks.sh`** instala `.git/hooks/pre-push` con `gate-lint` y el gate de la fase actual.
- Las correcciones de auditoría **B1–B8** se distribuyen en F0, F1, F2, F3, F5 y F6; no crean fases ni gates nuevos. El detalle está en `../../planificacion_desarrollo.md`.

## Reglas

1. **Un archivo por fase.** No se mezclan fases en un mismo documento.
2. **No se avanza de gate si el anterior falla.**
3. **Los commits los realiza el usuario** al cerrar cada fase. El documento sugiere el mensaje, no ejecuta el commit.
4. **El registro de ejecución se completa con hechos**, no con intenciones: fecha, autor, comandos, resultado y desviaciones.
5. **Cada fase deja su memoria** en `docs/memoria/mm_devFaseX.md`, con archivos y acciones en orden.
6. **La arquitectura se actualiza** en `docs/ARQUITECTURA.md` si cambia la estructura.
7. **Los espejos de progreso se sincronizan** con `scripts/sync-progreso.sh` al cerrar la fase; el usuario commitea y pushea en cada repositorio independiente.
8. **La deuda técnica se revisa al abrir y cerrar cada fase**: `scripts/check-deuda.sh <fase>` falla si una deuda abierta ya venció. Las desviaciones se registran en [`../deuda-tecnica.md`](../deuda-tecnica.md) con impacto y fase objetivo.

## Plantilla

```markdown
# Fase Fx — Nombre

| | |
|---|---|
| **Fase** | Fx |
| **Gate** | Gx |
| **Estado** | Planificada / En ejecución / Cerrada |
| **Documento maestro** | `../../planificacion_desarrollo.md` |

## 1. Contexto
Qué problema resuelve esta fase y por qué va en este orden.

## 2. Decisiones
Decisiones locales de la fase y su relación con D1–D20 del plan.

## 3. Cambios a aplicar
Lista de archivos, módulos, endpoints o configuraciones que se tocan.

## 4. Consecuencias
Qué queda habilitado, qué deuda se paga y qué riesgo se asume.

## 5. Gate Gx — Evidencia
Comandos, resultados esperados y artefactos que se guardan.

## 6. Registro de ejecución
- Fecha:
- Autor:
- Comandos ejecutados:
- Resultado:
- Desviaciones:
- Commit sugerido / realizado:

## 7. Pendientes para la siguiente fase
```

## Referencias

- `../../planificacion_desarrollo.md` — plan maestro.
- `../ARQUITECTURA.md` — arquitectura objetivo y árboles ASCII.
- `../memoria/PLANTILLA.md` — plantilla de la memoria de desarrollo.
- `../../informe-evaluacion-planificacion.md` — hallazgos H1–H15.
