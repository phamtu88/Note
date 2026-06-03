# Hướng dẫn định dạng hiển thị đẹp và chuyên nghiệp trong Oracle Database

Tài liệu này hướng dẫn chi tiết cách cấu hình hiển thị dữ liệu trong Oracle Database, giúp kết quả truy vấn luôn thẳng hàng, không bị vỡ cột, dễ đọc trên cả giao diện dòng lệnh (SQL*Plus) và các công cụ đồ họa (Toad, SQL Developer).

---

## 1. Cấu hình cố định vĩnh viễn cho SQL*Plus (glogin.sql)

Để không phải gõ lại các câu lệnh định dạng mỗi khi kết nối, bạn hãy cấu hình trực tiếp vào file cấu hình khởi động toàn cục của Oracle.

### Vị trí file cấu hình trên Linux (Red Hat)
Đường dẫn mặc định:
```text
$ORACLE_HOME/sqlplus/admin/glogin.sql
```
*(Ví dụ thực tế: `/u01/app/oracle/product/19.3.0/dbhome_1/sqlplus/admin/glogin.sql`)*

### Các bước thực hiện:
1. Mở Terminal và tìm đường dẫn chính xác của file:
   ```bash
   find / -name "glogin.sql" 2>/dev/null
   ```
2. Mở file bằng công cụ chỉnh sửa (như `vi` hoặc `nano`):
   ```bash
   sudo vi /u01/app/oracle/product/19.3.0/dbhome_1/sqlplus/admin/glogin.sql
   ```
3. Di chuyển xuống cuối file, dán đoạn mã cấu hình dưới đây và lưu lại:

```sql
-- =======================================================
-- CẤU HÌNH ĐỊNH DẠNG HIỂN THỊ MẶC ĐỊNH
-- =======================================================
-- Thiết lập độ rộng của một dòng tối đa 200 ký tự (tránh vỡ bảng)
SET LINESIZE 200;

-- Tiêu đề cột chỉ lặp lại sau mỗi 100 dòng kết quả
SET PAGESIZE 100;

-- Cắt bỏ khoảng trắng thừa ở cuối dòng khi hiển thị
SET TRIMSPOOL ON;

-- Không dùng phím Tab để tránh lệch cột
SET TAB OFF;

-- =======================================================
-- ĐỊNH DẠNG ĐỘ RỘNG MẶC ĐỊNH CHO CÁC CỘT PHỔ BIẾN
-- =======================================================
COLUMN username      FORMAT A20;
COLUMN name          FORMAT A25;
COLUMN network_name  FORMAT A25;
COLUMN event         FORMAT A30;
COLUMN parameter     FORMAT A30;
COLUMN value         FORMAT A30;
COLUMN grantee       FORMAT A20;
COLUMN privilege     FORMAT A30;
```

---

## 2. Các câu lệnh định dạng nhanh (Chạy trong phiên làm việc)

Khi cần điều chỉnh nhanh định dạng trong một session hoặc viết kịch bản script chạy một lần, bạn sử dụng các lệnh sau:

### Định dạng cấu trúc bảng kết quả

| Câu lệnh | Tác dụng |
| :--- | :--- |
| `SET LINESIZE 300;` | Tăng chiều rộng dòng lên 300 ký tự (hữu ích khi bảng có nhiều cột). |
| `SET PAGESIZE 0;` | Tắt hoàn toàn tiêu đề cột và ngắt trang (tiện cho việc export dữ liệu sạch). |
| `SET COLSEP ' \| ';` | Phân cách các cột bằng ký tự ` | ` thay cho khoảng trắng mặc định. |
| `SET FEEDBACK OFF;` | Tắt dòng thông báo số lượng bản ghi (ví dụ: "10 rows selected"). |

### Định dạng cột chuyên biệt (`COLUMN`)

*   **Định dạng cột văn bản (String):** Dùng `A` + số ký tự tối đa hiển thị.
    ```sql
    COLUMN email FORMAT A30;
    ```
*   **Định dạng cột số:** Sử dụng `9` để giữ chỗ cho chữ số, `,` cho phần nghìn và `.` cho phần thập phân.
    ```sql
    COLUMN salary FORMAT 999,999,990.00;
    ```
*   **Hủy bỏ định dạng đã cài cho một cột:**
    ```sql
    COLUMN email CLEAR;
    ```

---

## 3. Định dạng dữ liệu trực tiếp trong câu lệnh SQL

Bạn có thể viết truy vấn thông minh để kết quả tự động hiển thị đẹp trên mọi phần mềm (SQL*Plus, Toad, SQL Developer...):

### Định dạng ngày tháng (`TO_CHAR`)
```sql
SELECT username, TO_CHAR(created, 'DD/MM/YYYY HH24:MI:SS') AS "Ngay Tao"
FROM dba_users;
```

### Định dạng số tiền tệ (`TO_CHAR`)
```sql
SELECT name, TO_CHAR(salary, '$999,999,990.00') AS "Luong"
FROM employees;
```

---

## 4. Định dạng nhanh trên các công cụ GUI

Nếu bạn sử dụng phần mềm đồ họa, có các tính năng định dạng tự động tích hợp rất tiện lợi:

### Trên Oracle SQL Developer
*   **Làm đẹp câu lệnh SQL đang viết (Auto Format SQL):** 
    Nhấn tổ hợp phím **`Ctrl + F7`**. Lệnh sẽ tự động thụt lề, viết hoa từ khóa chính.
*   **Tự giãn cột vừa khít dữ liệu (Auto Fit Grid):**
    Click chuột phải vào lưới kết quả $\rightarrow$ Chọn **Size Columns** $\rightarrow$ Chọn **All Columns On Screen**.

### Trên Toad for Oracle
*   **Làm đẹp câu lệnh SQL đang viết:**
    Nhấn tổ hợp phím **`Ctrl + Shift + F`**.
*   **Tự động co giãn cột hiển thị:**
    Click chuột phải vào bảng lưới kết quả $\rightarrow$ Chọn **Appearance** $\rightarrow$ Chọn **Autofit columns**.

---

> [!TIP]
> **Cách xuất báo cáo định dạng bảng HTML từ SQL*Plus:**
> Nếu muốn xuất nhanh báo cáo dạng bảng web gửi cho sếp, bạn chạy các lệnh sau:
> ```sql
> SET MARKUP HTML ON SPOOL ON PREFORMAT OFF;
> SPOOL bao_cao.html;
> SELECT username, account_status, created FROM dba_users WHERE rownum <= 10;
> SPOOL OFF;
> SET MARKUP HTML OFF;
> ```
