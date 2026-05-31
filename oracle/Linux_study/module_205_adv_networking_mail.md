# Module 205, 206 & 207: Adv Network, Mail & DNS Services

Giám sát mạng chuyên sâu, thiết lập Mail Server và quản trị hệ thống DNS (BIND9).

---

## 1. 🔍 DNS Server (BIND9)

BIND9 là máy chủ tên miền phổ biến nhất trên Linux.

### Cấu hình Vùng (Zone) - `/etc/bind/named.conf.local`:
```bash
zone "example.com" {
    type master;
    file "/etc/bind/db.example.com";
};
```

### File bản ghi (Resource Records) - `db.example.com`:
- **SOA**: Khai báo quyền quản lý vùng.
- **A**: Ánh xạ tên miền -> IP (VD: `ns1 IN A 203.0.113.10`).
- **MX**: Chỉ định Mail Server (VD: `@ IN MX 10 mail.example.com.`).
- **CNAME**: Biệt danh (VD: `ftp IN CNAME www.example.com.`).

### Kiểm tra & Reload:
- `named-checkconf`: Kiểm tra file cấu hình.
- `named-checkzone example.com /etc/bind/db.example.com`: Kiểm tra file vùng.
- `rndc reload`: Nạp lại cấu hình không cần restart.

---

## 1. 🛰️ Advanced Networking Tools

- **Phân tích gói tin**: `tcpdump -i eth0 port 80 -w capture.pcap`
- **Giám sát băng thông**: `iptraf-ng` hoặc `iftop -i eth0`.
- **Socket statistics**: `ss -tuanp` (Hiển thị port, socket và tiến trình sử dụng).
- **Bonding/Teaming**: Chạy nhiều card mạng song song để tăng băng thông hoặc dự phòng. Cấu hình tại `/proc/net/bonding/bond0`.

---

## 2. 📧 Postfix Mail Server

Postfix là Mail Transfer Agent (MTA) hàng đầu trên Linux.

### Cấu hình chính (`/etc/postfix/main.cf`):
```bash
myhostname = mail.example.com
mydomain = example.com
myorigin = $mydomain
inet_interfaces = all
mydestination = $myhostname, localhost.$mydomain, localhost
```

### Quản lý & Kiểm tra:
- `postfix check`: Kiểm tra lỗi cú pháp cấu hình.
- `systemctl start postfix`: Khởi động service.
- **Test gửi mail**: `echo "Test email content" | mail -s "Test Subject" admin@example.com`
- **Soi log**: `tail -f /var/log/mail.log`

---

## 💡 Tip: Troubleshooting Mail
Khi mail không gửi được, hãy kiểm tra Queue bằng lệnh `mailq`. Nếu cần xóa sạch hàng đợi, dùng `postsuper -d ALL`.
