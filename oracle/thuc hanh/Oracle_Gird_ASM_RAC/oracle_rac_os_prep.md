# Bước 2: Chuẩn bị Hệ điều hành cho Oracle RAC (Thực hiện trên 2 Nodes)

Sau khi cấu hình xong mạng và ổ đĩa dùng chung trên VMware, bạn cần chuẩn bị môi trường OS đồng bộ trên cả 2 node để sẵn sàng cài đặt Grid Infrastructure.

---

## 1. Cài đặt các gói điều kiện (Oracle Preinstall)

Chạy lệnh sau trên **CẢ 2 NODES** bằng quyền `root`:

```bash
# Oracle Linux cung cấp gói chuyên dụng cho Grid
yum install -y oracle-database-preinstall-19c
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

> [!IMPORTANT]
> Bắt buộc phải chạy các lệnh `passwd` này trên **CẢ 2 NODES**. Nếu một Node bị quên không đặt mật khẩu, lệnh `ssh-copy-id` ở Bước 4 cấu hình SSH sẽ bị lỗi `Permission denied`.

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

> [!WARNING]
> Mẹo tránh các lỗi phổ biến ở bước này:
> - **Khi sinh chìa khóa (`ssh-keygen`)**: Nhấn <Enter> liên tục 3 lần, **tuyệt đối không nhập bất kỳ ký tự nào** làm passphrase để tạo khóa rỗng (Passwordless).
> - **Lỗi `Host key verification failed`**: Khi kết nối lần đầu, hệ thống hỏi `Are you sure you want to continue connecting (yes/no)?`, bạn **BẮT BUỘC** phải gõ đủ chữ `yes`. Nếu chỉ nhấn <Enter> hoặc gõ `y` sẽ sinh ra lỗi này.
> - **Lỗi `Permission denied`**: Xuất hiện do bạn nhập sai mật khẩu, hoặc do bạn quên chạy lệnh `passwd grid` để khởi tạo mật khẩu bên máy đích.

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

## 5. Đồng bộ thời gian với Chrony (Tối quan trọng cho RAC)

Oracle Grid Infrastructure yêu cầu thời gian giữa các Node phải giống hệt nhau (sai số tính bằng mili-giây). Nếu để xảy ra tình trạng lệch giờ, bộ cài sẽ báo lỗi văng ở giai đoạn chạy `root.sh` cực kỳ khó fix.

Chạy các lệnh sau trên **CẢ 2 NODES** bằng quyền `root`:

```bash
# 1. Đặt chung 1 múi giờ thống nhất (Ví dụ: Giờ VN)
timedatectl set-timezone Asia/Ho_Chi_Minh

# 2. Cài đặt dịch vụ chrony (nếu máy chưa cài sẵn)
yum install -y chrony

# 3. Khởi động dịch vụ và cấp quyền tự chạy cùng OS
systemctl enable --now chronyd

# 4. Ép đồng bộ giờ mạng ngay lập tức
chronyc -a makestep

# 5. Kiểm tra danh sách server giờ (Để ý có dấu ^* là đang đồng bộ tốt)
chronyc sources -v
```

---

## 6. Cấu hình các tham số hệ thống (Limits)

Gói cài đặt mồi `oracle-database-preinstall-19c` đã tự động điền toàn bộ thông số cực kỳ phức tạp vào lõi Kernel (Sysctl) và Limits cho user `oracle` rồi. Tuy nhiên, vì mục tiêu hệ thống chúng ta là tách riêng quyền quản trị Cluster cho user `grid`, nên hệ thống chưa tự nhận diện được thằng `grid` này. 

Bạn hãy bôi đen toàn bộ lệnh dưới đây và dán thẳng vào Terminal trên **CẢ 2 NODES** (chạy bằng quyền `root`) để nó tự động gõ phụ bạn (chèn Limits xuống cuối file):

```bash
cat <<EOF >> /etc/security/limits.d/oracle-database-preinstall-19c.conf

# Bổ sung giới hạn tài nguyên cho user grid để chạy ASM/Clusterware
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

> [!TIP]
> Lệnh `cat <<EOF >>` đóng vai trò "chép và chèn nhanh" dữ liệu xuống dưới cùng của một file mà không vất vả chui vào màn hình Vi/Vim mệt mỏi. Chạy xong, bạn gõ `tail -n 12 /etc/security/limits.d/oracle-database-preinstall-19c.conf` để kiểm tra thành quả nhé!

---

## 7. Thiết lập biến môi trường (.bash_profile)

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

## 8. Sẵn sàng cho bước tiếp theo

Bây giờ bạn đã có 2 máy chủ Linux cấu hình giống hệt nhau, có user `grid` và `oracle` có thể "nói chuyện" với nhau qua SSH và các biến môi trường đã được tải đầy đủ. 

Bước tiếp theo chúng ta sẽ tiến hành cấu hình **UDEV Rules** để "nhào nặn" các ổ đĩa VMware thành các ổ đĩa ASM sẵn sàng cho Grid.
