# ADR-005: Política de expiración de aprobaciones sensibles

- Fecha: 2026-04-02
- Estado: aceptada

## Contexto

OpenClaw v1 requiere confirmación por botones en Slack para acciones sensibles. Se debe definir si esas solicitudes caducan automáticamente.

## Decisión

Las solicitudes de aprobación de acciones sensibles no caducan automáticamente.

## Consecuencias

- La ejecución queda bloqueada hasta recibir `Aprobar` o `Rechazar`.
- Menor riesgo de perder solicitudes por timeout en sesiones largas.
- Se recomienda mostrar en cada solicitud la marca temporal y el contexto de acción para evitar aprobaciones tardías por error.
