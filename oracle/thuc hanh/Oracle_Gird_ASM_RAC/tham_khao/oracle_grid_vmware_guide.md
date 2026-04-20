# [TÀI LIỆU CŨ] - Vui lòng xem lộ trình mới tại [00_RAC_Setup_Roadmap.md](file:///d:/DB/setup/oracle/thuc%20hanh/Oracle_Gird_ASM_RAC/00_RAC_Setup_Roadmap.md)

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

---

## Bước tiếp theo (Rất quan trọng)

Sau khi bạn đã hoàn tất việc cấu hình ổ đĩa dùng chung trên VMware và sửa file `.vmx`, hệ thống của bạn đã có "phần cứng" chuẩn. Tuy nhiên, bạn **chưa thể** cấu hình UDEV Rules ngay lúc này.

Bạn cần thực hiện theo trình tự sau:

1.  **Tiếp tục với Bước 2:** Cấu hình Hệ điều hành, tạo người dùng `grid` và `oracle` tại tài liệu [oracle_rac_os_prep.md](file:///d:/DB/setup/oracle/thuc%20hanh/Oracle_Gird_ASM_RAC/oracle_rac_os_prep.md). (Chỉ khi có người dùng `grid`, bước cấu hình ổ đĩa mới có ý nghĩa).
2.  **Quay lại Bước 3:** Sau khi đã có người dùng, hãy thực hiện cấu hình **UDEV Rules** để gán quyền cho ổ đĩa tại tài liệu chuyên biệt: [oracle_rac_udev_asm.md](file:///d:/DB/setup/oracle/thuc%20hanh/Oracle_Gird_ASM_RAC/oracle_rac_udev_asm.md).

---
