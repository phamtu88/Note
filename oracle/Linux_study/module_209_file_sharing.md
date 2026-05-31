# Module 209: Chia Sẻ File (Samba & NFS)

Kết nối và chia sẻ dữ liệu giữa các hệ thống Windows và Linux.

---

## 1. 🏢 Samba (Dùng cho Windows Shares)

Cấu hình tại `/etc/samba/smb.conf`:
```ini
[global]
    workgroup = COMPANY
    security = user

[shared]
    comment = Shared Files
    path = /srv/samba/shared
    valid users = @staff
    read only = no
    create mask = 0664
```
**Lệnh hỗ trợ**:
- `smbpasswd -a john`: Thêm user vào database password của Samba.
- `testparm`: Kiểm tra lỗi cú pháp file config.

---

## 2. 🐧 NFS (Dùng cho Linux/Unix Shares)

### NFS Server (`/etc/exports`):
- `/srv/nfs/data 192.168.1.0/24(rw,sync,no_subtree_check)`
- **Reload**: `exportfs -ra`.

### NFS Client:
- **Mount tạm thời**: `mount server:/srv/nfs/data /mnt/data`
- **Mount cố định (`/etc/fstab`)**:
  `server:/srv/nfs/data /mnt/data nfs defaults,_netdev 0 0`

---

## ❓ Câu Hỏi Ôn Tập

**1. Tham số `_netdev` trong `/etc/fstab` cho NFS mount có ý nghĩa gì?**
- A. Tăng tốc độ truyền tải.
- B. Hệ thống sẽ đợi có kết nối mạng mới thử mount ổ đĩa (Tránh lỗi khởi động). (Đúng!)
