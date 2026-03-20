# Automatización de Despliegue

Este proyecto ya permite automatizar despliegue base + stacks iniciales con scripts idempotentes.

## Flujo recomendado

1. Host base (una vez por VPS):

```bash
sudo ./scripts/bootstrap-host.sh --user monis --with-tailscale
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
- `scripts/run-all.sh`: orquesta redes Docker + PostgreSQL + n8n.

## Re-ejecución segura

- Los scripts se pueden ejecutar más de una vez.
- Reaplican configuración de compose y mantienen servicios actualizados.
- En PostgreSQL:
  - crea roles/BBDD si no existen;
  - actualiza password de roles si ya existen.

## Política de secretos

- Nunca subir `configs/servers/*.env` reales al repositorio.
- Solo versionar `configs/servers/vareia.example.env`.
