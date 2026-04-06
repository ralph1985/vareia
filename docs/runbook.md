# Runbook VPS

## Acceso

- Proveedor: Cubepath
- Hostname: <hostname-interno> (provisional)
- IP pública: omitida (repositorio público)
- Usuario admin: omitido (repositorio público)
- Método de acceso actual: SSH por clave pública (usuario no-root) desde equipo local
- Acceso de contingencia: consola web del proveedor

## Estado actual y limitaciones

- SSH operativo desde equipo local con usuario no-root y clave pública.
- Consola web del proveedor mantenida solo como acceso de contingencia.
- Puerto SSH actual: `<SSH_PORT>/tcp` (IPv4/IPv6); `22/tcp` cerrado en firewall.
- UFW activo con política `deny incoming` y `allow outgoing`.
- Fail2ban activo para `sshd` (`bantime=1h`, `maxretry=5`).

## Mapa de directorios (fuente vs runtime)

- `~/apps/`: código fuente versionado (Git) de cada repositorio.
- `~/apps/vareia`: infraestructura, runbooks, scripts y checklists operativos.
- `~/apps/project-manager`: aplicación de gestión (monorepo Lerna propio).
- `~/apps/<app>`: nuevas apps, cada una en su repositorio independiente.
- `/opt/infra/`: runtime de servidor (stacks Docker, `.env` reales, logs, volúmenes).
- Regla: no alojar código fuente de apps dentro de `/opt/infra`.
- Regla: no usar `~/apps/project-manager/projects` para nuevos repositorios de apps en VPS.

## Comandos clave

```bash
# Estado general
uptime
free -h
df -h

# Servicios
systemctl --failed
systemctl status <service>

# Logs
journalctl -p err -n 100
```

## Secuencia prioritaria de despliegue

1. Instalar Docker Engine.
2. Instalar Docker Compose (plugin `docker compose`).
3. Instalar y configurar Tailscale.
4. Crear redes Docker: `infra-net` y `proxy-net`.
5. Preparar stacks separados:
   - `reverse-proxy`
   - `automation`
   - `orchestrator`
   - `apps`
6. Desplegar `postgres-shared` (`postgres:17`) solo en red interna.
7. Desplegar `n8n` (privado) con PostgreSQL (`app_n8n` / `usr_n8n`) y conectar alertas hacia Slack.
8. Definir e instalar OpenClaw como servicio orquestador (privado, DB dedicada futura).
9. Preparar `reverse-proxy` (Nginx) con `proxy-net` + `infra-net`.
10. Exponer solo `reverse-proxy` (80/443) cuando el dominio esté listo.

## Parametros operativos cerrados

- `postgres-shared`: puerto interno `5432`, solo en `infra-net`, sin publicar puertos.
- `postgres-shared`: `POSTGRES_DB=postgres` para bootstrap; BDs de apps separadas.
- `postgres-shared`: configuracion por defecto en fase inicial.
- `postgres-shared`: limites iniciales `0.5 CPU` y `512MB RAM`.
- Backups operativos reales:
  - script runtime: `/opt/infra/scripts/vareia-backup.sh`
  - fuente versionada: `~/apps/vareia/scripts/host/vareia-backup.sh`
  - config runtime: `/opt/infra/.backup.env` (fuente base: `~/apps/vareia/configs/servers/backup.example.env`)
  - automatizacion: `systemd` (`vareia-backup.service` + `vareia-backup.timer`)
  - programacion: diario a `03:30 UTC` (`Persistent=true`)
  - retencion local: 30 dias
  - cifrado local: no
- Alcance de backup diario:
  - PostgreSQL de `home-manager` (`app_home_manager`) en `/opt/backups/home-manager/*.sql.gz`
  - PostgreSQL de `n8n` (`app_n8n`) en `/opt/backups/n8n/postgres/*.sql.gz`
  - volumen `n8n-data` en caliente en `/opt/backups/n8n/data/*.tar.gz`
  - dataset de `loto-sync` exportado desde Vercel en `/opt/backups/loto-sync/loto-sync-*.json`
  - logs del propio backup en `/opt/backups/logs/backup-*.log`
- Copia externa:
  - subida automatica a OneDrive mediante `~/apps/onedrive-file-sync/run.sh`
  - ruta remota base: `backups/VareIA/...` (dentro de `Apps/<onedrive-app-name>/`)
- Variables adicionales requeridas en `/opt/infra/.backup.env` para `loto-sync`:
  - `LOTO_SYNC_REMOTE_SYNC_BASE_URL`
  - `LOTO_SYNC_DB_SYNC_TOKEN`
- Alertas:
  - Slack en `OK` y `FAIL` desde el propio script de backup
  - formato operativo con prefijo de estado y lista de ficheros generados/subidos
- Restore:
  - restore completo periodico pendiente (solo validado que el backup se genera y sube)
- `n8n`: contenedor `automation-n8n`, puerto interno `5678`, solo `infra-net`, sin publicacion.
- `n8n`: depende de `postgres-shared` saludable antes de iniciar.
- `n8n`: limites iniciales `0.5 CPU` y `512MB RAM`.
- `n8n`: `EXECUTIONS_MODE=regular`.
- `n8n`: politica de limpieza activa con retencion inicial de 14 dias.
- `n8n`: acceso privado por reverse-proxy en `/n8n/` (base path operativo con `N8N_PATH=/n8n/`).
- `orchestrator`: contenedor `orchestrator-openclaw`.
- `orchestrator`: solo `infra-net`, sin publicacion de puertos.
- `orchestrator`: volumen persistente `openclaw-data`.
- `orchestrator`: DB dedicada `app_openclaw` con usuario `usr_openclaw`.
- `orchestrator`: limites iniciales `0.25 CPU` y `256MB RAM`.
- `orchestrator`: `restart: unless-stopped` y `healthcheck`.
- `orchestrator`: acceso administrativo solo por Tailscale en fase inicial.
- `orchestrator`: desacoplado de `n8n` (integracion por API/webhook).
- `orchestrator`: interfaz minima documental `POST /jobs` para disparo desde `n8n`.
- `apps`: stack reservado para futuros servicios, sin despliegue inicial.
- `apps`: estructura por app en `/opt/infra/apps/<app-slug>/`.
- `apps`: cada app con `README`, `compose.yml`, `.env` y `.env.example`.
- `apps`: por defecto solo en `infra-net`; usar `proxy-net` solo con necesidad explicita.
- `apps`: cada app con DB dedicada (`app_<slug>` / `usr_<slug>`).
- `apps`: defaults operativos por app: `restart: unless-stopped`, `healthcheck`, `0.25 CPU`, `256MB RAM` (excepto `home-manager`, configurado con `restart: "no"`).
- `apps`: código fuente de cada app en `~/apps/<app>`, fuera de `/opt/infra`.
- `apps`: `project-manager` con auto-despliegue local tras `git pull` mediante hooks de Git.
- `apps`: hooks definidos en `/home/monis/apps/project-manager/.githooks/` (`post-merge`, `post-rewrite`).
- `apps`: script de despliegue ejecutado por hooks: `/home/monis/apps/project-manager/scripts/deploy-from-pull.sh`.
- `apps`: log de despliegue post-pull: `/tmp/project-manager-deploy.log`.
- `apps`: `home-manager` desplegado como stack runtime dedicado en `/opt/infra/home-manager`.
- `apps`: `home-manager` opera en modo dev dentro de contenedor (`node:24-bookworm-slim`) con código montado desde `~/apps/home-manager`.
- `apps`: `home-manager` usa `NEXT_BASE_PATH=/hm` para funcionar detrás del reverse-proxy por prefijo.
- `apps`: `home-manager` sincroniza esquema de BD al arranque con `npx prisma db push`.
- `apps`: `home-manager` queda apagado por defecto (`restart: "no"`); se arranca solo bajo demanda manual.
- Monitorizacion (n8n -> Slack):
  - heartbeat diario operativo (host -> webhook n8n -> Slack)
  - script runtime: `/opt/infra/scripts/heartbeat.sh`
  - fuente versionada: `~/apps/vareia/scripts/host/heartbeat.sh`
  - config runtime: `/opt/infra/.heartbeat.env` (fuente base: `~/apps/vareia/configs/servers/heartbeat.example.env`)
  - cron operativo diario en root para ejecutar `/opt/infra/scripts/heartbeat.sh` (log en `/var/log/heartbeat.log`)
  - autenticacion de heartbeat por header `X-Heartbeat-Token`
  - checks cada 15 minutos (modo conservador)
  - checks: `uptime`, disco, RAM, salud de `postgres`/`n8n`/`nginx`
  - alerta inmediata por caída de contenedor crítico
  - alerta por umbral: RAM > 85% (15 min), Disco > 80% (15 min), CPU > 90% (15 min)
  - severidad `warning` (aviso unico) y `critical` (repeticion cada 15 min)
  - cada alerta con enlace a runbook
  - registro histórico: solo eventos `critical` en `monitoring/monitoring-log.md`
  - canal objetivo: `<canal-alertas>`
  - formato de alerta con prefijo (`[WARNING]` / `[CRITICAL]`)
  - payload minimo: servicio, evento, impacto, timestamp, accion sugerida, enlace runbook
  - `critical` abre hilo de seguimiento hasta cierre
  - sin `@channel` por ahora
  - resumen diario automatizado a las `<hora-resumen-diario>`
- Seguridad operativa:
  - `fail2ban` inicial solo para `sshd`
  - valores iniciales `bantime=1h` y `maxretry=5`
  - `ignoreip` pendiente de definir con rangos de confianza
  - SSH publicado en puerto personalizado `<SSH_PORT>/tcp` (override en `ssh.socket`)
  - `unattended-upgrades` solo seguridad, sin upgrades generales
  - ventana de parches automáticos `<ventana-nocturna>` aplicada mediante overrides de `apt-daily*.timer`
- `reverse-proxy`: contenedor `reverse-proxy-nginx`.
- `reverse-proxy`: imagen fija `nginx:1.28-alpine`.
- `reverse-proxy`: conectado a `proxy-net` y `infra-net`.
- `reverse-proxy`: `80/443` cerrados por ahora; abrir solo con dominio y DNS operativos.
- `reverse-proxy`: publicado solo en loopback del host (`127.0.0.1:8080`) para integración privada.
- `reverse-proxy`: estructura de configuracion
  - `/opt/infra/reverse-proxy/nginx.conf`
  - `/opt/infra/reverse-proxy/conf.d/*.conf`
- `reverse-proxy`: incluir `default-deny.conf` desde inicio.
- `reverse-proxy`: plantilla de vhost privada por rutas activa.
- `reverse-proxy`: endpoint de salud disponible en `/nginx-health` dentro del vhost principal tailnet.
- `reverse-proxy`: enrutado actual privado:
  - `/` respuesta de estado (`VareIA reverse proxy OK`)
  - `/n8n/` -> `automation-n8n:5678`
  - `/pm/` -> `project-manager:4173`
  - `/hm` y `/hm/` -> `home-manager:3000`
- `reverse-proxy`: `project-manager` encapsulado en `/pm/` (sin exponer rutas globales `/dashboard` fuera del prefijo).
- `reverse-proxy`: logs en `/opt/infra/reverse-proxy/logs`; rotacion pendiente.
- `reverse-proxy`: rotacion de logs definida:
  - diaria
  - retencion 14 dias
  - compresion `.gz`
  - limite 50MB por archivo
- `reverse-proxy`: acceso web privado permanente vía Tailscale Serve (`https://<node>.ts.net/` -> `http://127.0.0.1:8080`).

## Plantilla documental de `/opt/infra` (sin ejecutar aún)

```text
/opt/infra/
  reverse-proxy/
    compose.yml
    nginx.conf
    conf.d/
    .env
    .env.example
    logs/
  automation/
    compose.yml
    .env
    .env.example
    logs/
  orchestrator/
    compose.yml
    api/
    .env
    .env.example
    logs/
  apps/
    <app-slug>/
      README.md
      compose.yml
      .env
      .env.example
      logs/
```

## Convenciones de despliegue

- Usar imágenes con versión fija (sin `latest`) para `n8n`, `nginx` y `postgres`.
- Definir variables por stack (`/opt/infra/<stack>/.env`).
- Mantener `.env.example` por stack sin secretos.
- Usar naming de contenedores con prefijo de stack.
- Arrancar cada stack con `docker compose --project-name <stack>`.

## Recordatorios

- SSH endurecido y validado en producción:
  - `PasswordAuthentication no`
  - `AuthenticationMethods publickey`
  - `PermitRootLogin no`
  - `Port <SSH_PORT>` efectivo
  - acceso real confirmado en nueva sesión SSH por clave pública

## Resolución conocida: Fail2ban no arranca tras reinicio manual

- Sintoma: `Could not start server... old socket file is still present`.
- Causa: socket huérfano en `/var/run/fail2ban/fail2ban.sock`.
- Resolucion:

```bash
sudo rm -f /var/run/fail2ban/fail2ban.sock
sudo systemctl restart fail2ban
sudo fail2ban-client status sshd
```

## Política de secretos

- No almacenar usuarios, IPs ni tokens en este repositorio público.
- Gestión de credenciales fuera de este repositorio.

## Operación de correo del bot (Gmail IMAP)

- Cuenta objetivo: `vareia.bot@gmail.com`.
- Método de integración vigente: Opción 1 en modo lectura (`IMAP + App Password`).
- Guía operativa: `docs/gmail-bot-imap-smtp.md`.
- Archivo runtime de secretos (VPS): `/opt/infra/.gmail-bot.env` (`0600`, no versionar).
- Implementación recomendada (fase actual):
  - lectura por IMAP en `n8n` (polling 1-5 min)
  - filtros obligatorios: allowlist de remitentes + prefijo de asunto + token compartido
  - acciones sensibles: siempre con flujo de aprobación antes de ejecutar
- SMTP queda aplazado para fase posterior (cuando se necesite envío desde `n8n`).
- Rotación: cambiar App Password periódicamente y actualizar credenciales en `n8n`.
- Estado operativo actual (2026-04-06):
  - workflow activo `leer-correos-imap`
  - lectura actual sin filtros (todos los correos de `INBOX`)
  - notificación de nuevo correo hacia Slack operativa vía webhook

## Procedimiento de mantenimiento

1. Crear backup.
2. Actualizar paquetes del sistema.
3. Reiniciar servicios afectados.
4. Validar salud y alertas.
5. Registrar cambio en `changes/CHANGELOG.md`.

## Operación de home-manager

```bash
# Política por defecto: apagado. Arranque manual solo cuando se necesite.

# Levantar/actualizar stack runtime de home-manager (manual)
docker compose -f /opt/infra/home-manager/compose.yml --env-file /opt/infra/home-manager/.env up -d

# Arrancar si ya existe y está parado
docker start home-manager

# Parar y dejarlo apagado
docker stop home-manager

# Ver logs
docker logs -f home-manager

# Verificar estado
docker ps --format 'table {{.Names}}\t{{.Status}}' | rg home-manager
```

## Operación de backups

```bash
# Estado del timer diario
systemctl list-timers --all | rg vareia-backup

# Lanzar backup manual
sudo systemctl start vareia-backup.service

# Ver logs del backup
sudo journalctl -u vareia-backup.service -n 120 --no-pager

# Ver ficheros locales generados
sudo find /opt/backups -maxdepth 4 -type f | sort | tail -n 30
```

## Referencia operativa

- Usar `docs/execution-checklist.md` como guia de ejecucion paso a paso.
