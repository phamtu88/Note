# Bước 4: Cài đặt Oracle Grid Infrastructure 19c

Sau khi đã chuẩn bị xong mạng, đĩa ASM (UDEV) và SSH Passwordless, chúng ta sẽ tiến hành cài đặt phần mềm Grid Infrastructure trên cụm 2 node.

---

## 1. Chuẩn bị bộ cài (Thực hiện TRÊN NODE 1)

Từ phiên bản 19c, Oracle sử dụng kiến trúc **Image-based Setup**. Bạn bắt buộc phải xả nén trực tiếp toàn bộ nội dung file `.zip` gốc vào thẳng thư mục sẽ làm Grid Home vĩnh viễn (`/u01/app/19.3.0/grid`).

**Lưu ý cực kỳ quan trọng về Phân quyền (Quy chuẩn Production):**
Nếu bạn dùng phần mềm (WinSCP, FileZilla...) đăng nhập bằng user `root` để upload file `.zip` vào thẳng `/u01/app/19.3.0/grid`, file đó sẽ bị dính quyền của `root`, khiến user `grid` không thể giải nén được. Bạn phải trao trả quyền sở hữu file đó về cho `grid` trước khi làm tiếp.

Thực hiện tuần tự các bước sau **trên Node 1**:

```bash
# 1. (Chỉ làm nếu bạn lỡ upload bằng root) Chuyển quyền sở hữu file zip cho user grid
chown grid:oinstall /u01/app/19.3.0/grid/LINUX.X64_193000_grid_home.zip

# 2. Đăng nhập sang tài khoản grid (Nếu đang ở root)
su - grid

# 3. Chuyển vào thư mục Grid Home
cd /u01/app/19.3.0/grid

# 4. Xả nén trực tiếp toàn bộ bộ cài ra thư mục hiện tại
unzip -q LINUX.X64_193000_grid_home.zip
```

> [!TIP]
> Sau khi giải nén xong 100%, bạn **BẮT BUỘC** phải xóa file `.zip` gốc để tránh rác hệ thống và các lỗi ảo xâm lấn không gian lưu trữ (giả sử có cảnh báo quét rác).
> Lệnh xóa: `rm -f LINUX.X64_193000_grid_home.zip`

---

## 2. Cài đặt package cvuqdisk (Thực hiện TRÊN CẢ 2 NODE)

Trước khi chạy trình cài đặt, phải cài package `cvuqdisk` trên **cả 2 node** bằng user `root` để tránh lỗi Prerequisite Check:

```bash
# Trên Node 1 (root):
rpm -ivh /u01/app/19.3.0/grid/cv/rpm/cvuqdisk-1.0.10-1.rpm

# Trên Node 2 (root) — copy file từ Node 1 rồi cài:
scp oracle1:/u01/app/19.3.0/grid/cv/rpm/cvuqdisk-1.0.10-1.rpm /tmp/
rpm -ivh /tmp/cvuqdisk-1.0.10-1.rpm
```

---

## 3. Khởi chạy Grid Setup

Đảm bảo bạn đã bật X11 Forwarding (ví dụ qua MobaXterm) và **đăng nhập trực tiếp bằng user `grid`** (KHÔNG đăng nhập root rồi su - grid, sẽ bị lỗi X11):

```bash
cd /u01/app/19.3.0/grid
./gridSetup.sh
```

---

## 4. Các bước trên giao diện đồ họa (GUI) — 19 bước

Dưới đây là toàn bộ 19 bước trên thanh bên trái của Oracle Grid Infrastructure 19c Installer, khớp đúng với giao diện thực tế:

### Step 1 — Configuration Option
Chọn **Configure Oracle Grid Infrastructure for a New Cluster**.

### Step 2 — Cluster Configuration
Chọn **Configure an Oracle Standalone Cluster**.

### Step 3 — Grid Plug and Play
- **Cluster Name:** `oracle-cluster`
- **SCAN Name:** `oracle-scan.localdomain` *(BẮT BUỘC phải khớp 100% với file `/etc/hosts`)*
- **SCAN Port:** `1521`
- **Configure GNS:** Không tick (bỏ trống).

### Step 4 — Cluster Node Information
- Node 1 (`oracle1`) đã có sẵn trong danh sách.
- Bấm **Add...** để thêm Node 2:
  - **Public Hostname:** `oracle2`
  - **Virtual Hostname:** `oracle2-vip`
- Bấm **SSH Connectivity...** → Nhập mật khẩu user `grid` → Bấm **Setup** → Đợi kết quả trả về "Successfully" → Bấm **Test** để kiểm tra.

### Step 5 — Network Interface Usage
- `ens33` (192.168.153.x / NAT): Chọn **Public**.
- `ens37` (10.10.10.x / Host-Only): Chọn **ASM & Private**.
- `virbr0` (192.168.122.x): Chọn **Do Not Use**.

### Step 6 — Storage Option
Chọn **Use Oracle Flex ASM for Storage** (mặc định).

### Step 7 — Create Grid Infrastructure Management Repository
Chọn **No** (Không tạo GIMR cho môi trường Lab).

### Step 8 — Create ASM Disk Group
- **Disk Group Name:** `OCR_VOTE`
- **Redundancy:** Chọn **External** (vì môi trường Lab VMware chỉ có 1 bản sao).
- Bấm **Change Discovery Path** → Điền: `/dev/oracleasm/*` → Bấm **OK**.
- Tick chọn **DUY NHẤT** đĩa `/dev/oracleasm/asm_ocr1` (10GB).
- **Configure Oracle ASM Filter Driver:** Không tick.

### Step 9 — ASM Password
- Chọn **Use same passwords for these accounts**.
- Đặt mật khẩu cho `SYS` và `ASMSNMP` (ví dụ: `Oracle123`).

> [!WARNING]
> Mật khẩu phải có ít nhất 1 chữ HOA, 1 chữ thường, 1 số và dài tối thiểu 8 ký tự.

### Step 10 — Failure Isolation
Chọn **Do not use Intelligent Platform Management Interface (IPMI)**.

### Step 11 — Management Options
- **Không tick** ô "Register with Enterprise Manager (EM) Cloud Control".
- Để trống tất cả và bấm **Next**.

### Step 12 — Operating System Groups
Để mặc định tất cả (các group `asmadmin`, `asmdba`, `asmoper` đã được tự nhận diện từ cấu hình trước đó). Bấm **Next**.

### Step 13 — Installation Location
- **Oracle base:** `/u01/app/grid` (mặc định).
- **Software location:** `/u01/app/19.3.0/grid` (mặc định).

### Step 14 — Create Inventory
- **Inventory Directory:** `/u01/app/oraInventory` (mặc định).
- **oraInventory Group Name:** `oinstall` (mặc định).
- Bấm **Next**.

### Step 15 — Root script execution
- Để trống (không tick) → Chúng ta sẽ chạy thủ công ở Bước 5 bên dưới.

### Step 16 — Prerequisite Checks
- Oracle sẽ tự quét kiểm tra toàn bộ điều kiện tiên quyết.
- Nếu chỉ có **WARNING** (vàng): Tick **Ignore All** rồi bấm **Next** → Chọn **Yes**.

### Step 17 — Summary
Xem lại tổng hợp cấu hình lần cuối. Nếu mọi thứ chuẩn, bấm **Install** để bắt đầu cài đặt.

### Step 18 — Install Product
- Oracle sẽ tiến hành copy file và cấu hình.
- Khi đạt khoảng 80%, một cửa sổ pop-up sẽ xuất hiện yêu cầu chạy **root scripts** → Xem Bước 5 bên dưới.

### Step 19 — Finish
Bấm **Close** để kết thúc trình cài đặt.

---

## 5. Chạy Script Root (Rất quan trọng)

Khi tiến trình cài đặt đạt khoảng 80%, một cửa sổ sẽ hiện lên yêu cầu bạn chạy các script với quyền `root`.

**Thứ tự thực hiện (KHÔNG ĐƯỢC LÀM NGƯỢC):**

```bash
# Bước 1: Trên Node 1 (root)
/u01/app/oraInventory/orainstRoot.sh

# Bước 2: Trên Node 2 (root)
/u01/app/oraInventory/orainstRoot.sh

# Bước 3: Trên Node 1 (root) — CHỜ HOÀN THÀNH 100% trước khi làm Node 2
/u01/app/19.3.0/grid/root.sh

# Bước 4: Trên Node 2 (root) — Chỉ chạy SAU KHI Node 1 đã xong hoàn toàn
/u01/app/19.3.0/grid/root.sh
```

> [!CAUTION]
> Script `root.sh` trên Node 1 phải chạy **XONG HOÀN TOÀN** trước khi chạy trên Node 2. Nếu chạy song song hoặc ngược thứ tự sẽ gây lỗi nghiêm trọng, phải cài lại từ đầu.

---

## 6. Kiểm tra sau khi cài đặt

Sau khi bấm **Close** và đóng trình cài đặt, hãy kiểm tra trạng thái cluster bằng user `grid`:

```bash
# Kiểm tra tổng quát
crsctl check cluster -all

# Kiểm tra trạng thái tài nguyên chi tiết
crsctl status resource -t
```

Nếu tất cả các cột đều hiển thị `ONLINE`, chúc mừng bạn đã cài đặt xong "Cỗ máy hạ tầng" Grid Infrastructure cho RAC!

