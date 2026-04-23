# Tài Liệu Toàn Tập: Hướng Dẫn Cài Đặt Oracle Database 19c Single Instance

Tài liệu này được tổng hợp và chú thích chi tiết nhằm mang lại cái nhìn toàn diện nhất cho việc triển khai hệ thống Oracle Database 19c (Single Node) trên nền tảng Oracle Linux. Từ khâu chuẩn bị phần cứng, tiến trình cài đặt OS, cấu hình Database cho tới việc xử lý sự cố.

---

## 1. TỔNG QUAN HỆ THỐNG VÀ CHUẨN BỊ TÀI NGUYÊN (PRE-REQUISITES)

Việc chuẩn bị nền móng tài nguyên tốt giúp Database hoạt động mượt mà và tuân thủ chuẩn **OFA (Optimal Flexible Architecture)** của Oracle.

### a. Tài nguyên Máy Ảo (VMware / Server)
- **CPU:** Tối thiểu 2 Cores, khuyến nghị **4 Cores** (Giúp compile kiến trúc lúc cài đặt nhanh hơn rất nhiều).
- **RAM:** Tối thiểu 4GB, khuyến nghị vùng **8GB - 16GB** (Đủ để cấp phát cho các bộ đệm chung tập trung cho SGA/PGA của database).
- **Network:** Chế độ NAT hoặc Bridged với **IP tĩnh (Static IP)** và có Hostname cụ thể (ví dụ: `oracle19.localdomain`). Điều này tránh lỗi listener của Oracle bị đổi địa chỉ ở các thiết lập khởi động.

### b. Chiến Lược Chia Ổ Cứng (Disk Partitioning)
Thay vì dùng 1 ổ cứng lớn gộp chung, nên chia nhiều ổ cứng vật lý ảo riêng rẽ để đảm bảo tối ưu tốc độ đọc ghi I/O và dễ sửa chữa, dễ backup:
- **Disk 1 (SDA) - khoảng 50GB:** Dành riêng cho Core Hệ điều hành Kernel Linux (`/`).
- **Disk 2 (SDB) - khoảng 40GB:** Chứa bộ mã nguồn cài đặt và phần mềm gốc Oracle (`/u01`).
- **Disk 3 (SDC) - khoảng 50GB+:** Nơi lưu tập trung Datafiles, Control files (`/u02`).
- **Disk 4 (SDD - Tuỳ chọn):** Phân vùng độc lập lưu Fast Recovery Area, Archive Logs sao lưu (`/u03`).

---

## 2. CÀI ĐẶT HỆ ĐIỀU HÀNH & CẤU HÌNH LVM

### a. Cài đặt HĐH (OS Installation)
- Lựa chọn bản **Server with GUI** và tick chọn **Development Tools** & **Compatibility Libraries** để có đủ các thư viện dev hỗ trợ tiến trình.
- Bỏ tick kdump để tránh việc lãng phí bộ đệm của RAM cho môi trường ảo hoá VM.
- Về phân vùng OS (`sda`): 
  - `/boot`: 1GB (Định dạng Standard partition - không thiết lập vào LVM).
  - `swap`: Nếu RAM < 2GB (bằng 1.5 lần RAM), Nếu RAM 2-16GB (bằng bằng dung lượng RAM), Nếu RAM > 16GB (cố định 16GB limit).
  - `/` (Root): Phần còn dung lượng trống của sda.

### b. Cấu hình LVM cho các ổ lưu trữ dữ liệu (`/u01` và `/u02`)
Sử dụng công nghệ LVM (Logical Volume Manager) để nhóm gộp các tài nguyên ổ cứng vật lý rời rạc - Giúp linh hoạt thay đổi mở rộng khối dung lượng bằng cơ chế Hot-Add mà không yêu cầu cần tắt máy Server. Tùy thuộc vào thói quen, bạn có thể thực hiện theo 1 trong 2 trường hợp sau:

> **Quyền thực thi:** Mọi lệnh cấu hình chia đĩa phải được chạy ở màn hình Terminal với phiên quyền **`root`** cao nhất.

#### 🟢 TRƯỜNG HỢP 1: TẠO LVM BẰNG GIAO DIỆN (Lúc đang cài OS)
Nếu bạn đã lắp ngay 3 ổ cứng ảo (sda, sdb, sdc) từ đầu trên VMware, tại màn hình **INSTALLATION DESTINATION** lúc cài đặt OS:
1. Tick chọn cả 3 ổ đĩa và ấn `I will configure partitioning` -> Done.
2. Đảm bảo kiểu phân vùng là `LVM`. (Cấu hình /boot và swap bình thường trên sda)
3. Cấu hình phân vùng `/u01` (ổ `sdb`): Tạo `+` Mount point `/u01`. Chọn *Modify* -> Create a new volume group tên `vg_u01`, gán 100% dung lượng ổ sdb, định dạng XFS.
4. Cấu hình phân vùng `/u02` (ổ `sdc`): Tạo `+` Mount point `/u02`. Chọn *Modify* -> Create a new volume group tên `vg_u02`, gán 100% dung lượng ổ sdc, định dạng XFS.
5. Lợi ích: Khi Setup OS xong hệ thống đã tự động định danh và cấu hình luôn `fstab` tự động cho bạn.

#### 🟠 TRƯỜNG HỢP 2: TẠO LVM BẰNG DÒNG LỆNH (Sau khi cài xong OS)
Dành cho tình huống ban đầu bạn chỉ cài OS lên 1 ổ `sda` duy nhất 50GB. Sau khi bật máy lên ổn định mới thêm 2 ổ SDB và SDC (Add Hard Disk trong cấu hình VMware ảo). Mở Terminal bằng tài khoản `root`:

1. **Định danh thiết bị cứng (Khởi tạo PV - Physical Volume):**
   ```bash
   pvcreate /dev/sdb
   pvcreate /dev/sdc
   ```
2. **Gom Nhóm Lưu Trữ Độc Lập (Tạo VG - Volume Group):**
   ```bash
   vgcreate vg_u01 /dev/sdb
   vgcreate vg_u02 /dev/sdc
   ```
3. **Kéo Cấp Phát Phân Vùng Ảo để nhận diện (Lvcreate):**
   ```bash
   # Cấp phát tận 100% tài nguyên rỗng ra làm khối phân vùng LV
   lvcreate -n lv_u01 -l 100%FREE vg_u01
   lvcreate -n lv_u02 -l 100%FREE vg_u02
   ```
4. **Định dạng theo chuẩn XFS (Chuẩn mặc định nhanh nhất cho lưu trữ DB):**
   ```bash
   mkfs.xfs /dev/vg_u01/lv_u01
   mkfs.xfs /dev/vg_u02/lv_u02
   ```
5. **Tạo Mount Point và Gắn Ổ Cứng (Bắt buộc cho Case 2):**
   Trong Linux, ổ đĩa phải được "gắn" (mount) vào một thư mục rỗng để sử dụng.
   ```bash
   # 5a. Tạo 2 thư mục làm điểm rơi cấu trúc (Mount Points)
   mkdir -p /u01 /u02     

   # 5b. Gắn tạm thời để sử dụng ngay
   mount /dev/vg_u01/lv_u01 /u01
   mount /dev/vg_u02/lv_u02 /u02

   # 5c. Cấu hình tự động kết nối khi khởi động (Auto-mount qua /etc/fstab)
   # Chèn cấu hình vào cuối file fstab
   echo "/dev/mapper/vg_u01-lv_u01   /u01    xfs    defaults    0 0" >> /etc/fstab
   echo "/dev/mapper/vg_u02-lv_u02   /u02    xfs    defaults    0 0" >> /etc/fstab
   
   # 5d. Lệnh "test cửa tử": Quét nghiệm thu cú pháp fstab tránh treo máy
   mount -a 
   ```

#### 🛠️ MẸO: CÁCH XÓA LVM KHI TẠO NHẦM (CẤP CỨU)
Nếu bạn lỡ đặt sai tên LV, VG hoặc muốn làm lại từ đầu, hãy chạy các lệnh sau theo đúng trình tự ngược:
1. **Unmount (Nếu đã lỡ mount):** `umount /u01`
2. **Xóa Logical Volume:** `lvremove /dev/vg_u01/lv_u01`
3. **Xóa Volume Group:** `vgremove vg_u01`
4. **Xóa Physical Volume:** `pvremove /dev/sdb`
*(Nhấn `y` để xác nhận xóa khi hệ thống hỏi)*.

---

## 3. CẤU HÌNH MÔI TRƯỜNG CÀI ĐẶT (PRE-INSTALLATION)

Bước này đảm bảo cấu trúc OS đã nạp sẵn hạt giống user và thư mục đủ tiêu chuẩn cho Database Engine.

### 0. Chuẩn bị Hệ thống: Firewall, SELinux và /etc/hosts (Thao tác bằng `root`)
Để tránh các sự cố về mạng, phân quyền và kết nối Listener sau này, ta cần làm sạch môi trường mạng cục bộ:

**1. Tắt Firewall và SELinux:**
```bash
# Tắt và dừng Firewall
systemctl stop firewalld
systemctl disable firewalld

# Đưa SELinux về chế độ Disabled (Yêu cầu khởi động lại máy để áp dụng vĩnh viễn)
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
```

**2. Khai báo phân giải tên miền cục bộ (/etc/hosts):**
Đây là bước cực kỳ quan trọng giúp Oracle Listener nhận định chính xác máy chủ đang đứng. Nếu bỏ qua, lúc cài đặt DBCA hoặc cấu hình mạng Listener rất dễ bị báo lỗi không thể phân giải.

Tiến hành thêm IP tĩnh và Hostname của máy vào cuối file `/etc/hosts`:
```bash
# Mở file bằng vi (hoặc bất kỳ trình soạn thảo nào)
vi /etc/hosts

# HOẶC dùng lệnh chèn nhanh sau (Thay 192.168.1.100 bằng IP thật của máy ảo):
echo "192.168.1.100   oracle19.localdomain   oracle19" >> /etc/hosts
```

### a. Sử dụng gói Tự động của Oracle Pre-install (Thao tác bằng `root`)
Khuyên dùng sử dụng script có sẵn `oracle-database-preinstall-19c` để trình cài tự cấu hình nhân Kernels.
```bash
dnf install -y oracle-database-preinstall-19c
```
*(Lưu ý siêu cấp: Gói RPM này sẽ lo toàn bộ thủ tục cấp user `oracle` và tạo ra vô vàn các nhóm `dba`, `dbla` tương ứng. Nếu trước đó bạn đã lanh chanh đi gõ lệnh `useradd oracle` trước, thì nó sẽ chặn tạo Group và khiến sau này Setup đồ họa báo thiếu Group DBA)*.

Sau khi chạy tiến trình tải, tiến hành reset một cái pass đàng hoàng cho user hệ thống `oracle`:
```bash
passwd oracle
```

### c. Xử lý khi không có Internet (Cấu hình Offline/Thủ công)
Nếu máy chủ không có mạng, bạn phải tự "tay không bắt giặc" theo 2 bước sau:

#### 1. Biến File ISO cài đặt thành kho ứng dụng (Local Repository)
Gắn đĩa ISO vào máy ảo (Settings VMware -> CD/DVD -> Connected).
```bash
# Gắn đĩa vào thư mục mnt
mount /dev/cdrom /mnt
cat > /etc/yum.repos.d/local.repo <<EOF
[LocalRepo]
name=Oracle Linux ISO AppStream
baseurl=file:///mnt/AppStream
enabled=1
gpgcheck=0

[LocalRepoBase]
name=Oracle Linux ISO Base
baseurl=file:///mnt/BaseOS
enabled=1
gpgcheck=0
EOF

# LƯU Ý: Nếu bạn dùng Oracle Linux 7 (như 7.9), hãy dùng nội bộ sau:
# cat > /etc/yum.repos.d/local.repo <<EOF
# [LocalRepo]
# name=Oracle Linux ISO
# baseurl=file:///mnt
# enabled=1
# gpgcheck=0
# EOF

# Cập nhật và cài các gói cần thiết (thay thế cho pre-install rpm)
# Cách 1: Lệnh cơ bản
dnf install -y binutils compat-libcap1 gcc gcc-c++ glibc glibc-devel ksh libaio libaio-devel libstdc++ libstdc++-devel make sysstat

# Cách 2: Lệnh "chắc chắn" (ép buộc chỉ cài từ Local Repository đã tạo ở trên)
dnf install -y --disablerepo="*" --enablerepo="LocalRepo*" binutils compat-libcap1 gcc gcc-c++ glibc glibc-devel ksh libaio libaio-devel libstdc++ libstdc++-devel make sysstat
```

#### 2. Cấu hình User và Tham số nhân thủ công
Nếu không chạy được gói `preinstall`, bạn phải gõ các lệnh sau dưới quyền `root`:
```bash
# Tạo các nhóm quyền
groupadd -g 54321 oinstall
groupadd -g 54322 dba
groupadd -g 54323 oper
groupadd -g 54324 backupdba
groupadd -g 54325 dgdba
groupadd -g 54326 kmdba
groupadd -g 54327 racdba

# Tạo user oracle
useradd -u 54321 -g oinstall -G dba,oper,backupdba,dgdba,kmdba,racdba oracle
passwd oracle

# Cấu hình tham số Kernel (/etc/sysctl.d/99-oracle.conf)
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

# Cấu hình giới hạn tài nguyên (/etc/security/limits.d/99-oracle.conf)
cat > /etc/security/limits.d/99-oracle.conf <<EOF
oracle   soft   nofile    1024
oracle   hard   nofile    65536
oracle   soft   nproc    16384
oracle   hard   nproc    16384
oracle   soft   stack    10240
oracle   hard   stack    32768
EOF
```

### b. Ráp cấu trúc Thư Mục Cơ Sở (Thao tác bằng `root`)
Khởi tạo cấu trúc của nhà ở Database:
```bash
# Tạo điểm trỏ gốc cho ORACLE_BASE và ORACLE_HOME (ngôi thai kiến trúc Oracle 19c)
mkdir -p /u01/app/oracle/product/19.0.0/dbhome_1
mkdir -p /u02/oradata

# Thay quyền Admin làm chủ cho user 'oracle' đứng quản lý tối cao ở thư mục vừa tạo
chown -R oracle:oinstall /u01
chown -R oracle:oinstall /u02     
chmod -R 775 /u01
chmod -R 775 /u02                 
```

### c. Thiết Lập Biến Môi Trường Bash (Thao tác bằng `oracle`)
Tiến hành đổi phiên vào nhân tài khoản của `oracle` (Dùng cờ minus `su - oracle`) thiết lập file `.bash_profile` để nạp các khai báo đường dẫn cần thiết cho máy tính đọc tự động. Dán mảng biến sau:
```bash
export TMP=/tmp
export TMPDIR=$TMP
export ORACLE_HOSTNAME=oracle19.localdomain   # Thay đúng bằng Hostname thật đang chạy để tránh báo lỗi mạng
export ORACLE_UNQNAME=oracle19                  
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/19.0.0/dbhome_1
export ORACLE_SID=oracle19                      
export PATH=$ORACLE_HOME/bin:$PATH
```
Chạy update ngay bằng từ khóa: `source ~/.bash_profile`.

### d. Bung Mở File ZIP Bộ Cài Đặt (Thao tác bằng `oracle` - QUAN TRỌNG)
> [!WARNING]
> Tuyệt đối không được xả nén file zip Oracle bằng User Root !! Nếu vi phạm, File cài sẽ bị gắn sai quyền owner "Root-Only". Bạn phải đứng bằng user Oracle thực thi việc giải nén (unzip) ngay tâm của khu vực ORACLE_HOME.

```bash
cd $ORACLE_HOME
unzip -oq /tmp/LINUX.X64_193000_db_home.zip
```
*(Lưu ý cho việc sử dụng `-oq`: O có tác dụng thay Write Overwrite, Q có tác dụng ẩn chạy tàng hình che giấu các đoạn Log trích xuất để Terminal SSH không bị chậm nổ bộ xử lý màn hình máy ảo).*

---

## 4. TIẾN TRÌNH CÀI ĐẶT DB BẰNG OUI (GIAO DIỆN)

Gọi Universal Installer để khởi chạy bộ GUI OUI ra xử lý quá trình ném dữ liệu Core.

1. Bật Terminal đứng dưới tên user **`oracle`** ở Desktop Máy Ảo hoặc sử dụng Terminal của phần mềm kết nối có tích hợp cửa sổ **MobaXterm**.
   ```bash
   cd $ORACLE_HOME
   ./runInstaller
   ```
2. **CHI TIẾT 18 BƯỚC CÀI ĐẶT & PHÂN TÍCH LỰA CHỌN:**

*   **Bước 1 (Configuration Option):** 
    - *Lựa chọn:* `Create and configure a single instance database`.
    - *Tại sao:* Nó sẽ cài cả phần mềm và tạo luôn 1 Database mẫu cho bạn dùng ngay.
    - *Nếu không chọn (Software only):* Bạn chỉ có phần mềm rỗng, sau này phải tự chạy lệnh `dbca` để tạo Database sau. Chỉ dùng khi bạn muốn cấu hình cực kỳ chuyên sâu.

*   **Bước 2 (System Class):** 
    - *Lựa chọn:* `Server class`.
    - *Tại sao:* Tối ưu cho môi trường máy chủ, cho phép cấu hình nâng cao về RAM và Storage.
    - *Nếu chọn Desktop class:* Phù hợp với máy tính cá nhân RAM yếu, nó sẽ ẩn đi nhiều cấu hình quan trọng.

*   **Bước 3 (Database Edition):** 
    - *Lựa chọn:* `Enterprise Edition`.
    - *Tại sao:* Có đầy đủ "đồ chơi" nhất (RAC, Partitioning...). Lab thì nên dùng bản này để học.

*   **Bước 4 (Installation Location):**
    - *Lưu ý:* Thư mục Oracle Base nên là `/u01/app/oracle`. Tránh để trong Home của user cá nhân để không bị lỗi phân quyền.

*   **Bước 5 (Create Inventory):**
    - *Inventory Directory:* Để mặc định là `/u01/app/oraInventory` (Nơi Oracle lưu metadata của bộ cài).
    - *oraInventory Group Name:* Chọn `oinstall`.

*   **Bước 6 (Configuration Type):**
    - *Lựa chọn:* Nhấn chọn `General Purpose / Transaction Processing`.
    - *Tại sao:* Tối ưu cho cơ sở dữ liệu xử lý giao dịch thông thường và học tập. Tùy chọn còn lại chỉ dành cho Data Warehouse (Kho dữ liệu phân tích lớn).

*   **Bước 7 (Database Identifiers):**
    - `Global DB Name`: Tên của DB trong mạng (ví dụ: `oracle19.localdomain`).
    - `SID`: Tên instance (thay vì mặc định `orcl`, ta đổi thành `oracle19` cho đồng bộ).
    - **Tùy chọn Container database:** 
        - *Nếu tích (CDB):* Bạn đang theo chuẩn hiện đại của Oracle (Multitenant). Ghi nhận tạo Pluggable database name là `orclpdb`.
        - *Nếu không tích:* Bạn dùng kiểu cũ (Non-CDB). Đơn giản, dễ quản lý cho người mới bắt đầu.

*   **Bước 8 (Configuration Options):** 
    - **Memory:** Nên tích `Enable Automatic Memory Management` để Oracle tự chia RAM thông minh cho bạn.
    - **Character sets:** 
        - *Lựa chọn:* `AL32UTF8`.
        - *Tại sao:* Lưu được mọi ngôn ngữ (Tiếng Việt).
        - *Nếu chọn sai:* Sau này sẽ bị lỗi font (????) khi lưu dữ liệu tiếng Việt và cực kỳ khó sửa.
    - **Sample schemas:** Nên tích chọn nếu bạn muốn có dữ liệu mẫu để tập viết SQL.

*   **Bước 9 (Database Storage):** 
    - *Lựa chọn:* `File system`, trỏ vào `/u02/oradata`.
    - *Tại sao:* Chúng ta đã chuẩn bị phân vùng `/u02` lớn để chứa dữ liệu. Tránh để ở `/u01` vì bộ cài đã chiếm gần hết rồi.
*   **Bước 10 (Management Options):** 
    - *Lựa chọn:* Bỏ qua.
    - *Tại sao:* Đây là kết nối với Oracle Enterprise Manager Cloud Control (một hệ thống quản lý tập trung lớn). Với môi trường Lab Single Node, chúng ta không cần đến nó.

*   **Bước 11 (Recovery Options):** 
    - *Lựa chọn:* `Enable Recovery` và trỏ vào `/u02/fast_recovery_area`.
    - *Tại sao:* Giúp Oracle tự động quản lý các file backup và logs phục hồi. Đây là tính năng cực kỳ quan trọng để bảo vệ dữ liệu.
    - *Nếu không chọn:* Bạn sẽ phải tự cấu hình sao lưu bằng tay sau này.

*   **Bước 12 (Schema Passwords):** 
    - *Lựa chọn:* `Use the same password for all accounts`.
    - *Tại sao:* Tiết kiệm thời gian cho môi trường Lab. Trong môi trường thật, bạn nên đặt mật khẩu riêng cho `SYS` và `SYSTEM` để tăng tính bảo mật.

*   **Bước 13 (Operating System Groups):** 
    - *Lựa chọn:* Để tất cả là `dba`.
    - *Tại sao:* Đảm bảo user `oracle` có toàn quyền quản trị cao nhất. Trong môi trường doanh nghiệp lớn, người ta sẽ chia nhỏ ra (`backupdba`, `dgdba`...) cho từng bộ phận.

*   **Bước 14 (Root script execution):** 
    - *Lựa chọn:* Tích vào `Automatically run...` và điền pass root.
    - *Tại sao:* Trình cài đặt sẽ tự chạy các script quan trọng cuối cùng mà không cần bạn phải mở Terminal phụ. Cực kỳ tiện lợi.

*   **Bước 15 (Prerequisite Checks):** 
    - *Lưu ý:* Nếu hiện `Warning` (thường là Swap hoặc Kernel parameters), bạn có thể tích **Ignore All** để đi tiếp. Nhưng nếu hiện `Failed`, bắt buộc phải sửa trước khi cài.

*   **Bước 16 (Summary):** 
    - *Lưu ý:* Kiểm tra lại toàn bộ thông tin lần cuối trước khi "bấm nút".
    - **Chức năng Save Response File:** 
        - *Tác dụng:* Lưu lại toàn bộ các lựa chọn của bạn vào một file `.rsp`. 
        - *Tại sao:* Dùng cho việc cài đặt tự động (Silent Install) trên các máy khác mà không cần GUI. 
        - *Lợi ích:* Bạn có thể mở file này ra để "soi" xem Oracle lưu cấu hình ngầm như thế nào.

*   **Bước 17 (Install Product):** 
    - *Lưu ý:* Đây là lúc Oracle copy file. Nếu ở Bước 14 bạn không chọn chạy tự động, thì lúc này nó sẽ hiện bảng yêu cầu bạn chạy script root thủ công.
*   **Bước 18 (Finish):** Nhấn OK và Finish.

3. **NGHIỆM THU:**
   ```bash
   sqlplus / as sysdba
   SQL> select status from v$instance;  -- Trạng thái 'OPEN' là thành công.
   ```

---

## 5. CẤU HÌNH TỰ ĐỘNG BẬT DATABASE KHI THEO OS (AUTO-START)

Để Oracle Database tự động phục hồi và bật lên cùng Server khi mất điện hoặc reboot máy ảo, bạn triển khai một script cấu hình tự động sửa lỗi cực mạnh sau (Triển khai dưới quyền **`root`**):

```bash
# 1. Quét tìm chính xác tên Database của bạn đã cài 
MY_SID=$(ls /u01/app/oracle/diag/rdbms/ | head -n 1)

# 2. Tạo Script khai báo biến môi trường chuẩn xác (setEnv.sh)
mkdir -p /home/oracle/scripts
cat > /home/oracle/scripts/setEnv.sh <<EOF
export TMP=/tmp
export TMPDIR=$TMP
export ORACLE_HOSTNAME=$(hostname)
export ORACLE_UNQNAME=$MY_SID
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/19.0.0/dbhome_1
export ORACLE_SID=$MY_SID
export ORACLE_HOME_LISTNER=$ORACLE_HOME
export PATH=/usr/sbin:/usr/local/bin:\$PATH
export PATH=\$ORACLE_HOME/bin:\$PATH
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib
EOF

# 3. Tạo cặp Script Đóng/Mở loại bỏ hoàn toàn mã độc tương tác
cat > /home/oracle/scripts/start_all.sh <<EOF
#!/bin/bash
. /home/oracle/scripts/setEnv.sh
dbstart \$ORACLE_HOME
EOF

cat > /home/oracle/scripts/stop_all.sh <<EOF
#!/bin/bash
. /home/oracle/scripts/setEnv.sh
dbshut \$ORACLE_HOME
EOF

chown -R oracle:oinstall /home/oracle/scripts
chmod u+x /home/oracle/scripts/*.sh

# 4. Gắn cứng cờ tự bật vào sổ cái /etc/oratab
sed -i "/^$MY_SID:/d" /etc/oratab
echo "$MY_SID:/u01/app/oracle/product/19.0.0/dbhome_1:Y" >> /etc/oratab

# 5. Khởi tạo Service chạy ngầm trên Linux (systemd daemon)
cat > /etc/systemd/system/dbora.service <<EOF
[Unit]
Description=Oracle Database 19c AutoStart
After=network.target

[Service]
Type=simple
User=oracle
Group=oinstall
ExecStart=/home/oracle/scripts/start_all.sh
ExecStop=/home/oracle/scripts/stop_all.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Load và bật chạy nghiệm thu
systemctl daemon-reload
systemctl enable dbora.service
systemctl start dbora.service
```

---

## 6. CẨM NANG "BẮT BỆNH" - XỬ LÝ LỖI NGẦM HAY GẶP (TROUBLESHOOTING)

> [!IMPORTANT]
> Toàn bộ quá trình thao tác sẽ tiềm ẩn một loạt các cạm bẫy đặc hữu. Hãy làm chủ chúng.

- **Thiếu Mất Group User:** Vòng chọn Nhánh Group báo màn trắng rỗng do lỗi gõ lệnh tạo user tay chống đè script yum Preinstall. Chữa cháy siêu nhanh là dùng terminal Root tạo thủ công `groupadd -f oinstall..` và nạp quyền quản lý ngược vào cho user.
- **Tiến Trình Chặn Lỗi Giao Diện Đồ Hoạ X11-Display:** Tránh hoàn toàn việc sử dụng lóng ngóng lệnh `xhost +`. Nếu bạn nối SSH từ máy tính ngoài chỉ để setup, công cụ bảo bối hiệu quả nhất toàn thế giới vẫn là **MobaXterm** (vừa kết nối SSH tiện dụng vừa cõng Giao Diện thẳng xuyên cổng Port 22 vượt luôn rào cản).
- **Lỗi [INS-35178] (AMM > 4GB RAM):** 
    - *Nguyên nhân:* Oracle 19c không cho phép dùng Automatic Memory Management (AMM) nếu RAM máy ảo > 4GB.
    - *Cách xử lý:* Quay lại tab **Memory**, **bỏ tích** ô "Enable Automatic Memory Management". Oracle sẽ chuyển sang dùng ASMM (tốt hơn cho máy cấu hình mạnh).
- **Thư Mục Trống của `oraInventory` (Lỗi [INS-32047]):** Nếu OUI pop-up có báo cáo "[INS-32047] Folder is not empty" thì nhấp Yes ép cho qua vì đó là log rác từ việc tải dở quá trình cài thất bại lần trước còn bỏ lại. Dễ dàng ghi lấp đè là được.
- **Treo Tiến trình Systemctl (Lỗi 127):** Thường do file `/etc/oratab` trống rỗng hoặc script bạn chép mạng có dính lệnh bắt tương tác `. oraenv`. Hãy luôn sử dụng thiết lập Service 5 bước ở [Mục 5] phía trên để vượt ải an toàn.
- **Lỗi [INS-20802] Oracle Net Configuration Assistant failed (Tiến trình cấu hình Listener bị Crash):**
    - *Nguyên nhân:* Thường gặp ở Bước 17 (Progress ~59%). Do địa chỉ IP bạn ghi ở tệp `/etc/hosts` bị sai lệch so với IP hệ thống thực tế hiện tại, khiến Listener không thể định danh (bind) thông qua port tĩnh 1521.
    - *Cách xử lý:* Giữ nguyên màn hình cài đặt. Mở cửa sổ terminal mới (quyền `root`), kiểm tra biến số IP thật bằng lệnh `ip a`. Sau đó sửa dứt điểm lỗi IP trong cấu hình `vi /etc/hosts`. Quay lại giao diện Oracle, bấm OK để đóng khung cảnh báo và kéo chọn **Retry**, hệ thống sẽ phục hồi kết nối.
- **Lỗi ORA-01034: ORACLE not available (Lỗi kết nối trượt Instance):**
    - *Nguyên nhân:* Do khi đăng nhập SQL*Plus, Terminal không biết hoặc nhận diện sai tên SID (ví dụ đang là `orcl` thay vì `oracle19`), hoặc Database thực sự chưa được bật.
    - *Cách xử lý:* Thoát ra bash (gõ `exit`), nạp lại môi trường bằng lệnh `source ~/.bash_profile` rồi đăng nhập thử lại. Nếu vẫn bị lỗi, hãy gõ lệnh `startup` trực tiếp trong prompt SQL*Plus để nạp Database lên.
- **Lỗi ORA-00936: missing expression (Thiếu biểu thức):**
    - *Nguyên nhân:* Gõ sai cú pháp SQL cơ bản (ví dụ lỗi thiếu tên cột tham chiếu giữa chữ `select` và `from`).
    - *Cách xử lý:* Sửa lại câu lệnh có chứa khai báo đầy đủ thành phần (Ví dụ `select * from v$instance` hoặc `select status from v$instance`).

## 7. GỠ BỎ HOÀN TOÀN GÓI PREINSTALL VÀ DỌN SẠCH HỆ THỐNG (UNDO / ROLLBACK)

> Nội dung phần này đã được tách thành tài liệu riêng để dễ tra cứu và quản lý:
> 📄 **[go_bo_oracle_preinstall_19c.md](go_bo_oracle_preinstall_19c.md)**
>
> Bao gồm: Gỡ gói RPM (`dnf remove` / `yum history undo`), xoá user/group, rollback kernel params, limits, dọn dependency packages, xoá thư mục cài đặt và service auto-start.

## 8. PHỤ LỤC HOT-RESIZING: GIA TĂNG DUNG LƯỢNG KHI LVM ĐẦY BẤT CHỢT

Đang thao tác vận hành Database chạy 24/24 phát hiện MountPoint `/u01` full 100% dung lượng. Sức mạnh LVM cho phép ta:

Ví dụ gắn thêm VMware 1 đĩa Sdd ảo khoảng 20GB.
1. **Ép kernel quét bắt chân Port SCSI:** `for host in /sys/class/scsi_host/host*/scan; do echo "- - -" > $host; done` (Nổi lên cái Device ký hiệu `sdd`).
2. **Kích Hoạt Block Phân vùng (Physical):** `pvcreate /dev/sdd`
3. **Mở Đẩy Volumn Group (Logical VG):** `vgextend vg_u01 /dev/sdd` (Nối 20GB đó vào hệ kho của u01).
4. **Giãn Nở Hệ Môi Giới Hệ Điều Hành (Logical LV):** `lvextend -l +100%FREE /dev/vg_u01/lv_u01`
5. **Cập Nhật Ngay Mép Dữ Liệu Thực:** `xfs_growfs /u01`
*(Quá trình giãn nở chỉ vài giây, Hệ DB đang truy xuất dữ liệu liên tục không hề bị đứt gãy kết nối)*.

## 9. PHỤ LỤC: CÀI ĐẶT TỰ ĐỘNG (SILENT INSTALL)

Nếu bạn cần cài đặt Oracle trên nhiều máy chủ cùng lúc mà không muốn Click chuột 18 bước, hãy dùng file `.rsp` đã lưu ở [Bước 16].

**Câu lệnh thực thi (Quyền `oracle`):**
```bash
# Thay /tmp/db.rsp bằng đường dẫn file bạn đã lưu
$ORACLE_HOME/runInstaller -silent -force -responseFile /tmp/db.rsp
```

**Các lưu ý khi mang sang máy mới:**
- Mở file `.rsp` và sửa lại các tham số sau nếu có thay đổi:
  - `ORACLE_HOSTNAME`: Tên máy mới.
  - `oracle.install.db.config.starterdb.password.ALL`: Mật khẩu mới.
  - `ORACLE_HOME` / `ORACLE_BASE`: Nếu bạn đổi thư mục cài đặt.

## 10. PHỤ LỤC: CÀI ĐẶT "SIÊU TỐC" BẰNG SCRIPT (AUTO SETUP)

Để tối ưu hóa quá trình cài đặt cho các máy chủ mới, bạn có thể sử dụng 3 script đã được chuẩn bị sẵn trong thư mục `Scrip`.

### Bước 1: Cấu hình OS (Quyền ROOT)
Chọn 1 trong 2 tùy chọn tùy theo tình trạng mạng:
- **Online:** `sh /d/DB/setup/oracle/thuc\ hanh/Scrip/1_setup_os_online.sh`
- **Offline:** `sh /d/DB/setup/oracle/thuc\ hanh/Scrip/1_setup_os_offline.sh`

### Bước 2: Cấu hình Môi trường (Quyền ROOT)
- Chạy: `sh /d/DB/setup/oracle/thuc\ hanh/Scrip/2_setup_env_all.sh`

======================
*(Biên soạn chi tiết hoàn chỉnh toàn phần cấu trúc Cài Đặt Oracle DB 19c Server Single).*
