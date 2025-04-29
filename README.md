# Trợ Lập Trình Tự Động n8n - Bản Cải Tiến (PRO Version)

Script giúp cài đặt **n8n** tự động trên VPS Ubuntu 20.04/22.04 dành cho người mới, không cần biết lập trình.

> Chỉ cần 1 dòng lệnh để cài đặt đầy đủ Docker, PostgreSQL, nginx SSL, n8n, Backup!

---

## ✨ Tính năng nổi bật

- Tự động cài Docker, Docker-Compose, nginx, Certbot.
- Thiết lập **n8n** và **PostgreSQL** qua Docker Compose.
- Thiết lập nginx proxy ngược có SSL Let's Encrypt.
- Tự động sinh mã Encryption Key cho n8n.
- Tự động tạo thông tin PostgreSQL và n8n đăng nhập.
- Kiểm tra và gỡ bỏ cài đặt n8n cũ nếu có.
- Tự động backup dữ liệu hàng ngày.
- Tự xóa backup cũ hơn 7 ngày, tránh đầy VPS.
- Đặt cronjob backup vào 2h sáng mỗi ngày.
- Hiển thị log chi tiết trong quá trình cài đặt để người dùng dễ theo dõi.

---

## 📚 Yêu cầu trước khi cài

- VPS Ubuntu 20.04 hoặc 22.04.
- Tên miền (domain) hoặc subdomain đã được trỏ về đúng IP VPS.
- Quyền root trên VPS.

---

## 🔄 Cài đặt nhanh với 1 dòng lệnh

```bash
bash <(curl -s https://raw.githubusercontent.com/vankhanhdhv/n8n/main/install_n8n.sh)
```

> ⚠️ Lưu ý: Hãy đảm bảo domain/subdomain đã được DNS trỏ về đúng IP VPS trước khi chạy script.

---

## 📚 Trong khi cài, bạn sẽ được hỏi:

| Bước | Nhập thông tin |
|:---|:---|
| 1 | Nhập domain/subdomain |

Các thông tin về Database và Tài khoản đăng nhập n8n sẽ được tự động tạo.

---

## 🔓 Sau khi cài xong

- Truy cập website: `https://yourdomain.com`
- Thông tin đăng nhập n8n và kết nối Database sẽ được in ra màn hình.
- Backup hàng ngày được lưu tại: `/opt/backups/`
- Chỉ giữ lại backup trong 7 ngày gần nhất.

### Thông tin kết nối node PostgreSQL trên n8n:

| Thông tin | Giá trị |
|:---|:---|
| Host | postgres |
| Database | POSTGRES_DB (tự động tạo) |
| User | POSTGRES_USER (tự động tạo) |
| Password | POSTGRES_PASSWORD (tự động tạo) |

---

## 💡 Lưu ý thêm

- Backup khôi phục dễ dàng nếu VPS gặp sự cố.
- Certbot đã thiết lập tự động gia hạn SSL.

---

## 📈 Bản quyền

Miễn phí cho cá nhân và cộng đồng.

> Nếu bạn thấy hữu ích, hãy cho repo một “⭐ Star” và chia sẻ để giúp nhiều người hơn nhé!
