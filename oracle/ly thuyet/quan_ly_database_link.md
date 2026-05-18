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

Lấy toàn bộ các cột (Dễ bị vỡ dòng nếu màn hình nhỏ):
```sql
SELECT * FROM dba_db_links;
```

Lấy các cột quan trọng nhất (Gọn gàng, dễ nhìn hơn):
```sql
SELECT owner, db_link, username, host, created 
FROM dba_db_links;
```
*(Lưu ý: Các DB Link có Owner là `SYS` hoặc `SEEDDATA` thường là DB Link nội bộ mặc định do Oracle tự sinh ra, không nên can thiệp).*

---

## 7. Các lỗi phổ biến và cách khắc phục

### 7.1. Lỗi ORA-12154: TNS:could not resolve the connect identifier specified
Lỗi này thường xảy ra khi bạn dùng TNS Alias (ví dụ `USING 'db19c_pdb1'`) để tạo DB Link nhưng lại nhận được thông báo lỗi TNS khi chạy truy vấn.

**Nguyên nhân gốc rễ (Hiểu nhầm về kiến trúc):**
Khi bạn gọi DB Link, câu lệnh thực chất được thực thi **trên máy chủ Server**. Do đó, Oracle sẽ đi tìm TNS Alias `db19c_pdb1` trong file `tnsnames.ora` của chính máy chủ Linux, chứ không phải file trên máy Client (Windows) của bạn. Nếu trên máy chủ Linux chưa khai báo alias này, hệ thống sẽ báo lỗi không tìm thấy.

**Cách khắc phục:**
Có 2 cách để xử lý triệt để:

*   **Cách 1 (Giữ nguyên DB Link): Khai báo bổ sung trên Server**
    Mở file `tnsnames.ora` trên máy chủ Linux (Thường ở `$ORACLE_HOME/network/admin/tnsnames.ora`) và thêm cấu hình vào cuối file.
    ```text
    db19c_pdb1 =
      (DESCRIPTION =
        (ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1521))
        (CONNECT_DATA =
          (SERVER = DEDICATED)
          (SERVICE_NAME = pdb1)
        )
      )
    ```
    *Mẹo để tìm đúng Service Name:* Đứng ở terminal máy chủ gõ lệnh `lsnrctl status` để xem danh sách chính xác các Service Name.

*   **Cách 2 (Bỏ qua tnsnames): Dùng thẳng chuỗi kết nối EZConnect**
    Xóa DB Link cũ và tạo lại bằng cách điền trực tiếp IP, Port và Service Name vào mệnh đề `USING`.
    ```sql
    DROP DATABASE LINK test_link;
    
    CREATE DATABASE LINK test_link 
    CONNECT TO system IDENTIFIED BY oracle 
    USING 'localhost:1521/pdb1';
    ```

### 7.2. Lỗi ORA-02019: connection description for remote database not found
**Nguyên nhân:** Bạn gọi sai tên DB Link trong câu truy vấn (gõ thừa/thiếu ký tự, ví dụ: tên thật là `test_link` nhưng gõ thành `test_links`).
**Khắc phục:** Chạy lệnh `SELECT * FROM dba_db_links;` để xem lại chính xác tên của DB Link và gõ lại cho đúng.

---

## 8. Các kỹ thuật nâng cao với DB Link (Mở rộng theo chuẩn DBA)

### 8.1. Xử lý mật khẩu có ký tự đặc biệt
Nếu mật khẩu của User đích chứa các ký tự đặc biệt (như `@`, `#`, `!`), bạn **bắt buộc phải bọc mật khẩu trong cặp dấu ngoặc kép `""`**, nếu không quá trình khởi tạo sẽ báo lỗi.
```sql
CREATE DATABASE LINK test_link 
CONNECT TO system IDENTIFIED BY "P@ssw0rd_123" 
USING 'db19c_pdb1';
```

### 8.2. Tạo Synonym (Bí danh) để che giấu DB Link
Thay vì mỗi lần truy vấn phải gõ đuôi DB Link dài dòng (Ví dụ: `SELECT * FROM employees@erp_hr_link;`), bạn có thể tạo một Synonym để che giấu đi sự tồn tại của DB Link đó.
```sql
CREATE SYNONYM nhan_vien FOR employees@erp_hr_link;

-- Từ giờ, bạn chỉ cần truy vấn bảng như thể nó nằm ở máy nội bộ:
SELECT * FROM nhan_vien;
```
*Kỹ thuật này vừa giúp bảo mật kiến trúc hệ thống, vừa giúp lập trình viên không phải sửa lại code Application nếu sau này hạ tầng thay đổi tên DB Link.*

### 8.3. Đóng kết nối DB Link thủ công (Giải phóng tài nguyên)
Khi bạn thực hiện truy vấn qua DB Link, Oracle sẽ ngầm định mở và giữ lại một Session ở máy chủ đích để phục vụ cho các câu lệnh tiếp theo (nếu có). 
Để tránh lãng phí tài nguyên (hoặc gây lỗi vượt quá số lượng session cho phép ở máy đích), bạn có thể chủ động đóng kết nối ngay sau khi hoàn tất công việc:
```sql
COMMIT; -- (Hoặc ROLLBACK để kết thúc Transaction)
ALTER SESSION CLOSE DATABASE LINK test_link;
```

### 8.4. Giám sát và xử lý Treo/Lock qua DB Link (Kill Lock DB Link)
Khi một User thực hiện lệnh DML (INSERT, UPDATE, DELETE) qua DB Link mà quên chưa COMMIT/ROLLBACK, hoặc kết nối mạng đột ngột bị đứt, giao dịch này sẽ bị treo (In-doubt Transaction) và gây Lock dữ liệu ở máy chủ đích.

**Bước 1: Truy tìm Session đang gây Lock ở máy chủ đích**
Đứng tại máy chủ đích (nơi bị Lock), chạy câu lệnh sau để phát hiện các giao dịch phân tán (Distributed Transactions) đến từ máy chủ khác:
```sql
SELECT s.sid, s.serial#, s.username, s.machine, s.osuser,
       g.global_tran_fmt, g.global_oracle_id, g.state
FROM v$session s
JOIN v$global_transaction g ON s.saddr = g.session_addr;
```
*(Cột `machine` sẽ cho bạn biết chính xác máy chủ nào đang dùng DB Link gọi sang gây Lock).*

**Bước 2: Kill (Tiêu diệt) Session gây Lock**
Dựa vào `SID` và `SERIAL#` tìm được ở Bước 1, bạn tiến hành ngắt kết nối phiên làm việc đó:
```sql
ALTER SYSTEM KILL SESSION 'sid,serial#' IMMEDIATE;

-- Ví dụ:
ALTER SYSTEM KILL SESSION '145,2389' IMMEDIATE;
```

**Bước 3: Xử lý triệt để giao dịch mồ côi (Dành cho DBA)**
Trong một số trường hợp, dù đã Kill Session nhưng dữ liệu vẫn bị treo lơ lửng. Bạn phải kiểm tra bảng `dba_2pc_pending`:
```sql
SELECT local_tran_id, state FROM dba_2pc_pending;
```
Nếu có giao dịch bị kẹt (state là `prepared` hoặc `collecting`), hãy ép hệ thống dọn dẹp nó:
```sql
ROLLBACK FORCE 'local_tran_id';
-- Ví dụ: ROLLBACK FORCE '1.14.2389';
```
