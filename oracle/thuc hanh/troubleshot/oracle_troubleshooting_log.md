# Nhật ký khắc phục lỗi Oracle (Oracle Troubleshooting Log)

Tài liệu này tổng hợp các lỗi và giải pháp đã thực hiện trong quá trình thiết lập Oracle 19c trên Oracle Linux và cấu hình kết nối mạng.

---

## 1. Lỗi kết nối mạng (Ping failure / Connection Issues)

### Triệu chứng:
- Không thể ping từ máy host (Windows) đến máy ảo Oracle Linux (IP: `192.168.182.128`).
- Toad for Oracle hoặc SQL Plus không thể kết nối đến Listener qua port 1521.

### Nguyên nhân:
- Xung đột UUID card mạng trong máy ảo Linux sau khi copy/move VM.
- Card mạng chưa được kích hoạt hoặc sai cấu hình MAC address.
- Firewall (firewalld) trên Linux chặn các kết nối đến.

### Giải pháp (Fix):
1. **Kiểm tra và nạp lại cấu hình mạng:** Sử dụng lệnh `nmcli connection reload` hoặc `systemctl restart network`.
2. **Xử lý UUID:** Kiểm tra file `/etc/sysconfig/network-scripts/ifcfg-ens33` (hoặc tương tự) để đảm bảo UUID và MAC address khớp với thiết lập của VMware.
3. **Cấu hình Firewall:**
   ```bash
   systemctl stop firewalld
   systemctl disable firewalld
   ```
   *Hoặc mở port 1521:*
   ```bash
   firewall-cmd --permanent --add-port=1521/tcp
   firewall-cmd --reload
   ```

---

## 2. Lỗi cài đặt Oracle 19c (Installation Errors)

### Triệu chứng:
- Lỗi kiểm tra điều kiện tiên quyết (Prerequisites) về bộ nhớ (Memory).
- Listener không khởi động (Listener network issue).
- Sai lệch SID (System ID) giữa cấu hình database và Listener.

### Nguyên nhân:
- Cấu hình swap space hoặc kernel parameters chưa đạt yêu cầu của Oracle.
- File `listener.ora` cấu hình IP tĩnh không khớp với IP hiện tại của máy.

### Giải pháp (Fix):
1. **Cấu hình lại Listener:** Cập nhật file `listener.ora` với hostname hoặc IP chính xác (`192.168.182.128`).
2. **Đồng bộ SID:** Đảm bảo biến môi trường `ORACLE_SID` (ví dụ: `ORCL`) khớp trong `~/.bash_profile` và các lệnh tạo database.

---

## 3. Cấu hình User SYS và Remote Login

### Các bước thực hiện:
1. **Xác nhận Instance Name:**
   ```sql
   select instance_name from v$instance;
   -- Kết quả: orcl
   ```
2. **Đổi mật khẩu SYS:**
   ```sql
   alter user sys identified by 123456;
   ```
3. **Kiểm tra tham số Remote Login:**
   ```sql
   show parameter remote_login_passwordfile;
   -- Kết quả: EXCLUSIVE (Cho phép kết nối SYSDBA từ xa)
   ```

---

## 4. Trạng thái hiện tại
- **Kết nối thành công:** Toad for Oracle đã kết nối được với `SYS@192.168.182.128:1521/ORCL`.
- **Cấu hình SYS:** Mật khẩu đã được cập nhật và cho phép đăng nhập từ xa.
- **Hệ thống ổn định:** Các dịch vụ Oracle Database và Listener đang hoạt động bình thường.
