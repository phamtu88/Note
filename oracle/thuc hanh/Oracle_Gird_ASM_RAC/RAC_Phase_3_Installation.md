# Giai đoạn 3: Cài đặt (Installation)

Giai đoạn này tập trung vào quy trình chạy các bộ cài đặt đồ họa (OUI) và cấu hình cụm Cluster.

---

## 1. Cài đặt Grid Infrastructure (GI) 19c
Đây là bước quan trọng nhất, thiết lập "linh hồn" của hệ thống RAC.

### 1.1 Chuẩn bị bộ cài
*   Download file zip Grid Infrastructure 19c.
*   Giải nén **trực tiếp** vào thư mục `GRID_HOME` đã tạo ở Phase 2 (VD: `/u01/app/19.3.0/grid`).
*   **Lưu ý:** Không giải nén ở chỗ khác rồi copy vào, vì sẽ mất các thuộc tính file.

### 1.2 Chạy bộ cài
Sử dụng user `grid`:
```bash
cd /u01/app/19.3.0/grid
./gridSetup.sh
```

### 1.3 Các tùy chọn quan trọng trong Wizard:
1. **Configuration Option:** Chọn "Configure Grid Infrastructure for a New Cluster".
2. **Cluster Configuration:** Chọn "Configure a Standard Cluster".
3. **Grid Plug and Play:** Đặt Cluster Name (VD: `oracle-cluster`) và SCAN Name (VD: `oracle-scan`). SCAN Port giữ nguyên 1521.
4. **Cluster Node Information:** Nhấn **Add...** để thêm Node 2 (`oracle2`, `oracle2-vip`).
5. **Network Interface:** Xác định đúng card mạng nào là **Public** và card nào là **ASM & Private**.
6. **Storage Option:** Chọn "Use Oracle ASM filter driver" hoặc "ASM".
7. **Create ASM Disk Group:**
   - Disk group name: `OCR` (hoặc `SYSTEM`).
   - Redundancy: `External` (Vì ta dùng đĩa ảo đơn).
   - **Disk Discovery Path:** Phải điền `/dev/oracleasm/*`.
   - Chọn ổ đĩa tương ứng với `ocr1`.
8. **Root Script execution:** Bạn có thể điền mật khẩu root để bộ cài tự chạy script, hoặc chạy thủ công khi được nhắc.

---

## 2. Cài đặt Oracle Database Software
Sau khi Clusterware đã chạy (trạng thái `realiable`), ta cài đặt phần mềm Database.

1. Login bằng user `oracle`.
2. Giải nén bộ cài Database vào thư mục tạm hoặc Home.
3. Chạy `./runInstaller`.
4. Chọn **Set Up Software Only**.
5. Chọn **Oracle Real Application Clusters database installation**.
6. Chọn cả 2 Node trong danh sách Cluster.

---

## 3. Tạo Cơ sở dữ liệu RAC (DBCA)
Sử dụng công cụ đồ họa để tạo Database dùng chung trên ASM.

1. Chạy lệnh `dbca` bằng user `oracle`.
2. Chọn **Create Database** -> **Advanced Configuration**.
3. **Storage Type:** Chọn **Automatic Storage Management (ASM)**.
4. **Disk Group:** Chọn Disk Group `DATA` (Bạn có thể cần tạo Group này trước trong ASM Configuration Assistant - `asmca` nếu chưa có).
5. Đảm bảo cấu hình **Management Options** để giám sát cluster.

---
> [!SUCCESS]
> Chúc mừng bạn! Sau khi hoàn thành Giai đoạn 3, bạn đã có một hệ thống Oracle 19c RAC hoàn chỉnh trên môi trường VMware.
