# ADR-006: Una sola aprobación sensible pendiente a la vez (v1)

- Fecha: 2026-04-02
- Estado: aceptada

## Contexto

OpenClaw v1 operará con acciones sensibles aprobadas por botones en Slack. Se debe decidir si se permiten varias solicitudes pendientes simultáneamente.

## Decisión

En v1 se permite una única acción sensible pendiente a la vez.

## Consecuencias

- Se reduce riesgo de aprobaciones cruzadas o equivocadas.
- Mejora trazabilidad al mantener un único flujo activo de cambio.
- Menor throughput en operaciones concurrentes, aceptable para fase inicial.
