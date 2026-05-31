# Module 101: Kiến Trúc Phần Cứng & Hệ Thống Linux

Module này giúp bạn hiểu cách Linux nhận diện, quản lý phần cứng và quá trình khởi động hệ thống.

---

## 1. 🔍 101.1 - Xác Định Và Cấu Hình Phần Cứng

Linux sử dụng các file ảo trong `/proc` và `/sys` để giao tiếp với phần cứng.

### Các lệnh kiểm tra thông tin quan trọng:

| Lệnh | Mục đích |
| :--- | :--- |
| `lspci` | Liệt kê các thiết bị kết nối qua bus PCI (Card mạng, VGA, v.v.) |
| `lsusb` | Liệt kê các thiết bị USB |
| `lsblk` | Hiển thị thông tin về các ổ đĩa và phân vùng |
| `lscpu` | Xem thông tin chi tiết về CPU |
| `free -m` | Kiểm tra dung lượng RAM (đơn vị MB) |

#### 💻 Ví dụ thực tế:
```bash
# Xem chi tiết card mạng và driver đang dùng
lspci -v | grep -i network -A 5

# Xem tên model CPU từ file hệ thống
cat /proc/cpuinfo | grep "model name" | uniq
```

---

## 2. ⚙️ Quản Lý Kernel Modules

Kernel Linux có tính modular, cho phép nạp/gỡ driver mà không cần khởi động lại.

- **`lsmod`**: Liệt kê các module đang nạp.
- **`modinfo <tên_module>`**: Xem thông tin chi tiết của module.
- **`modprobe <tên_module>`**: Nạp module (tự động xử lý dependencies).
- **`modprobe -r <tên_module>`**: Gỡ module an toàn.

> [!IMPORTANT]
> Lệnh `insmod` và `rmmod` cũng dùng để nạp/gỡ module nhưng **không** tự động xử lý các dependencies đi kèm. Ưu tiên dùng `modprobe`.

---

## 3. 🏁 101.2 - Quá Trình Khởi Động (Boot Process)

Thứ tự diễn ra:
`BIOS/UEFI` ➔ `Bootloader (GRUB2)` ➔ `Kernel` ➔ `initramfs` ➔ `Systemd (PID 1)`

### Kiểm tra log khởi động:
```bash
# Xem thông tin từ Kernel (ring buffer)
dmesg | head -n 20

# Tìm lỗi trong quá trình boot
dmesg | grep -i error

# Xem toàn bộ log hệ thống với systemd
journalctl -b
```

---

## 4. 🎯 101.3 - Runlevels và Systemd Targets

| Runlevel | Systemd Target | Mô tả |
| :--- | :--- | :--- |
| 0 | `poweroff.target` | Tắt máy |
| 1 | `rescue.target` | Chế độ cứu hộ (Single-user) |
| 3 | `multi-user.target` | Chế độ nhiều người dùng, không GUI |
| 5 | `graphical.target` | Chế độ nhiều người dùng, có GUI |
| 6 | `reboot.target` | Khởi động lại |

#### Các lệnh quản trị:
```bash
# Xem target hiện tại
systemctl get-default

# Chuyển sang chế độ console (Server mode)
systemctl set-default multi-user.target

# Chuyển sang chế độ cứu hộ ngay lập tức
systemctl isolate rescue.target
```

---

## ❓ Câu Hỏi Ôn Tập (Nâng Cao)

**1. Systemd target nào tương đương với runlevel 3 (multi-user, không GUI)?**
- A. `graphical.target`
- B. `multi-user.target`
- C. `rescue.target`
- D. `emergency.target`

**2. File nào trong `/proc` chứa thông tin chi tiết về RAM của hệ thống?**
- A. `/proc/cpuinfo`
- B. `/proc/meminfo`
- C. `/proc/version`
- D. `/proc/mounts`

> [!NOTE]
> **Đáp án**: 1-B (multi-user.target), 2-B (/proc/meminfo).

---

## 📝 Tổng Kết Module 101

- **lspci / lsusb**: Liệt kê thiết bị PCI và USB kết nối.
- **/proc/cpuinfo & /proc/meminfo**: Thông tin CPU và RAM dạng văn bản.
- **modprobe / lsmod**: Quản lý kernel modules với dependency.
- **dmesg / journalctl -b**: Đọc log khởi động và log hệ thống.
- **systemctl get/set-default**: Cấu hình target mặc định khi boot.
- **Thứ tự boot**: BIOS/UEFI ➔ Bootloader (GRUB2) ➔ Kernel ➔ initramfs ➔ systemd.

---

## 🛠️ Bài Tập Thực Hành

### Bài 1: Điều tra phần cứng hệ thống
Tạo một báo cáo phần cứng bằng cách chạy các lệnh sau và lưu kết quả vào file `hw_report.txt`:
1. Liệt kê tất cả thiết bị PCI và driver đang sử dụng.
2. Xem thông tin CPU (số lõi, tốc độ, model).
3. Xem tổng RAM và RAM còn trống.
4. Liệt kê các kernel module đang được nạp.

**Lời giải gợi ý:**
```bash
{
  echo "=== PCI Devices ==="
  lspci -k
  echo ""
  echo "=== CPU Info ==="
  grep -E "model name|cpu cores|MHz" /proc/cpuinfo | sort -u
  echo ""
  echo "=== Memory Info ==="
  grep -E "MemTotal|MemFree|MemAvailable" /proc/meminfo
  echo ""
  echo "=== Loaded Modules ==="
  lsmod
} > hw_report.txt

# Kiểm tra kết quả
cat hw_report.txt | head -n 30
```

### Bài 2: Thay đổi default boot target
1. Kiểm tra target hiện tại: `systemctl get-default`
2. Đổi sang `multi-user.target` (text mode): `systemctl set-default multi-user.target`
3. Xác nhận thay đổi.
4. Đổi lại `graphical.target` nếu bạn đang dùng Ubuntu Desktop.
