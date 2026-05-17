echo "=== GET /health ==="
curl.exe -s http://localhost:8080/health
echo ""

echo "=== GET /students/1 ==="
curl.exe -s http://localhost:8080/students/1
echo ""

echo "=== GET /students/999 (404) ==="
curl.exe -s -w " HTTP:%{http_code}" http://localhost:8080/students/999
echo ""
echo ""

echo "=== GET /metrics (первые строки) ==="
curl.exe -s http://localhost:8080/metrics | Select-String "app_http"
