# CẨM NANG "BẮT BỆNH" - XỬ LÝ LỖI NGẦM HAY GẶP KHI CÀI ĐẶT ORACLE 19C

> **Lưu ý quan trọng:** Toàn bộ quá trình thao tác cài đặt và vận hành sẽ tiềm ẩn một loạt các cạm bẫy đặc hữu. Hãy nắm vững các kiến thức gỡ lỗi dưới đây để làm chủ hệ thống.

### 1. Lỗi Cấu Hình OS & Môi Trường
- **Thiếu Mất Group User:** Vòng chọn Nhánh Group báo màn trắng rỗng do lỗi gõ lệnh tạo user tay chống đè script yum Preinstall. Chữa cháy siêu nhanh là dùng terminal Root tạo thủ công `groupadd -f oinstall..` và nạp quyền quản lý ngược vào cho user.
- **Tiến Trình Chặn Lỗi Giao Diện Đồ Hoạ X11-Display:** Tránh hoàn toàn việc sử dụng lóng ngóng lệnh `xhost +`. Nếu bạn nối SSH từ máy tính ngoài chỉ để setup, công cụ bảo bối hiệu quả nhất toàn thế giới vẫn là **MobaXterm** (vừa kết nối SSH tiện dụng vừa cõng Giao Diện thẳng xuyên cổng Port 22 vượt luôn rào cản).
- **Lỗi [INS-35178] (AMM > 4GB RAM):** 
    - *Nguyên nhân:* Oracle 19c không cho phép dùng Automatic Memory Management (AMM) nếu RAM máy ảo > 4GB.
    - *Cách xử lý:* Quay lại tab **Memory**, **bỏ tích** ô "Enable Automatic Memory Management". Oracle sẽ chuyển sang dùng ASMM (tốt hơn cho máy cấu hình mạnh).
- **Thư Mục Trống của `oraInventory` (Lỗi [INS-32047]):** Nếu OUI pop-up có báo cáo "[INS-32047] Folder is not empty" thì nhấp Yes ép cho qua vì đó là log rác từ việc tải dở quá trình cài thất bại lần trước còn bỏ lại. Dễ dàng ghi lấp đè là được.
- **Treo Tiến trình Systemctl (Lỗi 127):** Thường do file `/etc/oratab` trống rỗng hoặc script bạn chép mạng có dính lệnh bắt tương tác `. oraenv`. Hãy luôn sử dụng thiết lập Service chuẩn để vượt ải an toàn.

### 2. Các Lỗi Về Mạng / Listener (TNS, NetCA)
- **Lỗi [INS-20802] Oracle Net Configuration Assistant failed (Tiến trình cấu hình Listener bị Crash):**
    - *Nguyên nhân:* Thường gặp ở Bước 17 (Progress ~59%). Do địa chỉ IP bạn ghi ở tệp `/etc/hosts` bị sai lệch so với IP hệ thống thực tế hiện tại, khiến Listener không thể định danh (bind) thông qua port tĩnh 1521.
    - *Cách xử lý:* Giữ nguyên màn hình cài đặt. Mở cửa sổ terminal mới (quyền `root`), kiểm tra biến số IP thật bằng lệnh `ip a`. Sau đó sửa dứt điểm lỗi IP trong cấu hình `vi /etc/hosts`. Quay lại giao diện Oracle, bấm OK để đóng khung cảnh báo và kéo chọn **Retry**, hệ thống sẽ phục hồi kết nối.
- **Lỗi LSNRCT PORT nhảy số bất thường (Khác 1521):**
    - *Triệu chứng:* Khi gõ lệnh `lsnrctl status`, ở Output thấy dòng `Connecting to ... (PORT=1539)` hoặc các port tăng dần như 1522, 1523.
    - *Nguyên nhân:* Trong quá trình cài đặt hoặc lúc bấm Retry NETCA nhiều lần thất bại, tiến trình cũ bị treo bám cứng lấy Port 1521. Oracle tự động tịnh tiến các Port tiếp theo để dự phòng nhưng nó gây ra lỗi khi kết nối.
    - *Cách xử lý:* Di chuyển vào thư mục mạng: `cd $ORACLE_HOME/network/admin`. Mở file `vi listener.ora` và file `vi tnsnames.ora` (nếu có), tìm tất cả con số cổng bất thường (ví dụ 1539) và sửa thủ công về lại đúng số chuẩn là **`1521`**. Lưu file và gõ `lsnrctl start` để nạp khôi phục lại Listener hoàn hảo.

### 3. Khắc Phục Lỗi Kết Nối & Truy Vấn SQL*Plus
- **Lỗi ORA-01034: ORACLE not available (Lỗi kết nối trượt Instance / Idle Instance):**
    - *Nguyên nhân:* Do khi đăng nhập SQL*Plus, Terminal không biết hoặc nhận diện sai tên SID (ví dụ đang gọi `orcl` thay vì `oracle19`), hoặc Database thực sự chưa được khởi động.
    - *Cách xử lý:* Thoát ra bash (gõ `exit`), nạp lại môi trường chuẩn bằng lệnh `source ~/.bash_profile` rồi đăng nhập thử truy vấn lại. Nếu vẫn bị Idle, hãy gõ thẳng lệnh `startup` trực tiếp trong prompt SQL*Plus để mồi nạp Database lên bộ nhớ RAM.
- **Lỗi ORA-00936: missing expression (Thiếu biểu thức):**
    - *Nguyên nhân:* Gõ sai cú pháp SQL cơ bản (ví dụ lỗi thiếu tên cột tham chiếu giữa chữ `select` và `from`).
    - *Cách xử lý:* Sửa lại câu lệnh có chứa khai báo đầy đủ thành phần (Ví dụ `select * from v$instance` hoặc `select status from v$instance`).

---
*(Tài liệu này sẽ liên tục được cập nhật thêm theo các lỗi phát sinh trong thực tế)*
