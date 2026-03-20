# Vareia

Seguimiento operativo del VPS: inventario, hardening, cambios, incidencias, monitorización y arquitectura de despliegue.

## Estructura

- `docs/`: documentación general y runbook operativo.
- `docs/execution-checklist.md`: checklist ejecutable del despliegue por fases.
- `inventory/`: inventario técnico del VPS y servicios.
- `checklists/`: checklists de despliegue, hardening y mantenimiento.
- `changes/`: registro cronológico de cambios.
- `incidents/`: incidencias y postmortems.
- `monitoring/`: métricas, alertas y revisiones periódicas.

## Estado actual

- Proveedor: Cubepath (`España, Barcelona`).
- Plan: `gp.nano`.
- VPS: `Ubuntu 24 LTS` con `1 CPU`, `2 GB RAM`, `40 GB` disco.
- Coste: `~5 EUR/mes`.
- Red actual: `UFW` activo con `OpenSSH`; solo puerto `22` abierto.
- Limitación actual: acceso por consola web del proveedor (problema de acceso SSH desde equipo local por IPv6).

## Arquitectura objetivo (stacks)

- `reverse-proxy`
- `automation`
- `orchestrator`
- `apps`
- redes: `infra-net` (interna) y `proxy-net` (frontal)

## Decisiones clave

- Primer paso técnico: instalar `Docker` + `Docker Compose`.
- `n8n` irá dockerizado en este VPS, en privado, con alertas hacia Slack.
- `n8n` será el primer servicio real tras redes Docker.
- OpenClaw será un orquestador multiagente controlado desde Slack.
- OpenClaw: `orchestrator-openclaw`, privado, desacoplado de n8n (API/webhook), acceso por Tailscale.
- OpenClaw: DB dedicada `app_openclaw`/`usr_openclaw`, volumen `openclaw-data`, limites `0.25 CPU` + `256MB RAM`.
- `apps`: reservado para futuros servicios, con estructura por app `/opt/infra/apps/<app-slug>/`.
- `apps`: cada app con `README`, `compose.yml`, `.env`, `.env.example`, DB dedicada y red por defecto `infra-net`.
- `apps`: defaults por app `restart: unless-stopped`, `healthcheck`, `0.25 CPU`, `256MB RAM`.
- Seguridad operativa: `fail2ban` (`sshd`, `bantime=1h`, `maxretry=5`) y `unattended-upgrades` solo seguridad (`03:00-05:00`).
- Backups/restore en 3 fases (PostgreSQL, volumenes, configuracion), diarios, retencion 30 dias, horario escalonado `04:00/04:30/05:00`.
- Backups fases 2 y 3 en `.tar.gz` + checksum `sha256` en todas las fases.
- Slack operativo: canal `#vareia-alerts`, severidades `[WARNING]/[CRITICAL]`, `critical` en hilo hasta cierre.
- Slack operativo: resumen diario a las `09:00` (hora Espana), sin `@channel` por ahora.
- Cierre de SSH por contraseña pendiente hasta estabilizar acceso por Tailscale + clave.
- Se usará Tailscale como pieza prioritaria de red tras Docker.
- Exposición pública futura solo para `reverse-proxy` (80/443) cuando exista dominio.
- `reverse-proxy`: `reverse-proxy-nginx` con `nginx:1.28-alpine`, doble red (`proxy-net` + `infra-net`).
- Config de `reverse-proxy` con `nginx.conf` + `conf.d` por servicio y `default-deny.conf`.
- TLS/Let's Encrypt pospuesto hasta tener dominio y DNS operativos.
- Variables por stack en `/opt/infra/<stack>/.env` y `.env.example` sin secretos.
- Imágenes con versión fija para `n8n`, `nginx` y `postgres`.
- Naming con prefijo de stack y arranque con `docker compose --project-name <stack>`.
- Secretos y datos sensibles fuera de este repositorio público.
