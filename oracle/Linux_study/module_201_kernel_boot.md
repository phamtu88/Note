# Module 201 & 202: Kernel & Boot Management (LPIC-2)

Nâng cao về nhân hệ điều hành và quá trình khởi động hệ thống.

---

## 1. 🐧 Linux Kernel Management

- **Xem thông tin**: `uname -a` (Phiên bản kernel).
- **Cấu hình tại Runtime (`sysctl`)**:
  - `sysctl -a`: Liệt kê mọi tham số kernel.
  - `sysctl -w net.ipv4.ip_forward=1`: Bật chuyển tiếp gói tin (cho Router/Gateway).
  - `/etc/sysctl.conf`: Cấu hình cố định (Áp dụng bằng `sysctl -p`).
- **Boot parameters**: Xem tại `/proc/cmdline` để biết các cờ kernel nhận được từ bootloader.

---

## 2. 🚀 GRUB2 Bootloader

### Cấu trúc file:
- `/etc/default/grub`: Nơi cấu hình chính (Timeout, Default kernel).
- `/boot/grub/grub.cfg`: File cấu hình được generate (KHÔNG sửa trực tiếp).

### Các lệnh quan trọng:
- **Cập nhật cấu hình**:
  - `update-grub` (Debian/Ubuntu)
  - `grub2-mkconfig -o /boot/grub2/grub.cfg` (RHEL/CentOS)
- **Cài đặt GRUB**: `grub-install /dev/sda` (Cài vào MBR).

---

## 📝 Practice Task
Thử thay đổi thời gian chờ boot (`GRUB_TIMEOUT`) trong `/etc/default/grub` thành 10 giây và cập nhật lại config.
