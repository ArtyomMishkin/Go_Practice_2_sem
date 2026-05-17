# pz14-job-queue

**Практическое занятие №14:** Очередь задач (издатель–потребитель), повторы, DLQ, идемпотентность

## Связь с pz13

| pz13 | pz14 |
|------|------|
| `task_events` — уведомление | `task_jobs` — **задача на обработку** |
| событие без ожидания результата | повторы + DLQ |
| — | `message_id` — идемпотентность |

## Порты

| Компонент | Порт |
|-----------|------|
| tasks API | **8097** |
| RabbitMQ | 5672 / UI 15672 |

## Очереди

- `task_jobs` — основная (durable, DLX → dlq)
- `task_jobs_dlq` — сообщения после 3 неудачных попыток

## API

```http
POST /v1/jobs/process-task
Authorization: Bearer demo-token
{"task_id": "t_001"}
```

Ответ: `202 Accepted` + `{"status":"accepted","task_id":"..."}`

## Запуск

```powershell
.\start-rabbit.ps1
.\start-worker.ps1
.\start-tasks.ps1
.\tests.ps1
```

## Запуск без PowerShell

Из каталога `pz14-job-queue`. Три терминала — как в pz13.

```text
docker compose -f deploy/rabbit/docker-compose.yml up -d
```

```text
cd services/worker
go run ./cmd/worker
```

```text
cd services/tasks
go run ./cmd/tasks
```

API: http://localhost:8097

## Тесты

- `t_001` — успех, ack
- `t_fail` — 3 retry → DLQ

## JSON job

```json
{
  "job": "process_task",
  "task_id": "t_001",
  "attempt": 1,
  "message_id": "uuid"
}
```

## Дополнительно

- **Предварительная выборка** — `PREFETCH=1` (по умолчанию)
- **Идемпотентность** — повтор с тем же `message_id` пропускается
- **DLQ** — смотреть в http://localhost:15672
