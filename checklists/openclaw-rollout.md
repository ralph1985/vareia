# Checklist OpenClaw Rollout

Objetivo: desplegar OpenClaw como orquestador en Slack, con ejecución controlada y trazabilidad completa en VareIA.

## Fase 0 - Decisiones y documentación

- [x] Definir canal de interacción inicial por DM.
- [x] Definir idioma operativo en español.
- [x] Definir modo action-enabled con confirmación obligatoria en acciones sensibles.
- [x] Definir confirmación por botones interactivos de Slack.
- [x] Definir separación de app Slack para OpenClaw (independiente de `VareIA Alerts`).
- [x] Crear documento operativo `docs/orchestrator-openclaw.md`.
- [x] Crear estructura ADR en `docs/adr/`.
- [x] Registrar decisiones iniciales en ADR.

## Fase 1 - Slack App OpenClaw

- [x] Crear Slack App nueva para OpenClaw (`VareIA Bot`).
- [x] Definir nombre visible de app: `VareIA Bot`.
- [x] Definir handle del bot: `vareia-bot`.
- [ ] Configurar icono y metadatos.
- [x] Definir scopes mínimos de v1:
  - bot: `chat:write`, `im:history`, `im:write`, `users:read`
  - app-level (`Socket Mode`): `connections:write`
- [x] Configurar scopes en Slack App.
- [x] Activar eventos necesarios para DM (`message.im`).
- [x] Activar interactividad de botones.
- [x] Instalar app en workspace.
- [x] Guardar credenciales en runtime seguro (fuera de Git).
- [x] Validar recepción de eventos desde Slack (DM habilitado; envío operativo).
- [x] Validar respuesta funcional end-to-end del bot en Slack DM.
- [x] Decidir transporte Slack: `Socket Mode`.
- [x] Activar `Socket Mode` y generar `App-Level Token` (`xapp-...`, `connections:write`).

## Fase 2 - Stack Orchestrator en VPS

- [ ] Crear runtime Docker `/opt/infra/orchestrator` (fase 2).
- [x] Crear plantilla de `compose.yml` en repo (`configs/stacks/orchestrator/compose.example.yml`).
- [ ] Definir `compose.yml` runtime del servicio `orchestrator-openclaw` (fase 2).
- [x] Crear plantilla repo `configs/servers/openclaw.example.env` (sin secretos).
- [ ] Definir `.env` runtime en `/opt/infra/orchestrator/.env` (fase 2).
- [x] Crear `.env.example` de stack en repo (`configs/stacks/orchestrator/.env.example`).
- [ ] Definir `.env.example` runtime del stack.
- [ ] Validar imagen/tag oficial OpenClaw antes del primer deploy real.
- [ ] Conectar stack a `infra-net` (sin puertos públicos).
- [ ] Definir `restart: unless-stopped` y `healthcheck`.
- [ ] Definir límites iniciales (`0.25 CPU`, `256MB RAM`) o ajuste acordado.
- [ ] Levantar stack y validar contenedor `Up` en runtime (fase 2).

## Fase 2b - Runtime v1 (systemd, fuera de Docker)

- [x] Validar ejecución funcional manual de `openclaw gateway --allow-unconfigured`.
- [x] Validar integración Slack + proveedor LLM con respuesta real en DM.
- [x] Crear servicio `systemd` de OpenClaw (`openclaw-gateway.service`) bajo usuario `monis`.
- [x] Guardar variables de entorno en archivo seguro (`0600`) consumido por `systemd`.
- [x] Habilitar autoarranque del servicio y validar estado `active (running)`.
- [x] Ajustar modelo persistente a gratuito (`openrouter/free`) para evitar bloqueo por créditos.
- [x] Validar operación estable con Slack Socket Mode conectado y respuesta en DM.

## Punto de pausa (2026-04-02)

- Estado actual:
  - `orchestrator-openclaw` desplegado y estable en `Up`.
  - Slack App `VareIA Bot` instalada, `Socket Mode` activo, eventos DM e interactividad activos.
  - Tokens Slack en `/opt/infra/orchestrator/.env` con permisos `0600`.
  - Mensajería DM llega al bot, pero no hay respuesta por falta de proveedor LLM/API key.
- Siguiente acción al retomar:
  - configurar proveedor inicial (`OpenRouter`) en `/opt/infra/orchestrator/.env` y recrear contenedor.

## Cierre de reanudación (2026-04-03)

- Reanudación completada.
- OpenClaw operativo en modo persistente con `systemd`.
- Modelo en uso: `openrouter/free`.

## Fase 3 - Enrutado y acceso interno

- [ ] Definir endpoint interno para Slack Events y Interactivity.
- [ ] Publicar endpoint solo por canal privado controlado (Tailscale/reverse-proxy según diseño final).
- [ ] Validar roundtrip Slack -> OpenClaw -> Slack.

## Fase 4 - Subagentes y skills (v1)

- [ ] Registrar catálogo de subagentes iniciales en configuración del orquestador.
- [ ] `infra-devops`
- [ ] `automatizaciones-n8n`
- [ ] `producto-roadmap`
- [ ] `frontend-ui`
- [ ] `backend-api`
- [ ] `qa-testing`
- [ ] `code-review`
- [ ] `release-ops`
- [ ] Definir skill/prompt base por subagente.
- [ ] Definir límites de permisos por subagente.

## Fase 5 - Guardrails y auditoría

- [x] Definir lista de acciones sensibles sujetas a confirmación.
- [ ] Implementar flujo de aprobación/rechazo con botones.
- [x] Definir política de expiración de aprobación: sin caducidad automática.
- [x] Definir política de concurrencia de aprobaciones: una pendiente a la vez.
- [x] Definir política de aprobador: solo owner operativo autorizado.
- [x] Definir variable runtime de aprobador único: `OWNER_SLACK_USER_ID` (no versionar valor real).
- [ ] Registrar auditoría mínima: solicitud, aprobador, acción, resultado, timestamp.
- [ ] Definir retención y ubicación de logs de auditoría.

## Fase 6 - Operación

- [ ] Añadir comandos operativos al runbook.
- [ ] Definir checks de salud y alertas del orchestrator.
- [ ] Ejecutar prueba de humo completa.
- [ ] Actualizar `inventory/vps-inventory.md` con estado real.
- [ ] Registrar cambios reales en `changes/CHANGELOG.md`.
