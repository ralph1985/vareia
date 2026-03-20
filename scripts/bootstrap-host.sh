#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  sudo ./scripts/bootstrap-host.sh [--user <linux_user>] [--with-tailscale]

What it does (Ubuntu 24.04):
  - Installs base packages for operations.
  - Configures UFW (deny incoming, allow outgoing, allow OpenSSH).
  - Installs and configures fail2ban for sshd.
  - Enables unattended-upgrades (security updates window 03:00-05:00 Europe/Madrid).
  - Installs Docker Engine + Docker Compose plugin from official Docker repo.
  - Adds the operational user to docker group.
  - Creates base infra directories under /opt/infra.
  - Creates Docker networks infra-net and proxy-net.
  - Optionally installs Tailscale (--with-tailscale).

Notes:
  - This script is idempotent and safe to re-run.
  - It does NOT disable SSH password auth by design.
  - If --with-tailscale is used, you still need to run: sudo tailscale up --ssh
EOF
}

log() {
  printf '[bootstrap] %s\n' "$*"
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Run as root (example: sudo ./scripts/bootstrap-host.sh ...)" >&2
    exit 1
  fi
}

ensure_ubuntu() {
  if [[ ! -f /etc/os-release ]]; then
    echo "Cannot detect OS (/etc/os-release missing)." >&2
    exit 1
  fi
  # shellcheck disable=SC1091
  source /etc/os-release
  if [[ "${ID:-}" != "ubuntu" ]]; then
    echo "Unsupported distro: ${ID:-unknown}. Expected ubuntu." >&2
    exit 1
  fi
  if [[ "${VERSION_CODENAME:-}" != "noble" ]]; then
    log "Warning: tuned for Ubuntu 24.04 (noble). Detected ${VERSION_CODENAME:-unknown}."
  fi
}

install_base_packages() {
  log "Installing base packages..."
  apt-get update -y
  apt-get install -y \
    ca-certificates curl gnupg lsb-release \
    ufw fail2ban \
    unattended-upgrades apt-listchanges
}

configure_ufw() {
  log "Configuring UFW..."
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow OpenSSH
  ufw --force enable
}

configure_fail2ban() {
  log "Configuring fail2ban for sshd..."
  install -d -m 0755 /etc/fail2ban
  cat > /etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
backend = systemd

[sshd]
enabled = true
EOF
  systemctl enable --now fail2ban
  systemctl restart fail2ban
}

configure_unattended_upgrades() {
  log "Configuring unattended-upgrades (security only, 03:00-05:00 Europe/Madrid)..."
  cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

  cat > /etc/apt/apt.conf.d/52unattended-upgrades-vareia <<'EOF'
Unattended-Upgrade::Allowed-Origins {
  "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::Automatic-Reboot "false";
EOF

  install -d -m 0755 /etc/systemd/system/apt-daily-upgrade.timer.d
  cat > /etc/systemd/system/apt-daily-upgrade.timer.d/override.conf <<'EOF'
[Timer]
OnCalendar=
OnCalendar=*-*-* 03:00
RandomizedDelaySec=7200
Persistent=true
EOF
  systemctl daemon-reload
  systemctl restart apt-daily-upgrade.timer
}

install_docker() {
  log "Installing Docker from official repository..."
  install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
  fi

  # shellcheck disable=SC1091
  source /etc/os-release
  cat > /etc/apt/sources.list.d/docker.list <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable
EOF

  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
}

add_user_to_docker_group() {
  local user="$1"
  if id -u "${user}" >/dev/null 2>&1; then
    usermod -aG docker "${user}"
    log "User '${user}' added to docker group (effective on next login)."
  else
    log "Warning: user '${user}' does not exist; skipping docker group assignment."
  fi
}

install_tailscale() {
  log "Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh
  systemctl enable --now tailscaled
  log "Run manually after this script: sudo tailscale up --ssh"
}

create_infra_layout() {
  log "Creating base infra directories..."
  install -d -m 0755 \
    /opt/infra/reverse-proxy \
    /opt/infra/automation \
    /opt/infra/orchestrator \
    /opt/infra/apps \
    /opt/infra/backups/postgres
}

create_docker_networks() {
  log "Creating Docker networks (infra-net, proxy-net)..."
  docker network inspect infra-net >/dev/null 2>&1 || docker network create infra-net >/dev/null
  docker network inspect proxy-net >/dev/null 2>&1 || docker network create proxy-net >/dev/null
}

run_validations() {
  log "Validation summary:"
  printf '  - docker: %s\n' "$(docker --version)"
  printf '  - compose: %s\n' "$(docker compose version)"
  printf '  - docker service: %s\n' "$(systemctl is-active docker)"
  printf '  - fail2ban service: %s\n' "$(systemctl is-active fail2ban)"
  printf '  - ufw status: %s\n' "$(ufw status | head -n1)"
  printf '  - docker networks: %s\n' "$(docker network ls --format '{{.Name}}' | tr '\n' ' ')"
}

TARGET_USER="${SUDO_USER:-}"
WITH_TAILSCALE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user)
      TARGET_USER="${2:-}"
      shift 2
      ;;
    --with-tailscale)
      WITH_TAILSCALE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "${TARGET_USER}" ]]; then
  echo "No target user found. Use --user <linux_user>." >&2
  exit 1
fi

require_root
ensure_ubuntu
install_base_packages
configure_ufw
configure_fail2ban
configure_unattended_upgrades
install_docker
add_user_to_docker_group "${TARGET_USER}"
create_infra_layout
create_docker_networks

if [[ "${WITH_TAILSCALE}" -eq 1 ]]; then
  install_tailscale
fi

run_validations
log "Bootstrap completed."
