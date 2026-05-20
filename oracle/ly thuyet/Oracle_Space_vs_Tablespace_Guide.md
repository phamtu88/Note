# Tài Liệu: Phân Biệt Giữa Disk Space và Tablespace Trong Oracle

Trong quá trình quản trị Oracle Database, việc nhầm lẫn giữa hai khái niệm "Space" (Disk Space) và "Tablespace" là rất phổ biến. Tài liệu này sẽ làm rõ bản chất và sự khác biệt giữa chúng.

---

## 1. Khái niệm cốt lõi

### 1.1. Space (Disk Space - Không gian đĩa cứng)
*   **Bản chất:** Là dung lượng vật lý thực tế trên thiết bị lưu trữ của máy chủ (HDD, SSD, SAN...). Nó được quản lý và hiển thị bằng số GB, TB trên hệ điều hành (Windows, Linux, Unix).
*   **Ví dụ:** Ổ đĩa `D:\` của bạn trên Windows còn trống 500GB. Đó chính là "Space".

### 1.2. Tablespace (Không gian bảng)
*   **Bản chất:** Là một khái niệm **Logic (ảo)** sinh ra bên trong phần mềm Oracle Database để phân loại và quản trị các đối tượng dữ liệu (Table, Index, View...) một cách có tổ chức.
*   Bản thân Tablespace không có khả năng tự lưu trữ trên đĩa từ. Nó bắt buộc phải liên kết với ít nhất một file vật lý trên hệ điều hành, gọi là **Datafile** (thường có đuôi `.dbf`). Chính các Datafile này mới là đối tượng trực tiếp tiêu thụ dung lượng Disk Space.

---

## 2. Phép ẩn dụ: Khu công nghiệp

Để dễ hiểu nhất về mối quan hệ giữa chúng, hãy tưởng tượng hệ thống Database như một quá trình xây dựng khu công nghiệp:
1.  **Disk Space:** Chính là **diện tích đất đai** thực tế mà bạn đang sở hữu (Ví dụ mảnh đất 100 hecta).
2.  **Tablespace:** Giống như việc bạn quy hoạch trên bản đồ thành các **"Khu vực chuyên trách"** (Ví dụ: Khu A dành riêng cho sản xuất, Khu B dành riêng cho kho bãi). Bản thân cái tên "Khu A" không chứa được đồ vật.
3.  **Datafile:** Chính là các **tòa nhà xưởng/kho bãi vật lý** được xây dựng thực tế trên mảnh đất đó để phục vụ cho từng Khu vực.

**Nguyên lý hoạt động:** Khi các nhà xưởng ở Khu A đã chứa đầy hàng hóa (Tablespace bị full), bạn cần xây thêm một nhà xưởng mới (Add thêm Datafile mới vào Tablespace). Tuy nhiên, bạn chỉ có thể xây thêm nếu mảnh đất tổng (Disk Space) vẫn còn diện tích trống.

---

## 3. Bảng so sánh chi tiết

| Tiêu chí | Disk Space (Không gian đĩa) | Tablespace (Không gian bảng) |
| :--- | :--- | :--- |
| **Cấp độ kiến trúc** | Cấp độ Vật lý (Physical) | Cấp độ Logic (Logical) |
| **Môi trường quản lý**| Hệ điều hành (OS - Windows, Linux) | Phần mềm Oracle Database |
| **Thành phần chứa** | Chứa thư mục và các loại file (bao gồm Datafile `.dbf` của Oracle) | Chứa các đối tượng của Database (Tables, Indexes, LOBs...) |
| **Trách nhiệm chính** | System Administrator (Quản trị hệ thống/Hạ tầng) | Database Administrator (DBA - Quản trị CSDL) |
| **Khả năng mở rộng** | Bị giới hạn cứng bởi dung lượng phần cứng thiết bị | Mở rộng vô hạn (miễn là Hệ điều hành vẫn còn Disk Space trống để tạo Datafile) |

---

## 4. Xử lý lỗi "Hết dung lượng" (Out of space)

Vì mối quan hệ là: **Tablespace -> chứa các Datafile -> Datafile tiêu thụ Disk Space**, nên khi ứng dụng báo lỗi không thể lưu thêm dữ liệu (thường gặp là lỗi `ORA-01653: unable to extend table...`), một DBA luôn phải kiểm tra 2 lớp:

1.  **Lớp Logic (Tablespace đã đầy chưa?)**
    *   *Xử lý:* Nếu Datafile hiện tại đã đạt đến dung lượng tối đa giới hạn (MAXSIZE), DBA cần chạy lệnh `ALTER TABLESPACE ... ADD DATAFILE ...` để gán thêm một file vật lý mới vào Tablespace.
2.  **Lớp Vật lý (Disk Space còn chỗ không?)**
    *   *Xử lý:* Nếu cấu hình cho phép Datafile tự động giãn nở (AUTOEXTEND) nhưng ổ cứng của máy chủ (Disk Space) đã đầy 100%, tiến trình ghi sẽ thất bại. Lúc này DBA cần báo cáo cho Sysadmin để xóa bớt file rác trên hệ điều hành hoặc cắm thêm ổ cứng vật lý mới.
