**Shared Pool** đóng vai trò là vùng nhớ cốt lõi nằm trong SGA giúp **tối ưu hóa độ phản hồi của các câu truy vấn** 1, 2\. Vai trò quan trọng này được thực hiện chủ yếu thông qua hai thành phần cấu trúc bên trong nó:  
**1\. Data Dictionary Cache (còn gọi là Row Cache)**

* **Lưu trữ dữ liệu đặc tả (Metadata):** Đây là vùng nhớ đệm trên bộ RAM chuyên dùng để chứa thông tin định nghĩa về cấu trúc của cơ sở dữ liệu, bao gồm danh sách các bảng, cột, kiểu dữ liệu, index và quyền hạn của user 1, 3, 4\. Vùng này được gọi là Row Cache vì dữ liệu được tổ chức lưu trữ theo từng hàng (row) thay vì từng block 4\.  
* **Tránh hiện tượng thắt cổ chai I/O:** Bất cứ khi nào một câu lệnh SQL được chạy, Oracle bắt buộc phải kiểm tra tính hợp lệ của câu lệnh đó (ví dụ: bảng có tồn tại không, user có quyền xem không) 4\. Việc lưu trữ sẵn các thông tin kiểm tra này trên Data Dictionary Cache giúp máy chủ tra cứu ngay lập tức, rút ngắn đáng kể thời gian so với việc phải liên tục tìm kiếm và đọc các file cấu trúc vật lý tốc độ chậm từ ổ cứng 1, 4\.

**2\. Library Cache**

* **Lưu trữ Mã nguồn và Kế hoạch thực thi:** Lần đầu tiên một câu lệnh được thực thi (Hard Parse), Oracle phải trải qua nhiều bước tiêu tốn thời gian và CPU như kiểm tra cú pháp, ngữ nghĩa, và đặc biệt là phân tích (Optimizer) để tìm ra **Kế hoạch thực thi (Execution Plan)** tốt nhất, ngắn nhất nhằm lấy ra dữ liệu 5, 6\. Toàn bộ "bản dịch" của câu lệnh (mã **Parsed SQL/PL-SQL**) và Kế hoạch thực thi này sẽ được hệ thống cất giữ tại Library Cache 1, 5, 6\.  
* **Tái sử dụng để tăng tốc truy vấn:** Nhờ có sự tồn tại của Library Cache, nếu bạn hoặc bất kỳ người dùng nào khác chạy lại chính câu lệnh y hệt, Oracle sẽ không cần phân tích lại từ đầu mà chỉ việc lấy "bản dịch" đã lưu sẵn ra để xài luôn (Soft Parse) 5, 7\. Cơ chế này bỏ qua các bước kiểm tra tốn kém, giúp tăng tốc độ thao tác lên cực nhanh 5, 7\.

**Ví dụ thực tế về luồng xử lý liên kết của Shared Pool:**Khi có một truy vấn SELECT được gửi tới, Oracle sẽ dùng **Row cache** để kiểm chứng Metadata, sau đó lập một **Execution Plan** tốt nhất, "dịch" câu lệnh thành **Parsed SQL** và cuối cùng lưu tất cả vào **Library Cache** trên RAM để sẵn sàng tái sử dụng cho các lần gọi lệnh tiếp theo 7\.  
