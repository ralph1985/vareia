#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/host/heartbeat.sh [--env-file /opt/infra/.heartbeat.env]

Required env vars:
  HEARTBEAT_WEBHOOK_URL
  HEARTBEAT_TOKEN
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: required command not found: $1" >&2
    exit 1
  }
}

json_escape() {
  local value="$1"
  value="$(printf '%s' "$value" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  printf '%s' "$value" | sed ':a;N;$!ba;s/\n/\\n/g'
}

ENV_FILE="/opt/infra/.heartbeat.env"

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
      echo "ERROR: unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

[[ -f "$ENV_FILE" ]] || {
  echo "ERROR: env file not found: $ENV_FILE" >&2
  exit 1
}

require_cmd curl
require_cmd docker
require_cmd hostname
require_cmd uptime
require_cmd free
require_cmd df
require_cmd awk
require_cmd sed

# shellcheck disable=SC1090
set -a && source "$ENV_FILE" && set +a

HEARTBEAT_WEBHOOK_URL="${HEARTBEAT_WEBHOOK_URL:-${N8N_WEBHOOK_URL:-}}"
[[ -n "${HEARTBEAT_WEBHOOK_URL:-}" ]] || {
  echo "ERROR: HEARTBEAT_WEBHOOK_URL is required" >&2
  exit 1
}
[[ -n "${HEARTBEAT_TOKEN:-}" ]] || {
  echo "ERROR: HEARTBEAT_TOKEN is required" >&2
  exit 1
}

HOST="$(hostname)"
TS="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
UPTIME="$(uptime -p)"
RAM="$(free -m | awk '/Mem:/ {printf "%sMB/%sMB (%.1f%%)", $3, $2, ($3/$2)*100}')"
DISK="$(df -h / | awk 'NR==2 {printf "%s/%s (%s)", $3, $2, $5}')"
DOCKER="$(
  docker ps --format '{{.Names}}: {{.Status}}' 2>/dev/null \
  | awk '{printf "- %s\n", $0} END {if (NR==0) print "- sin contenedores"}'
)"

payload="$(
  cat <<EOF
{
  "host":"$(json_escape "$HOST")",
  "timestamp":"$(json_escape "$TS")",
  "uptime":"$(json_escape "$UPTIME")",
  "ram":"$(json_escape "$RAM")",
  "disk":"$(json_escape "$DISK")",
  "docker":"$(json_escape "$DOCKER")"
}
EOF
)"

curl -fsS -X POST "$HEARTBEAT_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -H "X-Heartbeat-Token: $HEARTBEAT_TOKEN" \
  --data "$payload"

