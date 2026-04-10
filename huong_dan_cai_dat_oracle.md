# Hướng dẫn phân định User khi cài đặt Oracle Database 19c
**Nguồn bài viết:** [Cài đặt Oracle Database 19c trên Oracle Linux 7 (OL7) của chuyên gia Trần Văn Bình](https://www.tranvanbinh.vn/2021/01/cai-at-oracle-database-19c-tren-oracle.html)

Dưới đây là bảng phân định chi tiết các bước cài đặt tương ứng với user thao tác (`root` hoặc `oracle`), bám sát theo từng tiêu đề (heading) trong bài viết trên:

## Phần 1: Các bước sử dụng user `root`
*(Áp dụng từ đầu bài viết cho đến hết mục "Thiết lập bổ sung")*

- **Mục "Hosts File"**
  - Thực hiện: Sửa `/etc/hosts` và `/etc/hostname`.
  - User: `root`

- **Mục "Điều kiện tiên quyết khi cài Oracle"**
  - Thực hiện: Chạy `yum install`, sửa `sysctl.conf`, thay đổi tham số kernel (`sysctl -p`), cấu hình `limits.conf`, chạy các script cấu hình kernel. Cài đặt thêm các gói hỗ trợ.
  - User: `root`

- **Mục tạo các group và user**
  - Thực hiện: `groupadd`, `useradd` để tạo group và tài khoản `oracle`.
  - User: `root`

- **Mục "Thiết lập bổ sung"**
  - Đặt mật khẩu (`passwd oracle`): **Dùng `root`**
  - Thiết lập cấu hình SELINUX (`permissive`) và disable Firewalld: **Dùng `root`**
  - Tạo các thư mục gốc (`mkdir -p /u01/app/oracle...`, `/u02/oradata`) và phân quyền (`chown -R oracle:oinstall /u01 /u02`, `chmod -R 775 /u01 /u02`): **Dùng `root`**
  - Kiểm tra GUI (`xhost +<machine-name>`): **Dùng `root`**
  - **Lưu ý đoạn cuối mục này:** Các thao tác tạo thư mục `/home/oracle/scripts`, tạo các file `setEnv.sh`, `start_all.sh`... trong ngữ cảnh bài viết đang được thực hiện ở terminal của `root`. Bằng chứng là tác giả dùng thêm lệnh `chown -R oracle:oinstall /home/oracle/scripts` ở phía dưới để trả lại quyền cho user `oracle`. Do đó, theo mạch bài viết, bạn vẫn gõ bằng `root`.
  - Cấu hình file `/etc/oratab`: **Dùng `root`**

---

## Phần 2: Các bước sử dụng user `oracle`
*(Sau khi hoàn thiện phần hệ thống, bạn khởi tạo terminal mới và chuyển sang user oracle: `su - oracle` để tiếp tục)*

- **Mục "Thiết lập thủ công"**
  - Thực hiện: Export biến `DISPLAY` (`DISPLAY=<machine...>; export DISPLAY`)
  - User: `oracle`

- **Mục "Cài đặt ở chế độ giao diện (interactive)"**
  - Thực hiện: Giải nén file cài đặt thông qua lệnh `unzip`, sau đó gọi công cụ đồ hoạ `./runInstaller`.
  - User: `oracle`

---

## Phần 3: Chạy script root (Bật lên tài khoản `root` trong lúc cài)

- **Mục "As a root user, execute the following script(s):"**
  - Thực hiện: Khi tiến trình giao diện (hoặc silent mode) ở bước cuối, trình cài đặt sẽ yêu cầu bạn chạy 2 script:
    1. `/u01/app/oraInventory/orainstRoot.sh`
    2. `/u01/app/oracle/product/19.0.0/dbhome_1/root.sh`
  - User: **Mở 1 terminal mới và chạy lệnh bằng `root`**, sau đó ấn OK trên cửa sổ cài đặt của `oracle` để tiếp tục.

---

## Phần 4: Cấu hình và Quản lý Database (Trở lại user `oracle`)

- **Mục "Tạo Database"**
  - Thực hiện: Bật Listener (`lsnrctl start`) và gọi giao diện cấu hình database (`dbca`).
  - User: `oracle`

- **Các phương pháp thay thế: Chế độ Silent Mode**
  - Nếu áp dụng cách cài không cần GUI (Silent Mode):
    - Mục "Có thể cài đặt ở chế độ silent mode" (Chạy `./runInstaller -silent`): **Dùng `oracle`** (vẫn kèm bước bật terminal root như thông báo).
    - Mục "Tạo Database ở chế độ silent mode" (Chạy `dbca -silent -createDatabase...`): **Dùng `oracle`**

- **Cấu hình Oracle Managed Files (OMF) & Truy vấn cơ bản**
  - Thực hiện: Thao tác kết nối vào `sqlplus / as sysdba` và chạy SQL (`alter system set db_create_file_dest`, `select instance_name...`).
  - User: `oracle`

***
**TỔNG KẾT NHANH:**
1. Thao tác hệ thống `/etc/`, `yum`, tạo thư mục gốc, phân quyền (`chown / chmod`), bật GUI tổng `xhost`: BẮT BUỘC dùng **`root`**.
2. Thao tác chạy `runInstaller`, tạo database `dbca`, bật Listener `lsnrctl`, kết nối `sqlplus`: BẮT BUỘC dùng **`oracle`**.
