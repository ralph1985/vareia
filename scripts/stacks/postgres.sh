#!/usr/bin/env bash
set -euo pipefail
SCRIPT_NAME="postgres"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../lib/common.sh"

require_pg_identifier() {
  local value="$1"
  local var_name="$2"
  if [[ ! "${value}" =~ ^[a-z_][a-z0-9_]*$ ]]; then
    die "Invalid PostgreSQL identifier in ${var_name}: '${value}'. Use [a-z0-9_] starting with [a-z_]."
  fi
}

sql_escape_literal() {
  local raw="$1"
  printf '%s' "${raw}" | sed "s/'/''/g"
}

usage() {
  cat <<'EOF'
Usage:
  ./scripts/stacks/postgres.sh --env-file ./configs/servers/vareia.env

Required env vars:
  POSTGRES_IMAGE
  POSTGRES_USER
  POSTGRES_PASSWORD
  POSTGRES_DB
  POSTGRES_TZ
  POSTGRES_MEM_LIMIT
  POSTGRES_CPUS
  APP_N8N_DB_NAME
  APP_N8N_DB_USER
  APP_N8N_DB_PASSWORD
  APP_OPENCLAW_DB_NAME
  APP_OPENCLAW_DB_USER
  APP_OPENCLAW_DB_PASSWORD
EOF
}

ENV_FILE=""
STACK_DIR="/opt/infra/postgres"
PROJECT_NAME="postgres"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env-file)
      ENV_FILE="${2:-}"
      shift 2
      ;;
    --stack-dir)
      STACK_DIR="${2:-}"
      shift 2
      ;;
    --project-name)
      PROJECT_NAME="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

[[ -n "${ENV_FILE}" ]] || die "--env-file is required."
require_cmd docker
require_docker_access
load_env_file "${ENV_FILE}"

require_env POSTGRES_IMAGE
require_env POSTGRES_USER
require_env POSTGRES_PASSWORD
require_env POSTGRES_DB
require_env POSTGRES_TZ
require_env POSTGRES_MEM_LIMIT
require_env POSTGRES_CPUS
require_env APP_N8N_DB_NAME
require_env APP_N8N_DB_USER
require_env APP_N8N_DB_PASSWORD
require_env APP_OPENCLAW_DB_NAME
require_env APP_OPENCLAW_DB_USER
require_env APP_OPENCLAW_DB_PASSWORD

require_pg_identifier "${APP_N8N_DB_NAME}" "APP_N8N_DB_NAME"
require_pg_identifier "${APP_N8N_DB_USER}" "APP_N8N_DB_USER"
require_pg_identifier "${APP_OPENCLAW_DB_NAME}" "APP_OPENCLAW_DB_NAME"
require_pg_identifier "${APP_OPENCLAW_DB_USER}" "APP_OPENCLAW_DB_USER"

APP_N8N_DB_PASSWORD_SQL="$(sql_escape_literal "${APP_N8N_DB_PASSWORD}")"
APP_OPENCLAW_DB_PASSWORD_SQL="$(sql_escape_literal "${APP_OPENCLAW_DB_PASSWORD}")"

ensure_dir "${STACK_DIR}"

cat > "${STACK_DIR}/.env" <<EOF
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=${POSTGRES_DB}
TZ=${POSTGRES_TZ}
EOF
chmod 600 "${STACK_DIR}/.env"

cat > "${STACK_DIR}/.env.example" <<'EOF'
POSTGRES_USER=postgres
POSTGRES_PASSWORD=__SET_STRONG_PASSWORD__
POSTGRES_DB=postgres
TZ=Europe/Madrid
EOF
chmod 644 "${STACK_DIR}/.env.example"

cat > "${STACK_DIR}/compose.yml" <<EOF
services:
  postgres-shared:
    image: ${POSTGRES_IMAGE}
    container_name: postgres-shared
    restart: unless-stopped
    env_file:
      - .env
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - infra-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \$\$POSTGRES_USER -d \$\$POSTGRES_DB"]
      interval: 10s
      timeout: 5s
      retries: 10
    mem_limit: ${POSTGRES_MEM_LIMIT}
    cpus: ${POSTGRES_CPUS}

volumes:
  postgres-data:

networks:
  infra-net:
    external: true
EOF

(
  cd "${STACK_DIR}"
  docker compose --project-name "${PROJECT_NAME}" up -d
)

wait_health "postgres-shared" 60 2

docker exec -i postgres-shared psql -v ON_ERROR_STOP=1 -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" <<EOF
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${APP_N8N_DB_USER}') THEN
    CREATE ROLE ${APP_N8N_DB_USER} LOGIN PASSWORD '${APP_N8N_DB_PASSWORD_SQL}';
  ELSE
    ALTER ROLE ${APP_N8N_DB_USER} WITH LOGIN PASSWORD '${APP_N8N_DB_PASSWORD_SQL}';
  END IF;
END
\$\$;

DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '${APP_N8N_DB_NAME}') THEN
    CREATE DATABASE ${APP_N8N_DB_NAME} OWNER ${APP_N8N_DB_USER};
  END IF;
END
\$\$;

DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${APP_OPENCLAW_DB_USER}') THEN
    CREATE ROLE ${APP_OPENCLAW_DB_USER} LOGIN PASSWORD '${APP_OPENCLAW_DB_PASSWORD_SQL}';
  ELSE
    ALTER ROLE ${APP_OPENCLAW_DB_USER} WITH LOGIN PASSWORD '${APP_OPENCLAW_DB_PASSWORD_SQL}';
  END IF;
END
\$\$;

DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '${APP_OPENCLAW_DB_NAME}') THEN
    CREATE DATABASE ${APP_OPENCLAW_DB_NAME} OWNER ${APP_OPENCLAW_DB_USER};
  END IF;
END
\$\$;
EOF

log "PostgreSQL stack deployed and databases initialized."
