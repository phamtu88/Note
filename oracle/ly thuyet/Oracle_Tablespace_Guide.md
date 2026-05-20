# Tài Liệu Quản Trị: Cấu hình và Tạo Tablespace trong Oracle

Tài liệu này hướng dẫn cách kiểm tra cấu hình lưu trữ tự động (OMF) và các kịch bản tạo Tablespace chuẩn xác dùng cho lưu trữ dữ liệu, Index, phân mảnh theo năm và lưu trữ file LOB.

---

## 1. Kiểm tra cấu hình Oracle Managed Files (OMF)

Trước khi tạo Tablespace, DBA cần kiểm tra xem hệ thống đã được cấu hình tính năng tự động quản lý file (OMF) thông qua tham số `db_create_file_dest` hay chưa.

### Lệnh kiểm tra:
```sql
-- Chạy trên TOAD, SQL Developer, PL/SQL Developer...
SELECT name, value 
FROM v$parameter 
WHERE name = 'db_create_file_dest';
```

### Cách đọc kết quả:
- **Nếu cột `VALUE` có chứa đường dẫn** (VD: `+DATA` hoặc `/u01/app/oracle/oradata`): Hệ thống ĐÃ BẬT OMF. Bạn áp dụng **Mục 2** bên dưới.
- **Nếu cột `VALUE` bị trống (Null)**: Hệ thống CHƯA BẬT OMF. Bạn áp dụng **Mục 3** bên dưới (Phải tự gõ đường dẫn tay).

---

## 2. Tạo Tablespace KHI ĐÃ BẬT OMF (Khuyên dùng)

> [!IMPORTANT]
> **Vị trí thực thi (Rất quan trọng):** Bạn **BẮT BUỘC** phải chuyển phiên làm việc vào trong PDB (Ví dụ: `ALTER SESSION SET CONTAINER = pdb1;`) trước khi chạy lệnh `CREATE TABLESPACE`. Tuyệt đối không tạo Tablespace dữ liệu nghiệp vụ ở ngoài `CDB$ROOT` để tránh làm rác và phá vỡ kiến trúc lõi của hệ thống.

Khi hệ thống đã có OMF, Oracle sẽ tự động sinh tên file (`.dbf`) và đặt đúng vào thư mục quy định. Câu lệnh tạo Tablespace sẽ vô cùng ngắn gọn.

Dưới đây là kịch bản tạo 10 Tablespace tiêu chuẩn (Dung lượng ban đầu 10MB, tự động mở rộng thêm 10MB và không giới hạn dung lượng tối đa):

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

## 3. Tạo Tablespace KHI CHƯA BẬT OMF (Phải tự quản lý)

> [!IMPORTANT]
> **Vị trí thực thi:** Tương tự Mục 2, bạn **BẮT BUỘC** phải chuyển phiên làm việc vào PDB (`ALTER SESSION SET CONTAINER = pdb1;`) trước khi tạo Tablespace.

Nếu cột `VALUE` ở Mục 1 bị trống, DBA phải tự định nghĩa đường dẫn lưu file một cách tường minh (`DATAFILE '/duong_dan/...'`).

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

## 4. Các tham số nâng cao (Mở rộng)

- `SIZE 10M`: Khởi tạo file cứng với dung lượng ban đầu là 10 Megabytes.
- `AUTOEXTEND ON`: Cho phép file tự phình to ra khi hết chỗ chứa.
- `NEXT 10M`: Mỗi lần hết chỗ, file sẽ xin hệ điều hành cấp thêm đúng 10 Megabytes. (Với các hệ thống lớn, nên set NEXT lớn hơn, ví dụ `100M` hoặc `500M` để tránh rớt hiệu năng IO do ổ cứng phải cấp phát liên tục).
- `MAXSIZE UNLIMITED`: Cho phép file phình to mãi mãi cho đến khi đầy dung lượng vật lý của ổ cứng.
