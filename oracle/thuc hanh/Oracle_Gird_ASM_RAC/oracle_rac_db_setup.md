# Bước 5: Cài đặt Software và Tạo Database RAC 19c

Đây là bước cuối cùng để hoàn thiện hệ thống. Sau khi Clusterware đã chạy (ONLINE), chúng ta sẽ cài đặt phần mềm Database Core và tạo Cơ sở dữ liệu chạy trên ASM.

---

## 1. Cài đặt Oracle Database Software (RAC)

Đăng nhập bằng user `oracle` trên **Node 1**:

```bash
# Chuyển vào thư mục Oracle Home
cd $ORACLE_HOME

# Giải nén bộ cài DB (LINUX.X64_193000_db_home.zip)
unzip -q /tmp/LINUX.X64_193000_db_home.zip

# Khởi chạy trình cài đặt
./runInstaller
```

**Các bước GUI Cần Lưu Ý:**
1.  **Select Configuration Option:** Chọn **Set Up Software Only**.
2.  **Select Database Installation Options:** Chọn **Oracle Real Application Clusters database installation**.
3.  **Node Selection:** Đảm bảo tick chọn cả 2 Node (`racnode1` và `racnode2`).
4.  **Select Database Edition:** Chọn **Enterprise Edition**.
5.  **Root Script Execution:** Khi hiện thông báo, hãy chạy script `/u01/app/oracle/product/19.0.0/dbhome_1/root.sh` bằng quyền `root` lần lượt trên từng Node.

---

## 2. Tạo Disk Group DATA & FRA (ASMCA)

Trước khi tạo DB, ta cần gán 2 ổ đĩa còn lại (`asm_data1`, `asm_fra1`) vào các Disk Group.

Đăng nhập bằng user `grid` trên **Node 1**:
```bash
asmca
```
- Vào tab **Disk Groups**, bấm **Create**.
- Tạo `DATA` (chọn đĩa `asm_data1`) và `FRA` (chọn đĩa `asm_fra1`).
- Đảm bảo trạng thái là `MOUNTED` trên cả 2 node.

---

## 3. Tạo Database bằng giao diện DBCA

Đăng nhập bằng user `oracle` trên **Node 1**:
```bash
dbca
```

**Các tham số quan trọng:**
1.  **Select Database Operation:** Chọn **Create a Database**.
2.  **Select Database Creation Mode:** Chọn **Advanced configuration**.
3.  **Select Database Deployment Type:**
    - Database Type: **Oracle RAC database**.
    - Configuration Type: **Admin-Managed**.
    - Bấm **Select All** để chọn cả 2 Nodes.
4.  **Storage Option:** Chọn **Use Common Location for All Database Files**, và trỏ về Disk Group `+DATA`.
5.  **Fast Recovery Area:** Tick chọn và trỏ về Disk Group `+FRA`.
6.  **Network Configuration:** Chọn Listener đã được Grid tạo sẵn.

---

## 4. Kiểm tra thành quả

Sau khi kết thúc DBCA, hãy kiểm tra trạng thái Instance trên cả 2 node:

```bash
# Sử dụng user oracle
srvctl status database -d <Tên_DB_của_bạn>
```

Kết quả mong đợi:
```text
Instance orcl1 is running on node racnode1
Instance orcl2 is running on node racnode2
```

---

## Kết luận

Bây giờ bạn đã có một hệ thống Oracle RAC 19c 2-Node hoàn chỉnh. Bạn có thể sử dụng SQLPlus để kết nối và thực hiện các bài Lab về High Availability (HA) và Load Balancing.

> [!TIP]
> Đừng quên ghi chú lại địa chỉ SCAN IP (`192.168.56.120`) và SCAN Name để cấu hình kết nối từ máy Client (như SQL Developer).
