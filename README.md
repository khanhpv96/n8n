# Cài Đặt Tự Động n8n Trên VPS Ubuntu

Script này giúp cài đặt nhanh chóng n8n (môt công cụ workflow automation mở nguồn) trên VPS Ubuntu 20.04 hoặc 22.04 vửa mua (fresh OS), hoàn toàn tự động, hợp với người dùng không có kinh nghiệm lập trình.

---

## ✨ Tính Năng
- Tự động sinh tên người dùng + mật khẩu + database
- Cài Docker, Docker Compose, Nginx, Certbot
- Tự xin SSL Let's Encrypt
- Tự gỡ cài trước đó (nếu có)
- Tự backup hàng ngày + cronjob
- Thông báo thông tin sau khi cài xong

---

## 📄 Cách Cài Đặt

### 1. SSH vào VPS vừa mua:
```bash
ssh root@IP_VPS
```

### 2. Chạy script cài n8n:
```bash
bash <(curl -s https://raw.githubusercontent.com/vankhanhdhv/n8n/refs/heads/main/install_n8n.sh)
```

Sau đó, bạn chỉ cần nhập domain/subdomain bạn sở hữu (VD: `n8n.tenmiencuaban.com`).

Script sẽ lo hết mọi thứ còn lại.

---

## 🚪 Đăng Nhập
Sau khi cài đặt, bạn sẽ thấy thông tin truy cập n8n như sau:
- Đường dẫn truy cập: `https://tenmiencuaban.com`
- Username: `admin_xxxx`
- Password: `xxxxxx`

---

## 🧰 Kết Nối Node PostgreSQL trong n8n
Khi tạo node PostgreSQL, dùng thông tin sau:

```
Host: postgres
Database: <in ra sau khi cài>
User: <in ra sau khi cài>
Password: <in ra sau khi cài>
```

---

## ⚖️ Backup
- Backup tự động tại: `/opt/backups`
- Dữ liệu sẽ được tự xóa sau 7 ngày

---

## 🚫 Gỡ Cài n8n
Muốn gỡ hoàn toàn n8n:
```bash
bash <(curl -s https://raw.githubusercontent.com/vankhanhdhv/n8n/refs/heads/main/uninstall_n8n.sh)
```

---

## 📄 Gợi Ý Kiến
- Vui lòng chia sẻ script này tới cộng đồng nếu hữ ích!
- Góp ý/bug: https://github.com/vankhanhdhv/n8n

---

✅ Mọi đóng góp và chia sẻ để giúp nhiều người dùng n8n hiệu quả hơn!
