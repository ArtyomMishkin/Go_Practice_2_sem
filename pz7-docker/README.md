# pz7-docker

**Студент:** Артём Мишкин  
**Практическое занятие №7:** Docker, Dockerfile (multi-stage), docker-compose

## Цели

- Собрать Go-сервисы в Docker-образы (builder + runner)
- Передавать конфигурацию через переменные окружения
- Запускать связку **auth** + **tasks** через `docker compose`
- Понять разницу между image и container, роль `.dockerignore`

## Порты (диапазон 8080–8100)

| Сервис | Порт | Назначение |
|--------|------|------------|
| auth | **8087** | Проверка Bearer-токена |
| tasks | **8088** | Список задач (с вызовом auth) |

> pz1 уже использует 8081/8082, pz6 — 8086. Здесь отдельные порты, чтобы практики не мешали друг другу.

## Структура

```
pz7-docker/
├── services/
│   ├── auth/          # GET /health, GET /v1/validate
│   └── tasks/         # GET /health, GET /v1/tasks
├── deploy/
│   └── docker-compose.yml
├── start-compose.ps1
├── stop-compose.ps1
├── build-images.ps1
├── start-local.ps1
└── tests.ps1
```

## Запуск через Docker Compose (рекомендуется)

Нужен установленный [Docker Desktop](https://www.docker.com/products/docker-desktop/).

```powershell
cd pz7-docker
.\start-compose.ps1
.\tests.ps1
.\stop-compose.ps1
```

Проверка вручную:

```powershell
curl.exe -i http://localhost:8088/v1/tasks `
  -H "Authorization: Bearer demo-token" `
  -H "X-Request-ID: pz7-001"
```

## Локальный запуск без Docker

```powershell
.\start-local.ps1
.\tests.ps1
```

## Сборка образов вручную

```powershell
.\build-images.ps1
docker run --rm -p 8087:8087 -e AUTH_PORT=8087 techip-auth:0.1
docker run --rm -p 8088:8088 -e TASKS_PORT=8088 -e AUTH_BASE_URL=http://host.docker.internal:8087 techip-tasks:0.1
```

На Windows `host.docker.internal` позволяет контейнеру tasks обращаться к auth на хосте.

## API

### auth (:8087)

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/health` | Проверка живости |
| GET | `/v1/validate` | Заголовок `Authorization: Bearer demo-token` → 200 |

Переменные: `AUTH_PORT`, `AUTH_VALID_TOKEN`, `LISTEN_ADDRESS`.

### tasks (:8088)

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/health` | Проверка живости |
| GET | `/v1/tasks` | Список задач; нужны `Authorization` и опционально `X-Request-ID` |

Переменные: `TASKS_PORT`, `AUTH_BASE_URL`, `LISTEN_ADDRESS`.

В compose: `AUTH_BASE_URL=http://auth:8087` — обращение по имени сервиса в docker-сети, не через `localhost`.

## Dockerfile (multi-stage)

1. **builder** — `golang:alpine`, `go mod download`, сборка бинарника  
2. **runner** — `alpine`, только бинарник + CA-сертификаты, `CMD ["./app"]`

Секреты и URL **не** зашиваются в образ — только через `ENV` / compose.

## Дополнительно

- **Healthcheck** в `docker-compose.yml` для auth и tasks (`wget /health`)
- **`depends_on`** — tasks стартует после healthy auth
- **`.dockerignore`** — не копировать `.git`, `bin`, логи в контекст сборки
- **`LISTEN_ADDRESS=0.0.0.0`** — иначе порт не пробросится с хоста в контейнер

## Типичные проблемы

| Проблема | Решение |
|----------|---------|
| `connection refused` к auth из tasks | В compose использовать `http://auth:8087`, не `localhost` |
| Порт занят | Остановить другой сервис или сменить маппинг в compose |
| Долгая пересборка | Проверить `.dockerignore`, собирать из каталога сервиса |
| 401 на tasks | Токен `Bearer demo-token` (или `AUTH_VALID_TOKEN`) |

## Отчёт (кратко)

- **Image** — шаблон (слои файловой системы + метаданные)  
- **Container** — запущенный экземпляр image  
- **Multi-stage** — маленький финальный образ без компилятора Go  
- **Сеть Docker** — сервисы видят друг друга по имени (`auth`, `tasks`)
