#!/usr/bin/env bash
# Remnawave Node — one-shot installer (private repo, key embedded)
# Usage:
#   curl -fsSL -H "Authorization: Bearer <PAT>" \
#     https://raw.githubusercontent.com/Friizers/remna-node/main/install.sh \
#     -o /tmp/remna-install.sh && sudo bash /tmp/remna-install.sh
#
# Optional override:
#   INSTALL_DIR=/opt/remnanode  (default)
#   NODE_PORT and SECRET_KEY env vars override the embedded constants below.

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

# -----------------------------------------------------------------------------
# Embedded constants (override via env vars if needed)
# -----------------------------------------------------------------------------
INSTALL_DIR="${INSTALL_DIR:-/opt/remnanode}"
NODE_PORT="${NODE_PORT:-2222}"
SECRET_KEY="${SECRET_KEY:-eyJub2RlQ2VydFBlbSI6Ii0tLS0tQkVHSU4gQ0VSVElGSUNBVEUtLS0tLVxuTUlJQmVUQ0NBUitnQXdJQkFnSUhBWGR5RlNja1ZEQUtCZ2dxaGtqT1BRUURBakFvTVNZd0pBWURWUVFERXgxNlxuVUVSNlMzWmtkMWQyVmxCMExWWlZOMjVZYjNSa2JuQlZjMlU0TkRBZUZ3MHlOakEwTWpZeE5EVTBNekphRncweVxuT1RBME1qWXhORFUwTXpKYU1DUXhJakFnQmdOVkJBTVRHVWMzYURNM1FraHRTbUpHTVZWSFZFZE1VblZtZEdaa1xuVWtzd1dUQVRCZ2NxaGtqT1BRSUJCZ2dxaGtqT1BRTUJCd05DQUFRdFJxQ0NkaWRNNXYweFU5WUFFdlVsVlNxZlxuam9HVEc4MmpRcGxENklrcUpzVWZ1MXdHN3YrbUp4TmhKR2kzZWFhSlJuZGZFZnpqN3MxdU1tYkk4WmVJb3pnd1xuTmpBTUJnTlZIUk1CQWY4RUFqQUFNQTRHQTFVZER3RUIvd1FFQXdJRm9EQVdCZ05WSFNVQkFmOEVEREFLQmdnclxuQmdFRkJRY0RBVEFLQmdncWhrak9QUVFEQWdOSUFEQkZBaUE5RjRFOWFLOWxtV2hIRmQxRU1KSnpVTHBPTldUOVxuZlVRaXVFa2thMlg0L2dJaEFNN2ZDOSsyNWc1ZFM3WUt2bEF2NEhBVUFISlJGRzh0aFUxVFlvczBqV0owXG4tLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tIiwibm9kZUtleVBlbSI6Ii0tLS0tQkVHSU4gUFJJVkFURSBLRVktLS0tLVxuTUlHSEFnRUFNQk1HQnlxR1NNNDlBZ0VHQ0NxR1NNNDlBd0VIQkcwd2F3SUJBUVFnRXlQZkpQYWtSZ1VkWmlIWlxub2kvdEF2MDRuQmNjbno3Vng5WTk3ZStpMUJlaFJBTkNBQVF0UnFDQ2RpZE01djB4VTlZQUV2VWxWU3Fmam9HVFxuRzgyalFwbEQ2SWtxSnNVZnUxd0c3dittSnhOaEpHaTNlYWFKUm5kZkVmemo3czF1TW1iSThaZUlcbi0tLS0tRU5EIFBSSVZBVEUgS0VZLS0tLS0iLCJjYUNlcnRQZW0iOiItLS0tLUJFR0lOIENFUlRJRklDQVRFLS0tLS1cbk1JSUJZVENDQVFpZ0F3SUJBZ0lCQVRBS0JnZ3Foa2pPUFFRREFqQW9NU1l3SkFZRFZRUURFeDE2VUVSNlMzWmtcbmQxZDJWbEIwTFZaVk4yNVliM1JrYm5CVmMyVTROREFlRncweU5qQXpNakl3TnpBME1UTmFGdzB6TmpBek1qSXdcbk56QTBNVE5hTUNneEpqQWtCZ05WQkFNVEhYcFFSSHBMZG1SM1YzWldVSFF0VmxVM2JsaHZkR1J1Y0ZWelpUZzBcbk1Ga3dFd1lIS29aSXpqMENBUVlJS29aSXpqMERBUWNEUWdBRTcyLzdqZ2VyYlNwQmIxbzF5aWVLeEpLUXdIdzZcbklEdGxOdysvWlc5VXhjeW12WG81VkVTQVk0NFkxbmRwT1NEbDBSV3BoMlRjYlpubTkrcW5EU2tMQnFNak1DRXdcbkR3WURWUjBUQVFIL0JBVXdBd0VCL3pBT0JnTlZIUThCQWY4RUJBTUNBb1F3Q2dZSUtvWkl6ajBFQXdJRFJ3QXdcblJBSWdFMjZraThhSUtEdVFBaWR0SFF1NW1wS2VXWkYyYWIrcHN5aE9TM0NlNXI4Q0lGRFdldkhSa09YNDBIUkxcbmJ5ZGFnT1F5a3lsMFJoWmhLeXpKUHNuUVBxaVdcbi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0iLCJqd3RQdWJsaWNLZXkiOiItLS0tLUJFR0lOIFBVQkxJQyBLRVktLS0tLVxuTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUF0Nms5Z1ZFUGhNUlZNOTRQc1hKWlxuSHZKRVo2dnBTWjJFd3Y3NVJseHZ6UndEdzl6MFZORjcxMDZ5cjkxR0J3bVQ2eFBvRXhGdHo1cDNnQzJQZWtWVVxuaTJYSGg4Nm9ic3daZ1BkNUsyRDNnQmVlcUNzdkJEYWtVa0wwalN6UDFJR25sRHBUYzdPQ29CN1pRek5DZ2JBdFxueE16VVNTVG9jRFRXVGtuSzJROEhOM1Jhcm56Q0pnQ1hOMXBUSUdrakIxWUxhMU4vQS8xTzBaelhvUWdCZk1WU1xucmpObVlRT0dRTzY4RTV4eTljRlBDYTBRb3E1RlV0SXlZcDNpaVliMVByUHlBSFQrUEVGRmVQa0VDdi85RlVhYVxuR0M3YmdtUnRURFYzYkUzd1lIcEdCdzZIa0djSWhRNjFmM1B0MmxZZlR5Q1dRWnQyU2FYTU5hTGxaNUhTUkdwL1xuK3dJREFRQUJcbi0tLS0tRU5EIFBVQkxJQyBLRVktLS0tLVxuIn0=}"

if ! [[ ${NODE_PORT} =~ ^[0-9]+$ ]] || (( NODE_PORT < 1 || NODE_PORT > 65535 )); then
    err "Некорректный NODE_PORT: ${NODE_PORT}"
    exit 1
fi

if [[ -z ${SECRET_KEY} ]]; then
    err "SECRET_KEY пуст."
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
