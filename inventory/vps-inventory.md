# Inventario VPS

## Datos generales

- Proyecto: Vareia
- Entorno: producción
- Proveedor: Cubepath
- Plan: gp.nano
- Región: España, Barcelona
- SO: Ubuntu 24 LTS
- vCPU / RAM / Disco: 1 CPU / 2 GB RAM / 40 GB disco
- Coste mensual: ~5 EUR

## Red y acceso

- Hostname: vareia-vps-prod (provisional)
- Dominio principal: pendiente
- Subdominios: ninguno
- Firewall activo: sí (`ufw allow OpenSSH` + `ufw enable`)
- Puertos abiertos: solo 22
- SSH por contraseña deshabilitado: sí (`PasswordAuthentication no`)
- SSH root (`PermitRootLogin no`): configurado y validado en comprobación de configuración efectiva
- IP pública: omitida (repositorio público)
- Usuario admin no-root: omitido (repositorio público)
- Método de acceso actual: SSH por clave pública con usuario no-root (equipo local)
- Acceso de contingencia: consola web del proveedor
- Objetivo SSH futuro: consolidar configuración SSH para eliminar directivas ambiguas en includes

## Servicios

| Servicio | Puerto | Estado | Observaciones |
|---|---:|---|---|
| Docker Engine | - | instalado | Docker CE 29.3.0 (repo oficial), validado con `hello-world` |
| Docker Compose | - | instalado | Plugin `docker compose` v5.1.1 |
| Tailscale | 100.x / fd7a:: | instalado | `tailscale` 1.96.2, nodo conectado al tailnet, `tailscaled` enabled/active |
| Nginx | 80/443 (futuro) | pendiente | `reverse-proxy-nginx`, `nginx:1.28-alpine`, en `proxy-net` + `infra-net` |
| n8n | privado | instalado | `automation-n8n` healthy; `5678` interno; `n8n-data`; `n8nio/n8n:1.91.3`; DB `app_n8n` |
| OpenClaw | privado | pendiente | `orchestrator-openclaw`; `openclaw-data`; DB `app_openclaw`; solo Tailscale |
| PostgreSQL compartido | interno | instalado | `postgres:17`, `postgres-shared` healthy, `5432` interno, `postgres-data`, sin exponer |

## Backups

- Estrategia: backup propio hacia OneDrive (sin backups gestionados por proveedor)
- Frecuencia: diario
- Retención: 30 días
- Formato: `pg_dump` comprimido (`.gz`)
- Ejecucion: script host + cron diario `04:00` (hora Espana)
- Ruta local: `/opt/infra/backups/postgres`
- Nombre: `YYYYMMDD-HHMM-app_<project>.sql.gz`
- Rotación local: eliminar copias de más de 30 días
- Verificacion: comprobar que el `.gz` generado no esta vacio
- Cifrado: no (por ahora)
- Última prueba de restore: no realizada
- Estrategia por fases:
  - Fase 1: PostgreSQL (`04:00`)
  - Fase 2: volumenes `n8n-data` + `openclaw-data` (`04:30`, `.tar.gz`)
  - Fase 3: configuracion `/opt/infra` sin secretos (`05:00`, `.tar.gz`)
- Integridad: checksum `sha256` por backup en todas las fases
- Restore: primera prueba completa pendiente (sin periodicidad fija)

## Arquitectura por stacks

- `reverse-proxy`
- `automation`
- `orchestrator`
- `apps`

## Redes Docker

- `infra-net` (interna)
- `proxy-net` (frontal)
- Estado: creadas y verificadas con `docker network ls`.

## Estándares de operación

- Variables por stack: `/opt/infra/<stack>/.env`
- Plantillas sin secretos: `/opt/infra/<stack>/.env.example`
- Naming de contenedores con prefijo de stack
- Arranque por stack con `docker compose --project-name <stack>`
- Limites iniciales de recursos:
  - `postgres-shared`: `0.5 CPU`, `512MB RAM`
  - `automation-n8n`: `0.5 CPU`, `512MB RAM`
- Dependencias:
  - `n8n` arranca tras healthcheck correcto de `postgres-shared`
- Orchestrator:
  - `orchestrator-openclaw` solo en `infra-net`, sin puertos publicados
  - Volumen `openclaw-data`
  - Limites iniciales `0.25 CPU`, `256MB RAM`
  - `restart: unless-stopped` + `healthcheck`
  - Acceso administrativo solo por Tailscale (fase inicial)
  - Integracion desacoplada con `n8n` por API/webhook (`POST /jobs`)
- Apps (futuras):
  - Stack reservado sin servicios iniciales
  - Estructura por app: `/opt/infra/apps/<app-slug>/`
  - Plantilla minima por app: `README`, `compose.yml`, `.env`, `.env.example`
  - Red por defecto: `infra-net` (`proxy-net` solo si aplica)
  - DB dedicada por app: `app_<slug>` / `usr_<slug>`
  - Defaults: `restart: unless-stopped`, `healthcheck`, `0.25 CPU`, `256MB RAM`
- n8n ejecucion:
  - `EXECUTIONS_MODE=regular`
  - Limpieza activa con retencion inicial de 14 dias
- reverse-proxy:
  - Config en `/opt/infra/reverse-proxy/nginx.conf` y `/opt/infra/reverse-proxy/conf.d/*.conf`
  - `default-deny.conf` habilitado desde inicio
  - Logs en `/opt/infra/reverse-proxy/logs` con rotacion diaria, 14 dias, `.gz`, limite 50MB
  - TLS pendiente hasta dominio y DNS operativos
- Monitorizacion y alertas:
  - checks tecnicos cada 15 minutos (modo conservador)
  - checks: `uptime`, disco, RAM y salud de `postgres`/`n8n`/`nginx`
  - alerta inmediata por caida de contenedor critico
  - alertas por umbral: RAM > 85% (15 min), Disco > 80% (15 min), CPU > 90% (15 min)
  - severidades: `warning` (aviso unico), `critical` (repeticion cada 15 min)
  - canal objetivo: `#vareia-alerts`
  - formato de alerta: prefijo `[WARNING]` / `[CRITICAL]`
  - campos minimos: servicio, evento, impacto, timestamp, accion sugerida, enlace runbook
  - eventos `critical` con hilo de seguimiento hasta cierre
  - sin mencion `@channel` por ahora
  - resumen diario a las `09:00` (hora Espana)
  - alertas con enlace a runbook
  - registro historico solo de eventos `critical`
- Seguridad operativa:
  - `fail2ban` inicial solo para `sshd`
  - parametros iniciales: `bantime=1h`, `maxretry=5`
  - `ignoreip` pendiente con rangos de confianza (sin definir aun)
  - `unattended-upgrades` solo seguridad
  - ventana de parches: `03:00-05:00` (hora Espana), aplicada mediante overrides de `apt-daily*.timer`
  - `PasswordAuthentication no` aplicado y validado
  - `PermitRootLogin no` validado en comprobación efectiva y acceso real

## Convenciones de base de datos

- Base de datos: `app_<project_slug>`
- Usuario: `usr_<project_slug>`
- Regla: `postgres` solo para administración
