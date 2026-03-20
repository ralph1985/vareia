#!/usr/bin/env bash
set -euo pipefail
SCRIPT_NAME="run-all"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/run-all.sh --env-file ./configs/servers/vareia.env

What it does:
  1) Verifies Docker access.
  2) Ensures Docker networks infra-net/proxy-net.
  3) Deploys PostgreSQL stack.
  4) Deploys n8n stack.
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
require_cmd docker
require_docker_access

log "Ensuring Docker networks..."
docker network inspect infra-net >/dev/null 2>&1 || docker network create infra-net >/dev/null
docker network inspect proxy-net >/dev/null 2>&1 || docker network create proxy-net >/dev/null

log "Deploying PostgreSQL stack..."
"${SCRIPT_DIR}/stacks/postgres.sh" --env-file "${ENV_FILE}"

log "Deploying n8n stack..."
"${SCRIPT_DIR}/stacks/n8n.sh" --env-file "${ENV_FILE}"

log "Done. Current stack status:"
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
