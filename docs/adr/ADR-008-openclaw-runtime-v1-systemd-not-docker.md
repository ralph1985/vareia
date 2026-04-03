# ADR-008: Runtime OpenClaw v1 en systemd (no Docker)

- Fecha: 2026-04-02
- Estado: aceptada

## Contexto

Se validó funcionamiento real de OpenClaw + Slack + proveedor LLM ejecutando `openclaw gateway --allow-unconfigured` fuera de Docker. En Docker persistían bloqueos operativos de bootstrap/configuración.

## Decisión

Para v1, OpenClaw se ejecuta fuera de Docker como servicio `systemd` bajo usuario `monis`.

Docker se mantiene como fase 2 (posterior), cuando se cierre un diseño de permisos/volúmenes y hardening del contenedor.

## Consecuencias

- Menor fricción para estabilizar la integración Slack en producción temprana.
- Mejor capacidad operativa inicial para tareas sobre repos/host.
- Requiere endurecer ejecución local (service unit, variables seguras, mínimos permisos) antes de ampliar alcance.
