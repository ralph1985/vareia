# Runbook VPS

## Acceso

- Proveedor: Cubepath
- Hostname: VareIA-vps-prod (provisional)
- IP pública: omitida (repositorio público)
- Usuario admin: omitido (repositorio público)
- Método de acceso actual: SSH por clave pública (usuario no-root) desde equipo local
- Acceso de contingencia: consola web del proveedor

## Estado actual y limitaciones

- SSH operativo desde equipo local con usuario no-root y clave pública.
- Consola web del proveedor mantenida solo como acceso de contingencia.
- Solo puerto 22 abierto por ahora.
- UFW activo con política `deny incoming` y `allow outgoing`.
- Fail2ban activo para `sshd` (`bantime=1h`, `maxretry=5`).

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
- Backups PostgreSQL: script en host + cron diario `04:00` (hora Espana).
- Backups PostgreSQL: ruta `/opt/infra/backups/postgres`, formato `YYYYMMDD-HHMM-app_<project>.sql.gz`.
- Backups PostgreSQL: rotacion >30 dias en el mismo cron + verificacion de fichero no vacio.
- Backups por fases:
  - Fase 1: PostgreSQL
  - Fase 2: volumenes `n8n-data` y `openclaw-data`
  - Fase 3: configuracion de `/opt/infra` (sin secretos)
- Backups por fases: frecuencia diaria y retencion de 30 dias en todas las fases.
- Backups por fases: horario escalonado (hora Espana):
  - Fase 1: `04:00`
  - Fase 2: `04:30`
  - Fase 3: `05:00`
- Backups fases 2 y 3: compresion `.tar.gz`.
- Backups todas las fases: generar checksum `sha256`.
- Restore: recordatorio pendiente de primera prueba completa (sin periodicidad fija).
- `n8n`: contenedor `automation-n8n`, puerto interno `5678`, solo `infra-net`, sin publicacion.
- `n8n`: depende de `postgres-shared` saludable antes de iniciar.
- `n8n`: limites iniciales `0.5 CPU` y `512MB RAM`.
- `n8n`: `EXECUTIONS_MODE=regular`.
- `n8n`: politica de limpieza activa con retencion inicial de 14 dias.
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
- `apps`: defaults operativos por app: `restart: unless-stopped`, `healthcheck`, `0.25 CPU`, `256MB RAM`.
- Monitorizacion (n8n -> Slack):
  - checks cada 15 minutos (modo conservador)
  - checks: `uptime`, disco, RAM, salud de `postgres`/`n8n`/`nginx`
  - alerta inmediata por caída de contenedor crítico
  - alerta por umbral: RAM > 85% (15 min), Disco > 80% (15 min), CPU > 90% (15 min)
  - severidad `warning` (aviso unico) y `critical` (repeticion cada 15 min)
  - cada alerta con enlace a runbook
  - registro histórico: solo eventos `critical` en `monitoring/monitoring-log.md`
  - canal objetivo: `#VareIA-alerts`
  - formato de alerta con prefijo (`[WARNING]` / `[CRITICAL]`)
  - payload minimo: servicio, evento, impacto, timestamp, accion sugerida, enlace runbook
  - `critical` abre hilo de seguimiento hasta cierre
  - sin `@channel` por ahora
  - resumen diario automatizado a las `09:00` (hora Espana)
- Seguridad operativa:
  - `fail2ban` inicial solo para `sshd`
  - valores iniciales `bantime=1h` y `maxretry=5`
  - `ignoreip` pendiente de definir con rangos de confianza
  - `unattended-upgrades` solo seguridad, sin upgrades generales
  - ventana de parches automáticos `03:00-05:00` (hora Espana) aplicada mediante overrides de `apt-daily*.timer`
- `reverse-proxy`: contenedor `reverse-proxy-nginx`.
- `reverse-proxy`: imagen fija `nginx:1.28-alpine`.
- `reverse-proxy`: conectado a `proxy-net` y `infra-net`.
- `reverse-proxy`: `80/443` cerrados por ahora; abrir solo con dominio y DNS operativos.
- `reverse-proxy`: publicado solo en loopback del host (`127.0.0.1:8080`) para integración privada.
- `reverse-proxy`: estructura de configuracion
  - `/opt/infra/reverse-proxy/nginx.conf`
  - `/opt/infra/reverse-proxy/conf.d/*.conf`
- `reverse-proxy`: incluir `default-deny.conf` desde inicio.
- `reverse-proxy`: plantilla de vhost privada para `n8n` activa.
- `reverse-proxy`: endpoint de salud disponible en `/nginx-health` dentro del vhost de `n8n`.
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
  - acceso real confirmado en nueva sesión SSH por clave pública

## Política de secretos

- No almacenar usuarios, IPs ni tokens en este repositorio público.
- Gestión de credenciales fuera de este repositorio.

## Procedimiento de mantenimiento

1. Crear backup.
2. Actualizar paquetes del sistema.
3. Reiniciar servicios afectados.
4. Validar salud y alertas.
5. Registrar cambio en `changes/CHANGELOG.md`.

## Referencia operativa

- Usar `docs/execution-checklist.md` como guia de ejecucion paso a paso.
