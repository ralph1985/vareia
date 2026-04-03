# ADR-001: Modelo de documentación para OpenClaw

- Fecha: 2026-04-02
- Estado: aceptada

## Contexto

VareIA ya tiene documentación operativa repartida entre `docs`, `checklists`, `inventory` y `changes`. Al iniciar OpenClaw, necesitamos registrar decisiones sin perder trazabilidad ni duplicar contenido.

## Decisión

Adoptar un modelo híbrido:

- `docs/orchestrator-openclaw.md` como estado operativo consolidado.
- `docs/adr/` para decisiones arquitectónicas clave.
- `checklists/openclaw-rollout.md` para ejecución por fases.
- `changes/CHANGELOG.md` para registro cronológico de cambios implementados.

## Consecuencias

- Mejor trazabilidad entre "por qué" (ADR), "qué hay" (doc operativo), "qué falta" (checklist) y "qué se hizo" (changelog).
- Menor riesgo de mezclar decisiones futuras con estado ya desplegado.
