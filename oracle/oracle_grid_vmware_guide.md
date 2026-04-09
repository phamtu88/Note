# Hướng dẫn Cấu hình VMware Workstation để cài đặt Oracle Grid Infrastructure

Khi cài đặt Oracle Grid Infrastructure (đặc biệt là cho Oracle RAC), yêu cầu quan trọng nhất là bạn phải có **Ổ cứng dùng chung (Shared Disks)** để cấu hình ASM (Automatic Storage Management). 

VMware Workstation mặc định không sinh ra để lập hệ thống Storage (SAN/NAS) cho nhiều máy tính cùng truy cập đồng thời vào một ổ. Do đó, chúng ta cần dùng một thủ thuật để tắt tính năng khóa file đĩa (Disk Locking) của VMware.

Dưới đây là các bước chi tiết để tạo hệ thống đĩa dùng chung cho Oracle Grid (Node 1 & Node 2).

---

## Phần 1: Tạo ổ cứng dùng chung (Shared Disks) trên VMware

Bạn nên tạo một thư mục riêng biệt trên máy tính thật (Windows) để lưu các ổ cứng dùng chung này (VD: `D:\VMs\Shared_Disks`). Giả sử chúng ta sẽ tạo 3 ổ cứng: 1 cho OCR/VOTING, 1 cho DATA, 1 cho FRA.

### Bước 1: Tạo ổ đĩa trên Node 1
1. Mở máy ảo Node 1 (đang tắt/Power Off). Chọn **Edit virtual machine settings**.
2. Bấm **Add...** -> Chọn **Hard Disk** -> Next.
3. Chọn **SCSI** (Recommended) -> Next.
4. Chọn **Create a new virtual disk** -> Next.
5. Cập nhật dung lượng đĩa (Ví dụ 10GB cho ASM_OCR).
   > [!IMPORTANT]
   > Bạn BẮT BUỘC phải tick vào ô **Allocate all disk space now** (Thick Provision Eager Zeroed). Các giải pháp Shared disk không hoạt động tốt với đĩa dạng cấp phát động (Thin provision).
6. Chọn **Store virtual disk as a single file** -> Next.
7. Đặt tên và lưu vào thư mục dùng chung (VD: `D:\VMs\Shared_Disks\ASM_OCR.vmdk`). Bấm Finish (Chờ một lúc để VMware khởi tạo dung lượng).

Lặp lại quy trình trên để tạo thêm ổ `ASM_DATA.vmdk` và `ASM_FRA.vmdk`.

### Bước 2: Đổi Mode của ổ đĩa thành Independent - Persistent
Sau khi tạo xong các ổ cứng, ở màn hình **Virtual machine settings** của Node 1:
1. Vẫn đang chọn từng ổ cứng SCSI vừa tạo.
2. Bấm nút **Advanced...** ở góc bên phải.
3. Tick chọn **Independent** -> Đảm bảo chọn **Persistent**.
4. Ghi nhớ các kênh SCSI, ví dụ: Ổ gốc chữa HĐH là `SCSI 0:0`. Các ổ mới tạo sẽ là `SCSI 1:0`, `SCSI 1:1`, `SCSI 1:2`... (Rất quan trọng). Hãy cố gắng xếp các đĩa ASM vào cùng một controller mới (VD: SCSI 1).

### Bước 3: Thêm ổ đĩa đã tạo vào Node 2
1. Tắt máy ảo Node 2. Truy cập **Edit virtual machine settings**.
2. Bấm **Add...** -> **Hard Disk** -> **SCSI**.
3. Tại bước chọn loại Disk, chọn **Use an existing virtual disk** -> Next.
4. Browse tới thư mục `D:\VMs\Shared_Disks\` và chọn từng file `.vmdk` đã tạo ở Bước 1.
5. Lặp lại việc bấm vào **Advanced...** -> Tick **Independent** và chọn **Persistent** cho Node 2.
6. *Lưu ý*: Hãy đảm bảo số thứ tự Node (SCSI 1:0, SCSI 1:1, v.v.) trên Node 2 khớp hoàn toàn với Node 1 để dễ quản lý trong HĐH.

---

## Phần 2: Cấu hình file `.vmx` (Bước quyết định)

Nếu bạn bật cả 2 Node lúc này, máy tính thứ 2 khởi động lên sẽ báo lỗi disk bị lock (File in use). Ta cần cấu hình file ảo hóa để cho phép nhiều máy ảo cùng đọc/ghi vào 1 file VMDK.

1. Tắt hoàn toàn phần mềm VMware Workstation.
2. Tìm tới thư mục chứa máy ảo **Node 1** và mở file `<Tên máy ảo Node 1>.vmx` bằng Notepad++ hoặc VS Code.
3. Cuộn xuống cuối file và copy/paste đoạn cấu hình sau vào:

```properties
disk.EnableUUID = "TRUE"
disk.locking = "FALSE"
# Thay scsi1 bằng số controller của các ổ Shared (nếu bạn gán vào SCSI 1:x)
scsi1.sharedBus = "virtual" 
```

4. Làm tương tự: Mở file `<Tên máy ảo Node 2>.vmx` của Node 2 và dán đoạn cấu hình trên vào cuối file. Lưu lại.

> [!NOTE]
> - `disk.EnableUUID = "TRUE"`: Giúp HĐH Linux nhận diện đĩa có mã UUID cố định, rất quan trọng bước gán UDEV Rules.
> - `disk.locking = "FALSE"`: Vô hiệu hóa bảo vệ chống ghi đồng thời của VMware.
> - `scsi1.sharedBus = "virtual"`: Khai báo controller này đóng vai trò là bus chia sẻ.

---

## Phần 3: Cấu hình trên OS (Linux) để Oracle Grid nhận diện và sử dụng Disk

Việc thiết lập Share trên VMWare chỉ giúp 2 máy ảo Linux cùng nhìn thấy thiết bị (`/dev/sdb`, `/dev/sdc`...). Nhưng để cài Grid, ổ đĩa cần thuộc quyền của user `grid` và group `asmadmin`. Bạn cần dùng `udev` rules.

### Bước 1: Tìm ID của ổ cứng (Thực hiện trên Node 1)
Sau khi bật máy lên, mở terminal bằng root:
```bash
/usr/lib/udev/scsi_id -g -u -d /dev/sdb
/usr/lib/udev/scsi_id -g -u -d /dev/sdc
```
*Kết quả sẽ trả về một chuỗi UUID (VD: `36000c29b4e78a4b4cc8c5e62c8e1bcd1`). Hãy lưu các chuỗi này lại.*

### Bước 2: Viết rules cho udev
Tạo một file rule mới:
```bash
vi /etc/udev/rules.d/99-oracle-asmdevices.rules
```

Dán cấu hình sau (thay thế UUID thực tế bạn vừa lấy được), mỗi thiết bị là một dòng:

```properties
KERNEL=="sd*", SUBSYSTEM=="block", PROGRAM=="/usr/lib/udev/scsi_id -g -u -d /dev/$parent", RESULT=="<UUID_TỪ_BƯỚC_1>", SYMLINK+="oracleasm/ocr1", OWNER="grid", GROUP="asmadmin", MODE="0660"

KERNEL=="sd*", SUBSYSTEM=="block", PROGRAM=="/usr/lib/udev/scsi_id -g -u -d /dev/$parent", RESULT=="<UUID_TỪ_BƯỚC_1>", SYMLINK+="oracleasm/data1", OWNER="grid", GROUP="asmadmin", MODE="0660"
```

### Bước 3: Load lại udev rules
Chạy các lệnh sau trên Server (root) để OS nhận diện cấu hình mới:
```bash
/sbin/udevadm control --reload-rules
/sbin/udevadm trigger --type=devices --action=change
```

### Bước 4: Kiểm tra kết quả
```bash
ll /dev/oracleasm/*
```
Lúc này bạn sẽ nhìn thấy `/dev/oracleasm/ocr1`, `/dev/oracleasm/data1` được sinh ra, có màu vàng chữ nổi bật, và thuộc quyền sở hữu của `grid:asmadmin`.

Bây giờ bạn đã sẵn sàng chạy bộ cài `gridSetup.sh`. Khi đến bước tạo Disk Groups, ở ô **Disk Discovery Path**, hãy điền `/dev/oracleasm/*` để nhận các đĩa này.

> [!TIP]
> Bạn nhớ thực hiện tương tự Bước 2 và Bước 3 trên Node 2 (với cùng nội dung rule udev giống hệt) để Node 2 cũng nhận được các alias `/dev/oracleasm/...` trước khi cài đặt Grid.
