# Hoàn tất Bộ Hướng dẫn Cài đặt Oracle RAC 19c (2-Nodes)

Tôi đã hoàn thành việc xây dựng bộ tài liệu hướng dẫn chi tiết từng bước để cài đặt Oracle RAC 19c trên môi trường máy ảo. Dưới đây là lộ trình thực hiện dựa trên các tài liệu đã tạo:

## Lộ trình Thực hiện (Roadmap)

### 1. Chuẩn bị Hạ tầng (Infrastructure)
Bắt đầu bằng việc thiết lập máy ảo và quan trọng nhất là tạo ổ đĩa dùng chung (Shared Disks) trên VMware.
- [oracle_grid_vmware_guide.md](file:///d:/DB/setup/oracle/oracle_grid_vmware_guide.md)

### 2. Cấu hình Mạng (Network)
Thiết lập địa chỉ IP Public, Private, Virtual và SCAN IP trong file `/etc/hosts`.
- [oracle_rac_network_setup.md](file:///d:/DB/setup/oracle/oracle_rac_network_setup.md)

### 3. Chuẩn bị Hệ điều hành (OS Prep)
Tạo người dùng `grid`, `oracle`, cấu hình SSH Passwordless và cài đặt các gói tiền đề.
- [oracle_rac_os_prep.md](file:///d:/DB/setup/oracle/oracle_rac_os_prep.md)

### 4. Cấu hình Lưu trữ ASM (UDEV)
Gán UUID cho các ổ đĩa và phân quyền để Grid Infrastructure có thể sử dụng.
- [oracle_rac_udev_asm.md](file:///d:/DB/setup/oracle/oracle_rac_udev_asm.md)

### 5. Cài đặt Grid Infrastructure
Quá trình chạy `gridSetup.sh` và thực thi các script `root.sh` quan trọng.
- [oracle_grid_install_steps.md](file:///d:/DB/setup/oracle/oracle_grid_install_steps.md)

### 6. Cài đặt Software và Tạo Database
Cài đặt nhân Database RAC và khởi tạo DB thông qua giao diện DBCA.
- [oracle_rac_db_setup.md](file:///d:/DB/setup/oracle/oracle_rac_db_setup.md)

---

## Các điểm cần lưu ý (Best Practices)

> [!TIP]
> **Thứ tự thực hiện:** Bạn nên thực hiện đúng theo thứ tự từ 1 đến 6 để tránh các lỗi logic về quyền hạn và kết nối.

> [!IMPORTANT]
> **Script Root:** Khi cài Grid, hãy đảm bảo chạy `root.sh` trên Node 1 xong hoàn toàn rồi mới chạy trên Node 2. Đây là nguyên nhân phổ biến nhất gây lỗi Cluster không khởi động được.

> [!NOTE]
> **Kiểm tra trạng thái:** Luôn dùng lệnh `crsctl status resource -t` để theo dõi sức khỏe của hệ thống sau mỗi bước cài đặt lớn.

Hy vọng bộ tài liệu này sẽ giúp bạn cài đặt thành công hệ thống Oracle RAC! Nếu bạn gặp bất kỳ lỗi nào trong quá trình thực hiện, đừng ngần ngại hỏi tôi.
