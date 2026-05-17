# pz13-rabbitmq

**Студент:** Артём Мишкин  
**Практическое занятие №13:** RabbitMQ — публикация и потребление событий

## Связь с другими практиками

| Практика | Связь |
|----------|--------|
| **pz7** | Сервис **tasks**, Bearer `demo-token`, `X-Request-ID` |
| **pz10** | Тот же домен задач |
| **pz13** | После `POST /v1/tasks` → событие в очередь → **worker** |

Поток: **HTTP синхронно** создаёт задачу → **асинхронно** worker обрабатывает событие.

## Цели

- Producer (tasks) публикует `task.created` в очередь `task_events`
- Consumer (worker) читает, логирует, отправляет **ack**
- **durable** queue + **persistent** messages
- **prefetch** (по умолчанию 1)

## Порты

| Компонент | Порт |
|-----------|------|
| tasks HTTP | **8096** |
| RabbitMQ AMQP | **5672** |
| RabbitMQ UI | **15672** (guest / guest) |

## Структура

```
pz13-rabbitmq/
├── deploy/rabbit/docker-compose.yml
├── pkg/events/              # JSON-события
├── internal/publisher/
├── services/tasks/          # producer
├── services/worker/         # consumer
├── start-rabbit.ps1
├── start-worker.ps1
├── start-tasks.ps1
└── tests.ps1
```

## Запуск (3 шага)

**1. RabbitMQ** (нужен Docker):

```powershell
.\start-rabbit.ps1
```

**2. Worker** (отдельное окно):

```powershell
.\start-worker.ps1
```

**3. Tasks** (ещё одно окно):

```powershell
.\start-tasks.ps1
```

**4. Тест:**

```powershell
.\tests.ps1
```

В логах worker:

```
received event=task.created task_id=t_001 ts=... request_id=pz13-001
```

## Формат события (JSON)

```json
{
  "event": "task.created",
  "task_id": "t_001",
  "ts": "2026-05-17T12:00:00Z",
  "request_id": "pz13-001",
  "producer": "tasks-service",
  "version": "1"
}
```

## API tasks

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/health` | Проверка |
| POST | `/v1/tasks` | Создать задачу + опубликовать событие |

Заголовки: `Authorization: Bearer demo-token`, `X-Request-ID`.

## Дополнительно

### Режим публикации (`PUBLISH_MODE`)

| Значение | Поведение |
|----------|-----------|
| `best_effort` (по умолчанию) | Задача создана, ошибка publish только в лог |
| `strict` | HTTP 500, если не удалось опубликовать |

```powershell
$env:PUBLISH_MODE = "strict"
.\start-tasks.ps1
```

### Prefetch

```powershell
$env:PREFETCH = "5"
.\start-worker.ps1
```

## RabbitMQ Management

http://localhost:15672 — очередь `task_events`, сообщения, consumers.

## Переменные окружения

| Переменная | По умолчанию |
|------------|--------------|
| `SERVER_ADDR` | `:8096` |
| `RABBIT_URL` | `amqp://guest:guest@localhost:5672/` |
| `QUEUE_NAME` | `task_events` |
| `PUBLISH_MODE` | `best_effort` |
| `PREFETCH` | `1` |

## Отчёт (кратко)

- **Producer** — tasks после успешного POST  
- **Consumer** — отдельный worker  
- **ack** — сообщение не теряется при сбое до ack  
- **durable + persistent** — переживают перезапуск RabbitMQ  

## Осталось по курсу

Практики **14, 15, 16** — пришли docx, сделаем по тому же шаблону.
