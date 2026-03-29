# Checklist de Ejecucion

Objetivo: ejecutar el despliegue en el orden confirmado, marcando estado real en cada paso.

## Orden confirmado

1. [x] Docker Engine + Docker Compose (oficial)
2. [x] Tailscale
3. [x] Redes Docker (`infra-net`, `proxy-net`)
4. [x] PostgreSQL compartido (`postgres-shared`, `postgres:17`)
5. [x] n8n (`automation`, con PostgreSQL)
6. [x] Reverse proxy (`reverse-proxy-nginx`)
7. [ ] Orchestrator (`orchestrator-openclaw`)
8. [x] Apps (estructura base + primer servicio web)
9. [ ] Monitorizacion y alertas (n8n -> Slack)

## Paso 1 - Docker

- [x] Instalar Docker Engine desde repo oficial.
- [x] Instalar plugin `docker compose`.
- [x] Añadir usuario operativo al grupo `docker`.
- [x] Verificar `docker --version` y `docker compose version`.

## Paso 2 - Tailscale

- [x] Instalar Tailscale.
- [x] Conectar nodo al tailnet.
- [x] Verificar acceso privado al VPS.
- [x] Mantener `PasswordAuthentication` temporalmente (cerrado: ya fijado en `no` tras validación de acceso por clave).

## Paso 3 - Redes Docker

- [x] Crear red `infra-net`.
- [x] Crear red `proxy-net`.
- [x] Verificar existencia de ambas redes.

## Paso 4 - PostgreSQL

- [x] Crear stack `/opt/infra/postgres`.
- [x] Definir `compose.yml` con imagen fija `postgres:17`.
- [x] Definir servicio `postgres-shared` solo en `infra-net`.
- [x] Mantener puerto interno `5432` sin publicar al host.
- [x] Usar `POSTGRES_DB=postgres` solo para bootstrap.
- [x] Definir `.env` y `.env.example` (sin secretos).
- [x] Crear volumen persistente `postgres-data`.
- [x] Mantener configuracion inicial por defecto.
- [x] Definir limites iniciales (`0.5 CPU`, `512MB RAM`).
- [x] Levantar stack con `docker compose --project-name postgres up -d`.
- [x] Crear credenciales de apps (`app_<project_slug>` / `usr_<project_slug>`).
- [ ] Dejar logs de consultas lentas como tarea futura (no ahora).
- [x] Implementar backup por script de host (`/opt/infra/scripts/vareia-backup.sh`) + automatización diaria.
- [x] Ejecutar backup diario con `systemd timer` (`vareia-backup.timer`, `03:30 UTC`).
- [x] Guardar backups locales en `/opt/backups` (home-manager, n8n, n8n-data, logs).
- [x] Ejecutar rotación local (>30 dias) dentro del propio script.
- [x] Verificar generación real de ficheros de backup (`.sql.gz` / `.tar.gz`).

## Paso 5 - n8n

- [x] Crear stack `/opt/infra/automation`.
- [x] Definir `compose.yml` con versión fija de n8n.
- [x] Definir nombre de contenedor: `automation-n8n`.
- [x] Definir volumen persistente `n8n-data`.
- [x] Conectar solo a `infra-net`.
- [x] Mantener puerto interno `5678` sin publicar.
- [x] Configurar DB `app_n8n` + usuario `usr_n8n`.
- [x] Definir `.env` y `.env.example` (sin secretos).
- [x] Arrancar con `docker compose --project-name automation up -d`.
- [x] Verificar arranque con `postgres-shared` saludable.
- [x] Validar healthcheck y reinicio `unless-stopped`.
- [x] Definir limites iniciales (`0.5 CPU`, `512MB RAM`).
- [x] Definir `EXECUTIONS_MODE=regular`.
- [x] Activar limpieza de ejecuciones con retencion inicial de 14 dias.

## Paso 6 - Reverse Proxy (Nginx)

- [x] Crear stack `/opt/infra/reverse-proxy`.
- [x] Definir `compose.yml` con imagen fija `nginx:1.28-alpine`.
- [x] Definir nombre de contenedor: `reverse-proxy-nginx`.
- [x] Conectar a `proxy-net` y `infra-net`.
- [x] Definir `/opt/infra/reverse-proxy/nginx.conf`.
- [x] Definir `conf.d/*.conf` con un archivo por servicio.
- [x] Incluir `default-deny.conf`.
- [x] Incluir vhost privado por rutas (`/n8n/`, `/pm/`) y raíz de estado (`/`).
- [x] Definir logs en `/opt/infra/reverse-proxy/logs`.
- [x] Publicar Nginx solo en loopback del host (`127.0.0.1:8080`) para integración privada.
- [x] Exponer acceso HTTPS privado vía `tailscale serve` al FQDN `*.ts.net` del nodo.
- [ ] Configurar rotacion de logs Nginx: diaria, 14 dias, compresion `.gz`, limite 50MB.
- [x] Mantener puertos `80/443` cerrados hasta dominio y DNS operativos.
- [x] Posponer TLS/Let's Encrypt hasta dominio y DNS operativos.

## Paso 7 - Orchestrator (OpenClaw)

- [ ] Crear stack `/opt/infra/orchestrator`.
- [ ] Definir contenedor `orchestrator-openclaw`.
- [ ] Conectar solo a `infra-net` (sin puertos publicados).
- [ ] Definir volumen persistente `openclaw-data`.
- [ ] Reservar DB `app_openclaw` y usuario `usr_openclaw`.
- [ ] Definir limites iniciales (`0.25 CPU`, `256MB RAM`).
- [ ] Definir `restart: unless-stopped` y `healthcheck`.
- [ ] Mantener acceso administrativo solo por Tailscale.
- [ ] Definir interfaz minima con `n8n` via API/webhook (`POST /jobs`).
- [ ] Mantener desacoplamiento entre OpenClaw y n8n.

## Paso 8 - Apps (futuras)

- [x] Desplegar primer servicio web de apps: `project-manager` en `/pm/` (privado por Tailscale).
- [x] Mantener servicios de `apps` documentados y publicados solo por reverse-proxy.
- [x] Configurar auto-despliegue de `project-manager` tras `git pull` en el VPS.
- [x] Activar `core.hooksPath=.githooks` en `/home/monis/apps/project-manager`.
- [x] Definir hooks `post-merge` y `post-rewrite` para ejecutar `scripts/deploy-from-pull.sh`.
- [x] Validar rebuild/restart automático del contenedor tras pull con cambios.
- [ ] Crear estructura por app en `/opt/infra/apps/<app-slug>/`.
- [ ] Exigir plantilla minima por app: `README`, `compose.yml`, `.env`, `.env.example`.
- [ ] Conectar apps por defecto solo a `infra-net`.
- [ ] Conectar a `proxy-net` solo con necesidad explicita.
- [ ] Asignar DB dedicada por app (`app_<slug>` / `usr_<slug>`).
- [ ] Definir defaults por app: `restart: unless-stopped`, `healthcheck`.
- [ ] Definir limites iniciales por app: `0.25 CPU`, `256MB RAM`.

## Paso 9 - Monitorizacion y alertas

- [x] Implementar heartbeat diario (host -> webhook n8n -> Slack).
- [x] Proteger webhook de heartbeat con token por header (`X-Heartbeat-Token`).
- [x] Programar heartbeat diario por cron en host.
- [ ] Validar en fecha posterior la ejecucion real del cron de heartbeat (entrada en `/var/log/heartbeat.log` y mensaje recibido en Slack).
- [ ] Configurar checks tecnicos cada 15 minutos.
- [ ] Configurar checks de `uptime`, disco, RAM y salud de `postgres`/`n8n`/`nginx`.
- [ ] Configurar alerta inmediata por caída de contenedor critico.
- [ ] Configurar alertas por umbral:
  - [ ] RAM > 85% durante 15 min.
  - [ ] Disco > 80% durante 15 min.
  - [ ] CPU > 90% durante 15 min.
- [ ] Configurar severidad `warning` (aviso unico).
- [ ] Configurar severidad `critical` (repeticion cada 15 min hasta resolver).
- [ ] Incluir enlace a runbook en cada alerta.
- [ ] Registrar en `monitoring/monitoring-log.md` solo eventos `critical`.
- [x] Definir canal de alertas `<canal-alertas>`.
- [ ] Definir formato de titulo con severidad (`[WARNING]` / `[CRITICAL]`).
- [ ] Incluir campos minimos: servicio, evento, impacto, timestamp, accion sugerida, enlace runbook.
- [ ] Abrir hilo de seguimiento para cada evento `critical` hasta cierre.
- [ ] Mantener sin mencion `@channel` por ahora.
- [ ] Configurar resumen diario en Slack a las `<hora-resumen-diario>`.

## Paso 10 - Backups y restore (estado real)

- [x] Backup diario local con alcance operativo:
  - [x] PostgreSQL `home-manager`
  - [x] PostgreSQL `n8n`
  - [x] Volumen `n8n-data` (hot backup)
- [x] Retención local de 30 días.
- [x] Alertas Slack en éxito y fallo del backup.
- [x] Subida automática a OneDrive (`backups/VareIA/...`) con `onedrive-file-sync`.
- [ ] Ejecutar y documentar restore completo periódico (pendiente).

## Criterios de seguridad minimos

- [x] Instalar `fail2ban` (inicialmente solo `sshd`).
- [x] Configurar `fail2ban`: `bantime=1h`, `maxretry=5`.
- [ ] Mantener `ignoreip` en pendiente hasta disponer de rangos reales.
- [x] Activar `unattended-upgrades` (solo seguridad).
- [x] Definir ventana de parches `<ventana-nocturna>`.
- [x] Recordatorio pendiente: deshabilitar SSH por password cuando haya SSH estable por Tailscale + clave.
- [x] Verificar `PermitRootLogin no` con prueba real antes de cerrar SSH por contraseña.

## Registro de cierre

- [x] Actualizar `changes/CHANGELOG.md`.
- [x] Actualizar `inventory/vps-inventory.md`.
- [ ] Registrar incidencias en `incidents/INCIDENTS.md` si aplica.
