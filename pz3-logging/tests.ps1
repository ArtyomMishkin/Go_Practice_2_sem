# Запустите сервер: .\start-server.ps1

echo "=== GET /health ==="
curl.exe -s -D - http://localhost:8083/health
echo ""

echo "=== GET /students/1 ==="
curl.exe -s -D - http://localhost:8083/students/1
echo ""

echo "=== GET /students/abc (400) ==="
curl.exe -s -w " HTTP:%{http_code}" http://localhost:8083/students/abc
echo ""
echo ""

echo "=== GET /students/999 (404) ==="
curl.exe -s -w " HTTP:%{http_code}" http://localhost:8083/students/999
echo ""
echo ""

echo "=== POST /students ==="
curl.exe -s -D - -X POST http://localhost:8083/students -H "Content-Type: application/json" -d "{\"full_name\":\"Козлов Дмитрий\",\"group\":\"ИТТ-04-25\",\"email\":\"kozlov@example.com\"}"
echo ""

echo "=== POST /students (дубликат email, 409) ==="
curl.exe -s -w " HTTP:%{http_code}" -X POST http://localhost:8083/students -H "Content-Type: application/json" -d "{\"full_name\":\"Test\",\"group\":\"G\",\"email\":\"kozlov@example.com\"}"
echo ""
