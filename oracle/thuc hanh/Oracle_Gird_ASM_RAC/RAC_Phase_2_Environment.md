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
# Lệnh cơ bản (nếu máy đã tắt hẳn các repo online)
yum install -y binutils compat-libcap1 gcc gcc-c++ glibc glibc-devel ksh libaio libaio-devel libstdc++ libstdc++-devel make sysstat

# Lệnh "chắc chắn" (ép buộc chỉ dùng LocalRepo, tránh lỗi nếu máy vẫn còn cắm NAT)
yum install -y --disablerepo="*" --enablerepo="LocalRepo" binutils compat-libcap1 gcc gcc-c++ glibc glibc-devel ksh libaio libaio-devel libstdc++ libstdc++-devel make sysstat
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
Tùy vào việc bạn đã chạy gói `preinstall` (Online) hay chưa, các bước tạo User sẽ khác nhau.

### 2.1 Tạo Nhóm (Groups) - [Cả 2 TH]
Chạy trên **CẢ 2 NODES** bằng quyền `root`:
```bash
# Nhóm quản trị ASM (Bắt buộc cho cả Online/Offline)
groupadd -g 54315 asmadmin
groupadd -g 54316 asmdba
groupadd -g 54317 asmoper

# Nhóm CSDL (Chỉ cần chạy nếu bạn làm Offline - Online đã có sẵn)
groupadd -g 54321 oinstall 2>/dev/null
groupadd -g 54322 dba 2>/dev/null
groupadd -g 54323 oper 2>/dev/null
groupadd -g 54324 backupdba 2>/dev/null
groupadd -g 54325 dgdba 2>/dev/null
groupadd -g 54326 kmdba 2>/dev/null
groupadd -g 54327 racdba 2>/dev/null
```

### 2.2 Tạo Người dùng (Users) - [Cả 2 TH]
```bash
# 1. Tạo user grid (Luôn phải tạo thủ công)
useradd -u 54322 -g oinstall -G asmadmin,asmdba,asmoper,dba grid

# 2. Tạo/Cập nhật user oracle
# [Offline]: Tạo mới hoàn toàn
useradd -u 54321 -g oinstall -G dba,oper,backupdba,dgdba,kmdba,racdba,asmdba,asmadmin oracle 2>/dev/null
# [Online]: Gói preinstall đã tạo sẵn oracle, ta chỉ cần thêm vào nhóm ASM
usermod -a -G asmdba,asmadmin oracle

# 3. Đặt mật khẩu (Bắt buộc trên cả 2 node để SSH không lỗi)
# Khuyên dùng: oracle123
passwd grid
passwd oracle
```

## 3. Khởi tạo cấu trúc thư mục OFA (Optimal Flexible Architecture)
Chúng ta quy hoạch tập trung vào thư mục `/u01`:
```bash
# Tạo các thư mục Home cho Grid và Database
mkdir -p /u01/app/19.3.0/grid               # GRID_HOME (Nơi giải nén bộ cài Grid)
mkdir -p /u01/app/oracle/product/19.3.0/dbhome_1 # DB_HOME (Nơi giải nén bộ cài DB)
mkdir -p /u01/app/grid                      # GRID_BASE
mkdir -p /u01/app/oracle                    # ORACLE_BASE

# Phân quyền chuẩn xác (Cực kỳ quan trọng)
chown -R grid:oinstall /u01
chown -R grid:oinstall /u01/app/19.3.0/grid
chown -R grid:oinstall /u01/app/grid
chown -R oracle:oinstall /u01/app/oracle
chown -R oracle:oinstall /u01/app/oracle/product/19.3.0/dbhome_1
chmod -R 775 /u01
```

## 4. Cấu hình SSH Passwordless (Tối quan trọng)
Bộ cài Oracle RAC cần các node có thể "nói chuyện" với nhau mà không hỏi mật khẩu. Chúng ta cấu hình cho **cả 2 user** `grid` và `oracle`.

> [!IMPORTANT]
> **Điều kiện tiên quyết:** Bạn BẮT BUỘC phải thực hiện lệnh `passwd grid` và `passwd oracle` trên **CẢ 2 NODES** trước khi làm bước này. Nếu không, lệnh `ssh-copy-id` sẽ bị lỗi `Permission denied`.

> [!WARNING]
> Mẹo tránh lỗi:
> - **Chìa khóa (`ssh-keygen`)**: Nhấn <Enter> liên tục 3 lần, không nhập passphrase.
> - **Lỗi `Host key verification failed`**: Phải gõ đủ chữ `yes` khi được hỏi lần đầu.

### 4.1 Cấu hình cho User `grid`
- **Trên Node 1:**
```bash
su - grid
ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
# Hoặc lệnh đơn giản (phải nhấn Enter 3 lần): ssh-keygen -t rsa
ssh-copy-id oracle1
ssh-copy-id oracle2
```
- **Trên Node 2:**
```bash
su - grid
ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
# Hoặc lệnh đơn giản (phải nhấn Enter 3 lần): ssh-keygen -t rsa
ssh-copy-id oracle1
ssh-copy-id oracle2
```

### 4.2 Cấu hình cho User `oracle`
- **Trên Node 1:**
```bash
su - oracle
# Lệnh "chắc chắn" (không hỏi lại):
ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
# Hoặc lệnh đơn giản (phải nhấn Enter 3 lần): ssh-keygen -t rsa
ssh-copy-id oracle1
ssh-copy-id oracle2
```
- **Trên Node 2:**
```bash
su - oracle
# Lệnh "chắc chắn" (không hỏi lại):
ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
# Hoặc lệnh đơn giản (phải nhấn Enter 3 lần): ssh-keygen -t rsa
ssh-copy-id oracle1
ssh-copy-id oracle2
```

**Kiểm tra:** Trên mỗi node, dùng cả 2 user để chạy thử lệnh `ssh <tên_node> date`. Nếu không hỏi mật khẩu là thành công.

## 5. Cấu hình các tham số hệ thống bổ sung (Limits)
Chạy trên **CẢ 2 NODES** bằng quyền `root`. 

### Trường hợp A: Online (Có gói Preinstall)
Gói preinstall đã cấu hình cho user `oracle`, bạn chỉ cần chèn thêm cho `grid`:
```bash
cat <<EOF >> /etc/security/limits.d/oracle-database-preinstall-19c.conf

# Bổ sung giới hạn cho user grid
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

### Trường hợp B: Offline (Cài thủ công)
Bắt buộc tạo mới file cấu hình cho cả 2 user:
```bash
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

**Kiểm tra:** `tail -n 15 /etc/security/limits.d/*.conf`

## 6. Thiết lập biến môi trường (.bash_profile)
Mỗi Node có `ORACLE_SID` riêng, hãy cấu hình cẩn thận bằng cách dán đoạn code sau vào cuối file `~/.bash_profile`.

**Tại Node 1 (oracle1):**
- **User `grid`**:
```bash
export ORACLE_SID=+ASM1
export ORACLE_BASE=/u01/app/grid
export ORACLE_HOME=/u01/app/19.3.0/grid
export PATH=$ORACLE_HOME/bin:$PATH
```
- **User `oracle`**:
```bash
export ORACLE_SID=orcl1
export ORACLE_UNQNAME=orcl
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/19.3.0/dbhome_1
export PATH=$ORACLE_HOME/bin:$PATH
```

**Tại Node 2 (oracle2):**
- **User `grid`**:
```bash
export ORACLE_SID=+ASM2
export ORACLE_BASE=/u01/app/grid
export ORACLE_HOME=/u01/app/19.3.0/grid
export PATH=$ORACLE_HOME/bin:$PATH
```
- **User `oracle`**:
```bash
export ORACLE_SID=orcl2
export ORACLE_UNQNAME=orcl
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/19.0.0/dbhome_1
export PATH=$ORACLE_HOME/bin:$PATH
```

## 7. Đồng bộ thời gian với Chrony
```bash
timedatectl set-timezone Asia/Ho_Chi_Minh
yum install -y chrony
systemctl enable --now chronyd
chronyc -a makestep
# Kiểm tra: Để ý danh sách có dấu ^* là đang đồng bộ tốt.
chronyc sources -v
```

## 8. Cấu hình UDEV Rules cho ASM Shared Disks

Trong Oracle RAC, các Node cần truy cập vào cùng một ổ đĩa vật lý. Để Grid Infrastructure nhận diện chính xác và ổn định các ổ đĩa này, chúng ta cần gán cho chúng các tên gợi nhớ (Alias) cố định và phân quyền sở hữu cho user `grid`.

### 8.1 Tìm UUID của các ổ Shared Disks
Thực hiện trên **Node 1** bằng quyền `root`.

```bash
# Liệt kê các ổ đĩa để xác định tên thiết bị (sdb, sdc, sdd...)
lsblk

# Chạy lệnh lấy UUID cho từng ổ (Ví dụ sdb là OCR)
/usr/lib/udev/scsi_id -g -u -d /dev/sdb
# Kết quả VD: 36000c29d009baba53549298586ea9a71

/usr/lib/udev/scsi_id -g -u -d /dev/sdc
# Kết quả VD: 36000c29f8f2b1d9c6c0e8a7d7f7e8a91

/usr/lib/udev/scsi_id -g -u -d /dev/sdd
# Kết quả VD: 36000c29a1b2c3d4e5f6a7b8c9d0e1f23
```

> [!TIP]
> Hãy ghi lại các UUID này tương ứng với mục đích (OCR, DATA, FRA) để viết Rule ở bước sau.

### 8.2 Tạo file UDEV Rules
Tạo file mới trên **CẢ 2 NODES** bằng quyền `root`:
```bash
vi /etc/udev/rules.d/99-oracle-asmdevices.rules
```

Dán nội dung sau vào (Hãy thay các chuỗi `RESULT=="..."` bằng UUID thực tế của bạn):
```properties
# ASM_OCR disk
KERNEL=="sd*", SUBSYSTEM=="block", PROGRAM=="/usr/lib/udev/scsi_id -g -u -d /dev/$name", RESULT=="36000c29d009baba53549298586ea9a71", SYMLINK+="oracleasm/asm_ocr1", OWNER="grid", GROUP="asmadmin", MODE="0660"

# ASM_DATA disk
KERNEL=="sd*", SUBSYSTEM=="block", PROGRAM=="/usr/lib/udev/scsi_id -g -u -d /dev/$name", RESULT=="36000c29f8f2b1d9c6c0e8a7d7f7e8a91", SYMLINK+="oracleasm/asm_data1", OWNER="grid", GROUP="asmadmin", MODE="0660"

# ASM_FRA disk
KERNEL=="sd*", SUBSYSTEM=="block", PROGRAM=="/usr/lib/udev/scsi_id -g -u -d /dev/$name", RESULT=="36000c29a1b2c3d4e5f6a7b8c9d0e1f23", SYMLINK+="oracleasm/asm_fra1", OWNER="grid", GROUP="asmadmin", MODE="0660"
```

### 8.3 Áp dụng Rule (Reload UDEV)
Chạy các lệnh sau trên **CẢ 2 NODES** bằng quyền `root`:
```bash
/sbin/udevadm control --reload-rules
/sbin/udevadm trigger --type=devices --action=change
```

### 8.4 Kiểm tra kết quả
Nếu thành công, bạn sẽ thấy các đường dẫn ảo (Symlinks) xuất hiện với đúng quyền hạn:
```bash
ls -alt /dev/oracleasm/*
```

Kết quả mong đợi:
```text
lrwxrwxrwx 1 root root 6 Apr 15 10:36 /dev/oracleasm/asm_ocr1 -> ../sdb
lrwxrwxrwx 1 root root 6 Apr 15 10:36 /dev/oracleasm/asm_data1 -> ../sdc
lrwxrwxrwx 1 root root 6 Apr 15 10:36 /dev/oracleasm/asm_fra1 -> ../sdd
```

Và kiểm tra quyền của thiết bị gốc:
```bash
ls -l /dev/sdb /dev/sdc /dev/sdd
```
Kết quả phải hiển thị owner là `grid` và group là `asmadmin`


> [!CAUTION]
> Khi cài đặt Grid Infrastructure (ở bước sau), tại màn hình chọn Disk, bạn phải thay đổi **Disk Discovery Path** thành `/dev/oracleasm/*` thì bộ cài mới nhìn thấy các ổ đĩa này.

---

## 9. Tại sao phải cấu hình UDEV Rules?

Sẽ có lúc bạn thắc mắc: *"Tại sao phải hì hục dò UUID rồi tạo file rule ảo như vậy? Chọn thẳng /dev/sdb lúc cài Grid là xong mà?"*. UDEV sinh ra để giải quyết 2 vấn đề lớn của Linux trong môi trường Enterprise:

1. **Chống lỗi "nhảy múa" Tên ổ đĩa (Device Naming Rotation):** Trên Linux, tên thiết bị `/dev/sdb`, `/dev/sdc` không hề cố định. Khi máy được Reboot hoặc cắm thêm USB/Card mạng, thứ tự nhận cổng SCSI có thể thay đổi và ổ `/dev/sdb` (đang lưu DATA) có thể bị đổi tên thành `/dev/sde`. Nếu bộ cài Grid trỏ vào tên thiết bị này, hệ thống sẽ lập tức bị sập. UDEV quét số UUID phần cứng duy nhất để định danh cố định. Dù thiết bị có đổi tên gốc thành `sdz`, cái cổng ảo `/dev/oracleasm/asm_data1` vẫn luôn ghim đúng vào cái ruột UUID đó.
2. **Chống cưỡng chế Khởi tạo Quyền (Permissions Persistence):** Ổ đĩa ASM bắt buộc phải thuộc quyền user **`grid`**. Nếu bạn gõ lệnh `chown` bằng tay, Linux sẽ tự động tước lại mọi quyền hạn và trả chủ sở hữu về tay **`root`** ngay khi máy khởi động lại. Bằng việc khai báo OWNER/GROUP trong UDEV Rules, bạn đã cài mã vào sâu trong nhân hệ thống, cưỡng ép Linux nạp đúng quyền sở hữu ngay từ giây phút máy tính vừa khởi động.
