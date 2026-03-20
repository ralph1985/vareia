#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[%s] %s\n' "${SCRIPT_NAME:-script}" "$*"
}

die() {
  printf '[%s] ERROR: %s\n' "${SCRIPT_NAME:-script}" "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

require_docker_access() {
  docker version >/dev/null 2>&1 || die "Docker is not reachable for current user."
}

require_env() {
  local var_name="$1"
  if [[ -z "${!var_name:-}" ]]; then
    die "Missing required env var: ${var_name}"
  fi
}

load_env_file() {
  local env_file="$1"
  [[ -f "${env_file}" ]] || die "Env file not found: ${env_file}"
  # shellcheck disable=SC1090
  set -a && source "${env_file}" && set +a
}

wait_health() {
  local container="$1"
  local retries="${2:-30}"
  local sleep_seconds="${3:-2}"
  local status=""

  for _ in $(seq 1 "${retries}"); do
    status="$(docker inspect -f '{{.State.Health.Status}}' "${container}" 2>/dev/null || true)"
    if [[ "${status}" == "healthy" ]]; then
      log "Container healthy: ${container}"
      return 0
    fi
    sleep "${sleep_seconds}"
  done

  docker ps --filter "name=${container}" --format 'table {{.Names}}\t{{.Status}}'
  die "Container did not become healthy: ${container}"
}

ensure_dir() {
  local dir="$1"
  mkdir -p "${dir}"
}
