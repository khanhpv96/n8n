# Cài Đặt Tự Động n8n Trên VPS Ubuntu

Script này giúp cài đặt nhanh chóng n8n (một công cụ workflow automation mã nguồn mở) trên VPS Ubuntu 20.04 hoặc 22.04 vừa mua (fresh OS), hoàn toàn tự động, phù hợp với người dùng không có kinh nghiệm lập trình.

---

## ✨ Tính Năng
- Tự động sinh tên người dùng, mật khẩu, và database PostgreSQL
- Cài Docker, Docker Compose, Nginx, Certbot
- Tự xin SSL Let's Encrypt
- Tự kiểm tra và gỡ cài đặt cũ nếu có
- Tự backup hàng ngày + tạo cronjob
- Hiển thị thông tin quan trọng sau khi cài đặt
- Tự động phân quyền thư mục tránh lỗi 502/permission

---

## 📄 Cách Cài Đặt

### 1. SSH vào VPS vừa mua:
```bash
ssh root@IP_VPS
```

### 2. Chạy script cài đặt n8n:
```bash
bash <(curl -s https://raw.githubusercontent.com/vankhanhdhv/n8n/refs/heads/main/install_n8n.sh)
```

Bạn sẽ được yêu cầu nhập domain/subdomain bạn sở hữu (VD: `n8n.tenmiencuaban.com`).

Script sẽ tự động thực hiện mọi thứ.

---

## 🚪 Đăng Nhập
Sau khi cài đặt, truy cập n8n tại:
```
https://tenmiencuaban.com
```

---

## 🧰 Kết Nối Node PostgreSQL trong n8n
Sử dụng khi tạo node PostgreSQL trong workflow:
```
Host: postgres
Database: (được in ra sau khi cài đặt)
User: (được in ra sau khi cài đặt)
Password: (được in ra sau khi cài đặt)
```

---

## ♻️ Backup
- Tự động tạo backup hàng ngày tại: `/opt/backups`
- Các bản backup sẽ được **tự xóa sau 7 ngày**

### 🧑‍💻 Backup thủ công:
```bash
bash /usr/local/bin/backup_n8n.sh
```

### 🗂 Khôi phục thủ công sau khi cài lại:
1. Copy lại file n8n_data.tar.gz và n8n_db.sql về thư mục `/opt/n8n`
2. Giải nén và khôi phục:
```bash
tar -xzf n8n_data.tar.gz -C /opt/n8n/
cat n8n_db.sql | docker exec -i n8n_postgres_1 psql -U n8nuser_xxxx n8n_xxxx
```

---

## 🚀 Cập Nhật n8n lên Phiên Bản Mới
Nếu bạn dùng image mặc định (`docker.n8n.io/n8nio/n8n`), bạn chỉ cần:
```bash
cd /opt/n8n
docker pull docker.n8n.io/n8nio/n8n
docker compose down
docker compose up -d
```

Không cần chỉnh sửa file docker-compose.yml.

Nếu bạn muốn dùng phiên bản cụ thể (VD: `1.45.0`), hãy sửa dòng trong `docker-compose.yml`:
```yaml
image: docker.n8n.io/n8nio/n8n:1.45.0
```
và sau đó chạy lại các lệnh như trên.

---

## 🚫 Gỡ Cài Đặt n8n
Muốn gỡ hoàn toàn n8n và dữ liệu liên quan:
```bash
bash <(curl -s https://raw.githubusercontent.com/vankhanhdhv/n8n/refs/heads/main/uninstall_n8n.sh)
```

---

## 💬 Góp Ý và Đóng Góp
- Hãy chia sẻ script này nếu bạn thấy hữu ích!
- Gửi góp ý/báo lỗi tại: https://github.com/vankhanhdhv/n8n

---

✅ Chúc các bạn thành công!
