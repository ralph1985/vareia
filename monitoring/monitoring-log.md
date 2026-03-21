# Monitoring Log

## Estrategia definida

- Gestión de alertas: `n8n`.
- Canal de notificación: `Slack`.
- Canal objetivo: `<canal-alertas>`.
- Estado actual: pendiente de implementación (canal/webhook aún no creados).
- Frecuencia de checks técnicos: cada `15 minutos` (modo conservador).
- Checks iniciales:
  - `uptime` VPS
  - uso de disco
  - uso de RAM
  - salud de contenedores críticos (`postgres`, `n8n`, `nginx`)
- Tipos de alerta:
  - Inmediata para caída de contenedor crítico
  - Por umbral para recursos
- Umbrales iniciales:
  - RAM > 85% durante 15 min
  - Disco > 80% durante 15 min
  - CPU > 90% durante 15 min
- Severidades:
  - `warning`: aviso único a canal
  - `critical`: aviso + repetición cada 15 min hasta resolver
- Formato de alertas en Slack:
  - titulo con prefijo de severidad (`[WARNING]` / `[CRITICAL]`)
  - campos minimos: servicio, evento, impacto, timestamp, accion sugerida, enlace a runbook
  - `critical`: abrir hilo de seguimiento hasta cierre
  - sin mencion `@channel` por ahora
- Resumen diario:
  - enviar resumen diario a las `<hora-resumen-diario>`
  - incluir estado general + alertas del dia
- Trazabilidad:
  - incluir enlace a runbook/acción recomendada en cada alerta
  - registrar en este archivo solo eventos `critical`

## Revisión semanal

- Fecha:
- Uptime:
- CPU media:
- RAM media:
- Disco libre:
- Alertas disparadas:
- Acciones tomadas:
- Riesgos identificados:
