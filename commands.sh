#!/usr/bin/env bash
# Bài 4: Custom Network & Named Volume bằng Docker CLI
set -euo pipefail

DB_USER=appuser
DB_PASS=apppass
DB_NAME=appdb

wait_db() {
  until docker exec db-server pg_isready -U $DB_USER -d $DB_NAME >/dev/null 2>&1; do sleep 1; done
}
run_db() {
  docker run -d --name db-server --network app-net \
    -e POSTGRES_USER=$DB_USER -e POSTGRES_PASSWORD=$DB_PASS -e POSTGRES_DB=$DB_NAME \
    -v db-data:/var/lib/postgresql/data \
    postgres:15-alpine
}
sql() { docker exec -i db-server psql -U $DB_USER -d $DB_NAME "$@"; }

echo "=== 0. Dọn môi trường cũ ==="
docker rm -f app-container db-server 2>/dev/null || true
docker network rm app-net 2>/dev/null || true
docker volume rm db-data 2>/dev/null || true

echo "=== 1. Tạo Custom Bridge Network ==="
docker network create --driver bridge app-net

echo "=== 2. Tạo Named Volume ==="
docker volume create db-data

echo "=== 3. Chạy Database Container ==="
run_db
wait_db

echo "=== 4. Chạy Backend Container (kết nối DB qua hostname db-server) ==="
docker run -d --name app-container --network app-net \
  -e DB_HOST=db-server -e DB_PORT=5432 \
  -e DB_NAME=$DB_NAME -e DB_USER=$DB_USER -e DB_PASSWORD=$DB_PASS \
  postgres:15-alpine sleep infinity

echo "=== 5. Kiểm tra ==="
docker network ls | grep app-net
docker volume ls | grep db-data
docker network inspect app-net
docker exec app-container ping -c 2 db-server

echo "=== 6. Test Data Persistence ==="
echo ">> Thêm dữ liệu"
sql <<'SQL'
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(150) UNIQUE NOT NULL
);
INSERT INTO users (name, email) VALUES
  ('Nguyen Van An', 'an@example.com'),
  ('Tran Thi Binh', 'binh@example.com'),
  ('Le Van Cuong',  'cuong@example.com');
SQL
echo ">> Backend đọc dữ liệu qua hostname db-server (TRƯỚC khi xóa DB):"
docker exec -e PGPASSWORD=$DB_PASS app-container \
  psql -h db-server -U $DB_USER -d $DB_NAME -c "SELECT * FROM users;"

echo ">> Xóa cứng container DB"
docker rm -f db-server

echo ">> Tạo lại container DB mới, gắn cùng volume db-data"
run_db
wait_db

echo ">> Dữ liệu SAU khi tạo lại container DB:"
docker exec -e PGPASSWORD=$DB_PASS app-container \
  psql -h db-server -U $DB_USER -d $DB_NAME -c "SELECT * FROM users;"
echo "✅ Dữ liệu vẫn còn nguyên => Volume hoạt động đúng"
