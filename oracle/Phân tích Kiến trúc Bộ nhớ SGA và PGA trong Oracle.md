Trong kiến trúc bộ nhớ của Oracle Database, **SGA (System Global Area)** và **PGA (Program Global Area)** là hai vùng bộ nhớ chính được thiết kế phục vụ các mục đích hoàn toàn khác biệt 1\.  
Dưới đây là những điểm khác biệt cốt lõi giữa hai vùng nhớ này:  
**1\. Tính chất chia sẻ và đối tượng phục vụ**

* **SGA:** Là **vùng bộ nhớ dùng chung (Shared)**. SGA chịu trách nhiệm lưu trữ các cấu trúc điều khiển và chia sẻ dữ liệu chung cho tất cả các tiến trình (processes) đang hoạt động trong hệ thống 2\.  
* **PGA:** Là **vùng bộ nhớ dành riêng (không chia sẻ)**. Vùng nhớ này là không gian hoạt động nội bộ độc lập dành cho mỗi Server Process 3\.

**2\. Thời điểm cấp phát bộ nhớ**

* **SGA:** Được hệ thống cấp phát ngay khi **Oracle Instance bắt đầu khởi động** 2\.  
* **PGA:** Được khởi tạo và cấp phát động mỗi khi một **Server Process mới được tạo ra** để xử lý các yêu cầu từ User Process 3, 4\.

**3\. Chức năng chính và các thành phần bên trong**

* **SGA (Tối ưu hóa tổng thể và lưu trữ chung):** Bao gồm nhiều vùng đệm lớn để giảm thiểu việc đọc/ghi trực tiếp lên ổ cứng cứng vật lý 2\. Các vùng quan trọng nhất gồm:  
* **Shared Pool:** Chứa *Library Cache* (lưu trữ mã lệnh Parsed SQL, Execution Plan để tái sử dụng) và *Data Dictionary Cache / Row Cache* (chứa Metadata/dữ liệu đặc tả về cấu trúc database) giúp rút ngắn thời gian máy chủ phải tự đọc file vật lý 2, 5-7.  
* **Database Buffer Cache:** Nơi chứa các block dữ liệu được đọc lên từ ổ cứng; mọi thao tác chỉnh sửa dữ liệu DML (như Insert, Update, Delete) đều được thực hiện trực tiếp tại đây trên bộ RAM 2\.  
* **Redo Log Buffer:** Bộ đệm tạm thời chứa thông tin thay đổi dữ liệu (Transaction logs) trước khi tiến trình chốt giao dịch ghi chúng xuống đĩa cứng để tránh mất mát dữ liệu 2\.  
* **Các thành phần khác:** Large Pool, Java Pool, Streams Pool, In-Memory Column Store 2\.  
* **PGA (Xử lý cục bộ và duy trì phiên làm việc):** Chuyên phục vụ để xử lý các câu lệnh và duy trì trạng thái của từng phiên người dùng độc lập 3\. Bao gồm các vùng như:  
* **Session Memory (Session Data):** Lưu trữ thông tin đăng nhập, biến cấp phiên (session variables) và trạng thái hiện tại của session đó 3, 8\.  
* **SQL Work Areas / Sort Areas:** Cung cấp bộ nhớ động để thực thi các tác vụ lập trình chuyên dụng tốn tài nguyên trên RAM, ví dụ như thao tác sắp xếp phân loại (ORDER BY, GROUP BY) hay các thuật toán ghép bảng phức tạp (Hash Join, Bitmap Merge) 3, 8\.  
* **Stack Space:** Không gian cấu trúc ngăn xếp dùng cho xử lý nội bộ của tiến trình 8\.

Tóm lại, **SGA** là nguồn tài nguyên công cộng trung tâm của toàn bộ hệ thống Oracle nhằm chia sẻ thông tin và tăng tốc độ xử lý I/O, trong khi **PGA** là không gian làm việc riêng biệt, khép kín để mỗi tiến trình Server Process thực hiện các phép toán và duy trì phiên kết nối riêng của mình 2, 3\.  
