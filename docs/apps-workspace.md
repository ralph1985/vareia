# Apps Workspace (`~/apps`)

## Objetivo

Definir una convención estable para separar código fuente de runtime en el VPS.

## Alcance

Estas reglas aplican al workspace `~/apps` y a todos los repositorios hijos.
Si existe conflicto con reglas locales, prevalece el `AGENTS.md` del repositorio específico.

## Estructura recomendada

- `~/apps/vareia`: infraestructura, documentación operativa y scripts de despliegue.
- `~/apps/project-manager`: aplicación de gestión (monorepo Lerna).
- `~/apps/<nueva-app>`: cada nueva aplicación en su propio repositorio Git.

## Regla clave: fuente vs runtime

- **Fuente (Git):** `~/apps/*`
- **Runtime (Docker, env reales, logs, volúmenes, stacks):** `/opt/infra/*`

No alojar código fuente de apps en `/opt/infra`.

## Reglas operativas

- Cada app vive en su repo (`~/apps/<repo>`).
- `project-manager` no debe actuar como contenedor de repos de otras apps.
- No usar `~/apps/project-manager/projects` para nuevos repositorios de apps en este servidor.
- Los secretos no se commitean.
- Mantener `.env.example` en el repo y `.env` real en `/opt/infra/<stack>/.env`.

## Flujo sugerido para nuevas apps

1. Clonar repo en `~/apps/<app>`.
2. Definir stack en `/opt/infra/<app>/`.
3. Desplegar con Docker Compose desde `/opt/infra/<app>`.
4. Publicar por reverse-proxy (ruta o subdominio) según política vigente.
