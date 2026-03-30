#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/host/vareia-backup.sh [--env-file /opt/infra/.backup.env]
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: required command not found: $1" >&2
    exit 1
  }
}

read_env() {
  local key="$1"
  local file="$2"
  [[ -f "$file" ]] || return 0
  sed -n "s/^${key}=//p" "$file" | tail -n 1
}

json_escape() {
  local value="$1"
  value="$(printf '%s' "$value" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  printf '%s' "$value" | sed ':a;N;$!ba;s/\n/\\n/g'
}

notify_slack() {
  local text="$1"
  [[ -z "${SLACK_WEBHOOK_URL:-}" ]] && return 0
  curl -fsS -X POST -H "Content-Type: application/json" \
    --data "{\"text\":\"$(json_escape "$text")\"}" \
    "$SLACK_WEBHOOK_URL" >/dev/null || true
}

cleanup_tmp() {
  [[ -n "${CURRENT_TMP:-}" && -f "${CURRENT_TMP}" ]] && rm -f -- "${CURRENT_TMP}"
  CURRENT_TMP=""
}

on_error() {
  local exit_code="$?"
  cleanup_tmp
  echo "ERROR: backup failed with exit code $exit_code at stage ${STAGE}"
  notify_slack "[VareIA] Backup FAIL
Host: ${HOSTNAME}
Hora: ${NOW_UTC}
Stage: ${STAGE}
Exit: ${exit_code}
Log: ${LOG_FILE}"
  exit "${exit_code}"
}

on_signal() {
  local sig="$1"
  cleanup_tmp
  echo "ERROR: backup interrupted by signal $sig at stage ${STAGE}"
  notify_slack "[VareIA] Backup INTERRUPTED
Host: ${HOSTNAME}
Hora: ${NOW_UTC}
Stage: ${STAGE}
Signal: ${sig}
Log: ${LOG_FILE}"
  exit 1
}

ENV_FILE="/opt/infra/.backup.env"

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

# shellcheck disable=SC1090
set -a && source "$ENV_FILE" && set +a

BACKUP_ROOT="${BACKUP_ROOT:-/opt/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
ONEDRIVE_SYNC_DIR="${ONEDRIVE_SYNC_DIR:-/home/monis/apps/onedrive-file-sync}"
BACKUP_REMOTE_ROOT="${BACKUP_REMOTE_ROOT:-backups/VareIA}"
BACKUP_POSTGRES_IMAGE="${BACKUP_POSTGRES_IMAGE:-postgres:17}"
HOME_MANAGER_ENV_FILE="${HOME_MANAGER_ENV_FILE:-/opt/infra/home-manager/.env}"
AUTOMATION_ENV_FILE="${AUTOMATION_ENV_FILE:-/opt/infra/automation/.env}"

HM_DIR="$BACKUP_ROOT/home-manager"
N8N_PG_DIR="$BACKUP_ROOT/n8n/postgres"
N8N_DATA_DIR="$BACKUP_ROOT/n8n/data"
LOG_DIR="$BACKUP_ROOT/logs"

TIMESTAMP="$(date -u +%Y%m%d-%H%M%S)"
NOW_UTC="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
HOSTNAME="$(hostname)"
LOG_FILE="$LOG_DIR/backup-$TIMESTAMP.log"
STAGE="init"
CURRENT_TMP=""

require_cmd docker
require_cmd gzip
require_cmd tar
require_cmd sed
require_cmd awk
require_cmd find
require_cmd tee
require_cmd date
require_cmd hostname
require_cmd curl

[[ -d "$ONEDRIVE_SYNC_DIR" ]] || {
  echo "ERROR: missing ONEDRIVE_SYNC_DIR: $ONEDRIVE_SYNC_DIR" >&2
  exit 1
}
[[ -f "$HOME_MANAGER_ENV_FILE" ]] || {
  echo "ERROR: missing HOME_MANAGER_ENV_FILE: $HOME_MANAGER_ENV_FILE" >&2
  exit 1
}
[[ -f "$AUTOMATION_ENV_FILE" ]] || {
  echo "ERROR: missing AUTOMATION_ENV_FILE: $AUTOMATION_ENV_FILE" >&2
  exit 1
}

SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-$(read_env "SLACK_WEBHOOK_URL" "$AUTOMATION_ENV_FILE")}"

umask 077
mkdir -p "$HM_DIR" "$N8N_PG_DIR" "$N8N_DATA_DIR" "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

trap on_error ERR
trap 'on_signal INT' INT
trap 'on_signal TERM' TERM

echo "[$(date -u +%FT%TZ)] Starting backup run"

HM_DATABASE_URL="$(read_env "DATABASE_URL" "$HOME_MANAGER_ENV_FILE")"
[[ -z "$HM_DATABASE_URL" ]] && {
  echo "ERROR: DATABASE_URL missing in $HOME_MANAGER_ENV_FILE"
  exit 1
}

STAGE="home-manager-postgres"
HM_FILE="$HM_DIR/home-manager-$TIMESTAMP.sql.gz"
CURRENT_TMP="$HM_FILE.tmp"
docker run --rm --network infra-net "$BACKUP_POSTGRES_IMAGE" \
  pg_dump --no-owner --no-privileges "${HM_DATABASE_URL%%\?*}" \
  | gzip -9 > "$CURRENT_TMP"
test -s "$CURRENT_TMP"
gzip -t "$CURRENT_TMP"
mv "$CURRENT_TMP" "$HM_FILE"
CURRENT_TMP=""

N8N_HOST="$(read_env "DB_POSTGRESDB_HOST" "$AUTOMATION_ENV_FILE")"
N8N_PORT="$(read_env "DB_POSTGRESDB_PORT" "$AUTOMATION_ENV_FILE")"
N8N_DB="$(read_env "DB_POSTGRESDB_DATABASE" "$AUTOMATION_ENV_FILE")"
N8N_USER="$(read_env "DB_POSTGRESDB_USER" "$AUTOMATION_ENV_FILE")"
N8N_PASS="$(read_env "DB_POSTGRESDB_PASSWORD" "$AUTOMATION_ENV_FILE")"
[[ -z "$N8N_HOST" || -z "$N8N_PORT" || -z "$N8N_DB" || -z "$N8N_USER" || -z "$N8N_PASS" ]] && {
  echo "ERROR: n8n DB config missing in $AUTOMATION_ENV_FILE"
  exit 1
}

STAGE="n8n-postgres"
N8N_PG_FILE="$N8N_PG_DIR/n8n-postgres-$TIMESTAMP.sql.gz"
CURRENT_TMP="$N8N_PG_FILE.tmp"
docker run --rm --network infra-net -e PGPASSWORD="$N8N_PASS" "$BACKUP_POSTGRES_IMAGE" \
  pg_dump -h "$N8N_HOST" -p "$N8N_PORT" -U "$N8N_USER" -d "$N8N_DB" --no-owner --no-privileges \
  | gzip -9 > "$CURRENT_TMP"
test -s "$CURRENT_TMP"
gzip -t "$CURRENT_TMP"
mv "$CURRENT_TMP" "$N8N_PG_FILE"
CURRENT_TMP=""

STAGE="n8n-data-volume"
N8N_DATA_FILE="$N8N_DATA_DIR/n8n-data-$TIMESTAMP.tar.gz"
CURRENT_TMP="$N8N_DATA_FILE.tmp"
N8N_DATA_TMP_BASENAME="${CURRENT_TMP##*/}"
docker run --rm \
  -v n8n-data:/src:ro \
  -v "$N8N_DATA_DIR":/dest \
  alpine:3.20 sh -lc "tar -czf /dest/$N8N_DATA_TMP_BASENAME -C /src ."
test -s "$CURRENT_TMP"
tar -tzf "$CURRENT_TMP" >/dev/null
mv "$CURRENT_TMP" "$N8N_DATA_FILE"
CURRENT_TMP=""

STAGE="onedrive-upload"
NODE_BIN_PATH="$(command -v node || true)"
if [[ -z "$NODE_BIN_PATH" ]]; then
  NODE_BIN_PATH="$(find /home/monis/.nvm/versions/node -maxdepth 4 -type f -path '*/bin/node' 2>/dev/null | sort | tail -n 1)"
fi
[[ -z "$NODE_BIN_PATH" ]] && {
  echo "ERROR: node binary not found"
  exit 1
}

NODE_BIN="$NODE_BIN_PATH" "$ONEDRIVE_SYNC_DIR/run.sh" \
  --local "$HM_FILE" \
  --remote "$BACKUP_REMOTE_ROOT/home-manager/${HM_FILE##*/}"

NODE_BIN="$NODE_BIN_PATH" "$ONEDRIVE_SYNC_DIR/run.sh" \
  --local "$N8N_PG_FILE" \
  --remote "$BACKUP_REMOTE_ROOT/n8n/postgres/${N8N_PG_FILE##*/}"

NODE_BIN="$NODE_BIN_PATH" "$ONEDRIVE_SYNC_DIR/run.sh" \
  --local "$N8N_DATA_FILE" \
  --remote "$BACKUP_REMOTE_ROOT/n8n/data/${N8N_DATA_FILE##*/}"

STAGE="retention"
find "$HM_DIR" -type f -name "*.sql.gz" -mtime +"$RETENTION_DAYS" -delete
find "$N8N_PG_DIR" -type f -name "*.sql.gz" -mtime +"$RETENTION_DAYS" -delete
find "$N8N_DATA_DIR" -type f -name "*.tar.gz" -mtime +"$RETENTION_DAYS" -delete
find "$LOG_DIR" -type f -name "backup-*.log" -mtime +"$RETENTION_DAYS" -delete

echo "[$(date -u +%FT%TZ)] Backup run completed successfully"
notify_slack "[VareIA] Backup OK
Host: ${HOSTNAME}
Hora: ${NOW_UTC}
Resultado: completado + subida OneDrive
Ficheros:
- home-manager: ${HM_FILE##*/}
- n8n-postgres: ${N8N_PG_FILE##*/}
- n8n-data: ${N8N_DATA_FILE##*/}"

