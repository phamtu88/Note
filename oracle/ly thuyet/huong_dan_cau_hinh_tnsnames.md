# Hướng Dẫn Cấu Hình TNS Names Kết Nối Oracle Database (Từ Client sang VM/Server Thực)

Sau khi cài đặt Oracle Client thành công, bước quan trọng tiếp theo để kết nối ứng dụng (như SQL*Plus, PL/SQL Developer, DBeaver) từ máy tính của bạn (Client) đến máy chủ chứa cơ sở dữ liệu (Server hoặc Máy ảo VMWare/VirtualBox) là cấu hình tệp **`tnsnames.ora`**.

---

## 1. Tệp `tnsnames.ora` là gì và nằm ở đâu?

Tệp `tnsnames.ora` hoạt động như một "danh bạ điện thoại". Thay vì mỗi lần kết nối bạn phải gõ một chuỗi thông tin dài (IP, Port, Service Name), bạn chỉ cần gọi một **Alias (Tên gợi nhớ)** đã được định nghĩa trong file này.

### Vị trí tệp `tnsnames.ora`:
* **Trên Windows:** Thường nằm ở đường dẫn `%ORACLE_HOME%\network\admin\` 
  * *Ví dụ:* `C:\oracle_client\network\admin\tnsnames.ora`
  * *Lưu ý:* Nếu bạn dùng Instant Client dạng file ZIP giải nén, bạn có thể tự tạo thư mục `network\admin` bên trong thư mục giải nén và tạo tệp `tnsnames.ora` thủ công.
* **Trên MacOS / Linux:** Nằm tại `$ORACLE_HOME/network/admin/tnsnames.ora`

---

## 2. Cấu trúc chuẩn của một cấu hình TNS

Mở tệp `tnsnames.ora` bằng Notepad (trên Windows nên mở quyền Administrator) hoặc bất kỳ trình soạn thảo nào. 

Bạn thêm một khối cấu hình theo mẫu sau:

```text
MY_DB_ALIAS =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = <IP_Máy_Chủ>)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = <Tên_Service_Oracle>) 
    )
  )
```

**Giải thích các thông số:**
* **`MY_DB_ALIAS`**: Tên gợi nhớ do bạn tự đặt (ví dụ: `ORCL_VM`, `PROD_DB`). Không được chứa dấu cách.
* **`<IP_Máy_Chủ>`**: Địa chỉ IP mạng của máy chủ thật hoặc máy ảo (VMWare/VirtualBox) đang chạy Oracle. **Tuyệt đối không dùng `localhost` hay `127.0.0.1` nếu DB nằm trên máy ảo.**
* **`1521`**: Cổng mặc định của Oracle Listener.
* **`<Tên_Service_Oracle>`**: Tên Service (hoặc SID) của database trên máy chủ. (Ở Oracle 19c, thường là `ORCL` cho Container DB hoặc `ORCLPDB1` cho Pluggable DB).

---

## 3. Lưu ý sống còn khi kết nối máy ảo (VMWare / VirtualBox)

Nếu Oracle Database của bạn được cài trên một máy ảo (chạy Oracle Linux, CentOS...), bạn **BẮT BUỘC** phải đảm bảo 3 yếu tố sau trước khi cấu hình TNS:

### A. Cấu hình mạng máy ảo (Network Adapter)
* **NAT Network hoặc Bridged Adapter:** Hãy chắc chắn máy tính thật (Client Windows/Mac) có thể `ping` thông đến địa chỉ IP của máy ảo.
* *Cách kiểm tra IP máy ảo:* Mở terminal trên máy ảo gõ lệnh `ip a` hoặc `ifconfig`. Sau đó về máy thật mở CMD và gõ `ping <IP_Máy_ảo>`. Phải có tín hiệu phản hồi (Reply).

### B. Tắt tường lửa trên máy ảo (Firewall)
Máy ảo Linux thường bật tường lửa (firewalld) mặc định, nó sẽ chặn cổng 1521 từ bên ngoài gọi vào.
* **Tắt tạm thời:** `sudo systemctl stop firewalld`
* **Mở cổng 1521:** 
  ```bash
  sudo firewall-cmd --zone=public --add-port=1521/tcp --permanent
  sudo firewall-cmd --reload
  ```

### C. Oracle Listener trên máy chủ phải trỏ đúng IP
Đôi khi, tệp `listener.ora` trên máy ảo (server) đang cấu hình chạy với `HOST = localhost`. Bạn phải sửa tệp `listener.ora` trên máy chủ để HOST là tên miền (hostname) của máy ảo hoặc địa chỉ IP của nó, sau đó khởi động lại Listener:
```bash
lsnrctl stop
lsnrctl start
lsnrctl status  # (Kiểm tra xem nó đang listen ở IP nào)
```

---

## 4. Cách kiểm tra kết nối (Testing)

Sau khi lưu tệp `tnsnames.ora`, bạn cần kiểm tra xem thông tin đã chính xác chưa.

### Bước 1: Dùng lệnh TNSPING
Mở CMD (Command Prompt) trên máy Windows hoặc Terminal trên Mac, gõ:
```bash
tnsping MY_DB_ALIAS
```
*(Thay MY_DB_ALIAS bằng tên bạn đã đặt trong file tnsnames.ora)*

* **Thành công:** Hiện chữ `OK (XX msec)`.
* **Thất bại:** Hiện thông báo lỗi `TNS-12541: TNS:no listener` (Mạng thông nhưng Listener máy chủ đang tắt/chặn cổng) hoặc `TNS-12154: TNS:could not resolve the connect identifier specified` (Lỗi do viết sai tên alias hoặc sai định dạng file tnsnames).

### Bước 2: Kết nối bằng SQL*Plus
Nếu tnsping thành công, bạn thử đăng nhập:
```bash
sqlplus username/password@MY_DB_ALIAS
```
Ví dụ: `sqlplus sys/123456@ORCL_VM as sysdba`

---

## 5. Dùng công cụ Net Manager (NETCA) - Dành cho Windows
Nếu bạn không muốn tự gõ code vào tệp `tnsnames.ora`, bạn có thể dùng giao diện (GUI) đi kèm bộ cài đặt Oracle Client Administrator.

1. Nhấn nút Start (Windows), tìm phần mềm **Net Manager** (hoặc **Net Configuration Assistant**).
2. Trong Net Manager, mở nhánh **Local** > **Service Naming**.
3. Bấm dấu `+` màu xanh bên trái để thêm mới.
4. Điền các thông số: Net Service Name (Tên Alias), TCP/IP Protocol, Hostname (IP máy ảo), Port (1521), Service Name.
5. Click **Test** để kiểm tra ngay trên giao diện. Khi test thành công, phần mềm sẽ tự động sinh mã lưu vào tệp `tnsnames.ora` cho bạn.
