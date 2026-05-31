# Module 109: Cấu Hình Mạng (Networking)

Nắm vững cách cấu hình IP, định tuyến và kiểm tra kết nối mạng trên Linux.

---

## 1. 🌐 Cấu Hình IP & Giao Diện Mạng

Ưu tiên sử dụng lệnh `ip` (thế hệ mới) thay cho `ifconfig`.

- **`ip addr show`**: Hiển thị địa chỉ IP của các interface.
- **`ip addr add 192.168.1.100/24 dev eth0`**: Gán IP tạm thời.
- **`ip link set eth0 up/down`**: Bật/Tắt card mạng.
- **`ip route show`**: Xem bảng định tuyến (Routing table).
- **`ip route add default via 192.168.1.1`**: Thiết lập Gateway mặc định.

---

## 2. 🛠️ Kiểm Tra Kết Nối (Troubleshooting)

| Lệnh | Công dụng |
| :--- | :--- |
| `ping -c 4 google.com` | Kiểm tra kết nối cơ bản |
| `traceroute 8.8.8.8` | Xem các chặng (hops) gói tin đi qua |
| `ss -tuln` | Xem các port đang lắng nghe (thay thế `netstat`) |
| `host google.com` | DNS lookup cơ bản |
| `dig google.com` | Truy vấn DNS chi tiết |

---

## 3. 📂 Các File Cấu Hình Mạng Quan Trọng
- `/etc/hostname`: Tên máy.
- `/etc/hosts`: File ánh xạ IP-Hostname cục bộ.
- `/etc/resolv.conf`: Cấu hình DNS Server.
- `/etc/network/interfaces` (Debian) hoặc `/etc/sysconfig/network-scripts/` (RHEL): Cấu hình card mạng cố định.

---

## ❓ Câu Hỏi Ôn Tập

**1. Lệnh nào hiển thị danh sách các port TCP và UDP đang lắng nghe trên hệ thống?**
- A. `ip addr`
- B. `ss -tuln` (Đúng!)

**2. File nào dùng để cấu hình DNS Server mà máy tính sẽ sử dụng?**
- A. `/etc/hosts`
- B. `/etc/resolv.conf` (Đúng!)
