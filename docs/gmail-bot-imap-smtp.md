# Gmail Bot en VPS (Opcion 1: IMAP primero, SMTP despues)

Objetivo: permitir que el VPS de VareIA lea y envie correo con la cuenta `vareia.bot@gmail.com` sin usar password principal ni secretos en Git.

## Alcance

- Integracion vigente por `IMAP` (lectura).
- `SMTP` (envio) aplazado para una fase posterior.
- Credenciales mediante `App Password` de Google.
- Ejecucion en `n8n` como punto de entrada de automatizaciones por correo.

## Prerrequisitos

- Cuenta creada: `vareia.bot@gmail.com`.
- Acceso a la cuenta Google para configurar seguridad.
- `n8n` operativo en el VPS.

## Estado actual (2026-04-06)

- `IMAP` operativo con credencial `gmail-bot-imap` en `n8n`.
- Workflow activo: `leer-correos-imap`.
- Flujo activo actual: lectura de todos los correos de `INBOX` + notificación a Slack.
- Modo actual sin filtros de remitente/asunto/token (pendiente endurecimiento).
- `SMTP` sigue aplazado.

## Flujo completo (paso a paso)

1. Endurecer la cuenta Google del bot.
   - Activar verificacion en dos pasos (2FA).
   - Guardar metodos de recuperacion de la cuenta en lugar seguro.
2. Activar IMAP en Gmail.
   - Gmail -> Settings -> See all settings -> Forwarding and POP/IMAP -> Enable IMAP.
3. Crear App Password.
   - Google Account -> Security -> App passwords.
   - Nombre sugerido: `vareia-vps-n8n-mail`.
   - Copiar el valor generado (16 caracteres). Solo se muestra una vez.
4. Preparar secretos en VPS (fuera de Git).
   - Crear archivo runtime: `/opt/infra/.gmail-bot.env`.
   - Permisos: `0600`.
   - Owner recomendado: `root:root` o usuario operativo segun politica local.
5. Cargar credencial IMAP en `n8n`.
   - Crear credencial IMAP:
     - Host: `imap.gmail.com`
     - Port: `993`
     - Secure: `true` (SSL/TLS)
     - User: `vareia.bot@gmail.com`
     - Password: App Password
6. Construir workflow base en n8n.
   - Trigger por IMAP polling (cada 1-5 minutos).
   - Filtro por remitente permitido (allowlist).
   - Filtro por formato de asunto (por ejemplo: `[VAREIA-CMD]`).
   - Validacion de token/palabra compartida en cuerpo.
   - Enrutado:
     - acciones no sensibles: ejecutar flujo normal.
     - acciones sensibles: enviar a flujo de aprobacion (OpenClaw/politica vigente).
7. Validar extremo a extremo.
   - Enviar correo de prueba desde remitente permitido.
   - Confirmar deteccion en n8n.
   - Confirmar ejecucion de filtros.
8. Operacion continua.
   - Rotar App Password periodicamente.
   - Actualizar credenciales en n8n tras cada rotacion.
   - Registrar cambios en `changes/CHANGELOG.md`.

## Archivo de entorno recomendado

Plantilla versionada (sin secretos):
- `configs/servers/gmail-bot.example.env`

Ruta runtime real (secreto, no versionar):
- `/opt/infra/.gmail-bot.env`

Despliegue sugerido:

```bash
cd /home/monis/apps/vareia
cp configs/servers/gmail-bot.example.env configs/servers/gmail-bot-prod.env
vi configs/servers/gmail-bot-prod.env
sudo install -m 0600 configs/servers/gmail-bot-prod.env /opt/infra/.gmail-bot.env
```

## Valores tecnicos de referencia (fase actual)

- IMAP host: `imap.gmail.com`
- IMAP port: `993`
- IMAP TLS/SSL: obligatorio

## SMTP (fase posterior)

- SMTP host: `smtp.gmail.com`
- SMTP port: `465`
- TLS/SSL: obligatorio
- Se habilitara cuando se necesite envio de respuestas por correo.

## Checklist de cierre

- [ ] 2FA activa en `vareia.bot@gmail.com`.
- [ ] IMAP activado en Gmail.
- [ ] App Password creada y guardada en almacen seguro.
- [ ] `/opt/infra/.gmail-bot.env` creado en VPS con `0600`.
- [ ] Credencial IMAP creada en n8n y test OK.
- [ ] Workflow base de correo desplegado con allowlist + token.
- [ ] Flujo de aprobacion para acciones sensibles conectado.
- [ ] Prueba E2E (entrada + procesamiento) completada.
- [ ] Rotacion de App Password planificada.
- [ ] (Posterior) Credencial SMTP creada en n8n y test OK.

## Politica de seguridad

- No commitear App Password ni tokens en este repositorio.
- No ejecutar acciones sensibles directamente desde correo sin aprobacion explicita.
- Mantener lista blanca de remitentes y validar patron de asunto/comando.
- Aplicar rate limit y anti-loop en el workflow de correo.
