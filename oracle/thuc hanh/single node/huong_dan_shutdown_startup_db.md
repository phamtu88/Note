# Hướng dẫn Shutdown và Startup Oracle Database an toàn

Tài liệu này cung cấp các bước chính xác để tắt và bật cơ sở dữ liệu Oracle trên môi trường Single Node (đơn lẻ), đảm bảo an toàn dữ liệu.

> [!IMPORTANT]  
> Hướng dẫn này **CHỈ DÀNH CHO SINGLE NODE**. Nếu bạn đang dùng cụm RAC, hãy xem [Hướng dẫn Shutdown/Startup cho RAC](file:///d:/DB/setup/oracle/thuc%20hanh/Oracle_Gird_ASM_RAC/huong_dan_shutdown_startup_rac.md) để tránh lỗi hệ thống Clusterware.

## 1. Các bước Shutdown (Tắt Database sạch sẽ)

Thực hiện theo thứ tự để tránh lỗi dữ liệu hoặc yêu cầu recovery sau này.

1. **Chuyển sang user `oracle`**
   ```bash
   su - oracle
   ```
2. **Tắt Oracle Listener**:
   Đóng các kết nối mới từ các ứng dụng.
   ```bash
   lsnrctl stop
   ```
3. **Đăng nhập vào SQL*Plus**:
   Sử dụng quyền quản trị tối cao (sysdba).
   ```bash
   sqlplus / as sysdba
   ```
4. **Chạy lệnh tắt Database an toàn**:
   Sử dụng chế độ `IMMEDIATE` để đóng và ngắt kết nối các datafiles sạch nhất.
   ```sql
   shutdown immediate;
   ```
   *Đợi cho đến khi nhận được thông báo "ORACLE instance shut down."*
5. **Thoát SQL*Plus**:
   ```sql
   exit
   ```
6. **(Optional) Tắt máy ảo an toàn (Quyền root)**:
   ```bash
   exit # Thoát khỏi user oracle về root
   shutdown -h now
   ```

---

## 2. Các bước Startup (Bật Database)

Thực hiện sau khi hệ thống OS đã sẵn sàng.

1. **Chuyển sang user `oracle`**:
   ```bash
   su - oracle
   ```
2. **Bật Oracle Listener**:
   Cổng kết nối cho các ứng dụng.
   ```bash
   lsnrctl start
   ```
3. **Đăng nhập vào SQL*Plus**:
   ```bash
   sqlplus / as sysdba
   ```
4. **Chạy lệnh bật Database**:
   ```sql
   startup;
   ```
   *Đợi cho đến khi nhận được thông báo "Database opened."*
5. **Thoát SQL*Plus**:
   ```sql
   exit
   ```

## Các lưu ý quan trọng:
- Luôn thực hiện các lệnh quản trị cơ sở dữ liệu (`sqlplus`, `lsnrctl`) bằng **user `oracle`**.
- Không nên tắt nóng (hard reset) máy ảo khi Database chưa được shutdown sạch sẽ.
- Sử dụng `shutdown immediate` thay vì `shutdown abort` để đảm bảo dữ liệu luôn được ghi đầy đủ vào các tệp tin đĩa cứng.
