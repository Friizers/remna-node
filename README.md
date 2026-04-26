# Remnawave Node — установка одной командой

Скрипт автоматически:

1. Устанавливает Docker (если его нет) через официальный `get.docker.com`.
2. Спрашивает `NODE_PORT` (по умолчанию `2222`) и `SECRET_KEY` (значение из панели Remnawave).
3. Создаёт `/opt/remnanode/docker-compose.yml` с правами `600`.
4. Подтягивает образ `remnawave/node:latest` и запускает контейнер.

## Установка

Скачайте скрипт и запустите его (нужны права root):

```bash
curl -fsSL https://raw.githubusercontent.com/Friizers/remna-node/main/install.sh -o /tmp/remna-install.sh \
  && sudo bash /tmp/remna-install.sh
```

> Если `sudo` не нужен (вы уже root), уберите его. Не используйте
> `curl ... | bash` — скрипт не сможет прочитать ввод (порт и SECRET_KEY) со stdin.

### Где взять `SECRET_KEY`

В панели Remnawave: **Nodes → Management → + (создать ноду) → Copy docker-compose.yml**.
В скопированном compose найдите строку:

```yaml
      - SECRET_KEY="eyJ..."
```

Значение внутри кавычек — это и есть `SECRET_KEY`. Кавычки можно оставить или убрать,
скрипт их сам отрежет.

## Неинтерактивная установка

Можно передать всё через переменные окружения и не отвечать на вопросы:

```bash
curl -fsSL https://raw.githubusercontent.com/Friizers/remna-node/main/install.sh -o /tmp/remna-install.sh \
  && sudo NODE_PORT=2222 SECRET_KEY='eyJ...' bash /tmp/remna-install.sh
```

## Что после установки

```bash
cd /opt/remnanode
docker compose logs -f -t          # логи
docker compose restart             # рестарт
docker compose pull && docker compose up -d   # обновление до latest
docker compose down                # остановить
```

В панели Remnawave: на карточке создаваемой ноды нажмите **Next → выберите Config Profile → Create**.

## Безопасность

- Закройте `NODE_PORT` (по умолчанию `2222`) в файрволе ноды, оставив доступ только с IP панели.
- Файл `/opt/remnanode/docker-compose.yml` создаётся с правами `600` (читать может только root),
  потому что в нём лежит `SECRET_KEY`.

## Поддерживаемые ОС

Тестировалось на Ubuntu 22.04/24.04 и Debian 12. На других дистрибутивах скрипт сработает,
если на них устанавливается официальный Docker через `get.docker.com`.
