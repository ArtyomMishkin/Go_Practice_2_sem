# pz11-graphql

**Студент:** Артём Мишкин  
**Практическое занятие №11:** GraphQL API на Go (gqlgen)

## Связь с другими практиками

| Практика | Что общего |
|----------|------------|
| **pz7-docker** | Домен **tasks** — список задач по API |
| **pz10-load-balancer** | Тот же сервис tasks, но REST; здесь — **GraphQL**-фасад |
| **pz9-redis-cache** | Кэш задач по ID; GraphQL читает тот же тип сущности |

GraphQL **не дублирует** REST-обработчики: используется общий слой `internal/service` + `internal/store` (как рекомендует методичка — единый repository/service, разные протоколы).

## Цели

- Схема GraphQL: `Task`, `Query`, `Mutation`
- Генерация сервера через **gqlgen**
- Playground для проверки запросов
- Отличие от REST: клиент сам выбирает поля ответа

## Порт

**8094** — Playground `http://localhost:8094/`, endpoint `http://localhost:8094/query`

## Структура

```
pz11-graphql/
├── graph/
│   ├── schema.graphqls
│   ├── schema.resolvers.go
│   ├── generated.go
│   └── model/
├── internal/
│   ├── store/          # in-memory (источник истины для учебки)
│   ├── service/        # общая бизнес-логика
│   └── auth/           # Bearer для mutations
├── cmd/graphql/main.go
├── gqlgen.yml
├── generate.ps1
├── start-server.ps1
└── tests.ps1
```

## Запуск

```powershell
cd pz11-graphql
.\generate.ps1      # после изменения schema.graphqls
.\start-server.ps1
```

Откройте Playground: http://localhost:8094/

## Схема

```graphql
type Task {
  id: ID!
  title: String!
  description: String
  done: Boolean!
}

type Query {
  tasks: [Task!]!
  task(id: ID!): Task
}

type Mutation {
  createTask(input: CreateTaskInput!): Task!
  updateTask(id: ID!, input: UpdateTaskInput!): Task!
  deleteTask(id: ID!): Boolean!
}
```

## Playground — примеры

**Список:**

```graphql
query {
  tasks {
    id
    title
    done
  }
}
```

**Одна задача:**

```graphql
query GetTask($id: ID!) {
  task(id: $id) {
    id
    title
    description
    done
  }
}
```

Variables: `{ "id": "t_001" }`

**Создание** (нужен заголовок `Authorization: Bearer demo-token` в Playground):

```graphql
mutation Create($input: CreateTaskInput!) {
  createTask(input: $input) {
    id
    title
    done
  }
}
```

## Дополнительно: авторизация mutations

- **Query** — без токена  
- **Mutation** — заголовок `Authorization: Bearer demo-token`  

В Playground: вкладка **Headers**:

```json
{
  "Authorization": "Bearer demo-token"
}
```

## Тесты (curl)

```powershell
.\tests.ps1
```

## gqlgen workflow

1. Редактировать `graph/schema.graphqls`
2. `.\generate.ps1`
3. Дописать логику в `graph/schema.resolvers.go` (если generate перезаписал — восстановить вызовы service)
4. `go run ./cmd/graphql`

## GraphQL vs REST (кратко)

| | REST (pz7/pz10) | GraphQL |
|---|-----------------|---------|
| Endpoint | много URL | один `/query` |
| Данные | фиксированный JSON | клиент выбирает поля |
| Over-fetching | возможен | меньше лишних полей |

## Отчёт

- Скрин Playground: `tasks`, `createTask`, `updateTask`
- Схема + сгенерированные файлы
- Пояснение связи с tasks из pz7/pz10
