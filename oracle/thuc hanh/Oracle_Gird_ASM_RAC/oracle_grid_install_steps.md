# Bước 4: Cài đặt Oracle Grid Infrastructure 19c

Sau khi đã chuẩn bị xong mạng, đĩa ASM (UDEV) và SSH Passwordless, chúng ta sẽ tiến hành cài đặt phần mềm Grid Infrastructure trên cụm 2 node.

---

## 1. Chuẩn bị bộ cài (Thực hiện trên Node 1)

Đăng nhập bằng user `grid` và thực hiện giải nén bộ cài vào thư mục Grid Home đã tạo:

```bash
# Chuyển vào thư mục Grid Home
cd /u01/app/19.3.0/grid

# Giải nén trực tiếp tại đây (Image-based setup)
unzip -q /tmp/LINUX.X64_193000_grid_home.zip
```

---

## 2. Khởi chạy Grid Setup

Đảm bảo bạn đã bật X11 Forwarding (ví dụ qua MobaXterm hoặc Xshell) và đăng nhập bằng user `grid`:

```bash
./gridSetup.sh
```

---

## 3. Các bước trên giao diện đồ họa (GUI)

Vui lòng chọn các tùy chọn sau khi trình cài đặt hiện lên:

1.  **Select Configuration Option:** Chọn **Configure Oracle Grid Infrastructure for a New Cluster**.
2.  **Select Cluster Type:** Chọn **Configure a Standard Cluster**.
3.  **Cluster Node Information:**
    - Cấu hình SCAN Name: `rac-scan.localdomain` (Port 1521).
    - Bấm **Add...** để thêm Node 2 (`racnode2.localdomain` và Virtual Hostname: `racnode2-vip`).
    - Bấm **SSH Connectivity...** để kiểm tra lại kết nối không mật khẩu.
4.  **Network Interface Usage:**
    - `eth0` (hoặc tên tương ứng): Chọn **Public**.
    - `eth1` (hoặc tên tương tự): Chọn **ASM & Private**.
5.  **Storage Option:** Chọn **Use Oracle Flex ASM**.
6.  **Create ASM Disk Group:**
    - Disk Group Name: `OCR_VOTE`.
    - Redundancy: Chọn **External** (vì chúng ta đang dùng Lab VMware).
    - Bấm **Change Discovery Path**: Điền `/dev/oracleasm/*`.
    - Chọn đĩa `/dev/oracleasm/asm_ocr1`.
7.  **ASM Password:** Đặt mật khẩu cho user `SYS` và `ASMSNMP` của ASM (VD: `oracle123`).
8.  **Failure Isolation:** Chọn **Do not use Intelligent Platform Management Interface (IPMI)**.
9.  **Root Script Execution:** Để trống (Chúng ta sẽ chạy thủ công ở bước cuối).

---

## 4. Chạy Script Root (Rất quan trọng)

Khi tiến trình cài đặt đạt khoảng 80%, một cửa sổ sẽ hiện lên yêu cầu bạn chạy các script với quyền `root`.

**Thứ tự thực hiện:**
1.  Mở terminal `root` trên **Node 1**: Chạy `/u01/app/oraInventory/orainstRoot.sh`.
2.  Mở terminal `root` trên **Node 2**: Chạy `/u01/app/oraInventory/orainstRoot.sh`.
3.  Mở terminal `root` trên **Node 1**: Chạy `/u01/app/19.3.0/grid/root.sh`. (**Chờ cho đến khi hoàn thành 100% trên Node 1**).
4.  Mở terminal `root` trên **Node 2**: Chạy `/u01/app/19.3.0/grid/root.sh`.

---

## 5. Kiểm tra sau khi cài đặt

Sau khi bấm **Finish** và đóng trình cài đặt, hãy kiểm tra trạng thái cluster bằng user `grid`:

```bash
# Kiểm tra tổng quát
crsctl check cluster -all

# Kiểm tra trạng thái tài nguyên chi tiết
crsctl status resource -t
```

Nếu tất cả các cột đều hiển thị `ONLINE`, chúc mừng bạn đã cài đặt xong "Cỗ máy hạ tầng" Grid Infrastructure cho RAC!
