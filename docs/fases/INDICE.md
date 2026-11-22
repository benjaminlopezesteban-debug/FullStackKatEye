# Documentación por fase — TiendaKatEye

Este directorio contiene un documento por cada fase de ejecución. Cada archivo registra **contexto, decisiones, cambios a aplicar, consecuencias y la evidencia del gate**. Al cerrar una fase se completa la sección **Registro de ejecución** con lo que realmente se hizo.

| Fase | Documento | Gate | Estado |
|---|---|---|---|
| F0 | [F0-estructura.md](F0-estructura.md) | G0 | Planificada |
| F1 | [F1-pruebas.md](F1-pruebas.md) | G1 | Planificada |
| F2 | [F2-rebanada-vertical.md](F2-rebanada-vertical.md) | G2 | Planificada |
| F3 | [F3-catalogo.md](F3-catalogo.md) | G3 | Planificada |
| F4 | [F4-sesion.md](F4-sesion.md) | G4 | Planificada |
| F5 | [F5-checkout.md](F5-checkout.md) | G5 | Planificada |
| F6 | [F6-release.md](F6-release.md) | G6 | Planificada |

## Reglas

1. **Un archivo por fase.** No se mezclan fases en un mismo documento.
2. **No se avanza de gate si el anterior falla.**
3. **Los commits los realiza el usuario** al cerrar cada fase. El documento sugiere el mensaje, no ejecuta el commit.
4. **El registro de ejecución se completa con hechos**, no con intenciones: fecha, autor, comandos, resultado y desviaciones.
5. **La arquitectura se actualiza** en `docs/ARQUITECTURA.md` si cambia la estructura.

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
Decisiones locales de la fase y su relación con D1–D19 del plan.

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
- `../../informe-evaluacion-planificacion.md` — hallazgos H1–H15.
