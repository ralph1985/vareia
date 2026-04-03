# OpenClaw Orchestrator

Documento operativo de referencia para el despliegue y evolución de OpenClaw como orquestador conversacional de VareIA.

## Estado

- Estado actual: v1 validado funcionalmente fuera de Docker; pendiente formalizar servicio persistente.
- Runtime v1: servicio local `systemd` (usuario `monis`).
- Stack Docker `/opt/infra/orchestrator`: reservado para fase 2.
- Integración principal v1: Slack (conversación directa por DM).

Estado operativo actual (2026-04-02):

- Servicio `openclaw-gateway.service` habilitado y en ejecución (`active (running)`).
- Variables runtime cargadas desde `/opt/infra/orchestrator/openclaw.systemd.env` (`0600`).
- Dependencia resuelta: añadir `PATH` de Node.js (NVM) en la unidad systemd para evitar `node: No such file or directory`.

Estado operativo actual (2026-04-03):

- Runtime persistente confirmado con `systemd`:
  - unidad: `openclaw-gateway.service`
  - estado: `enabled` + `active (running)`
- Modelo operativo fijado a gratuito:
  - `OPENCLAW_MODEL=openrouter/free`
- Integración Slack validada de extremo a extremo:
  - Socket Mode conectado
  - respuesta por DM operativa sin error de billing

## Objetivo v1

- Tener un orquestador disponible en Slack para hablar con él en español.
- Poder enrutar tareas a subagentes especializados.
- Permitir ejecución de acciones con guardrails y confirmación explícita.
- Mantener trazabilidad documental en este repositorio (`docs`, `checklists`, `changes`).

## Decisiones confirmadas

Fecha de captura: 2026-04-02.

- Canal de interacción inicial: DM con el bot (sin auto-respuesta en canales en v1).
- Idioma operativo: español siempre.
- Modo de operación: action-enabled con confirmación obligatoria en acciones sensibles.
- Confirmación de acciones sensibles: botones interactivos de Slack (aprobar/rechazar).
- Estrategia de app Slack: separar app de OpenClaw de `VareIA Alerts`.
- Runtime: despliegue en contenedor Docker dentro de `/opt/infra/orchestrator`.
- Runtime v1 confirmado: `systemd` fuera de Docker.
- Gestión de alcance: evolución por fases, documentando hecho/pendiente.

## Subagentes iniciales (v1)

- `infra-devops`
- `automatizaciones-n8n`
- `producto-roadmap`
- `frontend-ui`
- `backend-api`
- `qa-testing`
- `code-review`
- `release-ops`

## Guardrails mínimos

- Confirmación obligatoria antes de ejecutar operaciones sensibles.
- Registro de decisión y ejecución en logs de auditoría.
- Mantener secretos fuera del repositorio.
- Limitar privilegios por rol de agente y por tipo de acción.

### Política de acciones sensibles (v1)

Acciones que siempre requieren botones de confirmación:

- Deploy/cambios de servicios: `docker compose up/down/pull/build`, `docker restart/stop/rm`, cambios de imagen/tag.
- Host/systemd: `systemctl start/stop/restart/enable/disable`, edición de unidades/timers.
- Infra/config: cambios en `/opt/infra/**`, `/etc/**`, y en configuración de reverse-proxy.
- Red/seguridad: UFW/iptables, puertos expuestos, cambios de Tailscale Serve/Funnel.
- Base de datos: DDL (`CREATE/ALTER/DROP`), migraciones de riesgo, restores sobre entorno activo.
- Backups/datos: borrado/poda manual, cambios de retención y operaciones con posible pérdida de evidencia.
- Secretos: alta/rotación/revocación de credenciales y cambios en `.env` con secretos.

Acciones permitidas sin confirmación (solo lectura):

- Comandos de diagnóstico y estado (`docker ps`, `docker logs` lectura, `systemctl status`, `journalctl`, métricas host).
- Lectura documental e inventario.
- Propuesta de planes/diffs sin aplicar cambios.

Política de expiración de aprobaciones:

- En v1, las solicitudes de acciones sensibles no caducan automáticamente.
- La acción permanece pendiente hasta `Aprobar` o `Rechazar`.

Política de concurrencia de aprobaciones:

- En v1, solo puede existir una acción sensible pendiente a la vez.
- Nuevas acciones sensibles se encolan o rechazan hasta cerrar la pendiente activa.

Política de aprobador:

- En v1, solo un usuario autorizado (owner operativo) puede aprobar acciones sensibles.
- Cualquier intento de aprobación desde otro usuario debe rechazarse y auditarse.
- Identidad del aprobador: usar `OWNER_SLACK_USER_ID` (formato `U...`) en runtime.
- No versionar el valor real en Git público; guardarlo en `/opt/infra/orchestrator/.env` (`0600`).

## Flujo funcional v1 (alto nivel)

1. Usuario envía DM al bot en Slack.
2. OpenClaw clasifica intención y selecciona subagente.
3. Si hay acción sensible, solicita aprobación con botones interactivos.
4. Tras aprobación, ejecuta acción y responde resultado en Slack.
5. Se registra evidencia operacional (auditoría y changelog cuando aplique).

## Integración con la documentación existente

- Decisiones: `docs/adr/`.
- Ejecución por fases: `checklists/openclaw-rollout.md`.
- Registro cronológico: `changes/CHANGELOG.md`.
- Estado global del VPS: `inventory/vps-inventory.md` y `docs/runbook.md`.

## Pendientes inmediatos

- Crear y configurar nueva Slack App para OpenClaw (scopes, eventos, interactivity).
- Definir endpoint/callback interno para eventos de Slack.
- Definir compose y `.env` de `/opt/infra/orchestrator`.
- Definir política de permisos por subagente.
- Definir estrategia de auditoría y retención de logs.

## Plantilla de variables (repo)

- Archivo base sin secretos: `configs/servers/openclaw.example.env`.
- Flujo recomendado:
  1. copiar a `configs/servers/openclaw-<server>.env`;
  2. completar valores reales fuera de Git;
  3. instalar en runtime como `/opt/infra/orchestrator/.env` con permisos `0600`.

## Plantilla de compose (repo)

- Plantilla base del stack:
  - `configs/stacks/orchestrator/compose.example.yml`
  - `configs/stacks/orchestrator/.env.example`
- Runtime recomendado:
  - `/opt/infra/orchestrator/compose.yml`
  - `/opt/infra/orchestrator/.env`
- Reglas de red/publicación:
  - solo `infra-net`;
  - sin puertos publicados al host en v1 (Socket Mode).

Nota de fase:
- Estas plantillas de Docker quedan como referencia de fase 2.
- La operación v1 se ejecuta fuera de Docker con `openclaw gateway` gestionado por `systemd`.

## Política de imagen OpenClaw

- La imagen/tag de producción debe validarse siempre en fuentes oficiales antes del primer deploy o actualización.
- Fuentes oficiales de referencia:
  - `https://docs.openclaw.ai/install`
  - `https://docs.openclaw.ai/install/docker`
  - `https://github.com/openclaw/openclaw`
- Convención esperada para imagen prebuilt: `ghcr.io/openclaw/openclaw:<tag>`.
- No asumir `latest` por defecto sin validación explícita de compatibilidad.

## Slack App v1 (`VareIA Bot`)

Nombre y handle confirmados:

- App Name: `VareIA Bot`
- Bot handle: `vareia-bot`

Configuración recomendada para v1 (DM + botones):

1. Crear app desde cero en Slack (`From scratch`) con nombre `VareIA Bot`.
2. Activar bot user y fijar handle `vareia-bot`.
3. Bot Token Scopes v1 (confirmados):
   - `chat:write` (enviar respuestas del bot)
   - `im:history` (leer mensajes en DM)
   - `im:write` (iniciar/gestionar DM cuando aplique)
   - `users:read` (resolver identidad de usuarios para permisos/ruteo)
4. App-Level Token (`xapp-...`) para Socket Mode:
   - permiso `connections:write`
5. Event Subscriptions:
   - activar eventos;
   - suscribir evento de bot `message.im` (mensajes directos por DM).
6. Interactivity & Shortcuts:
   - activar interactividad para soportar botones de aprobación/rechazo.
7. Instalar app en workspace y obtener:
   - `Bot User OAuth Token` (`xoxb-...`)
   - `App-Level Token` (`xapp-...`)
   - `Signing Secret`
8. Guardar secretos fuera de Git (runtime en VPS):
   - `/opt/infra/orchestrator/.env` con permisos `0600`.
9. Validación funcional mínima:
   - enviar DM al bot;
   - verificar respuesta;
   - disparar una acción sensible simulada y comprobar botones interactivos.

Nota operativa:
- Para v1 se confirma `Socket Mode` (sin callback HTTP público).
- Tokens requeridos en runtime:
  - `SLACK_BOT_TOKEN` (`xoxb-...`)
  - `SLACK_APP_TOKEN` (`xapp-...`, con permiso `connections:write`)
  - `SLACK_SIGNING_SECRET` (mantenerlo igualmente para futuras fases HTTP)
- Enfoque de permisos v1: extendido para autonomía controlada del bot.
