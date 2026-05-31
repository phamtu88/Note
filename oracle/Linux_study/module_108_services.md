# Module 108: Hệ Thống & Dịch Vụ (System Services)

Quản lý các dịch vụ nền (daemons), ghi log và đồng bộ thời gian.

---

## 1. ⚙️ Quản Lý Dịch Vụ Với Systemd

Systemd là hệ thống khởi tạo và quản lý dịch vụ mặc định trên hầu hết các distro hiện đại.

### Các lệnh `systemctl` quan trọng:
- `systemctl start nginx`: Khởi chạy dịch vụ.
- `systemctl stop nginx`: Dừng dịch vụ.
- `systemctl restart nginx`: Khởi động lại.
- `systemctl reload nginx`: Nạp lại cấu hình (không ngắt kết nối).
- `systemctl enable nginx`: Tự động chạy khi khởi động máy.
- `systemctl status nginx`: Kiểm tra trạng thái chi tiết.

---

## 2. 📝 Ghi Log Hệ Thống (Logging)

### Journald (Log nhị phân của Systemd)
Sử dụng lệnh `journalctl`:
- `journalctl -f`: Theo dõi log thời gian thực (như `tail -f`).
- `journalctl -u nginx`: Chỉ xem log của dịch vụ nginx.
- `journalctl --since "1 hour ago"`: Xem log trong 1 giờ qua.
- `journalctl -p err`: Chỉ hiển thị các thông báo lỗi.

### Traditional Log Files (`/var/log/`)
- `/var/log/syslog` hoặc `/var/log/messages`: Log hệ thống chung.
- `/var/log/auth.log` hoặc `/var/log/secure`: Log đăng nhập và bảo mật.
- `/var/log/dmesg`: Log liên quan đến Kernel và phần cứng.

---

## ❓ Câu Hỏi Ôn Tập

**1. Lệnh nào dùng để cấu hình một dịch vụ tự động khởi động cùng hệ thống?**
- A. `systemctl start`
- B. `systemctl enable` (Đúng!)

**2. Để theo dõi log của dịch vụ Apache trong thời gian thực, ta dùng:**
- A. `journalctl -u apache -f` (Đúng!)
- B. `journalctl -p err`
