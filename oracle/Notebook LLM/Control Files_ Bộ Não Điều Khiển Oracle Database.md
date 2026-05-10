Trong kiến trúc lưu trữ của Oracle Database, **Control Files (.ctl)** tuy là những tệp có kích thước nhỏ nhưng lại đóng vai trò cực kỳ quan trọng, được ví như "bộ não" kiểm soát toàn bộ trạng thái vật lý của hệ thống cơ sở dữ liệu 1\.  
Control Files hoạt động như một bản "sơ yếu lý lịch" của Database, chuyên lưu giữ các luồng thông tin cốt lõi sau đây:

* **Vị trí của các tệp lưu trữ:** Ghi nhận và theo dõi đường dẫn vị trí vật lý của các tệp chứa dữ liệu thực tế (**Datafiles**) và các tệp nhật ký giao dịch (**Redo Log files**) 1\.  
* **Chỉ số thay đổi hệ thống (SCN \- System Change Number):** Lưu giữ chỉ số SCN hiện tại của toàn bộ hệ thống để đảm bảo tính đồng bộ 1\.  
* **Trạng thái Checkpoint:** Như chúng ta đã thảo luận trước đó, mỗi khi tiến trình **CKPT** báo hiệu việc ghi dữ liệu từ bộ đệm RAM xuống đĩa cứng đã hoàn tất, trạng thái Checkpoint và mốc thời gian tương ứng sẽ được cập nhật và lưu giữ tại Control Files 1, 2\.  
* **Thông tin sao lưu (Backup Metadata):** Lưu trữ các dữ liệu đặc tả (Metadata) liên quan đến tiến trình sao lưu và khôi phục của cơ sở dữ liệu 1\.

Nhờ những thông tin cấu trúc nền tảng này, Control Files giúp Oracle Database nhận diện chính xác trạng thái của hệ thống và điều phối an toàn các tác vụ phục hồi hoặc khởi động dữ liệu.  
