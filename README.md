# Trợ Lập Trình Tự Động n8n - Bản Cải Tiến (PRO Version)

Script giúp cài đặt **n8n** tự động trên VPS Ubuntu 20.04/22.04 dành cho người mới, không cần biết lập trình.

> Chỉ cần 1 dòng lệnh để cài đặt đầy đủ Docker, PostgreSQL, nginx SSL, n8n, Backup!

---

## ✨ Tính năng nổi bật

- Tự động cài Docker, Docker-Compose, nginx, Certbot.
- Thiết lập **n8n** và **PostgreSQL** qua Docker Compose.
- Thiết lập nginx proxy ngược có SSL Let's Encrypt.
- Tự động sinh mã Encryption Key cho n8n.
- Tự động backup dữ liệu hàng ngày.
- Tự xóa backup cũ hơn 7 ngày, tránh đầy VPS.
- Đặt cronjob backup vào 2h sáng mỗi ngày.

---

## 📚 Yêu cầu trước khi cài

- VPS Ubuntu 20.04 hoặc 22.04.
- Tên miên (domain) hoặc subdomain đã được trỏ về đúng IP VPS.
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
| 2 | Nhập mật khẩu Database PostgreSQL |
| 3 | Nhập tên đăng nhập n8n |
| 4 | Nhập mật khẩu đăng nhập n8n |

Sau khi nhập xong, script tự động chạy đến khi hoàn thành.

---

## 🔓 Sau khi cài xong

- Truy cập website: `https://yourdomain.com`
- Đăng nhập với username và password bạn vừa nhập.
- Backup hàng ngày được lưu tại: `/opt/backups/`
- Chỉ giữ lại backup trong 7 ngày gần nhất.

---

## 💡 Lưu ý thêm

- Backup khôi phục dễ dàng nếu VPS gặp sự cố.
- Certbot đã thiết lập tự động gia hạn SSL.

---

## 📈 Bản quyền

Miễn phí cho cá nhân và công đồng.

> Nếu bạn thấy hữu ích, hãy cho repo một “⭐ Star” và chia sẻ để giúc nhiều người hơn nhé!
