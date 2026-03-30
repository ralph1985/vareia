# Automatización de Despliegue

Este proyecto ya permite automatizar despliegue base + stacks iniciales con scripts idempotentes.

## Flujo recomendado

1. Host base (una vez por VPS):

```bash
sudo ./scripts/bootstrap-host.sh --user <usuario-admin> --with-tailscale
```

2. Preparar variables del servidor:

```bash
cp configs/servers/vareia.example.env configs/servers/vareia-prod.env
vi configs/servers/vareia-prod.env
```

3. Despliegue de stacks iniciales:

```bash
./scripts/run-all.sh --env-file ./configs/servers/vareia-prod.env
```

## Scripts disponibles

- `scripts/stacks/postgres.sh`: crea stack PostgreSQL + credenciales y BDs de apps.
- `scripts/stacks/n8n.sh`: crea stack n8n conectado a PostgreSQL.
- `scripts/stacks/reverse-proxy.sh`: crea stack reverse proxy privado (`reverse-proxy-nginx`) para enrutar a servicios internos.
- `scripts/run-all.sh`: orquesta redes Docker + PostgreSQL + n8n + reverse-proxy.

## Auto-despliegue local de `project-manager` tras `git pull`

Este flujo se implementa en el propio repo `project-manager` y se ejecuta en el VPS.

- Hooks usados: `.githooks/post-merge` y `.githooks/post-rewrite`.
- Script ejecutado por hooks: `scripts/deploy-from-pull.sh`.
- Activación en el repo local:

```bash
cd /home/monis/apps/project-manager
git config core.hooksPath .githooks
```

- Acción al hacer `git pull` con cambios: rebuild/restart del servicio `project-manager` usando `docker compose` en `/opt/infra/project-manager`.
- Log operativo: `/tmp/project-manager-deploy.log`.

## Acceso web privado por Tailscale (permanente)

Una vez desplegado `reverse-proxy`, exponer solo dentro del tailnet:

```bash
sudo tailscale serve --bg --https=443 --set-path / http://127.0.0.1:8080
```

Notas:
- Mantener `80/443` cerrados en UFW mientras no haya dominio público.
- Añadir el FQDN `*.ts.net` del nodo dentro de `NGINX_SERVER_NAMES` para que Nginx acepte ese host.
- Enrutado privado actual recomendado:
  - `/` estado del reverse proxy
  - `/n8n/` interfaz de n8n
  - `/pm/` interfaz de project-manager

## Re-ejecución segura

- Los scripts se pueden ejecutar más de una vez.
- Reaplican configuración de compose y mantienen servicios actualizados.
- En PostgreSQL:
  - crea roles/BBDD si no existen;
  - actualiza password de roles si ya existen.

## Scripts de host versionados (backup + heartbeat)

Fuente versionada en repo:
- `scripts/host/heartbeat.sh`
- `scripts/host/vareia-backup.sh`
- `configs/servers/heartbeat.example.env`
- `configs/servers/backup.example.env`

Despliegue recomendado al runtime del VPS:

```bash
cd /home/monis/apps/vareia

cp configs/servers/heartbeat.example.env configs/servers/heartbeat-prod.env
cp configs/servers/backup.example.env configs/servers/backup-prod.env
vi configs/servers/heartbeat-prod.env
vi configs/servers/backup-prod.env

sudo install -d -m 0755 /opt/infra/scripts
sudo install -m 0700 scripts/host/heartbeat.sh /opt/infra/scripts/heartbeat.sh
sudo install -m 0700 scripts/host/vareia-backup.sh /opt/infra/scripts/vareia-backup.sh

sudo install -m 0600 configs/servers/heartbeat-prod.env /opt/infra/.heartbeat.env
sudo install -m 0600 configs/servers/backup-prod.env /opt/infra/.backup.env
```

Ejecución manual de validación:

```bash
sudo /opt/infra/scripts/heartbeat.sh --env-file /opt/infra/.heartbeat.env
sudo /opt/infra/scripts/vareia-backup.sh --env-file /opt/infra/.backup.env
```

## Política de secretos

- Nunca subir `configs/servers/*.env` reales al repositorio.
- Solo versionar `configs/servers/vareia.example.env`.
