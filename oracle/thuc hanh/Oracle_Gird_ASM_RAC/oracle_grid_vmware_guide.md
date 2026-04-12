# Hướng dẫn Cấu hình VMware Workstation để cài đặt Oracle Grid Infrastructure

> [!WARNING]
> **Lưu ý Nền tảng:** Tài liệu này ĐƯỢC THIẾT KẾ DÀNH RIÊNG CHO **VMware Workstation**. Nếu sau này bạn chuyển sang thực hành trên **Oracle VM VirtualBox**, phương pháp tạo Shared Disk sẽ hoàn toàn khác (VirtualBox có giao diện chuyển Disk type sang *Shareable* trực tiếp thay vì phải can thiệp file cấu hình ẩn).

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
5. Cập nhật dung lượng đĩa:
   - **Ổ 1 (ASM_OCR):** 10GB (Dùng cho Clusterware OCR & Voting files).
   - **Ổ 2 (ASM_DATA):** 30GB+ (Dùng cho Database Data files).
   - **Ổ 3 (ASM_FRA):** 20GB+ (Dùng cho Recovery Area & Archivelogs).
   > [!IMPORTANT]
   > Bạn BẮT BUỘC phải tick vào ô **Allocate all disk space now** (Thick Provision Eager Zeroed). Ở bảng tiếp theo, bắt buộc chọn **Store virtual disk as a single file** (Tuyệt đối không chọn *multiple files* để tránh lỗi khóa đĩa chia nhỏ sau này).
6. Mục *Location*: Bạn hãy xóa tên file mặc định do hệ thống gợi ý và tự gõ lại để đặt tên rõ ràng, lưu vào thư mục dùng chung (VD: `D:\VMs\Shared_Disks\ASM_OCR.vmdk`). Bấm Finish (Chờ một lúc để VMware khởi tạo dung lượng).

Lặp lại quy trình trên để tạo thêm ổ `ASM_DATA.vmdk` và `ASM_FRA.vmdk`.

### Bước 2: Đổi Mode của ổ đĩa thành Independent - Persistent (Hay gặp lỗi khó gỡ)
Sau khi tạo xong các ổ cứng, ở màn hình **Virtual machine settings** của Node 1:
1. Chọn từng ổ cứng SCSI vừa tạo. *(Mẹo: Nếu giao diện không cho nhấn tiếp, hãy bấm **OK** ở ngoài cùng để lưu đĩa trước, xong mở lại Edit settings).*
2. Bấm nút **Advanced...** ở góc bên phải.
3. **Click chuột đánh dấu tick vào ô vuông nhỏ xíu** kề bên chữ **Independent**. (Phải tick vào ô này thì mới bật được tính năng chia sẻ độc lập, bỏ qua check Snapshot).
4. Đảm bảo chọn mốc bên dưới là **Persistent**.
5. Kiểm tra và ghi nhớ thông số **Virtual device node** (Kênh SCSI). 
   > [!IMPORTANT]
   > 1. Ổ đĩa cài hệ điều hành thông thường sẽ nằm ở `SCSI 0:0`.
   > 2. Các ổ Shared Disks **BẮT BUỘC phải nằm ở một Controller khác** (phải bấm sổ xuống chọn là `SCSI 1:x`, `SCSI 2:x`, `SCSI 3:x`...).
   > 3. **Tuyệt đối không** để ổ đĩa Shared dùng chung Controller `SCSI 0` với ổ điều hành. Nếu bạn kiểm tra ổ Shared mà thấy nó đang là `SCSI 0:1`, `SCSI 0:2`... thì bạn phải sổ danh sách xuống và chọn lại sang một nhóm `SCSI 1` hoặc `SCSI 2`.

### Bước 3: Thêm ổ đĩa đã tạo vào Node 2
1. Tắt máy ảo Node 2. Truy cập **Edit virtual machine settings**.
2. Bấm **Add...** -> **Hard Disk** -> **SCSI**.
3. Tại bước chọn loại Disk, ĐẶC BIỆT LƯU Ý, KHÔNG CHỌN TẠO MỚI MÀ CHỌN **Use an existing virtual disk** (Sử dụng đĩa đã có sẵn) -> Next.
4. Bấm *Browse*, duyệt tới thư mục `D:\VMs\Shared_Disks\`. 
   > [!CAUTION]
   > Tại bước này, bạn sẽ thấy cặp file sinh ra cho mỗi ổ (VD: `ASM_OCR.vmdk` và `ASM_OCR-flat.vmdk`). **Đừng bao giờ chọn file `-flat`**. File `-flat` chỉ là data thô. VMware bắt buộc bạn phải trỏ vào **file không có hậu tố `-flat`** (tức file chứa thông số của đĩa).
5. Lặp lại việc bấm vào **Advanced...** -> Kích hoạt tick ô **Independent** và chọn **Persistent** cho Node 2.
6. *Lưu ý*: Hãy đảm bảo số thứ tự Node (SCSI 0:1, SCSI 0:2, v.v.) trên Node 2 khớp hoàn toàn với Node 1. Mọi việc xong xuôi thì ấn OK để đóng lại.

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
/usr/lib/udev/scsi_id -g -u -d /dev/sdd
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

KERNEL=="sd*", SUBSYSTEM=="block", PROGRAM=="/usr/lib/udev/scsi_id -g -u -d /dev/$parent", RESULT=="<UUID_TỪ_BƯỚC_1>", SYMLINK+="oracleasm/fra1", OWNER="grid", GROUP="asmadmin", MODE="0660"
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
Lúc này bạn sẽ nhìn thấy `/dev/oracleasm/ocr1`, `/dev/oracleasm/data1`, `/dev/oracleasm/fra1` được sinh ra, có màu vàng chữ nổi bật, và thuộc quyền sở hữu của `grid:asmadmin`.


Bây giờ bạn đã sẵn sàng chạy bộ cài `gridSetup.sh`. Khi đến bước tạo Disk Groups, ở ô **Disk Discovery Path**, hãy điền `/dev/oracleasm/*` để nhận các đĩa này.

> [!TIP]
> Bạn nhớ thực hiện tương tự Bước 2 và Bước 3 trên Node 2 (với cùng nội dung rule udev giống hệt) để Node 2 cũng nhận được các alias `/dev/oracleasm/...` trước khi cài đặt Grid.

---

## Phụ lục: Triển khai Storage trong Môi trường Thực tế (Production)

Trong môi trường thực tế doanh nghiệp, việc chia sẻ ổ đĩa cho Oracle RAC **không** sử dụng file cấu hình `.vmx` như VMware Workstation mà sẽ dùng các thiết bị chuyên dụng:

**1. Môi trường Máy chủ Vật lý (Bare Metal) kết nối SAN/NAS:**
- **SAN Storage (Qua cáp quang FC):** Tủ đĩa (Dell EMC, NetApp, HP 3PAR) chia ra các cục đĩa ảo gọi là LUN. Quản trị viên thiết lập quyền (Zoning/Masking) ép 1 LUN này phát sóng đến đồng thời cả 2 máy chủ vật lý RAC thông qua Card quang HBA. Linux quét quang học sẽ nhận được `/dev/sdb`. Lúc này ta bỏ qua bài cấu hình VMware và chuyển thẳng sang đoạn viết UDEV Rules.
- **NAS Storage (NFS):** Các máy chủ truy cập dùng chung 1 thư mục mạng thông qua giao thức mạng dNFS cực nhanh của Oracle. File nằm gọn trên thư mục mạng.
- **iSCSI Storage:** Dùng 1 máy chủ vật lý thường làm điểm chia sẻ (Target). 2 Node RAC lên cấu hình (Initiator) để login lấy ổ đĩa dùng chung qua mạng IP (LAN).

**2. Môi trường VMware ESXi (vSphere / vCenter):**
VMware ESXi là hệ thống ảo hóa dành cho máy chủ. Cấu hình Share Disk trên ESXi đơn giản và chuẩn mực hơn Workstation rất nhiều với tính năng khóa **Multi-Writer**:
- **Tạo ổ cứng:** Ổ cứng BẮT BUỘC phải quy hoạch định dạng ở mức **Thick Provision Eager Zeroed**.
- **Chỉnh SCSI Controller:** Bộ điều khiển SCSI gánh các ổ chia sẻ phải được đổi thuộc tính *SCSI Bus Sharing* từ `None` sang **Physical** (nếu 2 VM RAC nằm trên 2 máy chủ ESXi khác nhau) hoặc **Virtual** (nếu 2 VM báo nằm chung 1 Host ESXi).
- **Cấu hình Multi-Writer flag:** Thay vì hì hục sửa file `.vmx` chống lock disk, trên giao diện vCenter xịn, bạn chỉ cần mở cài đặt ổ cứng, mụục *Sharing*, chọn cấu hình **Multi-writer**. ESXi sẽ chủ động bỏ khóa file và ném thẳng công việc điều phối I/O về cho phần mềm Oracle ASM tự phân xử.
