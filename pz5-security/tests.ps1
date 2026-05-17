# Нужны: PostgreSQL (.\start-db.ps1), сертификаты, .\start-server.ps1

echo "=== HTTPS health ==="
curl.exe -k -s https://localhost:8443/health
echo ""

echo "=== HTTP redirect -> HTTPS ==="
curl.exe -s -o NUL -w "HTTP:%{http_code} -> %{redirect_url}" http://localhost:8080/health
echo ""
echo ""

echo "=== GET /students?id=1 (safe, prepared) ==="
curl.exe -k -s "https://localhost:8443/students?id=1"
echo ""

echo "=== GET /students?id=999 (404) ==="
curl.exe -k -s -w " HTTP:%{http_code}" "https://localhost:8443/students?id=999"
echo ""
echo ""

echo "=== GET /students/by-email?email=ivanov@example.com ==="
curl.exe -k -s "https://localhost:8443/students/by-email?email=ivanov@example.com"
echo ""

echo "=== GET /students/by-email invalid email (400) ==="
curl.exe -k -s -w " HTTP:%{http_code}" "https://localhost:8443/students/by-email?email=not-an-email"
echo ""
echo ""

echo "=== UNSAFE demo /students/unsafe?id=1 ==="
curl.exe -k -s "https://localhost:8443/students/unsafe?id=1"
echo ""
