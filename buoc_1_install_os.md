# Bước 1 - Cài Đặt Hệ Điều Hành & Cấu Hình LVM ổ cứng (Oracle Linux 7.8)

Tài liệu này hướng dẫn chi tiết quá trình cài đặt hệ điều hành và cấu hình ổ cứng (LVM) cho Oracle Linux 7.8. Phần cấu hình ổ cứng được chia thành **2 Trường Hợp (Cases)** để bạn lựa chọn tùy theo phương pháp muốn sử dụng:

---

### PHẦN 1: TẠO MÁY ẢO VMWARE & TÙY CHỌN GẮN Ổ CỨNG

1. Mở VMware -> Nhấp **Create a New Virtual Machine...**
2. Tại màn hình "Specify Disk Capacity": Nhập **`50.0`** GB (Tick chọn *Store virtual disk as a single file*). 
3. Nhấp **Finish** để hoàn tất khởi tạo máy ảo.
4. Nhấp **Edit virtual machine settings**, tăng tối đa RAM lên **`8192 MB`** và Processors lên **`4 cores`** (2 CPU, mỗi CPU 2 nhân).

🔹 **QUYẾT ĐỊNH CHỌN LỐI ĐI TỪ ĐÂY:**
*   **🟢 Trường hợp 1 (Dùng giao diện đồ hoạ OUI):** Tại bảng Settings này, nhấp `Add...` -> `Hard Disk` để thêm 2 ổ cứng ảo (40GB và 50GB). Tổng thể máy có 3 ổ vật lý.
*   **🟠 Trường hợp 2 (Dùng dòng lệnh CLI):** Không thêm ổ cứng mới. Đóng bảng Hardware. Máy lúc này chỉ có duy nhất 1 ổ 50GB.

Chọn file ISO hệ điều hành trong mục CD/DVD rồi nhấp **Power On** để khởi động máy ảo.

---

### PHẦN 2: CHỌN ĐÚNG TRƯỜNG HỢP CÀI LVM (INSTALLATION DESTINATION)

Tại màn hình `INSTALLATION SUMMARY`:
Thực hiện các thiết lập cơ bản: `Software Selection` (Chọn *Server with GUI*, tick *Development Tools* & *Compatibility Libraries*), phần `Network` (Bật *ON*, điền *Hostname*), và `Kdump` (Bỏ tick mục *Enable kdump*).

Tại phần **`INSTALLATION DESTINATION`**, hãy thực hiện theo lựa chọn ban đầu của bạn:

#### 🟢 TRƯỜNG HỢP 1: TẠO LVM BẰNG GIAO DIỆN (Máy có sẵn 3 ổ sda, sdb, sdc)
Tick chọn cả 3 ổ đĩa. Chọn tùy chọn **`I will configure partitioning`** rồi nhấp **Done**.
Tại bảng MANUAL PARTITIONING, đảm bảo kiểu phân vùng là `LVM`:
1. Phân vùng Hệ điều hành (ổ `sda`):
   - Nhấp `+` -> Nhập `/boot` (1 GB) -> Ở cột phải, đổi Device Type thành *Standard Partition*. File System là *xfs*.
   - Nhấp `+` -> Nhập `swap` (8 GB) -> Nhấp nút *Modify* ở cột phải, **chỉ giữ lại đĩa SDA 50G**.
   - Nhấp `+` -> Nhập `/` (Phần dung lượng để trống) -> Nhấp *Modify*, **chỉ giữ lại đĩa SDA 50G**. Nhấp Save.
2. Phân vùng Phần mềm `/u01` (ổ `sdb`):
   - Nhấp `+` -> Nhập `/u01` (Dung lượng để trống) -> Add. Nhấp *Modify* -> Chọn *Create a new volume group*, đặt tên `vg_u01` và **chỉ tick vào đĩa SDB 40G**. Save.
3. Phân vùng Dữ liệu `/u02` (ổ `sdc`):
   - Nhấp `+` -> Nhập `/u02` (Dung lượng để trống) -> Add. Nhấp *Modify* -> Chọn *Create a new volume group*, đặt tên `vg_u02` và **chỉ tick vào đĩa SDC 50G**. Save.
   
Nhấp **Done** -> **Accept Changes**. Hoàn tất cấu hình LVM bằng giao diện. Nhấp `Begin Installation` để bắt đầu cài đặt.

#### 🟠 TRƯỜNG HỢP 2: CÀI OS TRƯỚC VÀ CẤU HÌNH LVM SAU BẰNG LỆNH (Máy có 1 ổ sda 50G)
Màn hình chỉ hiển thị 1 ổ đĩa cứng 50G. Tick chọn nó, chọn **`I will configure partitioning`** rồi nhấp **Done**.
Tại bảng MANUAL PARTITIONING:
1. Nhấp `+` -> Nhập `/boot` (1 GB) -> Đổi Device Type thành *Standard Partition*.
2. Nhấp `+` -> Lựa chọn `swap` (8 GB).
3. Nhấp `+` -> Nhập `/` (Mục Capacity để trống).

Nhấp **Done** -> **Accept Changes**. Nhấp `Begin Installation`. Đặt `Root Password`, chấp nhận `License Agreement` (sau khi khởi động lại) cho đến khi vào màn hình Desktop.

**CÁC BƯỚC CẤU HÌNH BẰNG DÒNG LỆNH (COMMAND LINE) SAU KHI CÀI OS:**
Tắt máy ảo (Power Off). Mở **VMware Settings**, nhấp **Add** để thêm 2 ổ đĩa ảo: SDB (40G) và SDC (50G). Bật máy ảo (Power On). Mở Terminal bằng quyền `root` và nhập tuần tự các lệnh LVM dưới đây:

```bash
# --- BƯỚC 1: KHỞI TẠO Ổ ĐĨA VẬT LÝ (Physical Volume) ---
# Lệnh pvcreate (Physical Volume Create) dán nhãn 2 ổ đĩa thô vừa cắm vào (sdb và sdc) để công cụ LVM bắt đầu quản lý.
pvcreate /dev/sdb
pvcreate /dev/sdc

# --- BƯỚC 2: TẠO NHÓM Ổ ĐĨA TỔNG (Volume Group) ---
# Lệnh vgcreate (Volume Group Create) gom các ổ đĩa vật lý thành những cái "Kho" độc lập. 
# Cú pháp: vgcreate [TÊN_KHO_BẠN_MUỐN_ĐẶT] [Ổ_ĐĨA_NGUỒN]
vgcreate vg_u01 /dev/sdb
vgcreate vg_u02 /dev/sdc

# --- BƯỚC 3: RÚT PHÂN VÙNG ẢO (Logical Volume) TỪ KHO ---
# Lệnh lvcreate (Logical Volume Create) rút linh hoạt dung lượng từ "Kho" (VG) ra thành phân vùng ảo để sử dụng.
# Giải thích cờ: 
#   -n : Định danh Tên phân vùng ảo (lv_u01)
#   -l 100%FREE : Yêu cầu cấp phát sử dụng toàn bộ 100% dung lượng trống của kho.
# Chữ cuối cùng bắt buộc phải gọi đúng tên Kho (VG) mà bạn đã tạo ở Bước 2. Nếu gõ chệch tên sẽ gây báo lỗi.
lvcreate -n lv_u01 -l 100%FREE vg_u01
lvcreate -n lv_u02 -l 100%FREE vg_u02

# --- BƯỚC 4: FORMAT ĐỊNH DẠNG FILE HỆ THỐNG TỐI ƯU CỦA ĐĨA ---
# Lệnh mkfs.xfs (Make File System) đúc khuôn phân vùng ảo thành định dạng XFS (chuẩn file tối ưu nhất của Oracle Linux) để có thể bắt đầu ghi nhận dữ liệu.
# Đường dẫn thiết bị ảo LVM thường sinh ra theo quy tắc tự động: /dev/Tên_Kho/Tên_Phân_Vùng
mkfs.xfs /dev/vg_u01/lv_u01
mkfs.xfs /dev/vg_u02/lv_u02

# --- BƯỚC 5: TẠO ĐIỂM GẮN KẾT (Mount Point) ĐỂ SỬ DỤNG ---
# 1. Bắt buộc phải có dấu gạch chéo '/' phía trước để ra lệnh tạo các thư mục rỗng chuẩn nằm ở ngay nhánh gốc (Root) của Hệ điều hành. Đừng gõ thiếu kẻo tạo nhầm ở thư mục nội bộ.
mkdir -p /u01
mkdir -p /u02

# 2. Lệnh Mount làm nhiệm vụ "bắt vít" gắn cái thư mục rỗng đó chốt dính chặt vào phân vùng đĩa ảo đã format xong ở bước 4. 
# Kể từ lúc gõ lệnh này, mọi dữ liệu bạn chép vào /u01 đều được hệ thống dẫn luồng ghi trực tiếp xuống mặt ổ đĩa ảo lv_u01.
mount /dev/vg_u01/lv_u01 /u01
mount /dev/vg_u02/lv_u02 /u02

# --- BƯỚC 6: CÔNG ĐOẠN SỐNG CÒN - GHI CHỐT VĨNH VIỄN VÀO FILE HỆ THỐNG CỐT LÕI (fstab) ---
# Nếu bạn tắt máy (Reboot) bây giờ, 2 lệnh mount ở trên sẽ bị hệ thống văng ra quên mất. Bạn PHẢI ghi cứng đường dẫn vào cuốn sổ nhân HĐH (/etc/fstab) để Linux tự động nhặt và gắn đĩa mỗi khi bật nguồn máy chủ.
# Bạn có thể gõ lệnh "vi /etc/fstab" rồi thao tác copy dán, HOẶC dùng lệnh echo >> để đẩy nhét thẳng 2 dòng địa chỉ này xuống dưới đáy file fstab cực lẹ mà không cần mở trình gõ code:
echo "/dev/mapper/vg_u01-lv_u01   /u01    xfs    defaults    0 0" >> /etc/fstab
echo "/dev/mapper/vg_u02-lv_u02   /u02    xfs    defaults    0 0" >> /etc/fstab

# --- BƯỚC 7: KIỂM TRA LỖI TEST ĐỘ CHẮC HĐH TRƯỚC KHI REBOOT ---
# Hễ đụng tay vào bảng chỉnh sửa file hạt nhân fstab, bạn TUYỆT ĐỐI KHÔNG ĐƯỢC nóng nẩy Restart máy ngay. Nếu xui xẻo gõ lỡ sai chính tả một chữ cái, khi Boot vào HĐH sẽ vỡ tan cấu trúc và xịt ra màn hình báo lỗi Kernel Panic ngưng khởi động vĩnh viễn. 
# Bạn phải rào lướt kiểm tra ngay bằng "Thập cẩm chú kép" sau:
umount -a    # Lệnh tháo dỡ gỡ Mount toàn bộ các đĩa tạm thời ở hiện tại đang cắm mộc thủ công trong bước 5.
mount -a     # Lệnh ép HĐH quét đọc lại toàn bộ các câu chữ viết trong file fstab. 

# NẾU câu lệnh mount -a chạy êm ru, tuột dòng nhẹ hẫng không báo lên màn hình dòng chữ Lỗi Error văng nào -> Tuyệt đỉnh! Fstab đã gõ CHUẨN 100% không tì vết lỗi lầm! 

# Hãy chốt lệnh kết thúc bằng lệnh df -h để ung dung thu hưởng ngắm nghía hai khối đĩa dung tích khổng lồ 40G, 50G đã được cài chặt vững như Thạch Bàn. Chúc sướng tay!
```

---
*(Đến đây là vẹn toàn toàn trình Bước 1: Máy chủ đã được cài đặt cứng cáp chia rẽ `/u01`, `/u02`. Chuyển ngay vành đai sang File Tài Liệu **Bước 2 - Preinstall Oracle** để triển thao tác bện cài dịch vụ nền tảng trước chuẩn bị đón Database).*
