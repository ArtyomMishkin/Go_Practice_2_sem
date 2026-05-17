# Практическое задание 3

## ЭФМО-02-25 Мишкин Артём Дмитриевич 17.05.2026

---

# Информация о проекте

**pz3-logging** — HTTP-сервис на Go с structured logging через **zap**.  
Эндпоинты: проверка здоровья и работа со студентами. Все запросы логируются с полями method, path, status_code, duration, request_id.

## Порты

| Сервис | Порт |
|--------|------|
| HTTP API | 8083 |

## Цели занятия

- Настроить structured logging (zap).
- Логировать HTTP-запросы через промежуточный слой.
- Использовать уровни debug, info, warn, error.
- Добавлять контекст в логи: путь, метод, статус, время, request_id.

## Файловая структура

```
pz3-logging/
├── cmd/server/main.go
├── internal/
│   ├── httpapi/
│   │   ├── handler.go
│   │   ├── middleware.go
│   │   └── response_writer.go
│   └── student/
│       ├── model.go
│       └── repo.go
├── pkg/logger/logger.go
├── logs/app.log          # создаётся при запуске
├── start-server.ps1
├── tests.ps1
├── go.mod
└── go.sum
```

## Запуск

```powershell
cd pz3-logging
.\start-server.ps1
.\tests.ps1
```

## Запуск без PowerShell

Из каталога `pz3-logging` (порт **8083**):

```text
go run ./cmd/server
```

Переменные (по желанию), CMD:

```text
set LOG_FILE=logs/app.log
set LOG_LEVEL=info
go run ./cmd/server
```

Linux / macOS:

```text
export LOG_FILE=logs/app.log
export LOG_LEVEL=info
go run ./cmd/server
```

Переменные окружения:

| Переменная | По умолчанию | Назначение |
|------------|--------------|------------|
| `LOG_FILE` | `logs/app.log` | путь к файлу логов |
| `LOG_LEVEL` | `info` | debug / info / warn / error |

## API

| Метод | URL | Описание |
|-------|-----|----------|
| GET | `/health` | статус сервиса |
| GET | `/students/{id}` | студент по ID |
| POST | `/students` | создать студента (JSON body) |

## Дополнительные задания (выполнено)

### Логи в файл

**Как работает:** `pkg/logger` через `zapcore.NewTee` пишет JSON одновременно в **stdout** и в файл `logs/app.log` (путь задаётся `LOG_FILE`). Каталог создаётся автоматически.

### request_id в ответе

**Как работает:** промежуточный слой генерирует ID, кладёт в контекст запроса и в заголовок ответа **`X-Request-ID`**. Тот же ID есть во всех связанных логах — удобно сопоставить запрос и строку в логе.

### Debug в бизнес-логике

**Как работает:** в `repo.GetByID` и `repo.Create` в начале операции пишется уровень отладки с `student_id` или полями входа — видно, что репозиторий реально вызван, до проверки ошибок.

### POST /students

**Как работает:** принимает JSON `{full_name, group, email}`, логирует тело на `Debug`, при пустых полях — `Warn` + 400, при дубликате email — `Warn` + 409, при успехе — `Info` + 201 и JSON созданного студента.

## Уровни логов в проекте

| Уровень | Примеры |
|---------|---------|
| **Отладка** | health, начало операций в репозитории, тело POST |
| **Info** | старт сервера, входящий/завершённый запрос, успешная выдача/создание |
| **Warn** | неверный метод, bad id, валидация, дубликат email |
| **Error** | студент не найден, ошибки чтения тела |

## Сравнение с обычным log

Текстовый `log.Println` даёт одну строку без полей. Zap пишет JSON с ключами — в Kibana/Grafana/Loki можно фильтровать по `student_id`, `status_code`, `request_id` без парсинга текста.
