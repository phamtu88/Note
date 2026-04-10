# Hướng dẫn mở rộng Disk LVM (Logical Volume Manager)

Tài liệu này hướng dẫn cách mở rộng dung lượng cho một phân vùng LVM khi ổ cứng bị đầy, dựa trên trường hợp thực tế mở rộng ổ `/u02`.

## 1. Chuẩn bị (Trên môi trường ảo hóa như VMware)
Trước khi thực hiện trên OS, bạn cần cấp thêm dung lượng vật lý:
1. Shutdown máy ảo (VM) an toàn.
2. Vào cài đặt VM -> **Add** thêm một ổ cứng mới (Hard Disk).
3. Cấu hình ổ mới:
   - Các tùy chọn tối ưu cho Lab: **Store virtual disk as a single file** và **không chọn** Allocate all disk space now (Thin Provisioning).
4. Bật lại máy ảo.

## 2. Các bước thực hiện trên Linux (Quyền root)

lsblk
```
*Lưu ý: Tên ổ đĩa (sdb, sdc, sdd...) có thể thay đổi tùy thuộc vào thứ tự bạn add vào VM. Bạn hãy quan sát cột **SIZE** ở lệnh `lsblk` để xác định đúng ổ mới (thường là ổ có dung lượng khớp với số GB bạn vừa thêm).*

### Bước 2: Khởi tạo Physical Volume (PV)
Định dạng ổ mới để LVM có thể nhận dạng và sử dụng.
```bash
pvcreate /dev/sdd
```

### Bước 3: Mở rộng Volume Group (VG)
Nạp dung lượng từ ổ PV mới vào Volume Group hiện tại (ví dụ Volume Group tên là `u02`).
```bash
vgextend u02 /dev/sdd
```

### Bước 4: Mở rộng Logical Volume (LV)
Để mở rộng dung lượng cho Logical Volume, bạn có thể sử dụng một trong hai cách viết đường dẫn sau (Kết quả là như nhau):

*   **Cách 1 (Truyền thống):** `/dev/TênVG/TênLV`
    ```bash
    lvextend -l +100%FREE /dev/u02/data2
    ```
*   **Cách 2 (Khuyên dùng):** `/dev/mapper/TênVG-TênLV`
    ```bash
    lvextend -l +100%FREE /dev/mapper/u02-data2
    ```
*Lưu ý: Luôn sử dụng đường dẫn đầy đủ `/dev/...` để đảm bảo hệ thống xác định đúng thiết bị.*

### Bước 5: Cập nhật File System
LVM đã tăng nhưng hệ điều hành cần lệnh này để "nhìn thấy" dung lượng mới.
- **Đối với XFS** (Mặc định trên Oracle Linux 7/8/9):
  ```bash
  xfs_growfs /u02
  ```
- **Đối với EXT4**:
  ```bash
  resize2fs /dev/mapper/u02-data2
  ```

### Bước 6: Kiểm tra kết quả
```bash
df -h /u02
```

---
## 💡 Giải thích về các cách viết đường dẫn LVM

Trong Linux, **"Mọi thứ đều là File"**. Khi bạn làm việc với LVM, hệ điều hành đại diện cho mỗi phân vùng bằng các tệp thiết bị (device file) trong thư mục `/dev/`.

### 1. Hai cách viết phổ biến:
*   **Cách 1: `/dev/VG_NAME/LV_NAME`** (Ví dụ: `/dev/u02/data2`)
    - Đây là cách viết truyền thống của LVM. Nó giúp người dùng dễ đọc vì phân cấp theo: **Thư mục thiết bị** -> **Tên Nhóm (Volume Group)** -> **Tên Phân vùng (Logical Volume)**.
*   **Cách 2: `/dev/mapper/VG_NAME-LV_NAME`** (Ví dụ: `/dev/mapper/u02-data2`)
    - Đây là cách viết của tầng **Device Mapper** (hạt nhân Linux quản lý các thiết bị ảo).

### 2. Tại sao mình lại khuyên bạn dùng Cách 2 (`/dev/mapper/...`)?
*   **Sự đồng nhất:** Khi bạn gõ lệnh kiểm tra dung lượng `df -h`, hệ điều hành luôn hiển thị kết quả là `/dev/mapper/u02-data2`.
*   **Dễ thao tác:** Khi bạn thấy ổ nào sắp đầy ở cột bên trái của lệnh `df -h`, bạn chỉ cần bôi đen, copy và paste vào lệnh `lvextend`. Bạn không cần phải "dịch" ngược lại xem Volume Group tên là gì để viết theo kiểu Cách 1.
*   **Tính ổn định:** Cách viết này chỉ định trực tiếp tệp thiết bị mà hệ thống đang sử dụng để ánh xạ phân vùng.

**Tóm lại:** Cả hai cách viết đều mang lại kết quả **giống hệt nhau** trên ổ cứng của bạn. Việc nắm vững cả hai cách giúp bạn có thể đọc hiểu mọi tài liệu hướng dẫn LVM khác nhau một cách dễ dàng.
