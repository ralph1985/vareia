# AGENTS

Guía para agentes y sesiones futuras que trabajen en este repositorio.

## Objetivo

Mantener y evolucionar la infraestructura de VareIA de forma reproducible, segura y documentada.

## Reglas no negociables

- No subir secretos al repositorio.
- No publicar datos sensibles reales en docs públicas:
  - IPs públicas
  - usuario admin real
  - puerto SSH real
  - hostnames internos
  - URLs privadas con tokens
- Usar placeholders (`<SSH_PORT>`, `<usuario-admin>`, `<hostname-interno>`, etc.).
- No usar `latest` en imágenes Docker; fijar versión explícita.

## Flujo de trabajo esperado

- Trabajar por pasos pequeños y verificables.
- Tras cambios de infraestructura:
  - validar servicio `healthy`
  - validar endpoint de salud (`/healthz` o equivalente)
  - revisar logs relevantes
- Reflejar cada cambio operativo en:
  - `inventory/vps-inventory.md` (estado actual)
  - `changes/CHANGELOG.md` (histórico)
  - checklist/runbook si aplica

## Estructura de stacks

- `reverse-proxy`
- `automation`
- `orchestrator`
- `apps`

Redes base:

- `infra-net` (interna)
- `proxy-net` (frontal)

## Convenciones operativas

- Configuración por stack en `/opt/infra/<stack>/.env`.
- Plantillas versionadas en `configs/servers/*.example.env`.
- Arranque por stack con `docker compose --project-name <stack>`.
- `restart: unless-stopped` y `healthcheck` en servicios críticos.

## Seguridad base esperada

- SSH con clave pública, root login deshabilitado y password auth deshabilitado.
- UFW restrictivo (solo puertos necesarios).
- Fail2ban activo en `sshd`.
- Acceso administrativo web por red privada (Tailscale).

## Orden recomendado de lectura

1. `README.md`
2. `docs/architecture.md`
3. `docs/bootstrap-host.md`
4. `docs/execution-checklist.md`
5. `docs/runbook.md`
6. `inventory/vps-inventory.md`
7. `changes/CHANGELOG.md`

## Definition of done (infra/docs)

- Cambio aplicado y validado técnicamente.
- Documentación alineada (inventario + changelog + checklist/runbook si aplica).
- Sin secretos ni datos sensibles añadidos al repo.
