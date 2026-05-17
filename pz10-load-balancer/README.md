# pz10-load-balancer

**Студент:** Артём Мишкин  
**Практическое занятие №10:** Горизонтальное масштабирование, NGINX Load Balancer

## Цели

- Запустить несколько реплик одного stateless-сервиса
- Настроить **upstream** в NGINX (round-robin)
- Проверить балансировку по заголовку `X-Instance-ID`
- Реализовать `GET /health` для проверки живости

## Порты

| Компонент | Порт | Описание |
|-----------|------|----------|
| NGINX (вход) | **8090** | Единая точка входа |
| tasks-1 | 8091 | Локально без Docker |
| tasks-2 | 8092 | Локально без Docker |
| tasks-3 | 8093 | Локально без Docker |
| tasks в Docker | 8082 | Внутри сети compose |

> Внешний порт **8090** вместо 8080 — чтобы не конфликтовать с pz3–pz5.

## Структура

```
pz10-load-balancer/
├── services/tasks/          # stateless tasks API
├── deploy/lb/
│   ├── nginx.conf
│   └── docker-compose.yml   # tasks_1, tasks_2, tasks_3 + nginx
├── start-instances.ps1      # 3 процесса без Docker
├── start-compose.ps1        # NGINX + 3 контейнера
├── tests-instances.ps1
└── tests-lb.ps1
```

## API (каждая реплика)

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/health` | `{"status":"ok","instance":"tasks-1"}` + `X-Instance-ID` |
| GET | `/whoami` | `{"instance":"tasks-1"}` |
| GET | `/v1/tasks` | Список задач + `X-Instance-ID` |

Переменные: `INSTANCE_ID`, `APP_PORT`.

## Запуск без Docker (локально)

```powershell
cd pz10-load-balancer
.\start-instances.ps1
.\tests-instances.ps1
```

В логах каждого окна — `instance=tasks-N method=...` (логирование запросов).

## Запуск с Docker + NGINX

```powershell
.\start-compose.ps1
.\tests-lb.ps1
.\stop-compose.ps1
```

Проверка round-robin:

```powershell
1..10 | ForEach-Object { curl.exe -s -D - http://localhost:8090/whoami -o NUL | Select-String "X-Instance-ID" }
```

Должны чередоваться `tasks-1`, `tasks-2`, `tasks-3`.

## Проверка отказоустойчивости

```powershell
cd deploy\lb
docker compose stop tasks_1
# снова tests-lb.ps1 — только tasks-2 и tasks-3
docker compose start tasks_1
```

## NGINX upstream

```nginx
upstream tasks_backend {
    server tasks_1:8082;
    server tasks_2:8082;
    server tasks_3:8082;
}
```

`proxy_pass` проксирует `Authorization`, `X-Request-ID`, `X-Forwarded-For`.

## Дополнительные задания

### 1. Третья реплика tasks-3

В `docker-compose.yml` и `nginx.conf` добавлен `tasks_3`.

### 2. Логирование входящих запросов

Middleware в `cmd/server/main.go` пишет `instance`, method, path, remote, duration.

### 3. GET /whoami

Отдельный endpoint для проверки, какой инстанс ответил.

### 4. Shared-state (конспект)

Для горизонтального масштабирования сервис должен быть **stateless**:

- данные — в общей БД или Redis (см. pz9-redis-cache);
- in-memory состояние в одной реплике ломает балансировку;
- сессии — во внешнем хранилище, не в памяти процесса.

## CI vs отчёт

- Скриншоты: `docker compose ps`, curl с разными `X-Instance-ID`
- Stateless: одна и та же задача с любой реплики

## Контрольные вопросы (кратко)

| Вопрос | Ответ |
|--------|--------|
| Вертикальное vs горизонтальное | Больше CPU/RAM vs больше реплик |
| Зачем LB | Одна точка входа, распределение нагрузки |
| Upstream | Группа backend-серверов за NGINX |
| Stateless | Нет локальной сессии — любая реплика может ответить |
| X-Instance-ID | Видно, какой инстанс обработал запрос |
