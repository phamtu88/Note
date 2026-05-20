# Tài Liệu Quản Trị: User và Profile trong Oracle Multitenant (12c+)

Tài liệu này tổng hợp các kiến thức và lệnh thực hành chi tiết để quản lý **User** (người dùng) và **Profile** (hồ sơ giới hạn tài nguyên/bảo mật) trong kiến trúc đa lớp (Multitenant) của Oracle, bao gồm Container Database (CDB) và Pluggable Database (PDB).

---

## 1. Kiến Thức Nền Tảng: Common vs Local

Trong môi trường Oracle từ 12c trở lên, dữ liệu được chia làm 2 cấp độ: Root (CDB) và các CSDL con (PDB). Do đó, User và Profile cũng được chia làm 2 loại tương ứng:

| Đặc điểm | Common (Dùng chung) | Local (Cục bộ) |
| :--- | :--- | :--- |
| **Vị trí tạo** | Bắt buộc phải tạo ở `CDB$ROOT`. | Tạo ở bên trong một `PDB` cụ thể. |
| **Phạm vi** | Có thể truy cập CDB và tất cả các PDB (nếu được cấp quyền). | Chỉ bị "nhốt" và truy cập dữ liệu bên trong PDB đó. |
| **Quy tắc đặt tên** | Bắt buộc phải có tiền tố `C##` hoặc `c##` ở đầu (VD: `c##admin`). | Đặt tên tự do không cần tiền tố (VD: `hr`, `tupt`). |
| **Cú pháp lệnh** | Thường phải gắn thêm tùy chọn `CONTAINER = ALL`. | Lệnh SQL thông thường. |

> [!IMPORTANT]
> **Quy tắc "Cùng Cấp":** Common User có thể được gán Common Profile. Local User chỉ được gán Local Profile. Bạn không thể lấy một Local Profile để gán cho một Common User ở phạm vi toàn hệ thống.

---

## 2. Chuẩn Bị: Bật tính năng theo dõi tài nguyên

Profile trong Oracle quản lý 2 nhóm thông số:
1. **Nhóm Mật Khẩu (Password Limits):** VD như `PASSWORD_LIFE_TIME` (hạn dùng mật khẩu). Nhóm này **luôn luôn hoạt động** mặc định vì lý do bảo mật.
2. **Nhóm Tài Nguyên (Resource Limits):** VD như `IDLE_TIME` (thời gian treo máy), `CPU_PER_SESSION`. Nhóm này tiêu tốn sức mạnh của hệ thống để theo dõi (đếm giờ, đếm CPU), nên Oracle **tắt mặc định**.

Để các thông số như `IDLE_TIME` có hiệu lực thực tế (thay vì chỉ tồn tại trên giấy), DBA bắt buộc phải bật cờ (flag) hệ thống bằng lệnh sau:

```sql
-- Dùng tài khoản SYS kiểm tra xem đã bật chưa (TRUE = đã bật)
SHOW PARAMETER resource_limit;
-- Hoặc: SELECT name, value FROM v$parameter WHERE name = 'resource_limit';

-- Nếu kết quả là FALSE, chạy lệnh sau để bật:
ALTER SYSTEM SET RESOURCE_LIMIT = TRUE;
```

---

## 3. Hướng Dẫn Thực Hành: COMMON USER & PROFILE

Kịch bản: Tạo một Profile dùng chung giới hạn pass 45 ngày, timeout 60 phút và gán cho một Common User.

### Bước 1: Trỏ phiên làm việc về Root
```sql
ALTER SESSION SET CONTAINER = CDB$ROOT;
```

### Bước 2: Tạo Common Profile
Lưu ý: Tên profile phải có `c##` và lệnh kết thúc bằng `container = all`.
```sql
CREATE PROFILE c##test_profile LIMIT
  PASSWORD_LIFE_TIME 45
  IDLE_TIME 60
  CONTAINER = ALL;
```

### Bước 3: Tạo Common User và gán Profile
```sql
-- Tạo User
CREATE USER c##tupt IDENTIFIED BY "oracle@123" CONTAINER = ALL;

-- Cấp quyền kết nối (tuỳ chọn)
GRANT CONNECT, RESOURCE TO c##tupt CONTAINER = ALL;

-- Gán Profile cho User
ALTER USER c##tupt PROFILE c##test_profile CONTAINER = ALL;
```

### Bước 4: Kiểm tra lại (Chứng minh)
> [!NOTE]
> Khi truy vấn trong các bảng Data Dictionary (`DBA_USERS`, `DBA_PROFILES`), chuỗi văn bản (tên user, tên profile) bắt buộc phải viết **IN HOA**.

```sql
-- Kiểm tra user c##tupt đang dùng profile nào
SELECT username, profile 
FROM dba_users 
WHERE username = 'C##TUPT';

-- Kiểm tra xem profile c##test_profile có đúng 45 ngày và 60 phút không
SELECT profile, resource_name, limit 
FROM dba_profiles 
WHERE profile = 'C##TEST_PROFILE' 
  AND resource_name IN ('PASSWORD_LIFE_TIME', 'IDLE_TIME');
```

---

## 4. Hướng Dẫn Thực Hành: LOCAL USER & PROFILE

Kịch bản: Tạo một Profile cục bộ giới hạn tương tự, và gán cho một Local User bên trong PDB1.

### Bước 1: Trỏ phiên làm việc vào PDB
```sql
ALTER SESSION SET CONTAINER = pdb1;
```

### Bước 2: Tạo Local Profile
Lưu ý: Không dùng tiền tố `c##`, đặt tên tự do. Không dùng `container = all`.
```sql
CREATE PROFILE test_profile LIMIT
  PASSWORD_LIFE_TIME 45
  IDLE_TIME 60;
```

### Bước 3: Tạo Local User và gán Profile
```sql
-- Tạo User
CREATE USER tupt IDENTIFIED BY "oracle@123";

-- Cấp quyền kết nối (tuỳ chọn)
GRANT CONNECT, RESOURCE TO tupt;

-- Gán Profile cho User
ALTER USER tupt PROFILE test_profile;
```

### Bước 4: Kiểm tra lại (Chứng minh)
Phải đảm bảo đang ở PDB1 trước khi chạy lệnh kiểm tra.

```sql
-- Kiểm tra user tupt đang dùng profile nào
SELECT username, profile 
FROM dba_users 
WHERE username = 'TUPT';

-- Kiểm tra xem profile test_profile có đúng 45 ngày và 60 phút không
SELECT profile, resource_name, limit 
FROM dba_profiles 
WHERE profile = 'TEST_PROFILE' 
  AND resource_name IN ('PASSWORD_LIFE_TIME', 'IDLE_TIME');
```

---

## 5. Hướng Dẫn Thực Hành: ROLE (Nhóm Quyền)

Tương tự như User và Profile, **Role** (nhóm quyền) cũng bị chia làm 2 loại là Common và Local với quy tắc đặt tên y hệt. Dưới đây là cách tạo Role và gán các quyền hệ thống vào Role.

> [!WARNING]
> **Lỗi Kinh Điển: `ORA-01931: cannot grant UNLIMITED TABLESPACE to a role`**
> Trong Oracle, bạn **TUYỆT ĐỐI KHÔNG** được phép gán quyền `UNLIMITED TABLESPACE` (không giới hạn dung lượng ổ đĩa) cho một Role. Đây là quy định bảo mật bắt buộc của Oracle. Để giải quyết, bạn phải gán các quyền khác cho Role bình thường, còn quyền `UNLIMITED TABLESPACE` thì phải gán **trực tiếp cho từng cá nhân (User)** (như hướng dẫn ở Bước 3.1 bên dưới).

### 5.1. Tạo Common Role (Tại CDB$ROOT)
Dùng để chứa các quyền cấp độ toàn hệ thống và gán cho các Common User.

```sql
ALTER SESSION SET CONTAINER = CDB$ROOT;

-- Bước 1: Tạo Common Role (Bắt buộc có c## và container=all)
CREATE ROLE c##test_role CONTAINER = ALL;

-- Bước 2: Gán các quyền yêu cầu vào Role (Trừ UNLIMITED TABLESPACE)
GRANT CONNECT, RESOURCE, SELECT ANY TABLE, SELECT ANY DICTIONARY 
TO c##test_role CONTAINER = ALL;

-- Bước 3: Gán Role này cho một Common User (VD: c##tupt)
GRANT c##test_role TO c##tupt CONTAINER = ALL;

-- Bước 3.1: Gán quyền UNLIMITED TABLESPACE trực tiếp cho User (Quy định của Oracle)
GRANT UNLIMITED TABLESPACE TO c##tupt CONTAINER = ALL;

-- Bước 4: Kiểm tra lại (Chứng minh)
-- Kiểm tra xem Role đã có đủ quyền chưa
SELECT grantee, privilege FROM dba_sys_privs WHERE grantee = 'C##TEST_ROLE';

-- Kiểm tra xem User đã được gán Role chưa
SELECT grantee, granted_role FROM dba_role_privs WHERE grantee = 'C##TUPT';

-- (Quan trọng) Vì UNLIMITED TABLESPACE không thể gán qua Role, nên để kiểm tra 
-- xem User đã có quyền này chưa, ta phải tra cứu các quyền được gán TRỰC TIẾP cho User:
SELECT grantee, privilege FROM dba_sys_privs WHERE grantee = 'C##TUPT';
```

### 5.2. Tạo Local Role (Tại PDB1)
Dùng để chứa các quyền chỉ áp dụng riêng cho dữ liệu bên trong một PDB cụ thể.

```sql
ALTER SESSION SET CONTAINER = pdb1;

-- Bước 1: Tạo Local Role (Tên tự do, không có container=all)
CREATE ROLE test_role;

-- Bước 2: Gán các quyền yêu cầu vào Role (Trừ UNLIMITED TABLESPACE)
GRANT CONNECT, RESOURCE, SELECT ANY TABLE, SELECT ANY DICTIONARY 
TO test_role;

-- Bước 3: Gán Role này cho một Local User (VD: tupt)
GRANT test_role TO tupt;

-- Bước 3.1: Gán quyền UNLIMITED TABLESPACE trực tiếp cho User (Quy định của Oracle)
GRANT UNLIMITED TABLESPACE TO tupt;

-- Bước 4: Kiểm tra lại (Chứng minh)
-- Kiểm tra xem Role đã có đủ quyền chưa
SELECT grantee, privilege FROM dba_sys_privs WHERE grantee = 'TEST_ROLE';

-- Kiểm tra xem User đã được gán Role chưa
SELECT grantee, granted_role FROM dba_role_privs WHERE grantee = 'TUPT';

-- (Quan trọng) Vì UNLIMITED TABLESPACE không thể gán qua Role, nên để kiểm tra 
-- xem User đã có quyền này chưa, ta phải tra cứu các quyền được gán TRỰC TIẾP cho User:
SELECT grantee, privilege FROM dba_sys_privs WHERE grantee = 'TUPT';
```

---

## 6. Phân tích và Thu hồi quyền (Privilege Analysis)

Trong quá trình vận hành, để đảm bảo nguyên tắc "Đặc quyền tối thiểu" (Least Privilege), DBA cần phân tích xem một user có được cấp thừa quyền hay không. Dưới đây là kịch bản sử dụng một **Common User (`c##tupt`)** để phân tích và thu hồi quyền dư thừa cho **Local User (`tupt`)** nằm bên trong PDB.

*(Lưu ý: Bạn hoàn toàn có thể dùng Common User để quản lý Local User. Cách làm là cấp quyền cho Common User trên toàn hệ thống, sau đó chuyển phiên làm việc vào PDB cụ thể để chạy công cụ phân tích).*

### Bước 1: Kiểm tra, cấp quyền CAPTURE_ADMIN và trỏ vào PDB

> [!TIP]
> **Cấp quyền Cục bộ (Local Grant) cho Common User:** Thay vì cấp quyền `CAPTURE_ADMIN` trên toàn hệ thống (Root), bạn có thể nhảy thẳng vào PDB và cấp quyền cục bộ (không dùng `CONTAINER = ALL`). Cách này bảo mật hơn, tuân thủ nguyên tắc "Đặc quyền tối thiểu" vì User `c##tupt` sẽ chỉ có quyền chạy phân tích bên trong đúng PDB đó mà không thể nhòm ngó các PDB khác.

Bạn có thể chọn 1 trong 2 cách sau để thực hiện:

**Cách 1: Cấp quyền cục bộ (Khuyên dùng - Đứng tại PDB)**
```sql
-- 1.1 Nhảy ngay vào PDB1
ALTER SESSION SET CONTAINER = pdb1;

-- 1.2 (Đứng tại PDB1 bằng SYS) Kiểm tra xem c##tupt đã có quyền cục bộ chưa
SELECT grantee, granted_role FROM dba_role_privs 
WHERE granted_role = 'CAPTURE_ADMIN' AND grantee = 'C##TUPT';

-- 1.3 Cấp quyền cục bộ (Lệnh ngắn gọn, KHÔNG có chữ CONTAINER=ALL)
GRANT CAPTURE_ADMIN TO c##tupt;
```

**Cách 2: Cấp quyền toàn hệ thống (Đứng tại ROOT)**
```sql
-- 1.1 (Đứng tại CDB$ROOT bằng SYS) Kiểm tra xem c##tupt đã có quyền chưa
SELECT grantee, granted_role FROM dba_role_privs 
WHERE granted_role = 'CAPTURE_ADMIN' AND grantee = 'C##TUPT';

-- 1.2 Cấp quyền trên toàn hệ thống
GRANT CAPTURE_ADMIN TO c##tupt CONTAINER = ALL;

-- 1.3 Nhảy vào PDB1 để chuẩn bị làm việc với Local User tupt
ALTER SESSION SET CONTAINER = pdb1;
```

### Bước 2: Tạo Policy phân tích riêng cho Local User `tupt`
*(Từ bước này trở đi, bạn sử dụng user `c##tupt` đã kết nối vào PDB1 để chạy lệnh)*
```sql
BEGIN
  DBMS_PRIVILEGE_CAPTURE.CREATE_CAPTURE(
    name        => 'capture_local_tupt',
    description => 'Theo doi cac quyen cua local user tupt',
    type        => DBMS_PRIVILEGE_CAPTURE.G_CONTEXT,
    condition   => 'SYS_CONTEXT(''USERENV'', ''SESSION_USER'') = ''TUPT'''
  );
END;
/
```

### Bước 3: Kích hoạt Policy (Bắt đầu theo dõi)
*Hệ thống cần chạy đủ lâu (vài ngày/vài tuần) để bắt được toàn bộ chu kỳ hoạt động của ứng dụng.*
```sql
BEGIN
  DBMS_PRIVILEGE_CAPTURE.ENABLE_CAPTURE('capture_local_tupt');
END;
/
```

### Bước 4: Vô hiệu hóa Policy và Tổng hợp dữ liệu
Sau khi chốt thời gian theo dõi:
```sql
-- Tắt theo dõi
BEGIN
  DBMS_PRIVILEGE_CAPTURE.DISABLE_CAPTURE('capture_local_tupt');
END;
/

-- Tổng hợp dữ liệu báo cáo
BEGIN
  DBMS_PRIVILEGE_CAPTURE.GENERATE_RESULT('capture_local_tupt');
END;
/
```

### Bước 5: Truy vấn các quyền ĐANG CÓ nhưng KHÔNG SỬ DỤNG
```sql
-- 1. Xem các quyền hệ thống (System Privileges) dư thừa
SELECT SYS_PRIV, ROLENAME 
FROM DBA_UNUSED_SYSPRIVS 
WHERE CAPTURE = 'capture_local_tupt' AND USERNAME = 'TUPT';

-- 2. Xem các quyền tác động lên bảng/view (Object Privileges) dư thừa
SELECT OBJECT_OWNER, OBJECT_NAME, OBJECT_TYPE, OBJ_PRIV, ROLENAME
FROM DBA_UNUSED_OBJPRIVS 
WHERE CAPTURE = 'capture_local_tupt' AND USERNAME = 'TUPT';
```

### Bước 6: Thu hồi quyền dư thừa và dọn dẹp
Giả sử từ kết quả Bước 5, ta phát hiện `tupt` chưa bao giờ sử dụng quyền SELECT ANY TABLE (được cấp từ `test_role` ở mục 5.2).

```sql
-- Thu hồi quyền từ Role (vì quyền này được gán thông qua test_role)
REVOKE SELECT ANY TABLE FROM test_role;

-- Hoặc nếu đó là quyền gán trực tiếp, ví dụ:
-- REVOKE DELETE ON HR.EMPLOYEES FROM tupt;

-- Xóa policy để giải phóng tài nguyên
BEGIN
  DBMS_PRIVILEGE_CAPTURE.DROP_CAPTURE('capture_local_tupt');
END;
/
```
