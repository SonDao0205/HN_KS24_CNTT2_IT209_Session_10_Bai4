# Bài 4: Custom Network & Named Volume bằng Docker CLI

## Mô tả
- Tạo custom bridge network `app-net` để các container gọi nhau bằng tên (DNS nội bộ).
- Tạo named volume `db-data` để lưu dữ liệu PostgreSQL bền vững.
- `db-server` (`postgres:15-alpine`) mount `db-data:/var/lib/postgresql/data`.
- `app-container` (backend) cùng mạng `app-net`, kết nối DB bằng `DB_HOST=db-server`.

## Cách chạy
```bash
chmod +x commands.sh
./commands.sh
```

## Lệnh kiểm tra
```bash
docker network ls | grep app-net
docker volume ls | grep db-data
docker network inspect app-net
docker exec -it app-container ping -c 2 db-server
```

## Kết quả mong đợi
- `ping db-server` từ `app-container` ra IP nội bộ của DB (dạng `172.x.x.x`) vì custom bridge có DNS resolution.
- Sau `docker rm -f db-server` và chạy lại container mới với cùng volume `db-data`, bảng `users` (3 bản ghi) vẫn còn nguyên.

## Giải thích
Container là tạm thời, dữ liệu ghi bên trong sẽ mất khi xóa container. Named volume nằm ngoài vòng đời container nên dữ liệu được giữ lại.

## Kết quả chạy
_(Dán output terminal hoặc ảnh chụp vào đây)_
