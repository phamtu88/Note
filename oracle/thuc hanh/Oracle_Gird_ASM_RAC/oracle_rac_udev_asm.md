# Bước 3: Cấu hình UDEV Rules cho ASM Shared Disks

Trong Oracle RAC, các Node cần truy cập vào cùng một ổ đĩa vật lý. Để Grid Infrastructure nhận diện chính xác và ổn định các ổ đĩa này, chúng ta cần gán cho chúng các tên gợi nhớ (Alias) cố định và phân quyền sở hữu cho user `grid`.

---

## 1. Tìm UUID của các ổ Shared Disks

Thực hiện trên **Node 1** bằng quyền `root`. Trước tiên, đảm bảo bạn đã gán các ổ đĩa SCSI mới từ VMware (như trong [Hướng dẫn VMware](oracle_grid_vmware_guide.md)).

```bash
# Liệt kê các ổ đĩa để xác định tên thiết bị (sdb, sdc, sdd...)
lsblk

# Chạy lệnh lấy UUID cho từng ổ (Ví dụ sdb là OCR)
/usr/lib/udev/scsi_id -g -u -d /dev/sdb
# Kết quả VD: 36000c29d009baba53549298586ea9a71

/usr/lib/udev/scsi_id -g -u -d /dev/sdc
# Kết quả VD: 36000c29f8f2b1d9c6c0e8a7d7f7e8a91

/usr/lib/udev/scsi_id -g -u -d /dev/sdd
# Kết quả VD: 36000c29a1b2c3d4e5f6a7b8c9d0e1f23
```

> [!TIP]
> Hãy ghi lại các UUID này tương ứng với mục đích (OCR, DATA, FRA) để viết Rule ở bước sau.

---

## 2. Tạo file UDEV Rules

Tạo file mới trên **CẢ 2 NODES** bằng quyền `root`:

```bash
vi /etc/udev/rules.d/99-oracle-asmdevices.rules
```

Dán nội dung sau vào (Hãy thay các chuỗi `RESULT=="..."` bằng UUID thực tế của bạn):

```properties
# ASM_OCR disk
KERNEL=="sd*", SUBSYSTEM=="block", PROGRAM=="/usr/lib/udev/scsi_id -g -u -d /dev/$parent", RESULT=="36000c29d009baba53549298586ea9a71", SYMLINK+="oracleasm/asm_ocr1", OWNER="grid", GROUP="asmadmin", MODE="0660"

# ASM_DATA disk
KERNEL=="sd*", SUBSYSTEM=="block", PROGRAM=="/usr/lib/udev/scsi_id -g -u -d /dev/$parent", RESULT=="36000c29f8f2b1d9c6c0e8a7d7f7e8a91", SYMLINK+="oracleasm/asm_data1", OWNER="grid", GROUP="asmadmin", MODE="0660"

# ASM_FRA disk
KERNEL=="sd*", SUBSYSTEM=="block", PROGRAM=="/usr/lib/udev/scsi_id -g -u -d /dev/$parent", RESULT=="36000c29a1b2c3d4e5f6a7b8c9d0e1f23", SYMLINK+="oracleasm/asm_fra1", OWNER="grid", GROUP="asmadmin", MODE="0660"
```

---

## 3. Áp dụng Rule (Reload UDEV)

Chạy các lệnh sau trên **CẢ 2 NODES** bằng quyền `root`:

```bash
/sbin/udevadm control --reload-rules
/sbin/udevadm trigger --type=devices --action=change
```

---

## 4. Kiểm tra kết quả

Nếu thành công, bạn sẽ thấy các đường dẫn ảo (Symlinks) xuất hiện với đúng quyền hạn:

```bash
ls -alt /dev/oracleasm/*
```

Kết quả mong đợi:
```text
lrwxrwxrwx 1 root root 7 Apr 12 10:20 /dev/oracleasm/asm_ocr1 -> ../sdb
lrwxrwxrwx 1 root root 7 Apr 12 10:20 /dev/oracleasm/asm_data1 -> ../sdc
lrwxrwxrwx 1 root root 7 Apr 12 10:20 /dev/oracleasm/asm_fra1 -> ../sdd
```

Và kiểm tra quyền của thiết bị gốc:
```bash
ls -l /dev/sdb /dev/sdc /dev/sdd
```
Kết quả phải hiển thị owner là `grid` và group là `asmadmin`.

---

## Lưu ý cực kỳ quan trọng

> [!CAUTION]
> Khi cài đặt Grid Infrastructure (ở bước sau), tại màn hình chọn Disk, bạn phải thay đổi **Disk Discovery Path** thành `/dev/oracleasm/*` thì bộ cài mới nhìn thấy các ổ đĩa này.

Bây giờ bạn đã sẵn sàng để tiến hành cài đặt phần mềm Grid Infrastructure!
