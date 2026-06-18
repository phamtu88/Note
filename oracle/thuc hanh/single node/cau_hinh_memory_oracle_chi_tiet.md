# Hướng Dẫn Chi Tiết Cấu Hình Memory (RAM) Cho Oracle Database

Tài liệu này đi sâu vào việc giải thích, tính toán và xử lý các lỗi liên quan đến cấu hình bộ nhớ (Memory) trong Oracle Database. Đây là một trong những thành phần quan trọng nhất quyết định hiệu năng của cơ sở dữ liệu.

## 1. Các Khái Niệm Cơ Bản

Trong Oracle Database, RAM được chia làm 2 vùng nhớ chính:

*   **SGA (System Global Area):** Vùng nhớ dùng chung cho toàn bộ Instance. Chức năng chính là cache (lưu trữ tạm) dữ liệu được truy vấn nhiều (`Database Buffer Cache`), lưu trữ các câu lệnh SQL đã biên dịch (`Shared Pool`), và bộ đệm ghi log (`Redo Log Buffer`).
*   **PGA (Program Global Area):** Vùng nhớ cấp phát **riêng** cho từng tiến trình máy chủ (Server Process) hoặc từng session kết nối. Chức năng chính là dùng làm "nháp" để thực hiện các thao tác sắp xếp (Sort), gom nhóm (Group By), Hash Join và lưu trữ các biến cục bộ.

## 2. Các Phương Pháp Quản Lý Bộ Nhớ

Trong quá trình cài đặt (hoặc khi quản trị), bạn có 2 hướng đi:

### A. Automatic Memory Management (AMM)
*   **Cách hoạt động:** Bật tùy chọn `Enable Automatic Memory Management`. Bạn chỉ cần định nghĩa một con số tổng cộng bằng tham số `MEMORY_TARGET`. Oracle sẽ tự động và liên tục "bơm" RAM qua lại giữa SGA và PGA tùy vào thời điểm DB đang cần cache nhiều dữ liệu hay đang phải xử lý nhiều câu lệnh phức tạp.
*   **Ưu điểm:** Nhàn rỗi, tối ưu tốt cho môi trường Lab, Test hoặc các hệ thống biến động không lường trước được.

### B. Automatic Shared Memory Management (ASMM) - Cấu hình thủ công
*   **Cách hoạt động:** Bạn tự tay ấn định cứng tham số `SGA_TARGET` và `PGA_AGGREGATE_TARGET`.
*   **Ưu điểm:** Phù hợp với các hệ thống lớn, quản trị viên (DBA) có kinh nghiệm muốn kiểm soát chính xác tài nguyên, đặc biệt là hệ thống có số lượng User truy cập đồng thời (CCU) cực lớn.

---

## 3. Công Thức Tính Toán & Kinh Nghiệm Thực Tế (Best Practices)

Nếu bạn chọn cấu hình thủ công (ASMM), hãy áp dụng công thức sau:

### Bước 1: Tổng RAM cho Oracle
*   Máy chủ **Dedicated** (chỉ chạy Oracle Database): Cấp tối đa **70% - 80%** tổng RAM vật lý. Phải chừa lại 20-30% cho hệ điều hành Linux/Windows hoạt động.

### Bước 2: Chia tỷ lệ SGA / PGA theo loại ứng dụng
*   **Hệ thống OLTP (Web, ERP, Thương mại điện tử...):**
    *   Đặc điểm: Truy vấn ngắn, đọc ghi theo dòng, nhiều User.
    *   Tỷ lệ chuẩn: **SGA = 80%, PGA = 20%**.
*   **Hệ thống OLAP / Data Warehouse (Hệ thống Báo cáo, Phân tích):**
    *   Đặc điểm: Ít User, truy vấn cực nặng, quét hàng triệu dòng và Sort/Join liên tục.
    *   Tỷ lệ chuẩn: **SGA = 50% - 60%, PGA = 40% - 50%**.

### Bước 3: Bài toán số lượng User (CCU) ảnh hưởng tới PGA
Trong kiến trúc Dedicated Server mặc định, mỗi user kết nối (session) sẽ sinh ra 1 tiến trình chiếm khoảng **2MB - 5MB PGA**.
*   **Công thức:** `PGA tối thiểu = (Số CCU thực tế * 3MB) + (Dung lượng dự phòng cho SQL nặng)`.
*   **Cảnh báo:** Nếu hệ thống có 1000 CCU kết nối trực tiếp, bạn sẽ tốn ngay ~3GB PGA chỉ để "chào hỏi". Để tránh điều này, ở tầng Application (Java, C#, Nodejs...) **bắt buộc phải sử dụng Connection Pooling** để giới hạn số kết nối thật tới DB xuống khoảng 50 - 200 connection.

### 💡 Ví Dụ Thực Tế
Giả sử bạn có **Server 16GB RAM**, chạy App bán hàng (OLTP) với **500 CCU**.
1.  **Tổng RAM Oracle:** `16GB * 75% = 12GB` (Còn 4GB cho OS).
2.  **Chia tỷ lệ (80/20):** `SGA = 12GB * 80% = 9.6GB` và `PGA = 12GB * 20% = 2.4GB`.
3.  **Kiểm tra PGA:** 500 CCU * 3MB = 1.5GB. Mức PGA 2.4GB hoàn toàn đáp ứng tốt và còn dư ~1GB dự phòng.

---

## 4. Các Lỗi "Chết Người" Ngăn Chặn Database Khởi Động

Nếu thiết lập sai cấu hình RAM, khi khởi động (Startup), Database sẽ lập tức báo lỗi. Dưới đây là 2 lỗi phổ biến nhất:

### Lỗi 1: `ORA-00845: MEMORY_TARGET not supported on this system`
*   **Nguyên nhân:** Lỗi kinh điển khi bật **AMM** trên Linux. Oracle trên Linux sử dụng thư mục RAM ảo chia sẻ `/dev/shm` (tmpfs). Nếu bạn cấp tham số `MEMORY_TARGET` lớn hơn dung lượng hiện tại của thư mục `/dev/shm`, Oracle sẽ từ chối khởi động.
*   **Cách khắc phục:** 
    1. Kiểm tra dung lượng hiện tại: `df -h /dev/shm`
    2. Tăng dung lượng `/dev/shm` trên OS (Ví dụ tăng lên 12GB):
       Gõ lệnh bằng quyền root: `mount -o remount,size=12G /dev/shm`
    3. Để lưu vĩnh viễn, thêm vào file `/etc/fstab`: `tmpfs /dev/shm tmpfs size=12G 0 0`

### Lỗi 2: `ORA-27102: out of memory`
*   **Nguyên nhân:** Xảy ra khi cấu hình thủ công (ASMM) mà bạn gõ nhầm hoặc "tham lam" cấp tổng `SGA + PGA` vượt quá dung lượng RAM vật lý còn trống của máy chủ. Hoặc do các tham số giới hạn bộ nhớ của nhân Linux (`kernel.shmmax`, `kernel.shmall` trong `/etc/sysctl.conf`) được set quá thấp.
*   **Cách khắc phục:** Chỉnh sửa file khởi tạo (pfile) để giảm dung lượng SGA/PGA xuống cho phù hợp với phần cứng, sau đó cấu hình lại tham số Kernel trên OS cho đồng bộ.

---

## 5. Thay Đổi Cấu Hình Sau Khi Cài Đặt (Không Cần Cài Lại)
Bạn không bị "khóa cứng" vào thiết lập lúc cài đặt. Khi hệ thống vận hành và có sự thay đổi về tài nguyên, bạn có thể dễ dàng thay đổi nóng (Dynamic) không cần khởi động lại bằng lệnh SQL:

```sql
-- Thay đổi SGA (Có tác dụng ngay lập tức)
ALTER SYSTEM SET sga_target = 10G SCOPE=BOTH;

-- Thay đổi PGA (Có tác dụng ngay lập tức)
ALTER SYSTEM SET pga_aggregate_target = 3G SCOPE=BOTH;
```
*(Lưu ý: Các thay đổi này chỉ có tác dụng "nóng" miễn là bạn không đẩy nó vượt quá giới hạn cứng `SGA_MAX_SIZE` hoặc `PGA_AGGREGATE_LIMIT`)*.
