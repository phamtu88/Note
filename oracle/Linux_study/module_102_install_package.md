# Module 102: Cài Đặt Linux & Quản Lý Package

Kỹ năng thiết yếu của một SysAdmin: cài đặt hệ thống từ đầu, phân vùng đĩa và quản lý phần mềm.

---

## 🏗️ 102.1 - Thiết kế Layout & Phân Vùng (Partitioning)

> [!TIP]
> **Layout khuyến nghị cho server production:** `/boot` (1GB), `/` (20GB), `/home` (phần còn lại), `swap` (1-2x RAM).

### Các lệnh quản lý đĩa:

```bash
# Liệt kê các phân vùng (MBR)
fdisk -l /dev/sda

# Xem cấu trúc cây và điểm gắn (Mount point)
lsblk

# Dùng parted cho đĩa lớn (>2TB, chuẩn GPT)
parted /dev/sdb
```

---

## 📚 102.3 - Shared Libraries

Shared libraries giúp tiết kiệm bộ nhớ bằng cách cho phép nhiều chương trình dùng chung một mã nguồn.

- **`ldd <lệnh>`**: Xem các thư viện mà chương trình cần (dependencies).
- **`ldconfig`**: Cập nhật cache thư viện (`/etc/ld.so.cache`).
- **`ldconfig -p | grep libssl`**: Tìm kiếm thư viện cụ thể trong cache.

---

## 📦 102.4 - Debian Package Management (apt/dpkg)

| Công cụ | Lệnh phổ biến | Mô tả |
| :--- | :--- | :--- |
| **APT** | `apt update` | Cập nhật danh sách package |
| | `apt upgrade` | Nâng cấp tất cả package |
| | `apt install <p>` | Cài đặt package |
| | `apt purge <p>` | Gỡ hoàn toàn (kể cả file cấu hình) |
| **DPKG** | `dpkg -i <file.deb>` | Cài file .deb cục bộ |
| | `dpkg -L <p>` | Liệt kê các file của package đã cài |
| | `dpkg -S <path>` | Tìm package chứa file cụ thể |

---

## 🔴 102.5 - RPM & DNF/YUM (RHEL/CentOS)

```bash
# DNF (High-level)
dnf install httpd       # Cài đặt
dnf remove httpd        # Gỡ bỏ
dnf list installed      # Liệt kê packge đã cài

# RPM (Low-level)
rpm -ivh package.rpm    # Cài đặt với verbose & progress bar
rpm -qf /usr/bin/vim    # Tìm package chứa file cụ thể
rpm -V httpd            # Kiểm tra tính toàn vẹn của package
```

---

## ❓ Câu Hỏi Ôn Tập

**1. Lệnh nào kiểm tra file nào trong hệ thống thuộc về package "nginx" trên Debian?**
- A. `dpkg -l nginx`
- B. `dpkg -L nginx` (Đúng! Liệt kê tất cả file thuộc package)
- C. `dpkg -s nginx`
- D. `apt show nginx`

**2. Lệnh `ldd` được dùng để làm gì?**
- A. Cập nhật cache thư viện hệ thống.
- B. Hiển thị các shared library mà một chương trình cần.
- C. Liệt kê files trong một package.

**3. Trên CentOS/RHEL, lệnh nào tìm package chứa file `/usr/bin/vim`?**
- A. `rpm -ql vim`
- B. `rpm -qf /usr/bin/vim`
- C. `dnf search vim`

> [!NOTE]
> **Đáp án**: 1-B, 2-B, 3-B.

---

## � Tổng Kết Module 102

- **apt / dpkg**: Hệ thống package của Debian/Ubuntu.
- **dnf / rpm**: Hệ thống package của RHEL/CentOS.
- **ldd**: Xem shared libraries của binary.
- **fdisk / parted**: Phân vùng ổ đĩa (MBR / GPT).
- **lsblk / df -h**: Xem layout ổ đĩa và dung lượng dùng.

---

## 🛠️ Bài Tập Thực Hành

### Bài 1: Package investigation
Trên hệ thống Ubuntu:
1. Cài package `curl`: `sudo apt update && sudo apt install -y curl`
2. Xem danh sách files được cài: `dpkg -L curl`
3. Tìm package nào cung cấp file `/usr/bin/curl`: `dpkg -S /usr/bin/curl`
4. Gỡ hoàn toàn kể cả cấu hình: `sudo apt purge curl && sudo apt autoremove`
