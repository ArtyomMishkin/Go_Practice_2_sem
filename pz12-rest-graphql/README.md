# pz12-rest-graphql

**Студент:** Артём Мишкин  
**Практическое занятие №12:** Сравнение REST и GraphQL

## Связь с другими практиками

| Практика | Роль |
|----------|------|
| **pz7 / pz10** | REST-сервис **tasks** |
| **pz11** | GraphQL + gqlgen для **Task** |
| **pz12** | **Оба API в одном процессе**, общий `store` + `service` |

Один источник данных — честное сравнение без расхождения между сервисами.

## Цель

Сравнить REST и GraphQL на **одних и тех же** сценариях:

1. Список задач (нужны только `id`, `title`, `done`)
2. Детали задачи (все поля)
3. Создание задачи
4. Обновление `done`
5. Ошибка «не найдено»

## Порт

**8095** — REST и GraphQL на одном сервере:

| API | URL |
|-----|-----|
| REST | `http://localhost:8095/v1/tasks` |
| GraphQL | `http://localhost:8095/graphql` |
| Playground | `http://localhost:8095/` |

## Запуск

```powershell
cd pz12-rest-graphql
.\start-server.ps1
.\tests.ps1
```

## Сценарии сравнения

### 1. Список (over-fetching)

**REST** — всегда полный JSON (`description` тоже):

```powershell
curl.exe http://localhost:8095/v1/tasks
```

**GraphQL** — только нужные поля:

```graphql
query {
  tasks {
    id
    title
    done
  }
}
```

**Вывод:** для списка GraphQL отдаёт меньше лишних данных.

### 2. Детали задачи

**REST:** `GET /v1/tasks/t_001`

**GraphQL:**

```graphql
query ($id: ID!) {
  task(id: $id) {
    id
    title
    description
    done
  }
}
```

### 3. Создание

**REST:**

```powershell
curl.exe -X POST http://localhost:8095/v1/tasks `
  -H "Content-Type: application/json" `
  -d "{\"title\":\"Сравнение REST и GraphQL\",\"description\":\"ПЗ12\"}"
```

**GraphQL:** mutation `createTask` в Playground.

### 4. Обновление

**REST:** `PATCH /v1/tasks/t_001` с `{"done":true}`

**GraphQL:** mutation `updateTask`.

### 5. Ошибки

| Ситуация | REST | GraphQL |
|----------|------|---------|
| Неизвестный id | `404` + `{"error":"task not found"}` | `200` + `"task": null` |

## Итоговая таблица (для отчёта)

| Критерий | REST | GraphQL |
|----------|------|---------|
| Точки входа | Несколько URL | Один `/graphql` |
| Выбор полей | Фиксированный ответ | Клиент выбирает поля |
| Over-fetching | Часто (список с `description`) | Меньше |
| Under-fetching | Несколько запросов при связях | Один запрос |
| Ошибки | HTTP-коды | Часто `200` + `errors[]` |
| Документация | OpenAPI / curl | Схема + Playground |
| Кэширование | Удобно по URL | Сложнее |
| Когда удобнее | CRUD, публичные API | Сложные клиенты, мобильные UI |

## Краткий вывод (шаблон)

- **REST** удобен для простых CRUD, привычен, хорошо кэшируется по URL.
- **GraphQL** удобен, когда клиенту нужны разные наборы полей без лишнего трафика.
- Для учебного **tasks**-сервиса REST проще; GraphQL выигрывает на сценарии «список без description».

## Структура

```
pz12-rest-graphql/
├── cmd/server/main.go      # REST + GraphQL
├── internal/
│   ├── store/              # общие данные
│   ├── service/            # общая логика
│   └── rest/               # REST handlers
├── graph/                  # gqlgen (из pz11)
├── tests.ps1
└── README.md
```

## gqlgen

После изменения `graph/schema.graphqls`:

```powershell
.\generate.ps1
```
