# PMON (Process Monitor) trong Oracle Database

## 1. Định nghĩa
**PMON** (viết tắt của **Process Monitor**) là tiến trình nền giám sát các tiến trình người dùng và thực hiện dọn dẹp khi có sự cố xảy ra.

## 2. Chức năng chính
*   **Dọn dẹp tiến trình lỗi:** Khi một kết nối người dùng (user process) bị ngắt đột ngột hoặc bị lỗi, PMON sẽ phát hiện và thực hiện:
    *   Rollback các giao dịch chưa được commit của người dùng đó.
    *   Giải phóng các khóa (locks) mà người dùng đang giữ.
    *   Giải phóng tài nguyên bộ nhớ (SGA/PGA) mà tiến trình đó đang chiếm dụng.
*   **Đăng ký dịch vụ với Listener:** PMON định kỳ thông báo thông tin về Instance và các dịch vụ cho Oracle Net Listener để người dùng có thể kết nối vào database.
*   **Khởi động lại các tiến trình nền:** Nếu một số tiến trình nền không bắt buộc bị lỗi, PMON có thể thử khởi tạo lại chúng.

## 3. Tầm quan trọng
PMON giống như một "nhân viên dọn dẹp" và "người quản lý tài nguyên". Nếu không có PMON, các lỗi kết nối từ phía người dùng sẽ khiến tài nguyên hệ thống bị rò rỉ và database sẽ sớm bị treo do hết tài nguyên hoặc bị khóa chết (deadlock).

---
*Tài liệu được tạo tự động bởi Antigravity.*
