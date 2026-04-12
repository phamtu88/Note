# Bước 2: Chuẩn bị Hệ điều hành cho Oracle RAC (Thực hiện trên 2 Nodes)

Sau khi cấu hình xong mạng và ổ đĩa dùng chung trên VMware, bạn cần chuẩn bị môi trường OS đồng bộ trên cả 2 node để sẵn sàng cài đặt Grid Infrastructure.

---

## 1. Cài đặt các gói điều kiện (Oracle Preinstall)

Chạy lệnh sau trên **CẢ 2 NODES** bằng quyền `root`:

```bash
# Oracle Linux cung cấp gói chuyên dụng cho Grid
dnf install -y oracle-database-preinstall-19c
```

## 2. Tạo Group và User cho Grid Infrastructure

Mặc định gói preinstall chỉ tạo user `oracle`. Đối với hệ thống RAC chuyên nghiệp, chúng ta nên tách biệt quyền hạn giữa người quản trị hạ tầng (`grid`) và người quản trị CSDL (`oracle`).

Chạy trên **CẢ 2 NODES** bằng quyền `root`:

```bash
# Tạo các nhóm quản trị bổ sung cho ASM
groupadd -g 54315 asmadmin
groupadd -g 54316 asmdba
groupadd -g 54317 asmoper

# Tạo user grid
useradd -u 54322 -g oinstall -G asmadmin,asmdba,asmoper,dba grid

# Thêm user oracle vào các nhóm ASM để nó nhìn thấy ổ cứng
usermod -a -G asmdba,asmadmin oracle

# Đặt mật khẩu (Khuyên dùng: oracle123)
passwd grid
passwd oracle
```

---

## 3. Khởi tạo cấu trúc thư mục (OFA)

Chạy trên **CẢ 2 NODES** bằng quyền `root`:

```bash
# Thư mục cho Grid Home
mkdir -p /u01/app/19.3.0/grid
mkdir -p /u01/app/grid

# Thư mục cho Database (ORACLE_BASE)
mkdir -p /u01/app/oracle

# Phân quyền cho grid
chown -R grid:oinstall /u01
chown -R grid:oinstall /u01/app/19.3.0/grid
chown -R grid:oinstall /u01/app/grid

# Phân quyền cho oracle
chown -R oracle:oinstall /u01/app/oracle

chmod -R 775 /u01
```

---

## 4. Cấu hình SSH Passwordless cho User Grid (Cực kỳ quan trọng)

Bộ cài Oracle RAC cần điều khiển các node từ xa mà không hỏi mật khẩu. Chúng ta sẽ cấu hình cho user `grid`.

**Bước 1: Trên Node 1 (User grid)**
```bash
su - grid
ssh-keygen -t rsa   # Nhấn Enter liên tục cho đến khi xong
ssh-copy-id oracle1
ssh-copy-id oracle2
```

**Bước 2: Trên Node 2 (User grid)**
```bash
su - grid
ssh-keygen -t rsa
ssh-copy-id oracle1
ssh-copy-id oracle2
```

**Bước 3: Kiểm tra (Thực hiện trên cả 2 node)**
```bash
# Phải login qua lại được mà không hỏi mật khẩu
ssh oracle1 date
ssh oracle2 date
```

---

## 5. Cấu hình các tham số hệ thống (Limits & Sysctl)

Gói `oracle-database-preinstall-19c` đã làm hầu hết, nhưng ta cần bổ sung cho user `grid`.

Mở file `/etc/security/limits.d/oracle-database-preinstall-19c.conf` (hoặc tạo file mới) trên **CẢ 2 NODES**:

```text
grid   soft   nofile    1024
grid   hard   nofile    65536
grid   soft   nproc     2047
grid   hard   nproc     16384
grid   soft   stack     10240
grid   hard   stack     32768
grid   hard   memlock   134217728
grid   soft   memlock   134217728
```

---

## 6. Thiết lập biến môi trường (.bash_profile)

Mỗi Node sẽ có các tham số môi trường khác nhau (như `ORACLE_SID`), vì vậy bạn phải thiết lập cẩn thận trên từng Node.

**Trên Node 1 (oracle1):**

*Biến môi trường cho user `grid`:*
```bash
su - grid
vi ~/.bash_profile
# Thêm vào cuối file:
export ORACLE_SID=+ASM1
export ORACLE_BASE=/u01/app/grid
export ORACLE_HOME=/u01/app/19.3.0/grid
export PATH=$ORACLE_HOME/bin:$PATH
```

*Biến môi trường cho user `oracle`:*
```bash
su - oracle
vi ~/.bash_profile
# Thêm vào cuối file:
export ORACLE_SID=orcl1
export ORACLE_UNQNAME=orcl
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/19.0.0/dbhome_1
export PATH=$ORACLE_HOME/bin:$PATH
```

**Trên Node 2 (oracle2):**

*Biến môi trường cho user `grid`:*
```bash
su - grid
vi ~/.bash_profile
# Thêm vào cuối file:
export ORACLE_SID=+ASM2
export ORACLE_BASE=/u01/app/grid
export ORACLE_HOME=/u01/app/19.3.0/grid
export PATH=$ORACLE_HOME/bin:$PATH
```

*Biến môi trường cho user `oracle`:*
```bash
su - oracle
vi ~/.bash_profile
# Thêm vào cuối file:
export ORACLE_SID=orcl2
export ORACLE_UNQNAME=orcl
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/19.0.0/dbhome_1
export PATH=$ORACLE_HOME/bin:$PATH
```

---

## 7. Sẵn sàng cho bước tiếp theo

Bây giờ bạn đã có 2 máy chủ Linux cấu hình giống hệt nhau, có user `grid` và `oracle` có thể "nói chuyện" với nhau qua SSH và các biến môi trường đã được tải đầy đủ. 

Bước tiếp theo chúng ta sẽ tiến hành cấu hình **UDEV Rules** để "nhào nặn" các ổ đĩa VMware thành các ổ đĩa ASM sẵn sàng cho Grid.
