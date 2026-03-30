# VareIA

VareIA es el repositorio de infraestructura y operación de un VPS para servicios autoalojados orientados a automatización y orquestación con IA.

El objetivo es disponer de una base reproducible, segura y mantenible para desplegar servicios en contenedores con separación por stacks, documentación operativa y automatización progresiva.

## Alcance

- Bootstrap de host base (seguridad, paquetes y base operativa).
- Despliegue por stacks Docker.
- Documentación de arquitectura, operación y troubleshooting.
- Registro de cambios, incidencias y monitorización.

## Arquitectura base

- Stacks: `reverse-proxy`, `automation`, `orchestrator`, `apps`.
- Redes: `infra-net` (interna) y `proxy-net` (frontal).
- Principio de despliegue: servicios desacoplados por stack con configuración en `.env`.
- Persistencia y datos: volúmenes Docker y backups por fases.
- Acceso privado administrativo: red privada (Tailscale).

Diagrama: `docs/architecture.md`.

## Estructura del repositorio

- `docs/`: documentación general, arquitectura y runbook.
- `inventory/`: inventario técnico del VPS y servicios.
- `checklists/`: checklists de despliegue, hardening y mantenimiento.
- `changes/`: changelog cronológico de infraestructura.
- `incidents/`: incidencias y postmortems.
- `monitoring/`: métricas y revisiones periódicas.
- `scripts/`: automatizaciones operativas.
- `scripts/host/`: scripts de host versionados (backup, heartbeat) para desplegar en `/opt/infra/scripts/`.
- `configs/servers/`: variables por servidor (`*.example.env` versionados).

## Cómo navegar esta documentación

1. `docs/architecture.md` para entender el diseño general.
2. `docs/bootstrap-host.md` para preparar un host base reproducible.
3. `docs/execution-checklist.md` para ejecutar despliegue por fases.
4. `docs/runbook.md` para operación diaria y troubleshooting.
5. `inventory/vps-inventory.md` para estado técnico consolidado.
6. `changes/CHANGELOG.md` para historial de cambios.

## Nota de seguridad del repositorio público

Este repositorio evita publicar secretos y anonimiza detalles operativos sensibles (usuarios, puertos reales, hostnames, horarios exactos y endpoints internos). Los valores reales se mantienen fuera del repositorio.
