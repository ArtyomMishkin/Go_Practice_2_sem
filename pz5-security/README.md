# Практическое задание 5

## ЭФМО-02-25 Мишкин Артём Дмитриевич 17.05.2026

---

# Информация о проекте

**pz5-security** — HTTPS-сервис на Go с PostgreSQL. Защита транспорта (TLS) и данных (параметризованные SQL-запросы, prepared statements).

## Порты

| Сервис | Порт |
|--------|------|
| HTTP → HTTPS redirect | 8080 |
| HTTPS API | 8443 |
| PostgreSQL | 5432 |

## Быстрый старт

```powershell
cd pz5-security

# 1. База данных
.\start-db.ps1

# 2. TLS-сертификаты (self-signed, через Go)
.\generate-certs.ps1

# 3. Сервер
.\start-server.ps1

# 4. Тесты
.\tests.ps1
```

## API (HTTPS)

| Метод | URL | Описание |
|-------|-----|----------|
| GET | `/health` | проверка сервиса |
| GET | `/students?id=1` | студент по ID (безопасно) |
| GET | `/students/by-email?email=...` | студент по email |
| GET | `/students/unsafe?id=...` | **демо** небезопасного SQL |

Все запросы: `curl -k` (self-signed сертификат).

## Переменные окружения

| Переменная | По умолчанию |
|------------|--------------|
| `HTTPS_ADDR` | `:8443` |
| `HTTP_REDIRECT_ADDR` | `:8080` |
| `TLS_CERT_FILE` | `certs/server.crt` |
| `TLS_KEY_FILE` | `certs/server.key` |
| `DB_DSN` | `postgres://postgres:postgres@localhost:5432/study_security?sslmode=disable` |

## Дополнительные задания (выполнено)

### HTTP → HTTPS редирект (:8080)

**Как работает:** отдельный HTTP-сервер на `:8080` отвечает `301 Moved Permanently` на `https://localhost:8443` + тот же путь. Любой запрос `http://localhost:8080/...` перенаправляется на HTTPS.

### Конфигурация из env

**Как работает:** `internal/config` читает адрес, DSN и пути к сертификатам из переменных окружения. Без env — значения по умолчанию из таблицы выше.

### GET /students/by-email

**Как работает:** email передаётся как query-параметр, проверяется regex (allow-list формата), затем выборка через **prepared statement** с `$1` — инъекция в SQL невозможна.

### Allow-list валидация

**Как работает:** `id` — только положительное целое ≤ 1e9; `email` — проверка regexp и длины ≤ 254. Некорректный ввод → `400 Bad Request` до обращения к БД.

### Демо небезопасного SQL

**Как работает:** `/students/unsafe` склеивает `id` в строку SQL (`UnsafeGetByID`). В ответе видно сформированный запрос — для сравнения с безопасным `/students?id=1`. **В production так делать нельзя.**

## Безопасный vs небезопасный SQL

```go
// ОПАСНО — конкатенация
query := "SELECT ... WHERE id = " + rawID

// БЕЗОПАСНО — placeholder + prepared statement
stmt.QueryRow(id)  // SQL: ... WHERE id = $1
```

## Структура

```
pz5-security/
├── certs/
├── cmd/server/main.go
├── internal/
│   ├── config/
│   ├── httpapi/
│   ├── httpserver/
│   └── student/
├── sql/init.sql
├── docker-compose.yml
├── generate-certs.ps1
├── start-db.ps1
├── start-server.ps1
└── tests.ps1
```

## HTTPS vs HTTP

| HTTP | HTTPS |
|------|-------|
| данные открыты | шифрование TLS |
| порт 8080 (редирект) | порт 8443 (основной API) |
| нет проверки сервера | сертификат server.crt/key |

Self-signed сертификат подходит для учёбы; браузер/curl покажут предупреждение — для curl используйте `-k`.
