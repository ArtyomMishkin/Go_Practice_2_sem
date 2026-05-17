# pz6-web-security

**Студент:** Артём Мишкин  
**Практическое занятие №6:** Веб-безопасность (CSRF, XSS, безопасные cookie)

## Цели

- Защита от CSRF через токен в форме и проверку на сервере
- Защита от XSS через `html/template` (автоэкранирование)
- Безопасные cookie: `HttpOnly`, `SameSite=Lax`, опционально `Secure`
- Демонстрация небезопасного вывода HTML для сравнения

## Структура

```
pz6-web-security/
├── cmd/server/main.go
├── internal/
│   ├── auth/          # CSRF-токены и session cookie
│   ├── config/        # SERVER_ADDR, SECURE_COOKIE
│   ├── httpapi/       # HTTP-обработчики
│   └── store/         # In-memory профили
├── templates/         # HTML-шаблоны
├── start-server.ps1
└── tests.ps1
```

## Запуск

```powershell
cd pz6-web-security
.\start-server.ps1
```

Откройте в браузере: http://localhost:8086/login

По умолчанию сервер слушает порт **8086** (чтобы не конфликтовать с pz3–pz5 на 8080).

Для cookie с флагом `Secure` (нужен HTTPS):

```powershell
$env:SECURE_COOKIE = "true"
.\start-server.ps1
```

## API / маршруты

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/login` | Создать сессию, выдать cookie, редирект на `/profile` |
| GET | `/logout` | Удалить сессию, очистить cookie |
| GET | `/profile` | Форма редактирования имени |
| POST | `/profile` | Сохранить имя (проверка CSRF) |
| GET | `/hello` | Безопасное приветствие через шаблон |
| GET | `/comments` | Список комментариев |
| POST | `/comments` | Добавить комментарий (проверка CSRF) |
| GET | `/demo/unsafe` | **Учебный** небезопасный HTML (конкатенация строк) |

## Дополнительные задания

### 1. Выход (`GET /logout`)

Удаляет профиль из памяти и сбрасывает cookie (`MaxAge: -1`), затем редирект на `/login`.

### 2. Флаг `Secure` для cookie

Переменная окружения `SECURE_COOKIE=true` включает `Secure` в session cookie. Для локальной работы по HTTP оставьте переменную пустой.

### 3. Ротация CSRF после POST

После успешного `POST /profile` и `POST /comments` генерируется новый CSRF-токен в store — старый токен из формы больше не принимается.

### 4. Страница комментариев

`GET /comments` и `POST /comments` выводят и сохраняют комментарии через шаблон `comments.html`. Даже если в тексте есть `<script>`, браузер покажет его как текст, а не выполнит.

## Сравнение XSS

- **Безопасно:** `/hello`, `/comments` — `html/template`
- **Небезопасно (демо):** `/demo/unsafe?name=...` — конкатенация в HTML

Пример для демонстрации:

```
http://localhost:8086/demo/unsafe?name=<script>alert('xss')</script>
```

На `/hello` то же имя в профиле будет экранировано шаблоном.

## Коды ошибок

| Код | Когда |
|-----|--------|
| 400 | Пустое имя или комментарий, невалидная форма |
| 403 | Неверный CSRF-токен |
| 401 | Сессия не найдена после POST |
| 302 | Редиректы login / logout / успешные POST |
