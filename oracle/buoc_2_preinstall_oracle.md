# Bước 2 - Cấu Hình Môi Trường (Pre-install) cho Oracle Database 19c

Sau khi đã cài xong tóm tắt Hệ điều hành Oracle Linux và cấu hình mạng cơ bản, bước tiếp theo là chuẩn bị môi trường OS (Pre-installation tasks) để sẵn sàng cho việc cài đặt phần mềm Oracle Database.

Tất cả các thao tác dưới đây bạn hãy mở Terminal và chạy với quyền tối cao là **`root`**.

### 1. Cài đặt gói tự động cấu hình (Oracle Preinstall Package)
*(Ghi chú: Trên Oracle Linux 7 bạn sử dụng lệnh `yum`, trên Oracle Linux 8/9 bạn sử dụng lệnh `dnf`. Cả hai lệnh này có cú pháp gần như hoàn toàn giống nhau, bài hướng dẫn này sẽ dùng `dnf` làm ví dụ mặc định).*

Oracle cung cấp một gói RPM cực kỳ tiện lợi. Gói này sẽ tự động giải quyết các vấn đề như: tạo user `oracle`, tạo các group bắt buộc (`oinstall`, `dba`, `oper`, v.v...), cấu hình tham số nhân (kernel parameters - `sysctl`), và cấu hình giới hạn hệ thống (user limits - `limits.conf`).

> [!TIP]
> **Lưu trữ các file cài đặt (.rpm) (Tùy chọn)**
> Mặc định, hệ thống sẽ xóa các file tải về sau khi cài đặt xong. Nếu muốn giữ lại các file này (để backup hoặc cài offline sau này), bạn có hai cách:
> 
> **Cách 1: Vừa cài đặt vừa lưu trữ vào Cache**
> Cấu hình `keepcache` trước khi chạy lệnh cài đặt:
> - **Oracle Linux 7:** Mở file `/etc/yum.conf`, đổi `keepcache=0` thành `keepcache=1`.
> - **Oracle Linux 8/9:** Mở file `/etc/dnf/dnf.conf`, thêm dòng `keepcache=True` vào cuối file.
> *(Sau khi cài, các gói sẽ được lưu tại `/var/cache/yum/` hoặc `/var/cache/dnf/`)*
>
> **Cách 2: CHỈ tải file về một thư mục, KHÔNG cài đặt**
> Dùng khi bạn chỉ muốn lấy bộ cài cất đi hoặc mang sang máy khác. Chạy lệnh (ví dụ tải vào `/tmp/oracle_rpms`):
> ```bash
> mkdir -p /tmp/oracle_rpms
> dnf install -y --downloadonly --downloaddir=/tmp/oracle_rpms oracle-database-preinstall-19c
> ```
> *(Lưu ý: Sau khi tải về một thư mục chỉ định, nếu bạn muốn tiến hành cài đặt bằng chính các gói vừa tải đó, bạn có hai lựa chọn lệnh:*
> *- **Cách an toàn (khuyên dùng):** `dnf localinstall -y /tmp/oracle_rpms/*.rpm` (Tự động bù thư viện thiếu)*
> *- **Cách thủ công:** `rpm -ivh /tmp/oracle_rpms/*.rpm` (Sẽ báo lỗi nếu chưa tải đủ 100% thư viện phụ thuộc)*
> *)*

Chạy lệnh sau để tiến hành tải và cài đặt luôn (Áp dụng cho trường hợp cài server thông thường):
```bash
dnf install -y oracle-database-preinstall-19c
```
*(Đợi một lát để hệ thống tải và cài đặt tự động từ server của Oracle. Oracle Linux cần được kết nối internet ở bước này).*

### 2. Đặt mật khẩu cho user Oracle
Gói cài đặt trên tự động sinh ra user tên là `oracle` trong OS nhưng chưa có mật khẩu. Bạn phải gán mật khẩu cho nó (Ví dụ: `oracle123`):
```bash
passwd oracle
```
*(Màn hình đen sẽ yêu cầu gõ mật khẩu 2 lần. Bạn cứ gõ bình thường vì Linux không hiển thị ký tự '*' trên màn hình).*

### 3. Khởi tạo cấu trúc thư mục (OFA - Optimal Flexible Architecture)
Trong bước cài hệ điều hành, ta đã tạo sẵn các phân vùng mount point `/u01` (chứa phần mềm) và `/u02` (chứa dữ liệu). Giờ ta sẽ tạo chi tiết các cây thư mục bên trong và cấp quyền sở hữu để user `oracle` quản lý.

Chạy lần lượt các lệnh sau:
```bash
# Tạo thư mục cài đặt gốc (ORACLE_BASE) và nơi chứa phần mềm lõi (ORACLE_HOME)
mkdir -p /u01/app/oracle/product/19.0.0/dbhome_1

# Tạo thư mục chứa dữ liệu vật lý của Database
mkdir -p /u02/oradata

# Tạo thư mục chứa backup và archive log (nếu có chia đĩa /u03, không có thì bỏ qua đoạn này)
mkdir -p /u03/fast_recovery_area

# Chuyển quyền sở hữu toàn bộ các thư mục cho user oracle và group oinstall
chown -R oracle:oinstall /u01
chown -R oracle:oinstall /u02
# Nếu có /u03 thì chạy thêm: chown -R oracle:oinstall /u03

# Phân quyền cho phép owner đọc, ghi, chạy (rwx)
chmod -R 775 /u01
chmod -R 775 /u02
# Thêm chmod -R 775 /u03 nếu có
```

### 4. Thiết lập biến môi trường (.bash_profile) cho user oracle
Mỗi khi user `oracle` đăng nhập, nó cần biết địa chỉ các biến môi trường quan trọng (như `ORACLE_HOME`, `ORACLE_SID`) nằm ở đâu để sẵn sàng nhận các lệnh quản trị như sqlplus hay rman.

Chuyển sang làm việc dưới quyền của user oracle:
```bash
su - oracle
```

Mở sửa file profile cấu hình cá nhân (bằng lệnh `vi`):
```bash
vi ~/.bash_profile
```

Bấm phím chữ `i` để bật chế độ Insert (sửa văn bản). Copy - Paste đoạn script dưới đây xuống ngay **dưới cùng** của file:

```bash
# --- Oracle Environment Settings ---
export TMP=/tmp
export TMPDIR=$TMP

export ORACLE_HOSTNAME=ora19c.localdomain   # Lưu ý: Sửa đúng theo Host Name máy ảo của bạn
export ORACLE_UNQNAME=orcl                  # Tên phân biệt toàn cầu của hệ thống Database (ví dụ orcl)
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/19.0.0/dbhome_1
export ORACLE_SID=orcl                      # SID sẽ dùng cho Database (ví dụ orcl)
export PATH=$ORACLE_HOME/bin:$PATH

export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib
# -----------------------------------
```

Hoàn tất Sửa chữa: Bấm phím `ESC`, gõ dấu `:` (hai chấm) rồi gõ `wq!` (viết liền `:wq!`) để Save và Thoát.

Để nạp file thay đổi này vào bộ nhớ và sử dụng liền:
```bash
source ~/.bash_profile
```

### 5. Đẩy bộ setup Oracle 19c (Source ZIP) máy ảo
Đây là bước bắt buộc để có nguồn cài đặt. Bạn cần lấy file ZIP cài DB 19c (`LINUX.X64_193000_db_home.zip`) được cung cấp trên website Oracle để chuẩn bị giải nén.

1. Bạn có thể dùng các tool như WinSCP, FileZilla kết nối theo địa chỉ IP của máy ảo (Dùng tài khoản root, port 22 sftp). Kéo thả file `LINUX.X64_193000_db_home.zip` từ PC bạn vào thư mục `/tmp/` của máy ảo.
2. Sau khi upload thành công, hãy **dùng chính user `oracle` (không phải ROOT)** để bung nén file trực tiếp vào thư mục cài đặt `$ORACLE_HOME` bạn vừa khai báo.

```bash
# Đảm bảo bạn đang login là oracle
su - oracle

# Chuyển thư mục hiện tại về thẳng dbhome_1 (ORACLE_HOME)
cd $ORACLE_HOME

# Thực thi lệnh giải nén. Thay đường dẫn /tmp/... bằng đường dẫn bạn cất file zip.
unzip -q /tmp/LINUX.X64_193000_db_home.zip
```
*(Lưu ý cực kỳ xương máu: Bắt buộc dùng tài khoản `oracle` để unzip bộ này. Nếu lỡ dùng `root` để chạy giải nén, tất cả các file bị sai quyền owner và bạn sẽ không thể tiến hành cài đặt thành công).*

**Tới đây, Môi Trường Hệ Điều Hành Của Bạn Đã Trở Nên Hoàn Hảo!** Bạn đã sẵn sàng để thực hiện gọi trình cài đặt giao diện `runInstaller` ở Bước kế tiếp.
