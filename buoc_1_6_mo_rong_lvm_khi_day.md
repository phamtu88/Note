# Phụ Lục: Hướng Dẫn Mở Rộng Dung Lượng ổ LVM Không Cần Khởi Động Lại Máy (Online Resize)

Một trong những ưu điểm lớn nhất của LVM (Logical Volume Manager) là khả năng mở rộng dung lượng lưu trữ ngay lúc máy đang hoạt động (Online Resizing) mà không làm gián đoạn hệ thống thư mục.

Ví dụ: Nếu phân vùng `/u01` (đang có 40GB) bị đầy, bạn có thể thực hiện 5 bước kỹ thuật sau để cấp thêm 20GB dung lượng cho nó:

### Bước 1: Thêm ổ đĩa vật lý mới từ VMware (Hot-Add)
Trên VMware, nhấp **Add...** -> Chọn **Hard Disk** -> Chọn dung lượng (Ví dụ: 20GB). Quá trình này có thể thực hiện khi máy ảo vẫn đang bật.

Lưu ý quan trọng: Mặc định hạt nhân Linux sẽ không tự động rà quét các thiết bị vòng quay SCSI được gắn nóng để tiết kiệm tài nguyên. Do đó, sau khi cấu hình thêm ổ đĩa từ VMware, bạn cần chạy chuỗi lệnh sau với quyền `root` để yêu cầu hệ điều hành quét lại toàn bộ cổng SCSI và trực tiếp nhận diện phân vùng mới:
```bash
for host in /sys/class/scsi_host/host*/scan; do echo "- - -" > $host; done
```
Sau khi chạy lệnh, tiến hành gõ `lsblk` để kiểm tra. Trong bài hướng dẫn này, sẽ giả định hệ điều hành đã nhận diện thành công đĩa mới với tên ký hiệu là **`sdd`**.

### Bước 2: Khởi tạo Phân vùng vật lý (Physical Volume)
Định dạng ổ đĩa `sdd` vừa được nhận diện để hệ thống LVM bắt đầu quản lý thiết bị này:
```bash
pvcreate /dev/sdd
```

### Bước 3: Đưa ổ đĩa mới vào Nhóm lưu trữ (Volume Group)
Tiến hành gộp dung lượng ổ 20GB mới vào Volume Group hiện tại đang cung cấp không gian cho `/u01` (ví dụ: `vg_u01`):
```bash
vgextend vg_u01 /dev/sdd
```
*(Bạn có thể dùng lệnh `vgs` sau bước này để kiểm tra tổng dung lượng của `vg_u01` đã được cộng dồn thành 60GB).*

### Bước 4: Mở rộng Phân vùng thiết bị Ảo (Logical Volume)
Thực hiện cấp phát phần dung lượng vừa bổ sung trong Volume Group cho cấp độ phân vùng ảo đang trực tiếp quản lý thư mục `/u01` (tên ví dụ: `lv_u01`):
```bash
lvextend -l +100%FREE /dev/vg_u01/lv_u01
```
*(Tham số `-l +100%FREE` mang ý nghĩa yêu cầu phân bổ tự động toàn bộ số dung lượng trống hiện hành của Volume Group).*

### Bước 5: Đồng bộ mức giãn nở cho hệ thống tệp tin (File System)
Mặc dù tầng Logical Volume đã được ghi nhận mức 60GB, bản thân định dạng tệp tin XFS tạo ra từ ban đầu vẫn đang thiết lập ở mốc cũ là 40GB. Do đó, cần chạy lệnh mở rộng sau để đồng bộ kích thước nhận diện lưu trữ với dung lượng thực tế, cho phép ghi dữ liệu:
```bash
xfs_growfs /u01
```
*(Lưu ý: Nếu phân vùng của máy chủ sử dụng định dạng EXT4 thời cũ thay vì XFS, lệnh tương ứng sẽ là: `resize2fs /dev/vg_u01/lv_u01`).*

**Hoàn tất:** Sử dụng lệnh `df -h` để kiểm tra xác nhận chéo. Dung lượng của phân vùng `/u01` lúc này đã tăng lên mốc mở rộng thành công.
