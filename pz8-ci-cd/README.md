# pz8-ci-cd

**Студент:** Артём Мишкин  
**Практическое занятие №8:** GitHub Actions / GitLab CI для Go backend

## Цели

- Понять разницу **CI** (тесты, сборка) и **CD** (доставка, деплой)
- Настроить автоматический pipeline при push/PR
- Собирать Docker-образы в CI (на GitHub runners)
- Хранить секреты вне репозитория

## На чём строится pipeline

CI настроен для сервисов из **pz7-docker**:

| Сервис | Путь | Порт (runtime) |
|--------|------|----------------|
| auth | `pz7-docker/services/auth` | 8087 |
| tasks | `pz7-docker/services/tasks` | 8088 |

## Файлы CI в корне репозитория

Для работы проекта (практика 8, push на GitHub/GitLab) в **корне** `Go_Practice_2_sem/` должны лежать:

| Файл |
|------|
| `.github/workflows/ci.yml` |
| `.github/workflows/docker-publish.yml` |
| `.gitlab-ci.yml` |

Если их нет — скачай из репозитория и положи в **корень**, не в папку `pz8-ci-cd/`.

```
Go_Practice_2_sem/
├── .github/workflows/ci.yml
├── .github/workflows/docker-publish.yml
├── .gitlab-ci.yml
└── pz8-ci-cd/
```

## Что делает CI (`ci.yml`)

**Job `test-auth` и `test-tasks`** (параллельно):

1. checkout  
2. setup Go 1.22  
3. `go mod tidy`  
4. `go test ./...`  
5. `go build ./...`  

**Job `docker-build`** (после успешных тестов):

- `docker build` для auth и tasks  
- тег образа: `${{ github.sha }}`  

## Дополнительные задания

### Публикация в registry (`docker-publish.yml`)

Запуск вручную из GitHub → **Actions** → **Docker Publish**.

Секреты в **Settings → Secrets**:

| Secret | Назначение |
|--------|------------|
| `REGISTRY_USERNAME` | логин GHCR/Docker Hub |
| `REGISTRY_PASSWORD` | токен |

Образы: `ghcr.io/<owner>/techip-auth:<sha>`, `ghcr.io/<owner>/techip-tasks:<sha>`.

### GitLab CI (`.gitlab-ci.yml`)

Стадии: `test` → `docker`. Тег: `$CI_COMMIT_SHORT_SHA`.

### Деплой на VPS (описание)

После push в registry на сервере:

```bash
docker pull ghcr.io/my-org/techip-tasks:<tag>
cd deploy && docker compose up -d
```

Для учебной сдачи достаточно скриншота успешного job в Actions.

## Локальная проверка (без Docker)

```powershell
cd pz8-ci-cd
.\verify-ci.ps1
```

Повторяет шаги test/build из CI за несколько секунд.

## Запуск на GitHub

1. Закоммитьте и запушьте репозиторий  
2. Откройте вкладку **Actions**  
3. Workflow **CI Pipeline** стартует на `main` / `master` и на PR  

## CI vs CD

| | CI | CD |
|---|----|----|
| Когда | каждый commit/PR | после успешного CI |
| Что | test, build, docker build | push registry, deploy |
| В этой работе | `ci.yml` | `docker-publish.yml` + compose на VPS |

## Секреты — правила

- не коммитить пароли и токены в YAML  
- использовать GitHub Secrets / GitLab Variables  
- не хранить `.env` с секретами в git  

## Типичные ошибки

| Ошибка | Решение |
|--------|---------|
| `go test` падает | добавить unit-тесты, проверить `verify-ci.ps1` |
| неверный путь | `working-directory: pz7-docker/services/tasks` |
| Docker build fail | Dockerfile в каталоге сервиса, контекст сборки = этот каталог |
| pipeline красный без тестов | временно оставить только `go build`, потом вернуть тесты |

## Контрольные вопросы (кратко)

- **Image vs container** — шаблон vs запущенный экземпляр  
- **Зачем CI** — раннее обнаружение поломок, единый стандарт сборки  
- **Secrets** — доступ pipeline к registry/SSH без утечки в код  
- **Тег образа** — `github.sha` / `CI_COMMIT_SHORT_SHA` для трассировки версии  
