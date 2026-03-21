# Checklist Hardening VPS

- [x] Usuario admin no-root creado. (nombre no documentado)
- [x] Login SSH por contraseña deshabilitado.
- [x] Login SSH de root deshabilitado (verificación efectiva realizada).
- [ ] Puerto SSH restringido por firewall/IP cuando aplique.
- [x] UFW/iptables configurado con política por defecto `deny`.
- [x] Fail2ban instalado y activo (inicialmente solo `sshd`).
- [x] Fail2ban con `bantime=1h` y `maxretry=5`.
- [ ] Mantener `ignoreip` pendiente hasta disponer de rangos reales.
- [x] Actualizaciones de seguridad automáticas habilitadas. (decisión: sí, solo seguridad)
- [x] Ventana de parches automáticos `<ventana-nocturna>`.
- [ ] NTP sincronizado.
- [ ] Swap configurada (si aplica).
- [ ] Alertas básicas de CPU, RAM, disco y uptime configuradas (vía n8n -> Slack).
- [ ] Copias de seguridad automáticas activas.
- [ ] Restore de backup probado al menos una vez.

## Operación de contenedores

- [x] Crear red `infra-net`.
- [x] Crear red `proxy-net`.
- [x] Definir `restart: unless-stopped` en servicios críticos.
- [x] Definir `healthcheck` en servicios críticos.

## Objetivos de red

- [x] Instalar y configurar Tailscale.
- [x] Definir política futura: acceso administrativo solo desde dispositivos autorizados por Tailscale.
