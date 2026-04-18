# Giai đoạn 2: Setup Môi trường (Environment Setup)

Sau khi hạ tầng phần cứng và mạng đã sẵn sàng, chúng ta tiến hành chuẩn bị các "phần mềm mồi", cấu trúc thư mục OFA và quy tắc lưu trữ ASM.

---

## 1. Cài đặt Gói tiền điều kiện (Oracle Preinstall)
Chạy trên **CẢ 2 NODES** bằng quyền `root`:
```bash
# Gói này tự động cấu hình Kernel, Sysctl và Resource Limits chuẩn cho Oracle.
yum install -y oracle-database-preinstall-19c
```

## 2. Tạo User và Group cho hạ tầng Grid
Mặc định gói preinstall chỉ tạo user `oracle`. Chúng ta cần tạo thêm user `grid` và gán vào các nhóm ASM chuyên dụng.

```bash
# 1. Tạo các nhóm quản trị ASM (Thực hiện trên CẢ 2 NODES)
groupadd -g 54315 asmadmin
groupadd -g 54316 asmdba
groupadd -g 54317 asmoper

# 2. Tạo user grid
useradd -u 54322 -g oinstall -G asmadmin,asmdba,asmoper,dba grid

# 3. Thêm oracle vào các nhóm ASM để nhìn thấy ổ cứng
usermod -a -G asmdba,asmadmin oracle

# 4. Đặt mật khẩu (Bắt buộc phải làm trên cả 2 node để cấu hình SSH không lỗi)
# Khuyên dùng: oracle123
passwd grid
passwd oracle
```

## 3. Khởi tạo cấu trúc thư mục OFA (Optimal Flexible Architecture)
Chúng ta quy hoạch tập trung vào thư mục `/u01`:
```bash
# Tạo các thư mục Home cho Grid và Database
mkdir -p /u01/app/19.3.0/grid   # GRID_HOME (Nơi giải nén bộ cài Grid)
mkdir -p /u01/app/grid          # GRID_BASE
mkdir -p /u01/app/oracle        # ORACLE_BASE

# Phân quyền chuẩn xác (Cực kỳ quan trọng)
chown -R grid:oinstall /u01
chown -R grid:oinstall /u01/app/19.3.0/grid
chown -R grid:oinstall /u01/app/grid
chown -R oracle:oinstall /u01/app/oracle
chmod -R 775 /u01
```

## 4. Cấu hình SSH Passwordless (Tối quan trọng)
Bộ cài RAC cần di chuyển dữ liệu giữa các node tự động. Phải cấu hình cho **cả 2 user** trên **cả 2 node**.

> [!WARNING]
> - **Chìa khóa (`ssh-keygen`)**: Nhấn <Enter> liên tục 3 lần, không nhập passphrase.
> - **Lỗi `Host key verification failed`**: Phải gõ đủ chữ `yes` khi được hỏi lần đầu.

```bash
# Ví dụ cấu hình cho user grid (Làm tương tự cho oracle)
su - grid
ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
ssh-copy-id oracle1
ssh-copy-id oracle2

# Kiểm tra: Lệnh sau phải trả về ngày tháng mà không hỏi mật khẩu
ssh oracle2 date
```

## 5. Cấu hình các tham số hệ thống bổ sung (Limits)
Chạy trên **CẢ 2 NODES** bằng quyền `root` để bổ sung giới hạn tài nguyên cho user `grid` (vì gói preinstall chỉ làm cho oracle).

```bash
cat <<EOF >> /etc/security/limits.d/oracle-database-preinstall-19c.conf

# Bổ sung giới hạn tài nguyên cho user grid
grid   soft   nofile    1024
grid   hard   nofile    65536
grid   soft   nproc     2047
grid   hard   nproc     16384
grid   soft   stack     10240
grid   hard   stack     32768
grid   hard   memlock   134217728
grid   soft   memlock   134217728
EOF
```

## 6. Thiết lập biến môi trường (.bash_profile)
Mỗi Node có `ORACLE_SID` riêng, hãy cấu hình cẩn thận:

**Trên Node 1 (oracle1):**
- User `grid`: `ORACLE_SID=+ASM1`, `ORACLE_BASE=/u01/app/grid`, `ORACLE_HOME=/u01/app/19.3.0/grid`.
- User `oracle`: `ORACLE_SID=orcl1`, `ORACLE_BASE=/u01/app/oracle`.

**Trên Node 2 (oracle2):**
- User `grid`: `ORACLE_SID=+ASM2`, `ORACLE_BASE=/u01/app/grid`, `ORACLE_HOME=/u01/app/19.3.0/grid`.
- User `oracle`: `ORACLE_SID=orcl2`, `ORACLE_BASE=/u01/app/oracle`.

## 7. Đồng bộ thời gian với Chrony
```bash
timedatectl set-timezone Asia/Ho_Chi_Minh
systemctl enable --now chronyd
chronyc -a makestep
# Kiểm tra: Có dấu ^* ở lệnh 'chronyc sources' là đạt yêu cầu.
```

## 8. Cấu hình UDEV Rules cho ASM
Đây là bước cuối cùng để gán quyền ổ đĩa cho `grid:asmadmin`.
1. Lấy UUID của đĩa: `/usr/lib/udev/scsi_id -g -u -d /dev/sdb`.
2. Tạo file `/etc/udev/rules.d/99-oracle-asmdevices.rules`.
3. Áp dụng: `udevadm control --reload-rules` và `udevadm trigger`.
4. Kiểm tra: `ll /dev/oracleasm/*`.

---
> [!NOTE]
> Sau khi `ll /dev/oracleasm/*` hiện đúng quyền và giờ 2 máy đã khớp hoàn toàn, hãy chuyển sang **[Giai đoạn 3: Cài đặt](RAC_Phase_3_Installation.md)**.
