# Tổng Quan Cấu Hình VM Server Oracle Linux cho Database

Việc chuẩn bị kỹ lưỡng cấu hình Virtual Machine (VM) ngay từ đầu là một bước rất quan trọng để đảm bảo server Oracle Database hoạt động ổn định và có hiệu năng tốt, đồng thời tuân thủ chuẩn **OFA (Optimal Flexible Architecture)** của Oracle.

Dưới đây là một cấu hình chuẩn và chuyên nghiệp (Best Practice) có thể áp dụng cho máy ảo trên VMware Workstation để cài Oracle Linux (thường là bản 8.x hoặc 9.x) và Oracle Database (như bản 19c).

### 1. Cấu hình phần cứng (VM Hardware Settings)

Trước khi cài hệ điều hành, bạn hãy cấu hình máy ảo với các thông số sau:

*   **CPU (Processors):** Tối thiểu **2 Cores**, khuyến nghị **4 Cores** trở lên giúp quá trình cài đặt db và compile nhanh hơn.
*   **Memory (RAM):**
    *   Tối thiểu: **4 GB** (chỉ đủ để dựng lên học tập, có thể hơi chậm).
    *   **Khuyến nghị: 8 GB đến 16 GB** (để setup SGA/PGA thoải mái và DB chạy mượt mà).
*   **Network Adapter:** Nên đặt ở chế độ **NAT** hoặc **Bridged**. Khuyến nghị cấu hình một địa chỉ **IP tĩnh (Static IP)** cho VM ngay khi cài OS để tránh rắc rối về listener sau này.

---

### 2. Chiến lược chia ổ đĩa cứng (Virtual Disks)

Thay vì tạo 1 ổ cứng ảo (Virtual Disk) lớn có dung lượng 100GB hay 200GB, cách làm chuẩn nhất cho server Database là **tạo nhiều ổ cứng ảo tách biệt**. Điều này giúp bạn dễ dàng quản lý IO, mở rộng dung lượng (resize disk) mà không ảnh hưởng tới hệ điều hành.

Trong VMware, bạn hãy thêm vào (Add Hardware) các ổ đĩa sau:

| Ổ đĩa ảo (Disk) | Kích thước đề xuất | Mục đích sử dụng | Thiết bị (Device name) trong Linux |
| :--- | :--- | :--- | :--- |
| **Disk 1** | 40GB - 50GB | Dành riêng cho OS (Hệ điều hành Linux) | `/dev/sda` |
| **Disk 2** | 30GB - 40GB | Dành chứa source cài đặt, bin Oracle (`/u01`) | `/dev/sdb` |
| **Disk 3** | Tùy nhu cầu (Vd: 50GB+) | Dành cho Datafiles, Control files (`/u02`) | `/dev/sdc` |
| **Disk 4** (Tùy chọn) | Tùy nhu cầu (Vd: 30GB+) | Dành cho Archive Logs, Backup, RMAN (`/u03`) | `/dev/sdd` |

---

### 3. Cấu hình phân vùng (Partitioning Scheme) lúc cài đặt Oracle Linux

Khi bước vào màn hình cài đặt Oracle Linux, ở phần **Installation Destination**, chọn "Custom" (Tự phân vùng) và thiết lập như sau (Nên sử dụng **LVM - Logical Volume Manager** cho sự linh hoạt):

#### A. Đối với Disk 1 (`/dev/sda` - OS Disk)
*   `/boot`: **1 GB** (Định dạng XFS hoặc EXT4, Standard Partition - *không* rớt vào LVM).
*   `swap`: Kích thước phụ thuộc vào RAM bạn cấp. Quy tắc của Oracle:
    *   Nếu RAM từ 1GB - 2GB: Swap = RAM x 1.5
    *   Nếu RAM từ 2GB - 16GB: **Swap = Bằng đúng dung lượng RAM** (VD: Nếu cấp 8GB RAM thì phân vùng swap là 8GB).
    *   Nếu RAM > 16GB: Swap = 16 GB.
*   `/` (Root): **Phần dung lượng còn lại** của Disk 1 (Định dạng XFS, nằm trong Volume Group của OS).

#### B. Đối với Disk 2 (`/dev/sdb` - Oracle Software)
*   **Mount Point:** `/u01`
*   **Dung lượng:** 100% của Disk 2.
*   **Định dạng:** XFS.
*   **Mục đích:** Đây sẽ là thư mục gốc của Oracle (ORACLE_BASE). Oracle Database software binaries (ORACLE_HOME) sẽ được cài đặt vào trong thư mục này (ví dụ: `/u01/app/oracle/product/19.0.0/dbhome_1`).

#### C. Đối với Disk 3 (`/dev/sdc` - Oracle Data)
*   **Mount Point:** `/u02` (hoặc `/oradata`)
*   **Dung lượng:** 100% của Disk 3.
*   **Định dạng:** XFS.
*   **Mục đích:** Đường dẫn lưu trữ dữ liệu (Datafiles, Tempfiles, Redo logs).

#### D. Đối với Disk 4 (`/dev/sdd` - Fast Recovery Area / Backups) - Tùy chọn
*   **Mount Point:** `/u03` (hoặc `/fast_recovery_area`)
*   **Dung lượng:** 100% của Disk 4.
*   **Định dạng:** XFS.
*   **Mục đích:** Dành cho việc lưu Archived Redo Logs và cấu hình Fast Recovery Area (FRA).
