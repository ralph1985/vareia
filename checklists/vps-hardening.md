# Checklist Hardening VPS

- [x] Usuario admin no-root creado. (nombre no documentado)
- [ ] Login SSH por contraseña deshabilitado. (condicionado a SSH estable por Tailscale + clave)
- [ ] Login SSH de root deshabilitado (pendiente verificación efectiva con prueba real).
- [ ] Puerto SSH restringido por firewall/IP cuando aplique.
- [ ] UFW/iptables configurado con política por defecto `deny`.
- [ ] Fail2ban instalado y activo (inicialmente solo `sshd`).
- [ ] Fail2ban con `bantime=1h` y `maxretry=5`.
- [ ] Mantener `ignoreip` pendiente hasta disponer de rangos reales.
- [ ] Actualizaciones de seguridad automáticas habilitadas. (decisión: sí, solo seguridad)
- [ ] Ventana de parches automáticos `03:00-05:00` (hora Espana).
- [ ] NTP sincronizado.
- [ ] Swap configurada (si aplica).
- [ ] Alertas básicas de CPU, RAM, disco y uptime configuradas (vía n8n -> Slack).
- [ ] Copias de seguridad automáticas activas.
- [ ] Restore de backup probado al menos una vez.

## Operación de contenedores

- [ ] Crear red `infra-net`.
- [ ] Crear red `proxy-net`.
- [ ] Definir `restart: unless-stopped` en servicios críticos.
- [ ] Definir `healthcheck` en servicios críticos.

## Objetivos de red

- [ ] Instalar y configurar Tailscale.
- [ ] Definir política futura: acceso administrativo solo desde dispositivos autorizados por Tailscale.
