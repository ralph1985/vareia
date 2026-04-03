# ADR-002: Interacción Slack v1 para OpenClaw

- Fecha: 2026-04-02
- Estado: aceptada

## Contexto

OpenClaw se va a usar como orquestador conversacional y debe minimizar riesgo en producción desde su primera versión.

## Decisión

- Canal de interacción inicial: DM en Slack.
- Idioma de respuesta: español siempre.
- Estrategia de app Slack: app separada de `VareIA Alerts`.
- Modo de operación: ejecución permitida con confirmación obligatoria para acciones sensibles.
- Mecanismo de confirmación: botones interactivos en Slack (aprobar/rechazar).

## Consecuencias

- Menor superficie de exposición inicial al evitar respuestas automáticas en canales.
- Mayor seguridad operativa al requerir aprobación explícita en operaciones de riesgo.
- Necesidad de configurar interactividad en Slack App y flujo de estado para aprobaciones.
