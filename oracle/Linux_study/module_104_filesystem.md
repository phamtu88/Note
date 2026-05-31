# Module 104: Filesystem & Thiết Bị Linux

Hiểu về cách Linux quản lý dữ liệu, quyền truy cập và các thiết bị lưu trữ.

---

## 1. 🔐 Quyền Truy Cập (Permissions & Ownership)

Mọi file/thư mục đều có: **Owner (u)**, **Group (g)**, **Others (o)**.

### Lệnh quản lý:
- **`chmod`**: Thay đổi quyền (r=4, w=2, x=1).
  - `chmod 755 file.sh` (rwxr-xr-x)
  - `chmod -R 644 /var/www` (Sửa hàng loạt)
- **`chown`**: Thay đổi chủ sở hữu.
  - `chown user:group file.txt`
- **`umask`**: Mặt nạ quyền mặc định (VD: 0022).

### Quyền đặc biệt (Special Bits):
- **SUID (4xxx)**: Chạy file với quyền của chủ sở hữu (VD: `/usr/bin/passwd`).
- **SGID (2xxx)**: Thư mục con tự động kế thừa group của thư mục cha.
- **Sticky Bit (1xxx)**: Chỉ chủ sở hữu mới được xóa file trong thư mục (VD: `/tmp`).

---

## 2. 🔗 Links: Hard Link vs Symbolic Link

- **Hard Link**: Cùng Inode, cùng hệ thống file. Xóa file gốc thì link vẫn hoạt động.
  - Lệnh: `ln source.txt link.txt`
- **Symbolic Link (Soft Link)**: Trỏ đến đường dẫn. Có thể trỏ xuyên hệ thống file.
  - Lệnh: `ln -s /etc/config my_config`

---

## 3. 💾 Quản Quản Quản Lý Filesystem

- **`mkfs.ext4 /dev/sdb1`**: Định dạng phân vùng.
- **`mount /dev/sdb1 /mnt/data`**: Gắn ổ đĩa vào thư mục.
- **`/etc/fstab`**: File cấu hình để tự động mount khi boot.
- **`df -h`**: Xem dung lượng đĩa trống.
- **`du -sh`**: Xem dung lượng của một thư mục cụ thể.

---

## ❓ Câu Hỏi Ôn Tập

**1. Quyền `755` tương ứng với chuỗi ký tự nào?**
- A. `rwxr-xr-x` (Đúng! 7=rwx, 5=r-x)
- B. `rw-r--r--`

**2. Để tìm các file có bit SUID được thiết lập, ta dùng `find` với tham số:**
- A. `-perm -2000`
- B. `-perm -4000` (Đúng!)
