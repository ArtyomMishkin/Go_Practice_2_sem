# Запустите user-service (:8081) и order-service (:8082), затем:
# cd "c:\Github\Go_Practice_2_sem\pz1-microservices"
# .\tests.ps1

echo "=== GET /users ==="
curl.exe -s http://localhost:8081/users
echo ""

echo "=== GET /users/1 ==="
curl.exe -s http://localhost:8081/users/1
echo ""

echo "=== GET /users/999 (404) ==="
curl.exe -s -w " HTTP:%{http_code}" http://localhost:8081/users/999
echo ""
echo ""

echo "=== GET /orders/101 ==="
curl.exe -s http://localhost:8082/orders/101
echo ""

echo "=== GET /orders/101/full ==="
curl.exe -s http://localhost:8082/orders/101/full
echo ""

echo "=== GET /orders/by-user/1 ==="
curl.exe -s http://localhost:8082/orders/by-user/1
echo ""

echo "=== GET /orders/by-user/2 ==="
curl.exe -s http://localhost:8082/orders/by-user/2
echo ""

echo "=== GET /orders/999 (404) ==="
curl.exe -s -w " HTTP:%{http_code}" http://localhost:8082/orders/999
echo ""
echo ""

echo "=== 502 (вручную: остановите user-service, затем выполните строку ниже) ==="
echo 'curl.exe -s -w " HTTP:%{http_code}" http://localhost:8082/orders/101/full'
