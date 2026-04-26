# Remnawave Node — установка одной командой

Приватный репо со встроенным `SECRET_KEY` для конкретной ноды.
Скрипт автоматически:

1. Устанавливает Docker (если его нет) через официальный `get.docker.com`.
2. Создаёт `/opt/remnanode/docker-compose.yml` с `NODE_PORT=2222` и встроенным `SECRET_KEY` (права `600`).
3. Подтягивает образ `remnawave/node:latest` и запускает контейнер.

Никаких промптов — полностью неинтерактивно.

## Установка

Замените `<PAT>` на ваш fine-grained Personal Access Token, выпущенный на этот репо:

```bash
curl -fsSL -H "Authorization: Bearer <PAT>" \
  https://raw.githubusercontent.com/Friizers/remna-node/main/install.sh \
  -o /tmp/remna-install.sh && sudo bash /tmp/remna-install.sh
```

Если уже под root, `sudo` можно убрать.

## Создание PAT

1. https://github.com/settings/personal-access-tokens/new
2. Token name: любое (например, `remna-node-installer`)
3. Resource owner: `Friizers`
4. Repository access: **Only select repositories** → `remna-node`
5. Permissions → Repository permissions → **Contents: Read-only**
6. Generate token, сохраните в менеджере паролей.

Токен переиспользуете на всех нодах с этим SECRET_KEY.

## После установки

```bash
cd /opt/remnanode
docker compose logs -f -t                          # логи
docker compose restart                             # рестарт
docker compose pull && docker compose up -d        # обновление
docker compose down                                # остановить
```

В панели Remnawave: на карточке создаваемой ноды нажмите **Next → Config Profile → Create**.

## Безопасность

- **Закройте `2222` в файрволе ноды**, оставив доступ только с IP панели.
- В `/opt/remnanode/docker-compose.yml` лежит SECRET_KEY → файл создаётся с правами `600`.
- При утечке PAT любой сможет вытащить SECRET_KEY из репо. PAT можно отозвать
  на https://github.com/settings/personal-access-tokens и выпустить новый.

## Если нужно поменять SECRET_KEY или порт

Редактируйте `install.sh` в репо (или передайте через env var на лету):

```bash
sudo NODE_PORT=2333 SECRET_KEY='другой_ключ' bash /tmp/remna-install.sh
```
