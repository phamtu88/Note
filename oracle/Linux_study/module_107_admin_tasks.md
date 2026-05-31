# Module 107: Quản Trị Hệ Thống (Administrative Tasks)

Quản lý người dùng, nhóm, lập lịch công việc và các file cấu hình quan trọng.

---

## 1. 👥 Quản Lý Users & Groups

### Các lệnh phổ biến:
- **`useradd -m -s /bin/bash -G sudo john`**: Tạo user mới, có thư mục home, shell bash và thêm vào nhóm sudo.
- **`usermod -aG docker john`**: Thêm user vào nhóm (Option `-a` để append, tránh bị mất các nhóm cũ).
- **`userdel -r john`**: Xóa user và thư mục home.
- **`id john`**: Xem UID, GID và các nhóm của user.
- **`passwd john`**: Đổi mật khẩu cho user.

### Các file hệ thống quan trọng:
- `/etc/passwd`: Thông tin user (dạng `user:pass:uid:gid:comment:home:shell`).
- `/etc/shadow`: Chứa mật khẩu đã được mã hóa (chỉ root mới đọc được).
- `/etc/group`: Thông tin về các nhóm.

---

## 2. ⏰ Lập Lịch Công Việc (Cron Jobs)

Sử dụng `crontab` để tự động hóa các tác vụ định kỳ.

**Định dạng Crontab:** `MIN HOUR DAY MONTH WEEKDAY COMMAND`

### Ví dụ:
- `0 2 * * * /usr/bin/backup.sh`: Chạy lúc 2:00 sáng mỗi ngày.
- `*/15 * * * * /usr/local/bin/monitor.sh`: Chạy mỗi 15 phút.
- `0 8 * * 1-5 /home/john/workday.sh`: 8:00 sáng từ Thứ 2 đến Thứ 6.

### Lệnh quản lý:
- `crontab -e`: Chỉnh sửa crontab của user hiện tại.
- `crontab -l`: Xem danh sách công việc đang lập lịch.
- `crontab -u john -e`: Sửa crontab cho user khác (cần quyền root).

---

## ❓ Câu Hỏi Ôn Tập

**1. File nào lưu trữ mật khẩu đã mã hóa của người dùng trong Linux?**
- A. `/etc/passwd`
- B. `/etc/shadow` (Đúng!)

**2. Ký tự nào trong Crontab đại diện cho "Tất cả các giá trị"?**
- A. `*` (Đúng!)
- B. `/`
