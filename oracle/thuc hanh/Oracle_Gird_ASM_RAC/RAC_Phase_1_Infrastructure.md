# Giai đoạn 1: Setup Hạ tầng (Infrastructure Setup)

Giai đoạn này tập trung vào việc xử lý định danh máy ảo, quy hoạch mạng chi tiết và chuẩn bị cấu hình Shared Disk trên VMware.

---

## 1. Định danh và Mạng (OS Identity & Network)
Thực hiện ngay sau khi bạn bật máy ảo Node 2 (Clone từ Node 1) lên lần đầu.

### 1.1 Xử lý định danh sau khi Clone (Trên Node 2)
```bash
# Đổi Hostname duy nhất
hostnamectl set-hostname oracle2.localdomain

# Reset Machine-ID (Tránh xung đột DHCP/Logging)
rm -f /etc/machine-id /var/lib/dbus/machine-id
systemd-machine-id-setup

# Reset SSH Host Keys
rm -f /etc/ssh/ssh_host_*
ssh-keygen -A
```

### 1.2 Quy hoạch Địa chỉ IP (IP Planning)
Mỗi Node yêu cầu ít nhất 3 loại địa chỉ IP. Giả sử dải mạng Public/NAT là `.153.x`.

| Loại IP | Mục đích | Node 1 | Node 2 |
| :--- | :--- | :--- | :--- |
| **Public IP** | Kết nối chính (Quản trị, SSH) | `192.168.153.131` | `192.168.153.132` |
| **Virtual IP (VIP)** | Chuyển đổi dự phòng cho Client | `192.168.153.111` | `192.168.153.112` |
| **Private IP** | Đồng bộ dữ liệu (Interconnect) | `10.10.10.101` | `10.10.10.102` |
| **SCAN IP** | Điểm truy cập chung cho cả cụm | `192.168.153.120` | (Dùng chung) |

> [!IMPORTANT]
> - **Public IP** và **Private IP**: Phải cấu hình cứng (Static) vào card mạng.
> - **VIP** và **SCAN IP**: Tuyệt đối **KHÔNG** gán thủ công. Khi cài Grid, hệ thống sẽ tự động gán các IP này lên card mạng ảo (VD: `ens33:1`).

### 1.3 Cấu hình Card mạng và File /etc/hosts
- **Card Private (Host-only):** Cấu hình IP Static, tuyệt đối **KHÔNG** đặt Gateway và DNS.
- **Card Public (NAT):** Cấu hình IP Static, có Gateway để ra Internet tải gói cài đặt.
- **Tắt DHCP:** Trong VMware Network Editor, hãy bỏ tích ô "Use local DHCP..." cho cả 2 mạng VMnet tương ứng.
- **File /etc/hosts:** Dán toàn bộ bảng quy hoạch IP trên vào file `/etc/hosts` của **CẢ 2 NODES**.

### 1.4 Tắt tường lửa và SELinux
Tránh lỗi kết nối Interconnect và OUI:
```bash
# Tắt Firewall
systemctl stop firewalld
systemctl disable firewalld

# Tắt SELinux (Yêu cầu restart máy để áp dụng vĩnh viễn)
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
setenforce 0
```

---

## 2. Cấu hình Shared Disk (VMware Workstation)

> [!WARNING]
> **Lưu ý Nền tảng:** Hướng dẫn này dành riêng cho **VMware Workstation**. VMware mặc định không sinh ra để lập hệ thống Storage (SAN/NAS) cho nhiều máy tính cùng truy cập đồng thời, nên ta cần dùng thủ thuật tắt Disk Locking.

### 2.1 Tạo ổ đĩa dùng chung trên Node 1
Nên tạo một thư mục riêng (VD: `D:\VMs\Shared_Disks`) để lưu các file đĩa này.
1. Mở Settings Node 1 (Power Off) -> **Add...** -> **Hard Disk** -> **SCSI** -> **Create new virtual disk**.
2. **Cập nhật dung lượng đĩa:**
   - **ASM_OCR.vmdk:** 10GB (Clusterware OCR & Voting).
   - **ASM_DATA.vmdk:** 30GB+ (Database Data files).
   - **ASM_FRA.vmdk:** 20GB+ (Recovery Area & Archivelogs).
3. **QUAN TRỌNG:** 
   - Bắt buộc tick **Allocate all disk space now** (Thick Provision Eager Zeroed).
   - Bắt buộc chọn **Store virtual disk as a single file**. Tuyệt đối không chọn *multiple files* để tránh lỗi khóa đĩa chia nhỏ sau này.
4. **Location:** Xóa tên file mặc định, tự gõ lại tên (VD: `D:\VMs\Shared_Disks\ASM_OCR.vmdk`) để lưu vào thư mục dùng chung. Bấm Finish (Chờ một lúc để VMware khởi tạo dung lượng).

### 2.2 Thiết lập Chế độ Độc lập (Independent)
*(Mẹo: Nếu giao diện không cho nhấn tiếp, hãy bấm OK ở ngoài cùng để lưu đĩa trước, xong mở lại Edit settings).*
Tại màn hình Settings của Node 1 cho từng ổ Shared:
1. Chọn ổ đĩa -> Bấm **Advanced...**.
2. **Kích hoạt tick ô Independent** và chọn **Persistent**. (Phải tick ô này mới bật được tính năng chia sẻ độc lập, bỏ qua check Snapshot).
3. **Virtual Device Node:** Bắt buộc phải nằm ở một Controller khác (VD: **SCSI 1:0**, **SCSI 1:1**...). Tuyệt đối không để chung Controller `SCSI 0` với ổ điều hành. Nếu bạn thấy nó đang là `SCSI 0:1, 0:2`... thì phải đổi ngay sang nhóm `SCSI 1`.

### 2.3 Thêm ổ đĩa đã tạo vào Node 2
1. Mở Settings Node 2 (Power Off) -> **Add...** -> **Hard Disk** -> **SCSI** -> **Use an existing virtual disk**.
2. Bấm *Browse*, trỏ tới các file `.vmdk` ở Node 1. 
   - **CẨN THẬN:** Bạn sẽ thấy cặp file (VD: `ASM_OCR.vmdk` và `ASM_OCR-flat.vmdk`). **Đừng bao giờ chọn file `-flat`** (đó là data thô), hãy trỏ vào file tên gốc chứa thông số.
3. Lặp lại việc thiết lập **Independent - Persistent** và gán đúng kênh SCSI (VD: 1:0, 1:1) khớp hoàn toàn với Node 1.

### 2.4 Cấu hình file .vmx (Bước quyết định)
1. Tắt hoàn toàn phần mềm VMware Workstation.
2. Mở file `.vmx` của cả 2 node bằng Notepad++. Cuộn xuống cuối dán đoạn code:
```properties
disk.EnableUUID = "TRUE"
disk.locking = "FALSE"
# scsi1 ứng với Controller bạn đã chọn ở bước trên
scsi1.sharedBus = "virtual" 
```
- `disk.EnableUUID = "TRUE"`: Giúp Linux nhận diện UUID cố định cho UDEV Rules.
- `disk.locking = "FALSE"`: Vô hiệu hóa bảo vệ chống ghi đồng thời của VMware.

---

## 3. Giải đáp thắc mắc về Mạng (Q&A)

**1. Tại sao có card mạng ảo `virbr0`?** 
- Do libvirt tự sinh ra, bạn có thể bỏ qua. Chỉ tập trung vào `ens33`, `ens37`.

**2. Tại sao không gán VIP thủ công?**
- Vì Grid Infrastructure sẽ tự quản lý. Nếu bạn gán trước, bộ cài sẽ báo lỗi IP đã tồn tại.

---
> [!TIP]
> **Kiểm tra cuối:** Thử ping qua lại giữa 2 Node bằng cả tên (Hostname) và IP. Nếu thông suốt, hãy chuyển sang **[Giai đoạn 2: Setup Môi trường](RAC_Phase_2_Environment.md)**.
