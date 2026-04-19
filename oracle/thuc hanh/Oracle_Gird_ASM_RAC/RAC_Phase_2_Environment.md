# Giai đoạn 2: Setup Môi trường (Environment Setup)

Sau khi hạ tầng phần cứng và mạng đã sẵn sàng, chúng ta tiến hành chuẩn bị các "phần mềm mồi", cấu trúc thư mục OFA và quy tắc lưu trữ ASM.

---

## 1. Cài đặt Gói tiền điều kiện (Oracle Preinstall)
Chạy trên **CẢ 2 NODES** bằng quyền `root`. Chọn một trong 2 trường hợp sau:

### Trường hợp A: Có Internet (Online)
```bash
# Gói này tự động cấu hình Kernel, Sysctl và Resource Limits chuẩn cho Oracle.
yum install -y oracle-database-preinstall-19c
```

### Trường hợp B: Không có Internet (Offline)
Nếu máy chủ không có mạng, bạn cần thực hiện theo các bước sau:

**1. Tạo Local Repository từ file ISO:**
Gắn đĩa ISO Oracle Linux vào máy ảo (VMware Settings -> CD/DVD -> Connected).
```bash
mount /dev/cdrom /mnt
cat > /etc/yum.repos.d/local.repo <<EOF
[LocalRepo]
name=Oracle Linux ISO
baseurl=file:///mnt
enabled=1
gpgcheck=0
EOF
```

**2. Cài đặt các gói thư viện cần thiết:**
```bash
# Thay thế cho gói preinstall RPM
yum install -y binutils compat-libcap1 gcc gcc-c++ glibc glibc-devel ksh libaio libaio-devel libstdc++ libstdc++-devel make sysstat
```

**3. Cấu hình tham số Kernel thủ công:**
Tạo file `/etc/sysctl.d/99-oracle.conf`:
```bash
cat > /etc/sysctl.d/99-oracle.conf <<EOF
fs.file-max = 6815744
kernel.sem = 250 32000 100 128
kernel.shmmax = 4294967296
kernel.shmall = 2097152
kernel.shmmni = 4096
kernel.panic_on_oops = 1
fs.aio-max-nr = 1048576
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
net.ipv4.ip_local_port_range = 9000 65500
EOF
sysctl --system
```

## 2. Tạo User và Group cho hạ tầng Grid
Mặc định gói preinstall chỉ tạo user `oracle`. Chúng ta cần tạo thêm user `grid` và gán vào các nhóm ASM chuyên dụng.

```bash
# 1. Tạo các nhóm quản trị (Thực hiện trên CẢ 2 NODES)
groupadd -g 54321 oinstall
groupadd -g 54322 dba
groupadd -g 54323 oper
groupadd -g 54324 backupdba
groupadd -g 54325 dgdba
groupadd -g 54326 kmdba
groupadd -g 54327 racdba
groupadd -g 54315 asmadmin
groupadd -g 54316 asmdba
groupadd -g 54317 asmoper

# 2. Tạo user (Nếu Case Offline chưa có user oracle)
useradd -u 54321 -g oinstall -G dba,oper,backupdba,dgdba,kmdba,racdba,asmdba,asmadmin oracle 2>/dev/null
useradd -u 54322 -g oinstall -G asmadmin,asmdba,asmoper,dba grid 2>/dev/null

# 3. Đảm bảo oracle cũng thuộc nhóm ASM
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
# Tạo file limit (Áp dụng cho cả oracle và grid)
cat > /etc/security/limits.d/99-oracle-limits.conf <<EOF
oracle   soft   nofile    1024
oracle   hard   nofile    65536
oracle   soft   nproc    16384
oracle   hard   nproc    16384
oracle   soft   stack    10240
oracle   hard   stack    32768

grid     soft   nofile    1024
grid     hard   nofile    65536
grid     soft   nproc     2047
grid     hard   nproc     16384
grid     soft   stack     10240
grid     hard   stack     32768
grid     hard   memlock   134217728
grid     soft   memlock   134217728
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
