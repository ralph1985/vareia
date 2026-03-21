#!/usr/bin/env bash
set -euo pipefail
SCRIPT_NAME="reverse-proxy"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../lib/common.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/stacks/reverse-proxy.sh --env-file ./configs/servers/vareia.env
EOF
}

ENV_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env-file)
      ENV_FILE="${2:-}"
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
load_env_file "${ENV_FILE}"

require_env NGINX_IMAGE
require_env NGINX_MEM_LIMIT
require_env NGINX_CPUS
require_env N8N_HOST
require_env N8N_PORT

NGINX_SERVER_NAMES="${NGINX_SERVER_NAMES:-${N8N_HOST}}"

require_cmd docker
require_docker_access

STACK_DIR="/opt/infra/reverse-proxy"
PROJECT_NAME="reverse-proxy"

ensure_dir "${STACK_DIR}"
ensure_dir "${STACK_DIR}/conf.d"
ensure_dir "${STACK_DIR}/logs"

cat > "${STACK_DIR}/.env" <<EOF
NGINX_IMAGE=${NGINX_IMAGE}
NGINX_MEM_LIMIT=${NGINX_MEM_LIMIT}
NGINX_CPUS=${NGINX_CPUS}
N8N_HOST=${N8N_HOST}
N8N_PORT=${N8N_PORT}
NGINX_SERVER_NAMES=${NGINX_SERVER_NAMES}
EOF

cat > "${STACK_DIR}/.env.example" <<'EOF'
NGINX_IMAGE=nginx:1.28-alpine
NGINX_MEM_LIMIT=256m
NGINX_CPUS=0.25
N8N_HOST=n8n.local
N8N_PORT=5678
NGINX_SERVER_NAMES=n8n.local
EOF

cat > "${STACK_DIR}/nginx.conf" <<'EOF'
user nginx;
worker_processes auto;

error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
  worker_connections 1024;
}

http {
  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                  '$status $body_bytes_sent "$http_referer" '
                  '"$http_user_agent" "$http_x_forwarded_for"';

  access_log /var/log/nginx/access.log main;

  sendfile on;
  keepalive_timeout 65;
  server_tokens off;

  include /etc/nginx/conf.d/*.conf;
}
EOF

cat > "${STACK_DIR}/conf.d/default-deny.conf" <<'EOF'
server {
  listen 8080 default_server;
  server_name _;

  location = /nginx-health {
    add_header Content-Type text/plain;
    return 200 'ok';
  }

  location / {
    return 444;
  }
}
EOF

cat > "${STACK_DIR}/conf.d/n8n-private.conf" <<'EOF'
server {
  listen 8080;
  server_name __SERVER_NAMES__;

  location = /nginx-health {
    add_header Content-Type text/plain;
    return 200 'ok';
  }

  location / {
    proxy_pass http://automation-n8n:__N8N_PORT__;
    proxy_http_version 1.1;

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Connection "";
  }
}
EOF

sed -i \
  -e "s/__SERVER_NAMES__/${NGINX_SERVER_NAMES}/" \
  -e "s/__N8N_PORT__/${N8N_PORT}/" \
  "${STACK_DIR}/conf.d/n8n-private.conf"

cat > "${STACK_DIR}/compose.yml" <<'EOF'
services:
  reverse-proxy-nginx:
    image: ${NGINX_IMAGE}
    container_name: reverse-proxy-nginx
    restart: unless-stopped
    mem_limit: ${NGINX_MEM_LIMIT}
    cpus: ${NGINX_CPUS}
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./conf.d:/etc/nginx/conf.d:ro
      - ./logs:/var/log/nginx
    ports:
      - "127.0.0.1:8080:8080"
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://127.0.0.1:8080/nginx-health >/dev/null 2>&1 || exit 1"]
      interval: 15s
      timeout: 5s
      retries: 10
    networks:
      - proxy-net
      - infra-net

networks:
  proxy-net:
    external: true
    name: proxy-net
  infra-net:
    external: true
    name: infra-net
EOF

log "Rendering stack files in ${STACK_DIR}"
(
  cd "${STACK_DIR}"
  docker compose config >/dev/null
  docker compose --project-name "${PROJECT_NAME}" up -d
)

wait_health "reverse-proxy-nginx" 90 2
log "Reverse proxy stack deployed."
