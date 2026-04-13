# Tài Liệu Toàn Tập: Hướng Dẫn Cài Đặt Oracle Database 19c Single Instance

Tài liệu này được tổng hợp và chú thích chi tiết nhằm mang lại cái nhìn toàn diện nhất cho việc triển khai hệ thống Oracle Database 19c (Single Node) trên nền tảng Oracle Linux. Từ khâu chuẩn bị phần cứng, tiến trình cài đặt OS, cấu hình Database cho tới việc xử lý sự cố.

---

## 1. TỔNG QUAN HỆ THỐNG VÀ CHUẨN BỊ TÀI NGUYÊN (PRE-REQUISITES)

Việc chuẩn bị nền móng tài nguyên tốt giúp Database hoạt động mượt mà và tuân thủ chuẩn **OFA (Optimal Flexible Architecture)** của Oracle.

### a. Tài nguyên Máy Ảo (VMware / Server)
- **CPU:** Tối thiểu 2 Cores, khuyến nghị **4 Cores** (Giúp compile kiến trúc lúc cài đặt nhanh hơn rất nhiều).
- **RAM:** Tối thiểu 4GB, khuyến nghị vùng **8GB - 16GB** (Đủ để cấp phát cho các bộ đệm chung tập trung cho SGA/PGA của database).
- **Network:** Chế độ NAT hoặc Bridged với **IP tĩnh (Static IP)** và có Hostname cụ thể (ví dụ: `ora19c.localdomain`). Điều này tránh lỗi listener của Oracle bị đổi địa chỉ ở các thiết lập khởi động.

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
5. **Tạo Mount Point và tự kết nối khởi động bằng Auto-mount `/etc/fstab`:**
   ```bash
   mkdir -p /u01 /u02     # Tạo 2 thư mục làm điểm rơi cấu trúc
   # Chèn cứng cài đặt Auto-mount ghi thẳng vào đuôi của file nhân cấu hình OS
   echo "/dev/mapper/vg_u01-lv_u01   /u01    xfs    defaults    0 0" >> /etc/fstab
   echo "/dev/mapper/vg_u02-lv_u02   /u02    xfs    defaults    0 0" >> /etc/fstab
   
   mount -a # Lệnh "test cửa tử": Quét nghiệm thu cú pháp báo cáo lỗi fstab chống Kernel Panic
   ```

---

## 3. CẤU HÌNH MÔI TRƯỜNG CÀI ĐẶT (PRE-INSTALLATION)

Bước này đảm bảo cấu trúc OS đã nạp sẵn hạt giống user và thư mục đủ tiêu chuẩn cho Database Engine.

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
export ORACLE_HOSTNAME=ora19c.localdomain   # Thay đúng bằng Hostname thật đang chạy để tránh báo lỗi mạng
export ORACLE_UNQNAME=orcl                  
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/19.0.0/dbhome_1
export ORACLE_SID=orcl                      
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
2. **Loạt cấu hình chuẩn thực chiến (Theo hệ thống Best Practice):**
   - **Configuration Option:** Click `Create and configure a single instance database`.
   - **System Class:** Click chọn `Server class`.
   - **Database Identifiers:** Đặt mục Global Name/SID là `orcl`. Khuyến nghị bật `Create as Container database` để tiếp cận tiêu chuẩn môi trường lõi Multitenant PDB cho sau này.
   - **Character Sets (Mục quan trọng tại thẻ tab Options):** Sửa bộ Character lưu dữ liệu sang Unicode `AL32UTF8` hỗ trợ khả năng nhập Tiếng Việt có dấu trọn vẹn. Khuyên dùng không sử dụng bảng hệ mã ASCII cũ WE8...
   - **Root script execution:** Tick vào khung `Automatically run configuration scripts` -> Trao khóa mật khẩu tài khoản Root điền vào Box. Tiến trình sẽ chạy tới áp chót tự cầm token của root đi cấu hình script thư mục `oraInventory` ngầm mà khỏi phải nảy Panel gọi bạn cầu cứu thao tác bằng tay.
3. Kéo nút Next -> Cài đặt (15~40 phút chờ xả kho Core Database). Nhận được kết quả trả thông điệp `"The setup of Oracle Database was successful"`.
4. Gọi sqlplus thử nghiệm nghiệm thu:
   ```bash
   sqlplus / as sysdba
   SQL> select status from v$instance;  -- Trạng thái in báo 'OPEN'
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
- **Thư Mục Trống của `oraInventory`:** Nếu OUI pop-up có báo cáo "[INS-32047] Folder is not empty" thì nhấp Yes ép cho qua vì đó là log rác từ việc tải dở quá trình cài thất bại lần trước còn bỏ lại. Dễ dàng ghi lấp đè là được.
- **Treo Tiến trình Systemctl (Lỗi 127):** Thường do file `/etc/oratab` trống rỗng hoặc script bạn chép mạng có dính lệnh bắt tương tác `. oraenv`. Hãy luôn sử dụng thiết lập Service 5 bước ở [Mục 5] phía trên để vượt ải an toàn.

---

## 7. GỠ BỎ HOÀN TOÀN GÓI PREINSTALL VÀ DỌN SẠCH HỆ THỐNG (UNDO / ROLLBACK)

> [!WARNING]
> Phần này chỉ nên thực hiện khi bạn muốn **xoá sạch hoàn toàn** mọi thứ mà gói `oracle-database-preinstall-19c` đã cấu hình, đưa hệ thống OS trở về trạng thái nguyên bản trước khi cài Oracle. Tất cả các bước dưới đây đều phải thao tác bằng quyền **`root`**.

### a. Bước 1 – Gỡ bỏ gói RPM oracle-database-preinstall-19c

Có **2 phương pháp** để gỡ gói preinstall. Tuỳ mức độ bạn muốn dọn sạch mà chọn:

#### 🔵 Cách 1: `dnf remove` (Gỡ gói chính, giữ lại dependencies)
```bash
# Kiểm tra gói đã cài chưa
rpm -qa | grep oracle-database-preinstall

# Gỡ bỏ gói preinstall (giữ lại các dependency dùng chung của OS)
dnf remove -y oracle-database-preinstall-19c
```
*(Lệnh `dnf remove` chỉ gỡ mỗi gói chính, **không** gỡ các dependency kéo theo và **không** tự dọn các thay đổi cấu hình kernel, user, group mà nó đã tạo ra. Phải dọn thủ công theo các bước tiếp theo).*

#### 🔴 Cách 2: `yum history undo` (Rollback nguyên transaction – GỠ TRIỆT ĐỂ cả dependencies)
Đây là phương pháp **mạnh nhất** — undo toàn bộ phiên giao dịch cài đặt, gỡ luôn tất cả các gói phụ thuộc đã kéo theo lúc `dnf install`:
```bash
# Bước 1: Xem lịch sử các transaction đã thực hiện
yum history
# Kết quả sẽ trả về danh sách transaction có đánh số ID, ví dụ:
#   ID | Command line             | Date and time    | Action(s) | Altered
#   ---+--------------------------+------------------+-----------+--------
#    4 | install oracle-database- | 2026-04-10 14:30 | Install   |   75

# Bước 2: Xác định đúng ID transaction đã cài preinstall (ví dụ ID = 4)
yum history info 4    # Xem chi tiết transaction đó đã cài những gói nào

# Bước 3: Undo nguyên transaction đó — gỡ sạch gói chính + toàn bộ dependencies
yum history undo 4 -y
```
> [!TIP]
> **Tại sao nên dùng `yum history undo`?** Khi bạn cài `oracle-database-preinstall-19c`, hệ thống kéo theo hàng chục gói phụ thuộc (compat-libcap, ksh, libaio-devel, sysstat...). Lệnh `dnf remove` chỉ gỡ 1 gói chính, còn `yum history undo` sẽ đảo ngược **toàn bộ transaction** — gỡ sạch cả gói chính lẫn mọi dependency đã cài kèm, đưa OS về đúng trạng thái trước khi cài.

### b. Bước 2 – Xoá User `oracle` và Home Directory
```bash
# Kiểm tra user oracle còn tồn tại không
id oracle

# Xoá user oracle kèm toàn bộ thư mục Home
userdel -r oracle
```
> [!CAUTION]
> Cờ `-r` sẽ xoá luôn thư mục `/home/oracle` và mailbox. Hãy chắc chắn đã sao lưu mọi dữ liệu quan trọng (scripts, bash_profile, wallet...) trước khi chạy lệnh này.

### c. Bước 3 – Xoá sạch các Group mà Preinstall đã tạo
Gói preinstall tạo ra hàng loạt group hệ thống chuyên dụng. Xoá từng group:
```bash
groupdel oinstall
groupdel dba
groupdel oper
groupdel backupdba
groupdel dgdba
groupdel kmdba
groupdel racdba
```
*(Nếu group nào báo `group 'xxx' does not exist` thì bỏ qua, không ảnh hưởng gì).*

### d. Bước 4 – Rollback cấu hình Kernel Parameters (sysctl)
Gói preinstall chèn tham số kernel vào file `/etc/sysctl.d/` hoặc `/etc/sysctl.conf`. Kiểm tra và xoá:
```bash
# Tìm file cấu hình kernel do Oracle tạo
ls -la /etc/sysctl.d/ | grep -i oracle

# Xoá file cấu hình kernel tham số Oracle (tên file có thể khác tuỳ phiên bản)
rm -f /etc/sysctl.d/97-oracle-database-sysctl.conf
rm -f /etc/sysctl.d/98-oracle-database-sysctl.conf

# Nạp lại kernel parameters sạch (loại bỏ giá trị Oracle cũ khỏi bộ nhớ)
sysctl --system
```

### e. Bước 5 – Rollback cấu hình Limits (Security Limits)
Gói preinstall chèn giới hạn tài nguyên cho user oracle vào thư mục `/etc/security/limits.d/`:
```bash
# Tìm file limits do Oracle tạo
ls -la /etc/security/limits.d/ | grep -i oracle

# Xoá file limits của Oracle
rm -f /etc/security/limits.d/oracle-database-preinstall-19c.conf
```

### f. Bước 6 – Dọn sạch các Dependency Packages thừa (Tuỳ chọn)
> [!NOTE]
> Nếu bạn đã dùng **Cách 2 (`yum history undo`)** ở Bước 1, thì bước này **có thể bỏ qua** vì dependencies đã bị gỡ sạch khi undo transaction. Bước này chỉ cần thiết nếu bạn dùng **Cách 1 (`dnf remove`)**.

Gói preinstall kéo theo hàng loạt dependency packages (thư viện dev, compatibility libs...). Dọn những gói không còn ai dùng:
```bash
# Liệt kê các gói mồ côi (không còn gói nào phụ thuộc)
yum autoremove -y
# Hoặc dùng dnf: dnf autoremove -y

# Dọn cache tải về của yum/dnf
yum clean all
```
> [!IMPORTANT]
> Lệnh `yum autoremove` chỉ gỡ các gói được đánh dấu là "dependency tự động kéo về". Các gói hệ thống cốt lõi sẽ **không bị ảnh hưởng**. Tuy nhiên hãy review danh sách trước khi xác nhận nếu muốn an toàn tuyệt đối: chạy `yum autoremove` (không có `-y`) để xem trước.

### g. Bước 7 – Xoá thư mục cài đặt Oracle (Nếu muốn dọn triệt để)
```bash
# Xoá toàn bộ cây thư mục phần mềm Oracle
rm -rf /u01/app/oracle
rm -rf /u02/oradata

# Xoá file cấu hình Oracle còn sót
rm -f /etc/oratab
rm -rf /opt/oracle
rm -rf /etc/oracle
```

### h. Bước 8 – Xoá Service Auto-start (Nếu đã cấu hình Mục 5)
```bash
# Tắt và gỡ service dbora
systemctl stop dbora.service
systemctl disable dbora.service
rm -f /etc/systemd/system/dbora.service
systemctl daemon-reload
```

### ✅ Kiểm Tra Xác Nhận Dọn Sạch Hoàn Toàn
Chạy lần lượt các lệnh kiểm tra sau để nghiệm thu kết quả:
```bash
# 1. User oracle không còn tồn tại
id oracle                        # Kỳ vọng: "no such user"

# 2. Không còn group Oracle
grep -E "oinstall|dba|oper|backupdba|dgdba|kmdba|racdba" /etc/group
                                 # Kỳ vọng: Không có kết quả trả về

# 3. Gói RPM đã bị gỡ
rpm -qa | grep oracle-database-preinstall
                                 # Kỳ vọng: Không có kết quả trả về

# 4. Kernel params Oracle đã xoá
sysctl -a 2>/dev/null | grep -i "sem\|shmall\|shmmax\|shmmni"
                                 # Kỳ vọng: Chỉ còn giá trị mặc định OS

# 5. File limits Oracle đã xoá
ls /etc/security/limits.d/ | grep -i oracle
                                 # Kỳ vọng: Không có kết quả trả về
```

---

## 8. PHỤ LỤC HOT-RESIZING: GIA TĂNG DUNG LƯỢNG KHI LVM ĐẦY BẤT CHỢT

Đang thao tác vận hành Database chạy 24/24 phát hiện MountPoint `/u01` full 100% dung lượng. Sức mạnh LVM cho phép ta:

Ví dụ gắn thêm VMware 1 đĩa Sdd ảo khoảng 20GB.
1. **Ép kernel quét bắt chân Port SCSI:** `for host in /sys/class/scsi_host/host*/scan; do echo "- - -" > $host; done` (Nổi lên cái Device ký hiệu `sdd`).
2. **Kích Hoạt Block Phân vùng (Physical):** `pvcreate /dev/sdd`
3. **Mở Đẩy Volumn Group (Logical VG):** `vgextend vg_u01 /dev/sdd` (Nối 20GB đó vào hệ kho của u01).
4. **Giãn Nở Hệ Môi Giới Hệ Điều Hành (Logical LV):** `lvextend -l +100%FREE /dev/vg_u01/lv_u01`
5. **Cập Nhật Ngay Mép Dữ Liệu Thực:** `xfs_growfs /u01`
*(Quá trình giãn nở chỉ vài giây, Hệ DB đang truy xuất dữ liệu liên tục không hề bị đứt gãy kết nối)*.

======================
*(Biên soạn chi tiết hoàn chỉnh toàn phần cấu trúc Cài Đặt Oracle DB 19c Server Single).*
