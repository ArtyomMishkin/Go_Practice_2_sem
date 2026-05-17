$root = $PSScriptRoot

Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "Set-Location '$root'; Write-Host 'pz3-logging :8080' -ForegroundColor Green; go run ./cmd/server"
)

Write-Host "Сервер запущен в отдельном окне (:8080). Логи: stdout + logs/app.log"
