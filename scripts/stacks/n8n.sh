#!/usr/bin/env bash
set -euo pipefail
SCRIPT_NAME="n8n"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../lib/common.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/stacks/n8n.sh --env-file ./configs/servers/vareia.env

Required env vars:
  N8N_IMAGE
  N8N_TZ
  N8N_HOST
  N8N_PORT
  N8N_PROTOCOL
  N8N_EDITOR_BASE_URL
  N8N_WEBHOOK_URL
  N8N_ENCRYPTION_KEY
  N8N_EXECUTIONS_MODE
  N8N_EXECUTIONS_DATA_PRUNE
  N8N_EXECUTIONS_DATA_MAX_AGE
  N8N_MEM_LIMIT
  N8N_CPUS
  APP_N8N_DB_NAME
  APP_N8N_DB_USER
  APP_N8N_DB_PASSWORD
EOF
}

ENV_FILE=""
STACK_DIR="/opt/infra/automation"
PROJECT_NAME="automation"

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

require_env N8N_IMAGE
require_env N8N_TZ
require_env N8N_HOST
require_env N8N_PORT
require_env N8N_PROTOCOL
require_env N8N_EDITOR_BASE_URL
require_env N8N_WEBHOOK_URL
require_env N8N_ENCRYPTION_KEY
require_env N8N_EXECUTIONS_MODE
require_env N8N_EXECUTIONS_DATA_PRUNE
require_env N8N_EXECUTIONS_DATA_MAX_AGE
require_env N8N_MEM_LIMIT
require_env N8N_CPUS
require_env APP_N8N_DB_NAME
require_env APP_N8N_DB_USER
require_env APP_N8N_DB_PASSWORD

ensure_dir "${STACK_DIR}"

cat > "${STACK_DIR}/.env" <<EOF
TZ=${N8N_TZ}
N8N_HOST=${N8N_HOST}
N8N_PORT=${N8N_PORT}
N8N_PROTOCOL=${N8N_PROTOCOL}
N8N_EDITOR_BASE_URL=${N8N_EDITOR_BASE_URL}
WEBHOOK_URL=${N8N_WEBHOOK_URL}
N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
EXECUTIONS_MODE=${N8N_EXECUTIONS_MODE}
N8N_RUNNERS_ENABLED=true
N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
EXECUTIONS_DATA_PRUNE=${N8N_EXECUTIONS_DATA_PRUNE}
EXECUTIONS_DATA_MAX_AGE=${N8N_EXECUTIONS_DATA_MAX_AGE}
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres-shared
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=${APP_N8N_DB_NAME}
DB_POSTGRESDB_USER=${APP_N8N_DB_USER}
DB_POSTGRESDB_PASSWORD=${APP_N8N_DB_PASSWORD}
EOF
chmod 600 "${STACK_DIR}/.env"

cat > "${STACK_DIR}/.env.example" <<'EOF'
TZ=Europe/Madrid
N8N_HOST=n8n.local
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_EDITOR_BASE_URL=http://n8n.local/
WEBHOOK_URL=http://n8n.local/
N8N_ENCRYPTION_KEY=__SET_STRONG_RANDOM_KEY__
EXECUTIONS_MODE=regular
N8N_RUNNERS_ENABLED=true
N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
EXECUTIONS_DATA_PRUNE=true
EXECUTIONS_DATA_MAX_AGE=336
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres-shared
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=app_n8n
DB_POSTGRESDB_USER=usr_n8n
DB_POSTGRESDB_PASSWORD=__SET_DB_PASSWORD__
EOF
chmod 644 "${STACK_DIR}/.env.example"

cat > "${STACK_DIR}/compose.yml" <<EOF
services:
  automation-n8n:
    image: ${N8N_IMAGE}
    container_name: automation-n8n
    restart: unless-stopped
    env_file:
      - .env
    volumes:
      - n8n-data:/home/node/.n8n
    networks:
      - infra-net
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://127.0.0.1:5678/healthz >/dev/null 2>&1 || exit 1"]
      interval: 15s
      timeout: 5s
      retries: 10
    mem_limit: ${N8N_MEM_LIMIT}
    cpus: ${N8N_CPUS}

volumes:
  n8n-data:

networks:
  infra-net:
    external: true
EOF

(
  cd "${STACK_DIR}"
  docker compose --project-name "${PROJECT_NAME}" up -d
)

wait_health "automation-n8n" 90 2
log "n8n stack deployed."
