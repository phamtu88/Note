# SMON (System Monitor) trong Oracle Database

## 1. Định nghĩa
**SMON** (viết tắt của **System Monitor**) là tiến trình nền chịu trách nhiệm quản lý và bảo trì toàn bộ hệ thống cơ sở dữ liệu ở cấp độ instance.

## 2. Chức năng chính
*   **Instance Recovery (Khôi phục Instance):** Khi database khởi động lại sau một sự cố sập nguồn hoặc tắt không đúng cách, SMON sẽ thực hiện quá trình khôi phục:
    *   Roll forward các thay đổi trong Redo Logs nhưng chưa được ghi vào Data Files.
    *   Sau đó mở Database cho người dùng vào.
    *   Cuối cùng là Rollback các giao dịch chưa được commit (với sự trợ giúp của PMON).
*   **Dọn dẹp các Segment tạm:** Giải phóng các phân đoạn (segments) tạm thời không còn được sử dụng (thường tạo ra do các lệnh sắp xếp dữ liệu lớn).
*   **Gộp các khoảng trống (Coalesce):** Gộp các vùng không gian trống (free extents) liền kề nhau trong các tablespace để tối ưu hóa việc cấp phát không gian mới.

## 3. Tầm quan trọng
SMON đảm bảo cho cơ sở dữ liệu luôn ở trạng thái khỏe mạnh và nhất quán. Nó làm việc âm thầm phía sau để bảo trì cấu trúc vật lý và logic của database, đồng thời là "người hùng" giúp hệ thống tự chữa lành sau mỗi lần gặp sự cố lớn.

---
*Tài liệu được tạo tự động bởi Antigravity.*
