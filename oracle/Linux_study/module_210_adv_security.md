# Module 210: Bảo Mật Nâng Cao & Hardening

Chống tấn công Brute-force, Audit hệ thống và thắt chặt an ninh OpenSSH.

---

## 1. 🛡️ Fail2ban (Chống Brute-force)

Tự động ban IP nếu đăng nhập sai nhiều lần (`/etc/fail2ban/jail.local`):
```ini
[DEFAULT]
bantime = 3600    # Ban 1 giờ
maxretry = 5      # Thử sai 5 lần là ban

[sshd]
enabled = true
```
**Quản lý**:
- `fail2ban-client status`: Xem các "nhà tù" (jails) đang hoạt động.
- `fail2ban-client set sshd unbanip 1.2.3.4`: Gỡ ban cho IP.

---

## 🔍 2. System Hardening Checklist

- **Audit Tool**: `lynis audit system` (Quét toàn bộ hệ thống để tìm lỗ hổng).
- **Check Rootkit**: `chkrootkit` hoặc `rkhunter --check`.
- **Hardening OpenSSH**:
  ```bash
  Protocol 2
  PermitRootLogin no
  MaxAuthTries 3
  PubkeyAuthentication yes
  PasswordAuthentication no
  ```
- **Tắt dịch vụ thừa**: `systemctl disable bluetooth avahi-daemon`.

---

## ❓ Câu Hỏi Ôn Tập

**1. Công cụ nào dùng để quét và phát hiện các Rootkits ẩn sâu trong hệ thống?**
- A. `fail2ban`
- B. `rkhunter` (Đúng!)

**2. Để chỉ cho phép tối đa 3 lần thử đăng nhập SSH trước khi ngắt kết nối, ta chỉnh tham số:**
- A. `MaxSessions`
- B. `MaxAuthTries` (Đúng!)
