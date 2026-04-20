# Bước 1.5 - Hướng dẫn thêm ổ cứng và cấu hình LVM bằng dòng lệnh (Dành cho người muốn ôn tập Command Line)

Vì bạn quyết định thử thách bản thân bằng cách cài OS trước (chỉ với 1 ổ 50GB) rồi mới thêm các ổ chứa Data sau, đây chính xác là những gì một Quản trị viên hệ thống (Sysadmin/DBA) thực thụ phải làm ngoài đời thực!

Dưới đây là các bước thao tác 100% bằng màn hình đen (Terminal) để cấu hình 2 ổ cứng mới trên Linux sử dụng công nghệ LVM (Logical Volume Manager).

### 1. Thêm ổ cứng vào VMware
1. Sau khi đã cài xong OS ở Bước 1 và máy ảo đang tắt máy (Power Off). Bạn mở giao diện **Edit virtual machine settings**.
2. Bấm **Add...** -> **Hard Disk** -> **SCSI** -> **Create a new virtual disk**.
3. Thêm đĩa số 2: Nhập dung lượng **`40 GB`** (Tick chọn Store virtual disk as a single file). Đặt tên file `Oracle_19c_Server-u01.vmdk` -> Finish.
4. Thêm đĩa số 3: Lặp lại quá trình, nhập dung lượng **`50 GB`**. Đặt tên file `Oracle_19c_Server-u02.vmdk` -> Finish.
5. Bấm **OK** để lưu lại -> Mở **Power On** máy ảo lên.

---

### 2. Kiểm tra ổ cứng mới trong Linux
Mở Terminal, đăng nhập bằng quyển siêu quản trị **`root`** (`su - root`). Gõ lệnh liệt kê Block Devices:
```bash
lsblk
```
Bạn sẽ nhìn thấy 2 đĩa mới toanh chưa hề có phân vùng xuất hiện ở dưới. Thông thường, chúng sẽ được hệ thống gán nhãn tên là **`sdb`** (40GB) và **`sdc`** (50GB). *(Ổ `sda` 50GB trên cùng đã chẻ ra thành boot, root và swap chứa hệ điều hành của bạn rồi).*

---

### 3. Thiết lập LVM (Physical Volume -> Volume Group -> Logical Volume)

LVM là kỹ thuật Gom - Chia ổ đĩa cực kỳ linh hoạt chia làm 3 tầng nhận diện. Hãy gõ lần lượt các lệnh sau:

**Tầng 1: Tạo Physical Volume (PV) - Đánh dấu các ổ đĩa vật lý để LVM quản lý**
```bash
pvcreate /dev/sdb
pvcreate /dev/sdc
```
*(Nếu hệ thống báo lệnh không tìm thấy, tức là bạn cài OS quá tối giản, hãy mồi bằng lệnh tải gói cài: `yum install lvm2 -y` sau đó chạy lại lệnh pvcreate)*

**Tầng 2: Tạo Volume Group (VG) - Tạo các Nhóm dung lượng độc lập**
Tại đây, chúng ta tạo ra 2 nhóm Group riêng biệt: `vg_u01` sẽ gom ổ `sdb` và `vg_u02` sẽ gom ổ `sdc` vào.
```bash
vgcreate vg_u01 /dev/sdb
vgcreate vg_u02 /dev/sdc
```

**Tầng 3: Tạo Logical Volume (LV) - Cắt phân vùng ảo từ nhóm VG**
Chúng ta sẽ "rút" sạch sẽ toàn bộ 100% dung lượng trống của mỗi nhóm VG để tạo thành 2 phân vùng ảo (LV) đem đi sử dụng.
```bash
lvcreate -n lv_u01 -l 100%FREE vg_u01
lvcreate -n lv_u02 -l 100%FREE vg_u02
```

---

### 4. Định dạng File System (Format ổ cứng)

Sau khi chẻ ra được phân vùng ảo `lv_u01` và `lv_u02`, ta vẫn chưa ghi dữ liệu lên được. Phải format chúng bằng hệ thống file **XFS** (chuẩn file siêu nén tối ưu nhất cho Oracle chạy trên môi trường mã nguồn mở thay vì dùng thẻ ext4 cũ kĩ).

Đường dẫn thiết bị ảo LVM hệ thống đẻ ra thường nằm quy tắc ở `/dev/Tên_VG/Tên_LV`:
```bash
mkfs.xfs /dev/vg_u01/lv_u01
mkfs.xfs /dev/vg_u02/lv_u02
```

---

### 5. Tạo Điểm Gắn Kết (Mount Point) và Gắn Ổ Cứng

Trong nhân Linux không tồn tại khái niệm ổ đĩa C, D, E loằng ngoằng. Mọi ổ đĩa vật lý cắm mới vào đều phải được trỏ ngầm định (Mount) núp vào lưng một thư mục rỗng.
```bash
# Tạo 2 chiếc thư mục rỗng nằm vạ vật ngay gốc hệ điều hành
mkdir -p /u01
mkdir -p /u02

# Gắn (Mount) các phân vùng LVM vào 2 chiếc thư mục rỗng này
mount /dev/vg_u01/lv_u01 /u01
mount /dev/vg_u02/lv_u02 /u02
```

Lúc này, bạn hãy gõ lệnh đi phơi bày băng thông dung lượng:
```bash
df -h
```
Bạn sẽ thấy 2 thư mục `/u01` có 40GB và `/u02` có 50GB mọc lên hoành tráng trong danh sách cuối cùng.

---

### 6. Cấu hình tự gắn ổ đĩa khi khởi động (CỰC KỲ QUAN TRỌNG)

Lệnh `mount` bằng tay ở trên là tạm bợ, nó sẽ bị bốc hơi văng ra ngoài ngay khi bạn tắt máy. Để cặp đĩa `/u01`, `/u02` dính chặt như keo 502 với OS, ta phải đăng ký chúng với Cục Quản Lý Nhân (file `/etc/fstab`).

Mở file thiết yếu này ra bằng công cụ `vi`:
```bash
vi /etc/fstab
```

Bấm phím **`i`** để sang chế độ thêm thắt. Di chuyển con trỏ xuống tận **Dưới cùng** của file và Gõ thêm thủ công 2 dòng y chang như sau (Dùng phím Tab bàn phím thay cho dấu cách để căn lề đẹp mắt):
```text
/dev/mapper/vg_u01-lv_u01   /u01    xfs    defaults    0 0
/dev/mapper/vg_u02-lv_u02   /u02    xfs    defaults    0 0
```
Xong xuôi thì bấm phím chữ `ESC`, Cạch dấu `:` gõ chữ `wq!` rồi đập Enter để Save.

**CẢNH BÁO BẮT BUỘC TEST TRƯỚC KHI REBOOT:**
Tương truyền sau khi sửa `fstab`, tuyệt đối không được gõ thử `reboot` máy ngay lập tức. Nếu bạn luống cuống gõ lệch chữ `defaults` thành chữ `defauld` ở bước trên, khởi động lại hệ thống sẽ cắn lỗi treo cứng màn hình (Kernel Panic - vỡ nhân) đòi nhét đĩa vào cứu viện mệt lử. Hãy dùng tool **Test cửa tử** an toàn siêu xịn sau:
```bash
# Đá bung/Gỡ gắn kết hai ổ đĩa hiện tại
umount /u01
umount /u02

# Ép hệ điều hành quét đọc lại cái file fstab ban nãy xem gõ đúng cú pháp không rồi tự móc nối ra
mount -a
```
Nếu lệnh `mount -a` chạy ngấm ngầm qua cái vèo, im phăng phắc không báo dòng chữ Error lòe loẹt màu đỏ nào cả. Bạn hãy vui vẻ test lần chót `df -h`. 
Thấy hai em thư mục `/u01`, `/u02` hiên ngang trở lại -> Tuyệt Tác! Quá trình nâng cấp LVM của bạn đã thành công như một DBA chính hiệu!

===========================

*(Khi hoàn thành toàn bộ bài tập bổ túc ở file này xong, bạn mới lôi cái file **Bước 2 - Pre-install Oracle** ra chạy tiếp bước số 1 `dnf` tải package và chạy bước 3 `chown` đổi chủ quyền sở hữu thư mục cho user `oracle` quản lý là vừa vặn trơn tru nhé!)*
