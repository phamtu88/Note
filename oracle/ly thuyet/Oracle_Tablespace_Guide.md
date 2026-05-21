# Tài Liệu Quản Trị: Cấu hình và Tạo Tablespace trong Oracle

Tài liệu này hướng dẫn cách kiểm tra cấu hình lưu trữ tự động (OMF), phân quyền và các kịch bản tạo Tablespace chuẩn xác dùng cho lưu trữ dữ liệu, Index, phân mảnh theo năm và lưu trữ file LOB.

---

## 1. Phân quyền và Tạo Tablespace bằng Common User

Khi quản trị hệ thống Multitenant lớn, DBA thường dùng **Common User** (có tiền tố `c##`, ví dụ `c##admin`) để quản lý. Khi dùng user này để tạo Tablespace, bạn cần thực hiện theo các bước sau để đảm bảo an toàn và đúng quyền hạn.

### 1.1. Bước 1: Kiểm tra quyền hiện tại của User (Bắt buộc)
Để đảm bảo nguyên tắc an toàn, trước tiên DBA (dùng quyền `SYS`) cần kiểm tra xem Common User đã có đặc quyền `CREATE TABLESPACE` hay chưa.

```sql
-- Đăng nhập bằng quyền SYSDBA, chạy câu lệnh sau:
SELECT grantee, privilege, admin_option, common 
FROM dba_sys_privs 
WHERE grantee = 'C##ADMIN' -- (Thay bằng tên user của bạn, luôn ghi IN HOA)
AND privilege = 'CREATE TABLESPACE';
```

**Đọc kết quả:**
- **No rows selected:** User CHƯA có quyền. Tiến hành Bước 1.2.
- **Có dữ liệu và `COMMON = YES`:** User đã có quyền Global (tạo ở mọi PDB). Chuyển ngay sang Bước 1.3.
- **Có dữ liệu và `COMMON = NO`:** User chỉ có quyền Local ở một PDB cụ thể (bạn cần kiểm tra xem mình đang đứng ở PDB nào để biết quyền đó áp dụng ở đâu).

### 1.2. Bước 2: Phân chia các trường hợp cấp quyền (GRANT)
Nếu ở Bước 1 user chưa có quyền, bạn tiến hành cấp quyền tùy theo chính sách bảo mật:

**Trường hợp 1: Cấp quyền Global (Cho phép tạo Tablespace ở BẤT KỲ PDB nào)**
Thường dành cho DBA quản trị tổng của hệ thống. Bạn bắt buộc phải đứng ở `CDB$ROOT` để cấp quyền này.
```sql
ALTER SESSION SET CONTAINER = CDB$ROOT;
GRANT CREATE TABLESPACE TO c##admin CONTAINER=ALL;
```

**Trường hợp 2: Cấp quyền Local (Chỉ cho phép tạo ở MỘT PDB nhất định)**
Dành cho người quản trị dự án hoặc ứng dụng cụ thể. Bạn bắt buộc phải chuyển vào PDB đó trước khi cấp quyền.
```sql
-- Ví dụ: Chỉ cho phép c##admin tạo Tablespace ở PDB1
ALTER SESSION SET CONTAINER = PDB1;
GRANT CREATE TABLESPACE TO c##admin;
```

### 1.3. Bước 3: Đăng nhập và chuẩn bị tạo Tablespace
> [!WARNING]
> Common User có quyền di chuyển tự do giữa các Container. **Tuyệt đối không quên** chuyển phiên làm việc vào đúng PDB trước khi chạy lệnh tạo để tránh tạo nhầm Tablespace vào `CDB$ROOT`.

```sql
-- Đăng nhập bằng tài khoản Common User (VD: c##admin)
-- 1. Chuyển vào PDB đích
ALTER SESSION SET CONTAINER = PDB1;
```

---

## 2. Kiểm tra cấu hình Oracle Managed Files (OMF)

Trước khi tạo Tablespace, DBA cần kiểm tra xem hệ thống đã được cấu hình tính năng tự động quản lý file (OMF) thông qua tham số `db_create_file_dest` hay chưa.

### Lệnh kiểm tra:
```sql
-- Chạy trên TOAD, SQL Developer, PL/SQL Developer...
SELECT name, value 
FROM v$parameter 
WHERE name = 'db_create_file_dest';
```

### Cách đọc kết quả:
- **Nếu cột `VALUE` có chứa đường dẫn** (VD: `+DATA` hoặc `/u01/app/oracle/oradata`): Hệ thống ĐÃ BẬT OMF. Bạn áp dụng **Mục 3** bên dưới.
- **Nếu cột `VALUE` bị trống (Null)**: Hệ thống CHƯA BẬT OMF. Bạn áp dụng **Mục 4** bên dưới (Phải tự gõ đường dẫn tay).

---

## 3. Tạo Tablespace KHI ĐÃ BẬT OMF (Khuyên dùng)

> [!IMPORTANT]
> **Vị trí thực thi (Rất quan trọng):** Đảm bảo bạn đã chuyển phiên làm việc vào trong PDB (như Mục 1.3). Tuyệt đối không tạo Tablespace dữ liệu nghiệp vụ ở ngoài `CDB$ROOT` để tránh làm rác và phá vỡ kiến trúc lõi của hệ thống.

Khi hệ thống đã có OMF, Oracle sẽ tự động sinh tên file (`.dbf`) và đặt đúng vào thư mục quy định. Câu lệnh tạo Tablespace sẽ vô cùng ngắn gọn.

Dưới đây là kịch bản tạo 10 Tablespace tiêu chuẩn (Dung lượng ban đầu 10MB, tự động mở rộng thêm 10MB và không giới hạn dung lượng tối đa):

> [!NOTE]
> **Ghi chú về `MAXSIZE UNLIMITED`:** Các script dưới đây sử dụng `MAXSIZE UNLIMITED` theo yêu cầu của bài tập/lab để đơn giản hóa quá trình test. Tuy nhiên, trong môi trường vận hành thực tế (Production), bạn nên giới hạn MAXSIZE bằng một con số cụ thể (VD: `MAXSIZE 32G`) để tránh rủi ro lỗi ứng dụng làm đầy tràn ổ cứng vật lý.

```sql
-- 1. Tablespace lưu dữ liệu chung
CREATE TABLESPACE DATA DATAFILE SIZE 10M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

-- 2. Tablespace lưu Index chung
CREATE TABLESPACE INDX DATAFILE SIZE 10M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

-- 3. Tablespace lưu dữ liệu phân mảnh theo năm (VD: 2026)
CREATE TABLESPACE DATA2026 DATAFILE SIZE 10M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

-- 4. Tablespace lưu Index phân mảnh theo năm (VD: 2026)
CREATE TABLESPACE INDX2026 DATAFILE SIZE 10M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

-- 5. Tablespace lưu dữ liệu chuyên biệt cho nghiệp vụ
CREATE TABLESPACE DATA_NGHIEPVU DATAFILE SIZE 10M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

-- 6. Tablespace lưu Index cho phần nghiệp vụ
CREATE TABLESPACE INDX_NGHIEPVU DATAFILE SIZE 10M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

-- 7. Tablespace cho DUMP (dữ liệu rác/tạm/import-export)
CREATE TABLESPACE DUMP DATAFILE SIZE 10M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

-- 8. Tablespace chuyên lưu trữ dữ liệu lớn (LOB - CLOB/BLOB)
CREATE TABLESPACE LOB DATAFILE SIZE 10M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

-- 9. Tablespace lưu dữ liệu LOG (nhật ký hệ thống/ứng dụng)
CREATE TABLESPACE DATA_LOG DATAFILE SIZE 10M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

-- 10. Tablespace lưu Index cho LOG
CREATE TABLESPACE INDX_LOG DATAFILE SIZE 10M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;
```

---

## 4. Tạo Tablespace KHI CHƯA BẬT OMF (Phải tự quản lý)

> [!IMPORTANT]
> **Vị trí thực thi:** Tương tự Mục 3, bạn **BẮT BUỘC** phải chuyển phiên làm việc vào PDB (`ALTER SESSION SET CONTAINER = pdb1;`) trước khi tạo Tablespace.

Nếu cột `VALUE` ở Mục 2 bị trống, DBA phải tự định nghĩa đường dẫn lưu file một cách tường minh (`DATAFILE '/duong_dan/...'`).

*(Lưu ý: Nhớ thay thế chuỗi `/u01/app/oracle/oradata/YOUR_DB/` thành đường dẫn thư mục thực tế trên Server của bạn)*.

```sql
CREATE TABLESPACE DATA
DATAFILE '/u01/app/oracle/oradata/YOUR_DB/data01.dbf' SIZE 10M 
AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

CREATE TABLESPACE INDX
DATAFILE '/u01/app/oracle/oradata/YOUR_DB/indx01.dbf' SIZE 10M 
AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

CREATE TABLESPACE DATA2026
DATAFILE '/u01/app/oracle/oradata/YOUR_DB/data2026_01.dbf' SIZE 10M 
AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

CREATE TABLESPACE INDX2026
DATAFILE '/u01/app/oracle/oradata/YOUR_DB/indx2026_01.dbf' SIZE 10M 
AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

CREATE TABLESPACE DATA_NGHIEPVU
DATAFILE '/u01/app/oracle/oradata/YOUR_DB/data_nghiepvu_01.dbf' SIZE 10M 
AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

CREATE TABLESPACE INDX_NGHIEPVU
DATAFILE '/u01/app/oracle/oradata/YOUR_DB/indx_nghiepvu_01.dbf' SIZE 10M 
AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

CREATE TABLESPACE DUMP
DATAFILE '/u01/app/oracle/oradata/YOUR_DB/dump01.dbf' SIZE 10M 
AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

CREATE TABLESPACE LOB
DATAFILE '/u01/app/oracle/oradata/YOUR_DB/lob01.dbf' SIZE 10M 
AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

CREATE TABLESPACE DATA_LOG
DATAFILE '/u01/app/oracle/oradata/YOUR_DB/data_log01.dbf' SIZE 10M 
AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

CREATE TABLESPACE INDX_LOG
DATAFILE '/u01/app/oracle/oradata/YOUR_DB/indx_log01.dbf' SIZE 10M 
AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;
```

---

## 5. Kiểm tra trạng thái và file vật lý của Tablespace

Sau khi chạy lệnh tạo ở Mục 3 hoặc Mục 4, bạn nên chạy các lệnh sau (tại PDB hiện hành) để xác nhận Tablespace đã tạo thành công và cấu hình chuẩn xác chưa.

### 5.1. Kiểm tra danh sách Tablespace
```sql
-- Xem danh sách Tablespace và trạng thái (Cần thấy trạng thái ONLINE)
SELECT tablespace_name, status, contents 
FROM dba_tablespaces
ORDER BY tablespace_name;
```

### 5.2. Kiểm tra chi tiết Datafile của Tablespace (Quan trọng)
```sql
-- Xem vị trí lưu file (.dbf), dung lượng, chế độ AUTOEXTEND và bước nhảy
SELECT 
    tablespace_name, 
    file_name, 
    bytes/1024/1024 AS size_mb, 
    autoextensible, 
    (increment_by * (bytes/blocks) / 1024 / 1024) AS next_extent_mb,
    maxbytes/1024/1024 AS max_size_mb 
FROM dba_data_files 
ORDER BY tablespace_name;
```

---

## 6. Các tham số nâng cao (Mở rộng)

- `SIZE 10M`: Khởi tạo file cứng với dung lượng ban đầu là 10 Megabytes.
- `AUTOEXTEND ON`: Cho phép file tự phình to ra khi hết chỗ chứa.
- `NEXT 10M`: Mỗi lần hết chỗ, file sẽ xin hệ điều hành cấp thêm đúng 10 Megabytes. (Với các hệ thống lớn, nên set NEXT lớn hơn, ví dụ `100M` hoặc `500M` để tránh rớt hiệu năng IO do ổ cứng phải cấp phát liên tục).
- `MAXSIZE UNLIMITED`: Cho phép file phình to mãi mãi cho đến khi đầy dung lượng vật lý của ổ cứng.

---

## 7. Chỉnh sửa kích thước Datafile (Resize / Autoextend)

Trong quá trình vận hành, đôi khi DBA cần chủ động tăng dung lượng của một Datafile hoặc thay đổi tốc độ giãn nở của nó. Oracle quy định lệnh `ALTER` chỉ chạy được trên từng file một và phải sử dụng đường dẫn tuyệt đối (lấy từ cột `FILE_NAME` ở Mục 5.2).

Tùy vào số lượng file cần xử lý, bạn có thể chọn một trong các cách sau:

### 7.1. Cách 1: Làm thủ công (Dành cho 1-2 file)

> [!TIP]
> **Mẹo đối với hệ thống dùng OMF:** Do tên file sinh tự động rất dài, bạn nên gõ sẵn cú pháp `ALTER DATABASE DATAFILE '' ...`, sau đó copy đường dẫn từ kết quả truy vấn ở Mục 5.2 và dán (paste) vào giữa cặp dấu nháy đơn để tránh gõ sai chính tả.

```sql
-- Đảm bảo bạn đang đứng đúng ở PDB chứa Tablespace đó
-- Lệnh Thay đổi (Resize) dung lượng của datafile lên thành 20MB
ALTER DATABASE DATAFILE '/đường/dẫn/thực/tế/của/file.dbf' RESIZE 20M;

-- Lệnh Cấu hình lại chế độ Autoextend: mỗi lần đầy tăng thêm 20MB, max không giới hạn
ALTER DATABASE DATAFILE '/đường/dẫn/thực/tế/của/file.dbf' AUTOEXTEND ON NEXT 20M MAXSIZE UNLIMITED;
```

### 7.2. Cách 2: Làm tự động hàng loạt bằng PL/SQL (Khuyên dùng cho nhiều file)

> [!CAUTION]
> Các Tablespace hệ thống lõi (SYSTEM, SYSAUX, UNDOTBS1) thường có dung lượng mặc định rất lớn (>100MB). **TUYỆT ĐỐI KHÔNG** được gộp chung chúng vào lệnh Resize xuống 20MB vì sẽ làm sập Database. Vòng lặp dưới đây đã cài sẵn điều kiện `NOT IN` để loại trừ các file này.

Copy đoạn mã PL/SQL dưới đây chạy trực tiếp để áp dụng thay đổi cho tất cả các file do người dùng tạo ra:

```sql
BEGIN
  -- Lọc lấy danh sách file, LOẠI TRỪ các tablespace hệ thống
  FOR df IN (
      SELECT file_name 
      FROM dba_data_files 
      WHERE tablespace_name NOT IN ('SYSTEM', 'SYSAUX', 'UNDOTBS1', 'USERS')
  ) 
  LOOP
    -- Tự động chạy lệnh Resize
    EXECUTE IMMEDIATE 'ALTER DATABASE DATAFILE ''' || df.file_name || ''' RESIZE 20M';
    
    -- Tự động chạy lệnh Autoextend
    EXECUTE IMMEDIATE 'ALTER DATABASE DATAFILE ''' || df.file_name || ''' AUTOEXTEND ON NEXT 20M MAXSIZE UNLIMITED';
  END LOOP;
END;
/
```

### 7.3. Cách 3: Dùng Dynamic SQL (Sinh ra câu lệnh)

Nếu bạn muốn tạo ra một danh sách các câu lệnh `ALTER` để kiểm tra bằng mắt trước khi chạy thật, hãy dùng câu lệnh `SELECT` sau:

```sql
SELECT 'ALTER DATABASE DATAFILE ''' || file_name || ''' RESIZE 20M; ' || CHR(10) ||
       'ALTER DATABASE DATAFILE ''' || file_name || ''' AUTOEXTEND ON NEXT 20M MAXSIZE UNLIMITED;' AS script_can_chay
FROM dba_data_files
WHERE tablespace_name NOT IN ('SYSTEM', 'SYSAUX', 'UNDOTBS1', 'USERS');
```
*Kết quả trả về sẽ là các câu lệnh SQL hoàn chỉnh. Bạn chỉ việc copy kết quả đó và dán vào tab chạy lệnh mới.*
