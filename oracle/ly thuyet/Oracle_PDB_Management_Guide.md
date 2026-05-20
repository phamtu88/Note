# Tài Liệu Quản Trị: Quản lý Pluggable Database (PDB) trong Oracle

Tài liệu này tổng hợp các kiến thức về giới hạn số lượng PDB và các bước thực hành khởi tạo một PDB mới trong môi trường Oracle Multitenant (CDB/PDB).

---

## 1. Giới hạn số lượng Pluggable Database (PDB)

Giới hạn số lượng PDB trong một Container Database (CDB) phụ thuộc vào phiên bản Oracle và bản quyền phần mềm (License):

### 1.1. Khi KHÔNG có giấy phép Multitenant (Bản quyền mặc định)
- **Oracle 12c:** Cho phép tối đa **1 PDB** do người dùng tạo.
- **Oracle 19c (và 21c, 23c):** Cho phép tối đa **3 PDBs** do người dùng tạo.

### 1.2. Khi ĐÃ MUA giấy phép Multitenant Option (Tối đa kỹ thuật)
- **Oracle 12c (từ 12.1):** Hỗ trợ tối đa **252 PDBs**.
- **Oracle 12.2 và Oracle 19c:** Hỗ trợ tối đa lên đến **4,096 PDBs**.

> [!NOTE]
> Khi sử dụng lệnh `SHOW PDBS`, hệ thống luôn hiển thị một container có tên là `PDB$SEED`. Đây là một bản mẫu (template) mặc định của hệ thống ở trạng thái `READ ONLY` dùng làm khuôn để đúc (tạo) ra các PDB khác. `PDB$SEED` **không bị tính** vào số lượng PDB giới hạn ở trên.

### 1.3. Cấu hình giới hạn chủ động (Tham số MAX_PDBS)
Để tránh DBA tạo quá số lượng PDB cho phép gây vi phạm bản quyền, từ bản 12.2, bạn có thể cấu hình chặn cứng ở cấp độ hệ thống:
```sql
-- Ví dụ: Giới hạn tối đa 3 PDB cho hệ thống Oracle 19c (không license Multitenant)
ALTER SYSTEM SET MAX_PDBS=3;
```

---

## 2. Các bước khởi tạo một Pluggable Database (PDB) mới

Để tạo PDB, DBA phải đăng nhập với quyền tối cao (`SYSDBA`) và đang làm việc ở container gốc là `CDB$ROOT`.

### Bước 1: Kết nối và kiểm tra vị trí hiện tại
```sql
-- Đăng nhập vào database
sqlplus / as sysdba

-- Kiểm tra container hiện tại đang kết nối (Phải là CDB$ROOT)
SHOW CON_NAME;

-- Nếu chưa phải, chuyển phiên làm việc về CDB$ROOT:
ALTER SESSION SET CONTAINER = CDB$ROOT;
```

### Bước 2: Khởi tạo PDB
Lệnh khởi tạo PDB phụ thuộc vào việc hệ thống có sử dụng tính năng **Oracle Managed Files (OMF)** hay không. *(Xem thêm cách kiểm tra OMF tại mục 1 của tài liệu `Oracle_Tablespace_Guide.md`)*.

**Kịch bản A: Hệ thống ĐÃ BẬT OMF (Khuyên dùng)**
Oracle sẽ tự động sinh file dữ liệu và đặt đúng thư mục. Bạn chỉ cần chạy lệnh ngắn gọn:
```sql
-- Lệnh dưới đây tạo PDB2, đồng thời tạo một tài khoản admin cục bộ tên là pdb2_admin
CREATE PLUGGABLE DATABASE PDB2 ADMIN USER pdb2_admin IDENTIFIED BY "MatKhauBaoMat123";
```

**Kịch bản B: Hệ thống CHƯA BẬT OMF**
DBA bắt buộc phải chỉ định đường dẫn thủ công để Oracle biết nơi copy file từ `PDB$SEED` sang.
```sql
CREATE PLUGGABLE DATABASE PDB2 
  ADMIN USER pdb2_admin IDENTIFIED BY "MatKhauBaoMat123"
  FILE_NAME_CONVERT = ('/đường/dẫn/thư/mục/pdbseed/', '/đường/dẫn/thư/mục/pdb2/');
```

### Bước 3: Mở PDB và lưu trạng thái khởi động
Sau khi quá trình tạo kết thúc (hiển thị `Pluggable database created`), PDB mới sẽ nằm ở trạng thái đóng (`MOUNTED`). Bạn cần mở nó lên để sử dụng.

```sql
-- 1. Mở PDB vừa tạo
ALTER PLUGGABLE DATABASE PDB2 OPEN;

-- 2. Kiểm tra lại trạng thái các PDB (PDB2 phải ở trạng thái READ WRITE)
SHOW PDBS;

-- 3. Lưu trạng thái (Rất quan trọng)
-- Giúp PDB2 tự động mở (OPEN) mỗi khi máy chủ database bị khởi động lại.
ALTER PLUGGABLE DATABASE PDB2 SAVE STATE;
```

Hoàn tất! Giờ đây bạn có thể chuyển đổi phiên làm việc vào PDB mới (`ALTER SESSION SET CONTAINER = PDB2;`) để bắt đầu tạo Tablespace lưu trữ và User ứng dụng.
