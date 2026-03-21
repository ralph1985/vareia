# Bootstrap de Host Base

Script para preparar un VPS Ubuntu 24.04 con baseline operativo de VareIA.

## Archivo

- `scripts/bootstrap-host.sh`

## Qué configura

- Paquetes base operativos.
- UFW (`deny incoming`, `allow outgoing`, `allow OpenSSH`).
- Fail2ban para `sshd` (`bantime=1h`, `findtime=10m`, `maxretry=5`).
- `unattended-upgrades` solo seguridad con ventana `03:00-05:00` (Europe/Madrid).
- Docker Engine + plugin `docker compose` desde repo oficial.
- Usuario operativo al grupo `docker`.
- Estructura base en `/opt/infra`.
- Redes Docker `infra-net` y `proxy-net`.
- Opción de instalar Tailscale.

## Uso

```bash
cd /ruta/al/repo/VareIA
sudo ./scripts/bootstrap-host.sh --user monis
```

Con Tailscale:

```bash
sudo ./scripts/bootstrap-host.sh --user monis --with-tailscale
```

## Post-ejecución

Si se instala Tailscale, autenticar nodo:

```bash
sudo tailscale up --ssh
```

Para aplicar el grupo `docker` al usuario:

- Cerrar sesión SSH y volver a entrar.
- O abrir una nueva sesión.

## Alcance y límites

- No deshabilita `PasswordAuthentication` en SSH.
- No configura secretos ni `.env` de stacks.
- No despliega servicios de aplicación (`postgres`, `n8n`, `nginx`, etc.).
