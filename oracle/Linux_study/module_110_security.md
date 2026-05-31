# Module 110: Bảo Mật Hệ Thống (Security)

Thiết lập tường lửa, quản lý quyền sudo và các biện pháp bảo mật cơ bản.

---

## 1. 🛡️ Sudo & Privilege Escalation

Không bao giờ làm việc trực tiếp bằng tài khoản `root`. Hãy dùng `sudo`.

- **`/etc/sudoers`**: File cấu hình quyền sudo. **LUÔN chỉnh sửa bằng lệnh `visudo`** để tránh sai cú pháp làm khóa máy.
- **Cú pháp**: `user host=(runas) commands`
  - `john ALL=(ALL:ALL) ALL`: Quyền tối cao cho john.
  - `%admin ALL=(ALL) NOPASSWD: ALL`: Nhóm admin không cần nhập pass khi sudo.

---

## 2. 🧱 Tường Lửa (Iptables)

Linux sử dụng Netfilter thông qua lệnh `iptables`.

- **Xem rules**: `iptables -L -n -v` (Hiển thị số packet và byte).
- **Thêm rules (VD: Cho phép web và ssh)**:
  - `iptables -A INPUT -p tcp --dport 22 -j ACCEPT`
  - `iptables -A INPUT -p tcp --dport 80 -j ACCEPT`
  - `iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT`
  - `iptables -P INPUT DROP`: Mặc định chặn mọi kết nối vào nếu không có rule cho phép.
- **Lưu rules**: `iptables-save > /etc/iptables/rules.v4`

---

## ❓ Câu Hỏi Ôn Tập

**1. Lệnh nào an toàn nhất để chỉnh sửa file cấu hình Sudo?**
- A. `nano /etc/sudoers`
- B. `visudo` (Đúng!)

**2. Để chặn hoàn toàn một IP truy cập vào server, ta dùng lệnh nào?**
- A. `iptables -A INPUT -s 1.2.3.4 -j DROP` (Đúng!)
- B. `iptables -A INPUT -d 1.2.3.4 -j ACCEPT`
