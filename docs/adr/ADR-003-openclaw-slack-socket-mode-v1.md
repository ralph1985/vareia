# ADR-003: Transporte Slack en v1 con Socket Mode

- Fecha: 2026-04-02
- Estado: aceptada

## Contexto

El VPS de VareIA opera en modo privado (sin exposición pública 80/443) y OpenClaw v1 se integrará con Slack para DM e interactividad.

## Decisión

Usar `Socket Mode` en la Slack App `VareIA Bot` para v1.

## Motivos

- Evita publicar callbacks HTTP de Slack en Internet.
- Encaja con la postura de seguridad actual del VPS.
- Reduce complejidad inicial de proxy y validación de firma en endpoint público.

## Consecuencias

- El servicio `orchestrator-openclaw` debe mantener conexión activa con Slack.
- Se requiere token adicional de nivel app (`xapp-...`) además del token bot (`xoxb-...`).
- Si el proceso se cae, se interrumpe recepción de eventos hasta reconexión.
