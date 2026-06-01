# Hướng Dẫn Thực Hành: Phân Biệt Common vs Local User & CDB vs PDB Table trong Oracle Multitenant

Tài liệu này cung cấp hướng dẫn chi tiết và các quy tắc thực tế (Best Practices) để xác định:
1. Khi nào sử dụng **Common User** (Người dùng chung) và **Local User** (Người dùng cục bộ).
2. Khi nào tạo bảng trong **CDB** (`CDB$ROOT`) và **PDB** (Pluggable Database).

---

## PHẦN 1: COMMON USER vs LOCAL USER

Trong môi trường Oracle Multitenant (từ phiên bản 12c trở lên), khái niệm User được phân chia làm hai cấp độ rõ rệt để đảm bảo tính cô lập và khả năng di động của dữ liệu.

```mermaid
graph TD
    subgraph CDB Root Container
        CDB[CDB$ROOT] --> CommonUser["Common User (c##tuan) <br> Có thể truy cập Root và tất cả PDBs"]
    end
    subgraph PDB 1 (Sales)
        PDB1[PDB_SALES] --> LocalUser1["Local User (sales_app) <br> Chỉ hoạt động trong PDB_SALES"]
    end
    subgraph PDB 2 (HR)
        PDB2[PDB_HR] --> LocalUser2["Local User (hr_app) <br> Chỉ hoạt động trong PDB_HR"]
    end
```

### 1. Bảng so sánh tổng quan

| Đặc điểm | Common User (Người dùng chung) | Local User (Người dùng cục bộ) |
| :--- | :--- | :--- |
| **Nơi khởi tạo** | Bắt buộc phải tạo ở `CDB$ROOT`. | Tạo bên trong một `PDB` cụ thể. |
| **Quy tắc đặt tên** | Bắt buộc bắt đầu bằng `C##` hoặc `c##` (VD: `c##monitor`). | Đặt tên tự do, không được chứa tiền tố `C##` (VD: `hr_app`). |
| **Phạm vi hoạt động** | Có thể kết nối và thao tác trên CDB và mọi PDB (nếu được gán quyền). | Chỉ tồn tại và hoạt động duy nhất bên trong PDB được tạo. |
| **Tính di động (Portability)** | Không di động. Nằm cố định ở CDB Root. | Cực kỳ di động. Tự động đi theo PDB khi PDB được Unplug/Plug. |
| **Mục đích chính** | Quản trị hệ thống, sao lưu, vá lỗi, giám sát tập trung. | Lưu trữ schema ứng dụng, xử lý nghiệp vụ phần mềm. |

---

### 2. Khi nào sử dụng Common User?

Chỉ sử dụng **Common User** khi bạn cần thực hiện các công việc quản trị ảnh hưởng đến toàn bộ hệ thống Database hoặc cần một kết nối giám sát duy nhất cho tất cả các phân vùng:

*   **Quản trị viên toàn hệ thống (Super DBA):** Các tài khoản hệ thống mặc định như `SYS` và `SYSTEM` là Common User. Khi tạo tài khoản cho các kỹ sư DBA trong công ty, bạn nên tạo dạng Common User (VD: `C##DBA_AN`) để họ có thể đăng nhập vào mọi PDB để ứng cứu sự cố mà không cần xin cấp tài khoản riêng trên từng PDB.
*   **Giám sát và thu thập thông số tập trung (Centralized Monitoring):** Khi cấu hình các công cụ giám sát (Grafana, Zabbix, Oracle Enterprise Manager), bạn cần tạo một Common User (VD: `C##MONITOR`) có quyền đọc các view hiệu năng hệ thống (`v$`, `dba_`) trên toàn bộ CDB và các PDB.
*   **Sao lưu toàn diện (RMAN Backup):** Tài khoản chạy script RMAN để thực hiện sao lưu toàn bộ dữ liệu của cả Container và các Pluggable Database.

#### 🛠️ Câu lệnh thực hành Common User (Thực hiện tại `CDB$ROOT`):
```sql
-- 1. Chuyển sang Container Root
ALTER SESSION SET CONTAINER = CDB$ROOT;

-- 2. Tạo Common User (Bắt buộc có tiền tố c## và mệnh đề CONTAINER=ALL)
CREATE USER c##sys_monitor IDENTIFIED BY "SecurePass123#" CONTAINER = ALL;

-- 3. Cấp quyền kết nối và đọc dictionary trên toàn bộ hệ thống
GRANT CREATE SESSION, SELECT ANY DICTIONARY TO c##sys_monitor CONTAINER = ALL;
```

---

### 3. Khi nào sử dụng Local User?

Hãy sử dụng **Local User** cho **99% các tài khoản nghiệp vụ thông thường**:

*   **Schema ứng dụng nghiệp vụ (Application Schemas):** Mọi tài khoản đại diện cho một phần mềm hoặc phân vùng nghiệp vụ (như `HR`, `SALES`, `KETOAN`, `CRM`) bắt buộc phải là Local User trong PDB tương ứng.
*   **Bảo mật cô lập (Isolation):** Đảm bảo nhà phát triển hoặc ứng dụng của phòng ban này không thể truy cập, can thiệp trái phép vào dữ liệu của phòng ban khác.
*   **Dễ dàng cắm rút, di chuyển (Portability):** Khi bạn cần chuyển PDB nghiệp vụ (ví dụ: `PDB_HR`) sang một máy chủ mới để nâng cấp phần cứng, tất cả Local Users và phân quyền của họ sẽ được đóng gói nguyên vẹn và đi theo PDB đó mà không gặp bất kỳ lỗi phụ thuộc nào.

#### 🛠️ Câu lệnh thực hành Local User (Thực hiện tại PDB cụ thể):
```sql
-- 1. Chuyển sang Pluggable Database tương ứng (VD: PDB1)
ALTER SESSION SET CONTAINER = pdb1;

-- 2. Tạo Local User (Tên tự do, không có tiền tố c##, không dùng CONTAINER=ALL)
CREATE USER sales_app IDENTIFIED BY "AppPassword123#";

-- 3. Cấp quyền cục bộ cho User ứng dụng
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW TO sales_app;
ALTER USER sales_app QUOTA UNLIMITED ON users;
```

---
---

## PHẦN 2: KHI NÀO TẠO BẢNG TRONG CDB vs PDB?

```
Container Database (CDB)
 ├── CDB$ROOT  <── [CHỈ CHỨA BẢNG HỆ THỐNG / METADATA]
 │
 ├── PDB_SALES <── [CHỨA BẢNG NGHIỆP VỤ: KHACH_HANG, HOA_DON...]
 │
 └── PDB_HR    <── [CHỨA BẢNG NGHIỆP VỤ: NHAN_VIEN, BAN_LUONG...]
```

> [!WARNING]
> **QUY TẮC VÀNG (GOLDEN RULE):**
> Tuyệt đối không bao giờ tạo các bảng dữ liệu nghiệp vụ của ứng dụng trong container gốc `CDB$ROOT`. `CDB$ROOT` phải được giữ sạch sẽ, chỉ chứa các đối tượng hệ thống do Oracle cung cấp.

### 1. Khi nào tạo bảng trong CDB (`CDB$ROOT`)?

Bạn hầu như **không bao giờ** chủ động tạo bảng trong CDB Root, ngoại trừ một số tình huống kỹ thuật rất đặc thù sau:

*   **Lưu trữ Log kiểm toán tập trung (Custom Auditing/Logging Tables):** Trong trường hợp DBA muốn viết một script trigger hệ thống theo dõi hành vi đăng nhập/thao tác đáng ngờ của tất cả các user trên toàn hệ thống và ghi tập trung vào một bảng để dễ quản lý.
*   **Chia sẻ dữ liệu qua Application Containers (Ứng dụng đa lớp nâng cao):** Khi bạn thiết kế một ứng dụng SaaS chạy trên nhiều PDB con, nhưng có một số bảng danh mục dùng chung (ví dụ: Bảng danh mục `QUOC_GIA`, `TINH_THANH`). Bạn có thể tạo các bảng này ở `Application Root` với thuộc tính chia sẻ liên kết dữ liệu (`SHARING = METADATA` hoặc `SHARING = DATA`). Các PDB con sẽ tự động tham chiếu đến bảng này để tránh nhân bản dữ liệu lãng phí.
*   **Hoạt động hệ thống của Oracle:** Khi Oracle thực hiện các tiến trình nâng cấp (Upgrade) hoặc vá lỗi (Patching), hệ thống sẽ tự sinh ra các bảng tạm lưu trạng thái trong `CDB$ROOT` và tự động xóa đi khi hoàn tất.

---

### 2. Khi nào tạo bảng trong PDB (Pluggable Database)?

Tất cả các bảng dữ liệu thực tế phục vụ cho ứng dụng và người dùng cuối **bắt buộc** phải được tạo bên trong PDB:

*   **Lưu trữ dữ liệu nghiệp vụ:** Các bảng chứa thông tin nghiệp vụ thực tế như `KHACH_HANG`, `DON_HANG`, `SAN_PHAM`, `NHAN_VIEN`...
*   **Độc lập và bảo mật tài nguyên lưu trữ:** Mỗi PDB sở hữu các Tablespace riêng (`SYSTEM`, `SYSAUX`, `USERS`). Tạo bảng trong PDB giúp bạn quản lý dung lượng đĩa (Disk Quota) độc lập cho từng ứng dụng, tránh trường hợp ứng dụng này bị tràn đĩa làm treo ứng dụng khác bên cạnh.
*   **Duy trì tính năng cắm rút (Portability/Pluggability):** Khi bảng được tạo trong PDB, nó sẽ gắn liền với Tablespace của PDB đó. Việc di chuyển PDB sang một hệ thống khác sẽ mang theo toàn bộ dữ liệu một cách nguyên vẹn mà không bị đứt gãy liên kết hay mất mát dữ liệu nghiệp vụ.

---

## PHẦN 3: TÓM TẮT KỊCH BẢN THỰC TẾ (BEST PRACTICES)

Giả sử công ty bạn cần triển khai 2 hệ thống: **Bán hàng (Sales)** và **Nhân sự (HR)**. Quy trình chuẩn sẽ như sau:

1.  **Bước 1:** Khởi chạy một **CDB** làm hạ tầng cơ sở chung.
2.  **Bước 2:** Khởi tạo 2 Pluggable Database độc lập: `PDB_SALES` và `PDB_HR`.
3.  **Bước 3 (Thiết lập cho Sales):** 
    *   Chuyển session vào `PDB_SALES`.
    *   Tạo Local User `sales_app`.
    *   Đăng nhập bằng `sales_app` và tạo các bảng: `KHACH_HANG`, `DON_HANG`.
4.  **Bước 4 (Thiết lập cho HR):**
    *   Chuyển session vào `PDB_HR`.
    *   Tạo Local User `hr_app`.
    *   Đăng nhập bằng `hr_app` và tạo các bảng: `NHAN_VIEN`, `BAN_LUONG`.
5.  **Bước 5 (Thiết lập Giám sát):**
    *   Chuyển session về `CDB$ROOT`.
    *   Tạo Common User `c##sys_monitor` để thu thập log hiệu năng của cả `PDB_SALES` và `PDB_HR` hiển thị lên màn hình Grafana của đội ngũ vận hành.
