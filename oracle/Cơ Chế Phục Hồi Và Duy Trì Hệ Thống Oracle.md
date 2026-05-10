**SMON (System Monitor)** và **PMON (Process Monitor)** là hai tiến trình nền thiết yếu trong hệ thống Oracle, đóng vai trò như những "người dọn dẹp và y tá" giúp hệ thống tự động phục hồi và duy trì sự ổn định khi xảy ra sự cố 1, 2\.  
Dưới đây là cách thức hoạt động cụ thể của từng tiến trình:  
**1\. Tiến trình SMON (Phục hồi ở cấp độ Hệ thống \- Instance)**SMON tập trung vào việc tự vá lỗi và dọn dẹp tổng thể cho toàn bộ hệ thống cơ sở dữ liệu:

* **Phục hồi Instance (Instance Recovery):** Khi máy chủ bị tắt đột ngột (crash) do mất điện hoặc lỗi phần cứng, lúc khởi động lại, SMON sẽ tự động kích hoạt để "chữa lành" hệ thống. Nó sẽ sử dụng các bản ghi nhật ký (Redo) để chạy lại các giao dịch đã hoàn tất nhưng chưa kịp ghi xuống đĩa, đồng thời loại bỏ (rollback) những dữ liệu rác, đang xử lý dang dở (uncommitted) để đảm bảo tính nhất quán của dữ liệu 1, 2\.  
* **Dọn dẹp không gian tạm (Temporary Segment):** Trong quá trình vận hành, hệ thống thường tạo ra các phân vùng tạm thời để xử lý dữ liệu. Khi không còn sử dụng nữa, SMON sẽ đi thu dọn các không gian dư thừa này để trả lại tài nguyên cho cơ sở dữ liệu 1\.

**2\. Tiến trình PMON (Phục hồi ở cấp độ Tiến trình \- Process)**Trong khi SMON lo cho toàn bộ hệ thống, thì PMON lại tập trung giám sát và dọn dẹp hậu quả của các phiên làm việc (sessions) hoặc tiến trình người dùng (User processes) cụ thể bị lỗi:

* **Dọn dẹp sau sự cố người dùng:** Khi một kết nối bị ngắt đột ngột (do rớt mạng, tắt ứng dụng ngang, hoặc dead process), tiến trình Server Process phục vụ cho người dùng đó bị bỏ lại trạng thái treo 1\.  
* **Giải phóng tài nguyên:** PMON sẽ phát hiện các tiến trình "chết" này để tiến hành dọn dẹp vùng nhớ RAM (trong PGA/SGA) đang bị dư thừa 1\.  
* **Tháo gỡ khóa (Lock release):** Quan trọng nhất, nếu tiến trình bị lỗi đang khóa (lock) một số khối dữ liệu (blocks) không cho người khác sửa, PMON sẽ can thiệp để tháo gỡ các khóa này, giúp các người dùng khác có thể tiếp tục truy cập và thao tác bình thường mà không bị kẹt 1\.

Tóm lại, **SMON** là tiến trình cấp cứu toàn cục cứu sống hệ thống sau các đợt sập nguồn, còn **PMON** là quản quản lý vi mô đi dọn dẹp rác bộ nhớ và tháo gỡ các tắc nghẽn cục bộ do lỗi rớt mạng của từng người dùng gây ra 1, 2\.  
