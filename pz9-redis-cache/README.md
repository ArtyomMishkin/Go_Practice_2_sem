# pz9-redis-cache

**Студент:** Артём Мишкин  
**Практическое занятие №9:** Распределённый кэш (Redis), cache-aside

## Цели

- Использовать Redis как внешний кэш (не источник истины)
- Реализовать стратегию **cache-aside**
- Настроить TTL и **jitter**
- Инвалидировать кэш при PATCH/DELETE
- Graceful degradation при недоступности Redis

## Порт

| Сервис | Порт |
|--------|------|
| HTTP API | **8089** |
| Redis | **6379** |

## Структура

```
pz9-redis-cache/
├── cmd/server/main.go
├── internal/
│   ├── cache/       # redis, keys, serializer, ttl
│   ├── config/
│   ├── httpapi/
│   ├── service/     # cache-aside logic
│   └── task/
├── deploy/redis/docker-compose.yml
├── start-redis.ps1
├── start-server.ps1
└── tests.ps1
```

## Запуск

**1. Redis** (нужен Docker):

```powershell
cd pz9-redis-cache
.\start-redis.ps1
```

**2. Сервер:**

```powershell
.\start-server.ps1
```

**3. Тесты:**

```powershell
.\tests.ps1
```

В логах сервера смотрите: `cache hit`, `cache miss`, `cache set`, `cache invalidated`.

## API

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/v1/tasks/{id}` | Задача по ID (кэш `tasks:task:<id>`) |
| GET | `/v1/tasks?page=1&limit=10` | Список (кэш `tasks:list:page=1:limit=10`) |
| PATCH | `/v1/tasks/{id}` | Обновить + инвалидация кэша |
| DELETE | `/v1/tasks/{id}` | Удалить + инвалидация кэша |

## Cache-aside (кратко)

1. Читаем из Redis  
2. **Hit** → отдаём  
3. **Miss** → читаем из in-memory repo  
4. Кладём в Redis с TTL + jitter  
5. При ошибке Redis → только repo (API не падает)

## Ключи Redis

| Ключ | Пример |
|------|--------|
| Задача | `tasks:task:1` |
| Список | `tasks:list:page=1:limit=10` |

## Переменные окружения

| Переменная | По умолчанию |
|------------|--------------|
| `SERVER_ADDR` | `:8089` |
| `REDIS_ADDR` | `localhost:6379` |
| `CACHE_TTL_SEC` | `120` |
| `CACHE_TTL_JITTER_SEC` | `30` |
| `LIST_CACHE_TTL_SEC` | `60` |
| `NEGATIVE_CACHE_TTL_SEC` | `30` |

## Дополнительные задания

### 1. Кэширование списка

`GET /v1/tasks` с query `page` и `limit`, ключ `tasks:list:page=1:limit=10`, TTL короче (60 с).

### 2. Явное логирование

В `task_service.go`: `cache hit`, `cache miss`, `cache set`, `cache invalidated`.

### 3. Key-builder и Serializer

- `internal/cache/keys.go` — `KeyBuilder`  
- `internal/cache/serializer.go` — JSON marshal/unmarshal  

### 4. Отрицательное кеширование

При 404 по ID в Redis кратко сохраняется маркер `__NOT_FOUND__` (TTL ~30 с + jitter), чтобы не долбить repo.

## Проверка без Redis

```powershell
cd deploy\redis
docker compose stop
curl.exe http://localhost:8089/v1/tasks/2
```

Сервис отвечает из репозитория, в логах — предупреждение при старте.

## Отчёт (кратко)

- Redis — ускоритель, не БД  
- TTL — автоочистка устаревших данных  
- Jitter — размазывает одновременное истечение ключей  
- Инвалидация — консистентность после PATCH/DELETE  
