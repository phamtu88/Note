# Tài liệu Tổng hợp về Oracle Database Link (DB Link)

## 1. Khái niệm cơ bản
**Database Link (DB Link)** là một đối tượng (object) bên trong Oracle Database, cho phép một Database (Máy chủ A) có thể kết nối và truy vấn dữ liệu trực tiếp từ một Database khác (Máy chủ B). 

Khi sử dụng DB Link, người dùng ngồi ở Máy chủ A có thể chạy lệnh `SELECT`, `INSERT`, `UPDATE` lên các bảng nằm ở Máy chủ B như thể bảng đó đang nằm ngay trên máy của mình.

---

## 2. Phân loại DB Link (Private vs Public)

Sự khác biệt cốt lõi giữa hai loại này nằm ở **Phạm vi sử dụng (Scope)** và **Tính bảo mật (Security)**.

| Tiêu chí | Private DB Link (Mặc định) | Public DB Link |
| :--- | :--- | :--- |
| **Cú pháp** | `CREATE DATABASE LINK...` | `CREATE PUBLIC DATABASE LINK...` |
| **Phạm vi sử dụng** | **Chỉ duy nhất User tạo ra nó** mới được quyền sử dụng. | **Tất cả các User** có trong Database hiện tại đều có quyền sử dụng. |
| **Mục đích** | Đảm bảo tính bảo mật, cô lập ứng dụng. (Ví dụ: User KETOAN không thể xem được dữ liệu qua DB Link do user NHANSU tạo ra). | Tiện lợi, không cần tạo nhiều lần. Dành cho các kết nối chia sẻ chung cho toàn hệ thống. |
| **Quyền khởi tạo** | Cần quyền `CREATE DATABASE LINK`. | Cần quyền `CREATE PUBLIC DATABASE LINK` (Thường chỉ DBA mới có quyền này). |

---

## 3. Quy chuẩn đặt tên DB Link (Best Practices)

Về mặt kỹ thuật, bạn có thể đặt tên DB Link tùy ý (không chứa khoảng trắng hay ký tự đặc biệt). Tuy nhiên, trong môi trường làm việc thực tế, cần tuân thủ 2 nguyên tắc sau:

### 3.1. Quy ước đặt tên dễ quản lý (Naming Convention)
Nên đặt tên sao cho nhìn vào là hiểu DB Link này trỏ đi đâu, bằng tài khoản gì.
**Công thức gợi ý:** `[TÊN_DB_ĐÍCH]_[TÀI_KHOẢN_ĐÍCH]_LINK`
*   *Ví dụ:* `ERP_HR_LINK` (Kết nối tới DB ERP bằng user HR)

### 3.2. Ràng buộc bảo mật GLOBAL_NAMES (Cực kỳ quan trọng)
*   Nếu tham số hệ thống **`GLOBAL_NAMES = FALSE`** (Mặc định): Tên DB Link có thể đặt tự do.
*   Nếu tham số hệ thống **`GLOBAL_NAMES = TRUE`** (Bảo mật cao): **Tên DB Link BẮT BUỘC phải trùng khớp 100% với tên định danh toàn cầu (Global Database Name) của máy chủ đích.**
    *   *Ví dụ:* Database đích tên là `SALES.WORLD`, thì lệnh tạo phải bắt đầu bằng `CREATE DATABASE LINK SALES.WORLD CONNECT TO...` Nếu đặt sai, Oracle sẽ từ chối kết nối.

---

## 4. Các bước khảo sát hệ thống trước khi tạo DB Link
Trước khi tạo DB Link, đặc biệt trong môi trường thực hành, bạn nên kiểm tra các thông tin sau để đảm bảo kết nối thành công:

### 4.1. Kiểm tra tham số GLOBAL_NAMES
Đảm bảo bạn biết quy tắc đặt tên đang áp dụng là tự do hay bắt buộc.
```sql
SHOW PARAMETER global_names;
```
Nếu `VALUE` là `TRUE`, bạn phải kiểm tra tên định danh của DB đích bằng lệnh `SELECT * FROM global_name;` để đặt tên DB Link cho khớp.

### 4.2. Kiểm tra danh sách PDB (Pluggable Database)
Dùng để xác định Database đích (nếu bạn muốn kết nối giữa các PDB với nhau).
```sql
SHOW PDBS;
-- Hoặc chi tiết hơn:
SELECT name, open_mode FROM v$pdbs;
```

### 4.3. Tìm User hợp lệ để kết nối (Đang OPEN)
Tìm một tài khoản đang hoạt động (OPEN) ở DB đích để điền vào phần `CONNECT TO...`.
```sql
SELECT username, account_status 
FROM dba_users 
WHERE account_status = 'OPEN';
```

---

## 5. Các câu lệnh thao tác với DB Link

### 5.1. Câu lệnh tạo Private DB Link
```sql
CREATE DATABASE LINK [ten_dblink] 
CONNECT TO [ten_user_remote] IDENTIFIED BY [mat_khau_remote] 
USING 'TNS_ALIAS_HOAC_CHUOI_KET_NOI';

-- Ví dụ:
CREATE DATABASE LINK erp_hr_link 
CONNECT TO hr IDENTIFIED BY 123456 
USING '192.168.1.100:1521/orcl';
```

### 5.2. Câu lệnh tạo Public DB Link
Chỉ cần thêm chữ `PUBLIC` ngay sau chữ `CREATE`.
```sql
CREATE PUBLIC DATABASE LINK [ten_dblink] 
CONNECT TO [ten_user_remote] IDENTIFIED BY [mat_khau_remote] 
USING 'TNS_ALIAS';
```

### 5.3. Lệnh kiểm tra kết nối (Ping DB Link)
Cách nhanh nhất và chuẩn xác nhất để kiểm tra DB Link có hoạt động hay không là truy vấn bảng `dual` ở máy chủ đích:
```sql
SELECT * FROM dual@[ten_dblink];
```
*   **Thành công:** Trả về 1 cột `DUMMY` có giá trị là chữ `X`.
*   **Thất bại:** Trả về mã lỗi ORA (Ví dụ: `ORA-12154` TNS không tìm thấy, `ORA-01017` Sai tài khoản...).

### 5.4. Lệnh Xóa (Drop) DB Link
Xóa Private DB Link:
```sql
DROP DATABASE LINK [ten_dblink];
```
Xóa Public DB Link:
```sql
DROP PUBLIC DATABASE LINK [ten_dblink];
```

---

## 6. Quản lý danh sách DB Link trong hệ thống

Để xem trong Database hiện tại đang có những DB Link nào, ai tạo, kết nối đi đâu, bạn dùng View `dba_db_links`.

### Câu lệnh làm đẹp màn hình hiển thị (Dành cho SQL*Plus)
Do kết quả của bảng dba_db_links thường dài và bị vỡ dòng, hãy chạy bộ lệnh format này trước:
```sql
SET LINESIZE 200;
SET PAGESIZE 100;
COL owner FORMAT A15;
COL db_link FORMAT A25;
COL username FORMAT A15;
COL host FORMAT A30;
```

### Lệnh truy vấn danh sách DB Link
```sql
SELECT owner, db_link, username, host, created 
FROM dba_db_links;
```
*(Lưu ý: Các DB Link có Owner là `SYS` hoặc `SEEDDATA` thường là DB Link nội bộ mặc định do Oracle tự sinh ra, không nên can thiệp).*
