# ADR-004: Política de acciones sensibles en OpenClaw v1

- Fecha: 2026-04-02
- Estado: aceptada

## Contexto

OpenClaw operará en modo action-enabled. Se necesita una frontera clara entre acciones permitidas sin fricción y operaciones con riesgo operativo.

## Decisión

Toda acción catalogada como sensible requiere aprobación explícita en Slack mediante botones (`Aprobar` / `Rechazar`) antes de ejecutarse.

## Acciones sensibles (requieren confirmación)

- Deploy y ciclo de vida de servicios:
  - `docker compose up/down/pull/build`
  - `docker restart/stop/rm`
  - cambios de imagen/tag en runtime
- Sistema y servicios del host:
  - `systemctl start/stop/restart/enable/disable`
  - cambios de unidades/timers de `systemd`
- Infra y configuración:
  - escritura/modificación en `/opt/infra/**`
  - cambios en `/etc/**` (ssh, fail2ban, timers, etc.)
  - cambios en proxy/rutas de Nginx
- Red y seguridad:
  - cambios de UFW/iptables/nftables
  - cambios en política de Tailscale Serve/Funnel
  - cambios de puertos expuestos
- Base de datos:
  - `CREATE/ALTER/DROP` de roles, DBs, tablas
  - migraciones con riesgo de pérdida de datos
  - restore de backup sobre entornos activos
- Backups y datos:
  - borrado masivo o poda manual de backups
  - cambios de retención/ruta remota
  - rotación o eliminación de logs críticos
- Secretos y credenciales:
  - creación/rotación/revocación de tokens, claves y contraseñas
  - cambios de `.env` con secretos

## Acciones no sensibles (sin confirmación)

- Lectura de estado y diagnóstico:
  - `docker ps`, `docker logs` (solo lectura), `systemctl status`, `journalctl`
  - checks de CPU/RAM/disco/uptime
- Lectura de documentación y ficheros de inventario/checklists/changelog.
- Propuestas de plan y diff sin aplicar cambios.

## Consecuencias

- Más seguridad y trazabilidad en producción.
- Mayor latencia operativa en acciones de cambio (requieren un paso de aprobación).
