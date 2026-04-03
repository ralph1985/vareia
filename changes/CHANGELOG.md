# Changelog de infraestructura

Formato de fecha: `YYYY-MM-DD`.

## 2026-04-03

- Reanudada la puesta en marcha de OpenClaw y validada operación end-to-end en Slack DM.
- Corregida selección de modelo del agente principal para evitar fallback a Anthropic sin credenciales.
- Fijado modelo operativo gratuito en configuración local: `openrouter/free`.
- Confirmado funcionamiento de Slack Socket Mode con respuesta del bot en DM.
- Confirmado runtime persistente con `systemd` (`openclaw-gateway.service`) tras ajuste de entorno final.
- Actualizados `docs/orchestrator-openclaw.md` y `checklists/openclaw-rollout.md` con estado final operativo.

## 2026-04-02

- Definido modelo documental para OpenClaw con capa ADR + documento operativo + checklist de rollout.
- Añadido documento operativo base `docs/orchestrator-openclaw.md`.
- Añadida carpeta `docs/adr/` con decisiones iniciales:
  - `ADR-001-openclaw-documentation-model.md`
  - `ADR-002-openclaw-slack-v1-interaction.md`
- Añadido `checklists/openclaw-rollout.md` para seguimiento por fases (`hecho`/`pendiente`).
- Confirmadas decisiones de arranque de OpenClaw v1:
  - interacción inicial por DM en Slack;
  - idioma español siempre;
  - app Slack separada de `VareIA Alerts`;
  - ejecución permitida con confirmación obligatoria en acciones sensibles;
  - confirmación mediante botones interactivos.
- Definidos identificadores iniciales de la nueva app Slack del orquestador:
  - nombre de app: `VareIA Bot`
  - handle del bot: `vareia-bot`
- Añadida guía de configuración Slack v1 (scopes/eventos/interactividad) en `docs/orchestrator-openclaw.md`.
- Confirmado transporte Slack para v1: `Socket Mode` (sin callback HTTP público).
- Añadido `ADR-003-openclaw-slack-socket-mode-v1.md`.
- Definidos scopes mínimos de `VareIA Bot` para v1:
  - bot: `chat:write`, `im:history`
  - app-level (`Socket Mode`): `connections:write`
- Ampliados scopes del bot para autonomía inicial:
  - añadidos `im:write` y `users:read`.
- Definida política de acciones sensibles con confirmación obligatoria por botones en Slack.
- Añadido `ADR-004-openclaw-sensitive-actions-policy.md`.
- Definida política de expiración de aprobaciones sensibles: sin caducidad automática.
- Añadido `ADR-005-openclaw-approval-expiration-policy.md`.
- Definida política de concurrencia de aprobaciones para v1: una sola acción sensible pendiente a la vez.
- Añadido `ADR-006-openclaw-single-pending-approval-v1.md`.
- Definida política de aprobador de acciones sensibles: solo owner operativo.
- Añadido `ADR-007-openclaw-approver-policy-owner-only-v1.md`.
- Definida la variable runtime `OWNER_SLACK_USER_ID` para control de aprobador único (sin versionar el valor real).
- Añadida plantilla `configs/servers/openclaw.example.env` con variables de Slack, políticas de aprobación, catálogo inicial de subagentes y auditoría.
- Añadidas plantillas de stack para orchestrator:
  - `configs/stacks/orchestrator/compose.example.yml`
  - `configs/stacks/orchestrator/.env.example`
- Alineado `openclaw.example.env` con variables de runtime de imagen y límites (`OPENCLAW_IMAGE`, `OPENCLAW_MEM_LIMIT`, `OPENCLAW_CPUS`).
- Añadida política de validación de imagen/tag OpenClaw contra fuentes oficiales antes de primer deploy/upgrade.
- Creada en Slack la nueva app de orquestación `VareIA Bot` (separada de `VareIA Alerts`).
- Añadidos y configurados en Slack App los Bot Token Scopes de v1: `chat:write`, `im:history`, `im:write`, `users:read`.
- Instalada `VareIA Bot` en el workspace de Slack.
- Activado `Socket Mode` y generado token app-level (`xapp-...`) con `connections:write`.
- Activadas suscripciones de eventos para DM (`message.im`).
- Confirmada interactividad activa en Slack App para flujo de botones de aprobación/rechazo.
- Guardadas credenciales Slack (`xoxb`, `xapp`, `signing secret`) en runtime seguro (`/opt/infra/orchestrator/.env`, permisos `0600`).
- Desplegado runtime inicial de `orchestrator-openclaw` en `/opt/infra/orchestrator` con contenedor en estado `Up`.
- Corregida plantilla de compose para OpenClaw:
  - eliminado `command` hardcodeado (`node dist/index.js`);
  - desactivado healthcheck embebido de imagen en v1 (`healthcheck.disable=true`) para evitar bloqueos durante bootstrap.
- Habilitada recepción de DM en Slack App (Messages Tab) y validado envío de mensajes al bot.
- Identificado bloqueo funcional actual: proveedor/modelo LLM no configurado en runtime (sin API key).
- Punto de reanudación definido: integrar proveedor inicial (`OpenRouter`) en `.env` y recrear stack.
- Validada respuesta real del bot en Slack al ejecutar `openclaw gateway --allow-unconfigured` fuera de Docker.
- Decidido runtime de v1 fuera de Docker con `systemd`; Docker queda como fase 2.
- Añadido `ADR-008-openclaw-runtime-v1-systemd-not-docker.md`.
- Creado y habilitado `openclaw-gateway.service` en systemd (usuario `monis`) para operación persistente.
- Variables sensibles movidas a `/opt/infra/orchestrator/openclaw.systemd.env` con permisos `0600`.
- Corregido arranque en systemd añadiendo `PATH` de Node.js (NVM) en la unidad para resolver `/usr/bin/env: node: No such file or directory`.

## 2026-03-30

- Desactivado el autoarranque de `home-manager` en runtime (`/opt/infra/home-manager/compose.yml`) cambiando política de reinicio a `restart: "no"`.
- Alineados `~/apps/home-manager/docker-compose.yml` y `~/apps/home-manager/docker-compose.infra.yml` para mantener `home-manager` apagado por defecto.
- Definida política operativa: `home-manager` se levanta solo bajo demanda manual (`docker compose ... up -d` o `docker start home-manager`) y se detiene explícitamente con `docker stop home-manager`.

## 2026-03-29

- Añadido nuevo stack runtime de app en `/opt/infra/home-manager` para desplegar `home-manager` desde código fuente en `~/apps/home-manager`.
- Provisionada base de datos dedicada en PostgreSQL compartido para la app (`app_home_manager` / `usr_home_manager`) siguiendo convención `app_<slug>` / `usr_<slug>`.
- Definido `home-manager` en modo operativo de desarrollo en contenedor (`node:24-bookworm-slim`) con:
  - volumen de código `~/apps/home-manager:/app`
  - volumen persistente para `node_modules`
  - sincronización de esquema con `prisma db push` al arranque
- Publicada ruta privada de la app en reverse-proxy bajo prefijo `/hm` y `/hm/`.
- Alineada configuración de `home-manager` con `basePath=/hm` para servir assets y rutas correctamente detrás de proxy por prefijo.
- Ajustados headers de proxy (`X-Forwarded-*`) para mantener navegación HTTPS estable a través de Tailscale Serve.
- Implementada política operativa de backups en producción mediante `systemd`:
  - `vareia-backup.service` (oneshot)
  - `vareia-backup.timer` diario a `03:30 UTC` (`Persistent=true`)
- Implantado backup local con retención de 30 días en `/opt/backups` para:
  - PostgreSQL de `home-manager` (`app_home_manager`)
  - PostgreSQL de `n8n` (`app_n8n`)
  - volumen `n8n-data` en caliente (`.tar.gz`)
- Añadidas alertas Slack de éxito y fallo para el proceso de backup con formato operativo.
- Integrada copia externa automática a OneDrive usando `~/apps/onedrive-file-sync` con destino remoto `backups/VareIA/...`.
- Corregidas incidencias operativas durante el despliegue de backups:
  - exclusión de query param `?schema=public` para `pg_dump`
  - resolución de `NODE_BIN` al ejecutar sincronización OneDrive desde contexto `root`.

## 2026-03-22

- Actualizado stack `automation-n8n` a versión segura `1.122.x` (tag desplegado `n8nio/n8n:1.122.1`) tras aviso crítico de actualización en panel.
- Validada actualización en runtime con contenedor `automation-n8n` en estado `healthy` y `healthz` operativo vía dominio Tailscale.
- Corregida publicación de n8n detrás de reverse-proxy por prefijo: `N8N_PATH=/n8n/`, `N8N_PROTOCOL=https`, `N8N_EDITOR_BASE_URL` y `WEBHOOK_URL` alineadas al FQDN tailnet.
- Reestructurada configuración Nginx por rutas y servicio para el host tailnet:
  - `/` estado de gateway
  - `/n8n/` -> `automation-n8n:5678`
  - `/pm/` -> `project-manager:4173`
- Desplegado `project-manager` en Docker (contenedor `project-manager`) y validado acceso privado por Tailscale en `/pm/`.
- Encapsulado `project-manager` bajo `/pm/` para evitar exposición de rutas globales fuera del prefijo.
- Documentado autodespliegue local de `project-manager` tras `git pull` (hooks `post-merge`/`post-rewrite`, `core.hooksPath`, script `deploy-from-pull.sh` y log operativo).

## 2026-03-21

- Implementado heartbeat diario de monitorizacion: host -> webhook n8n -> Slack.
- Añadido script de host `/opt/infra/scripts/heartbeat.sh` para recopilar `hostname`, `uptime`, RAM, disco y estado de contenedores.
- Activado cron root diario para heartbeat con log en `/var/log/heartbeat.log`.
- Protegido webhook de heartbeat con token por header `X-Heartbeat-Token`.
- Pendiente operativo abierto: validar en día posterior la ejecución automática del cron de heartbeat y la recepción del mensaje en Slack.
- Corregida estabilidad de n8n tras proxy inverso:
  - `N8N_PROXY_HOPS=1` en stack `automation`
  - soporte WebSocket en vhost `n8n-private` de Nginx (`Upgrade`/`Connection upgrade`)
- SSH movido de `22/tcp` a puerto personalizado `<SSH_PORT>/tcp` con override de `ssh.socket` (IPv4/IPv6).
- Validado acceso real en nueva sesion por `ssh -p <SSH_PORT>`.
- Cerrado `22/tcp` en UFW; regla de entrada SSH mantenida solo en `<SSH_PORT>/tcp`.
- Incidencia operativa resuelta en fail2ban tras reinicio manual: eliminado socket huérfano `/var/run/fail2ban/fail2ban.sock` y servicio recuperado.
- Cerrada ambigüedad de SSH en includes: `/etc/ssh/sshd_config.d/50-cloud-init.conf` sin directivas activas de autenticación.
- Validación efectiva SSH completada: `PasswordAuthentication no`, `AuthenticationMethods publickey`, `PermitRootLogin no`.
- Validado acceso real por clave pública en nueva sesión SSH tras reinicio de servicio.
- Ajustada ventana de parches automáticos a `<ventana-nocturna>` mediante overrides de `apt-daily.timer` y `apt-daily-upgrade.timer`.
- Alineada documentación de inventario/runbook/checklists con estado real de hardening y acceso SSH.
- Añadido script `scripts/stacks/reverse-proxy.sh` para despliegue idempotente de `reverse-proxy-nginx`.
- Actualizado `run-all.sh` para incluir despliegue de `reverse-proxy` junto a PostgreSQL y n8n.
- Desplegado `reverse-proxy-nginx` en `proxy-net` + `infra-net` y validado estado `healthy`.
- Validada ruta privada a n8n via reverse-proxy (`Host: n8n.local` -> `/healthz` devuelve `{"status":"ok"}`).
- Ajustado reverse-proxy para publicar solo en loopback del host (`127.0.0.1:8080`) y mantener `80/443` públicos cerrados.
- Habilitado acceso HTTPS permanente por Tailscale Serve (`https://<node>.ts.net/` -> `http://127.0.0.1:8080`).
- Añadido endpoint `/nginx-health` en vhost principal de n8n para validación directa desde dominio Tailscale.

## 2026-03-20

- Alta del proyecto VareIA para seguimiento del VPS.
- Completado Paso 1 (Docker): Docker Engine y plugin `docker compose` instalados desde repositorio oficial.
- Validacion Docker completada con `docker --version`, `docker compose version` y `docker run --rm hello-world`.
- Usuario operativo `<usuario-admin>` añadido al grupo `docker` y cambio validado en nueva sesion SSH.
- Completado Paso 2 (Tailscale): `tailscale` 1.96.2 instalado y nodo autenticado en tailnet.
- Validacion Tailscale completada: `tailscale status`, IPs `100.x`/`fd7a::`, `tailscaled` en estado `enabled` y `active`.
- Verificada conectividad privada por Tailscale sirviendo HTTP de prueba en `<tailscale-ip>:8080`.
- Completado Paso 3 (Redes Docker): creadas redes `infra-net` y `proxy-net`.
- Validacion de redes Docker completada con `docker network ls`.
- Completado despliegue inicial de PostgreSQL compartido (`postgres-shared`, `postgres:17`) en `/opt/infra/postgres`.
- Validado estado `healthy` del contenedor y creado esquema inicial de credenciales/BBDD: `usr_n8n`/`app_n8n` y `usr_openclaw`/`app_openclaw`.
- Completado despliegue inicial de n8n (`automation-n8n`, `n8nio/n8n:1.91.3`) en `/opt/infra/automation`.
- Validado estado `healthy` de n8n, ejecución de migraciones y conectividad con PostgreSQL `app_n8n`.
- Definido alcance funcional del VPS:
  - reverse-proxy
  - automation
  - orchestrator
  - apps
- Decidido despliegue dockerizado por stacks separados.
- Definido n8n en este mismo VPS (privado) con alertas a Slack.
- Definido OpenClaw como orquestador multiagente (privado), pendiente de diseño/instalación.
- Definido Tailscale como bloque prioritario de red tras instalación de Docker.
- Definida estrategia de backups propia hacia OneDrive (diario, retención 30 días).
- Acordado no documentar secretos ni datos sensibles en repositorio público.
- Confirmado plan del VPS: `gp.nano`.
- Definidas redes Docker separadas: `infra-net` + `proxy-net`.
- Definido PostgreSQL compartido: `postgres:17`, contenedor `postgres-shared`, volumen `postgres-data`, sin exponer.
- Definido n8n como primer servicio real (`app_n8n` / `usr_n8n`), privado y accesible vía reverse-proxy interno.
- Definida convención de BBDD por proyecto: `app_<project_slug>` / `usr_<project_slug>`.
- Definidas políticas de operación: `restart: unless-stopped` y `healthcheck` en servicios críticos.
- Definido backup lógico diario de PostgreSQL (`pg_dump` + `.gz`) con rotación >30 días.
- Definido recordatorio: deshabilitar `PasswordAuthentication` más adelante.
- Definido `n8n-data` como volumen persistente para n8n.
- Definidas imágenes fijas (sin `latest`) para `n8n`, `nginx` y `postgres`.
- Definido esquema de variables por stack (`/opt/infra/<stack>/.env`) con `.env.example`.
- Definido naming con prefijo de stack y uso de `docker compose --project-name <stack>`.
- Añadida plantilla documental de directorios para `/opt/infra` (sin ejecución aún).
- Confirmado orden de ejecucion final: Docker/Compose -> Tailscale -> redes Docker -> PostgreSQL -> n8n.
- Definidos parametros de PostgreSQL: `5432` interno, solo `infra-net`, `POSTGRES_DB=postgres` de bootstrap y configuracion inicial por defecto.
- Definidos limites iniciales de recursos: PostgreSQL `0.5 CPU` + `512MB RAM`; n8n `0.5 CPU` + `512MB RAM`.
- Definida estrategia tecnica de backups PostgreSQL: script en host + cron diario `<hora-backup-f1>`, ruta `/opt/infra/backups/postgres`, formato `YYYYMMDD-HHMM-app_<project>.sql.gz`, rotacion >30 dias y validacion de fichero no vacio.
- Definidos parametros de n8n: contenedor `automation-n8n`, puerto interno `5678`, dependencia de healthcheck de PostgreSQL, `EXECUTIONS_MODE=regular` y limpieza de ejecuciones a 14 dias.
- Definido bloque documental de `reverse-proxy`: contenedor `reverse-proxy-nginx`, imagen `nginx:1.28-alpine`, redes `proxy-net` + `infra-net`.
- Definida estructura de configuracion Nginx: `nginx.conf` + `conf.d/*.conf` por servicio + `default-deny.conf`.
- Definido bloqueo de exposicion `80/443` y TLS/Let's Encrypt hasta contar con dominio y DNS operativos.
- Definido logging de reverse-proxy en `/opt/infra/reverse-proxy/logs` con rotacion pendiente.
- Definido bloque documental de `orchestrator/OpenClaw`: contenedor `orchestrator-openclaw`, solo `infra-net`, sin puertos publicados.
- Definido OpenClaw con DB dedicada `app_openclaw`/`usr_openclaw` y volumen `openclaw-data`.
- Definidos limites iniciales de OpenClaw `0.25 CPU` + `256MB RAM`, con `restart: unless-stopped` y `healthcheck`.
- Definido acceso administrativo inicial de OpenClaw solo por Tailscale.
- Definida integracion desacoplada `n8n` -> OpenClaw via API/webhook, interfaz minima documental `POST /jobs`.
- Definido bloque documental de `apps`: stack reservado sin servicios iniciales.
- Definida estructura de apps futuras por carpeta `/opt/infra/apps/<app-slug>/`.
- Definida plantilla minima por app: `README`, `compose.yml`, `.env`, `.env.example`.
- Definida politica de red para apps: `infra-net` por defecto y `proxy-net` solo bajo necesidad explicita.
- Definida politica de BD por app: `app_<slug>` / `usr_<slug>`.
- Definidos defaults por app: `restart: unless-stopped`, `healthcheck`, `0.25 CPU`, `256MB RAM`.
- Definido bloque de monitorizacion/alertas: checks cada 15 min para `uptime`, disco, RAM y salud de `postgres`/`n8n`/`nginx`.
- Definido esquema de alertas mixto: inmediata por caída de contenedor crítico y por umbrales de recursos.
- Definidos umbrales iniciales: RAM > 85% (15 min), Disco > 80% (15 min), CPU > 90% (15 min).
- Definidas severidades: `warning` (aviso unico) y `critical` (repeticion cada 15 min hasta resolver).
- Definido que cada alerta incluya enlace a runbook y que `monitoring-log.md` registre solo eventos `critical`.
- Definido bloque de seguridad operativa: `fail2ban` inicial solo `sshd`, `bantime=1h`, `maxretry=5`, `ignoreip` pendiente.
- Definido `unattended-upgrades` solo seguridad con ventana nocturna `<ventana-nocturna>`.
- Condicionado cierre de `PasswordAuthentication` a SSH estable por Tailscale + clave.
- Añadido control de verificacion real de `PermitRootLogin no` antes de cerrar SSH por contraseña.
- Definida estrategia de backup/restore en 3 fases: PostgreSQL, volumenes de apps (`n8n-data`, `openclaw-data`) y configuracion de `/opt/infra` sin secretos.
- Definida frecuencia diaria y retencion de 30 dias para las tres fases.
- Definido horario escalonado (hora Espana): `<hora-backup-f1>` (F1), `<hora-backup-f2>` (F2), `<hora-backup-f3>` (F3).
- Definida compresion `.tar.gz` para fases 2 y 3.
- Definido checksum `sha256` para backups en todas las fases.
- Añadido recordatorio de primera prueba completa de restore sin periodicidad fija.
- Definido bloque operativo Slack/n8n: canal dedicado `<canal-alertas>`.
- Definido formato de alertas con prefijo de severidad (`[WARNING]` / `[CRITICAL]`) y campos minimos.
- Definido seguimiento de `critical` en hilo hasta cierre y sin `@channel` por ahora.
- Definido resumen diario de estado/alertas en Slack a las `<hora-resumen-diario>`.
- Definida rotacion de logs de Nginx: diaria, retencion 14 dias, compresion `.gz`, limite 50MB por archivo.
- Confirmado `ignoreip` de fail2ban en estado pendiente hasta disponer de rangos reales.
