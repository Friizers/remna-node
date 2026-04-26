#!/usr/bin/env bash
# Remnawave Node — one-shot installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Friizers/remna-node/main/install.sh -o /tmp/remna-install.sh \
#     && sudo bash /tmp/remna-install.sh
#
# Optional environment variables (skip prompts):
#   sudo NODE_PORT=2222 SECRET_KEY="eyJ..." bash /tmp/remna-install.sh
#   INSTALL_DIR=/opt/remnanode  (default)

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { printf "${GREEN}[INFO]${NC} %s\n"  "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; }
err()   { printf "${RED}[ERROR]${NC} %s\n"   "$*" >&2; }

# -----------------------------------------------------------------------------
# Require root
# -----------------------------------------------------------------------------
if [[ ${EUID} -ne 0 ]]; then
    err "Скрипт должен запускаться от root."
    err "Запустите так:  sudo bash $0"
    exit 1
fi

# -----------------------------------------------------------------------------
# OS sanity check
# -----------------------------------------------------------------------------
if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    case "${ID:-}${ID_LIKE:-}" in
        *ubuntu*|*debian*) ;;
        *) warn "OS '${PRETTY_NAME:-unknown}' не тестировалась. Продолжаю..." ;;
    esac
fi

INSTALL_DIR="${INSTALL_DIR:-/opt/remnanode}"
NODE_PORT="${NODE_PORT:-}"
SECRET_KEY="${SECRET_KEY:-}"

# -----------------------------------------------------------------------------
# Interactive input (only if not pre-set via env)
# -----------------------------------------------------------------------------
TTY=/dev/tty
if [[ ! -r ${TTY} ]]; then
    TTY=/dev/stdin
fi

if [[ -z ${NODE_PORT} ]]; then
    read -rp "NODE_PORT [2222]: " NODE_PORT <"${TTY}" || true
    NODE_PORT="${NODE_PORT:-2222}"
fi

if ! [[ ${NODE_PORT} =~ ^[0-9]+$ ]] || (( NODE_PORT < 1 || NODE_PORT > 65535 )); then
    err "Некорректный NODE_PORT: ${NODE_PORT}"
    exit 1
fi

if [[ -z ${SECRET_KEY} ]]; then
    echo
    echo "Вставьте SECRET_KEY (значение из docker-compose, всё что внутри кавычек после"
    echo "  - SECRET_KEY=\"...\"  ) и нажмите Enter."
    echo "Ввод скрыт."
    read -rs SECRET_KEY <"${TTY}" || true
    echo
fi

# Strip optional surrounding double-quotes (panel sometimes copies them)
SECRET_KEY="${SECRET_KEY%\"}"
SECRET_KEY="${SECRET_KEY#\"}"

if [[ -z ${SECRET_KEY} ]]; then
    err "SECRET_KEY пуст. Прерываю."
    exit 1
fi

# -----------------------------------------------------------------------------
# Install Docker if missing
# -----------------------------------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
    info "Docker не найден — устанавливаю через get.docker.com..."
    curl -fsSL https://get.docker.com | sh
else
    info "Docker уже установлен ($(docker --version))."
fi

if ! docker compose version >/dev/null 2>&1; then
    err "Docker Compose v2 plugin недоступен. Обновите Docker."
    exit 1
fi

# -----------------------------------------------------------------------------
# Project files
# -----------------------------------------------------------------------------
mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

if [[ -f docker-compose.yml ]]; then
    backup="docker-compose.yml.bak.$(date +%Y%m%d-%H%M%S)"
    warn "Найден существующий docker-compose.yml — копия в ${backup}"
    cp docker-compose.yml "${backup}"
fi

cat > docker-compose.yml <<EOF
services:
  remnanode:
    container_name: remnanode
    hostname: remnanode
    image: remnawave/node:latest
    network_mode: host
    restart: always
    cap_add:
      - NET_ADMIN
    ulimits:
      nofile:
        soft: 1048576
        hard: 1048576
    environment:
      - NODE_PORT=${NODE_PORT}
      - SECRET_KEY="${SECRET_KEY}"
EOF

chmod 600 docker-compose.yml

# -----------------------------------------------------------------------------
# Launch
# -----------------------------------------------------------------------------
info "Подтягиваю образ remnawave/node:latest..."
docker compose pull

info "Запускаю ноду..."
docker compose up -d

sleep 2
docker compose ps

cat <<EOF

$(printf "${GREEN}Готово!${NC}")
  Каталог:     ${INSTALL_DIR}
  Compose:     ${INSTALL_DIR}/docker-compose.yml
  NODE_PORT:   ${NODE_PORT}

Полезные команды:
  cd ${INSTALL_DIR} && docker compose logs -f -t   # смотреть логи
  cd ${INSTALL_DIR} && docker compose restart      # перезапуск
  cd ${INSTALL_DIR} && docker compose pull && docker compose up -d  # обновление

Не забудьте закрыть порт ${NODE_PORT} файрволом на ноде, оставив доступ только с IP панели.
EOF
