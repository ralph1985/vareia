# ADR-007: Aprobador único de acciones sensibles en v1

- Fecha: 2026-04-02
- Estado: aceptada

## Contexto

OpenClaw v1 ejecuta acciones sensibles bajo confirmación por botones en Slack. Se debe fijar quién tiene permiso de aprobar.

## Decisión

En v1, solo el owner del workspace (usuario principal de operación) puede aprobar acciones sensibles.

## Consecuencias

- Máximo control en fase inicial.
- Menor riesgo de aprobaciones incorrectas por terceros.
- Si el owner no está disponible, no se ejecutan cambios sensibles hasta su aprobación.
