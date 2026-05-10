**DBWn (Database Writer)** và **LGWR (Log Writer)** là hai trong số các tiến trình nền (Background Processes) quan trọng nhất của hệ thống Oracle, hoạt động ngầm và bất đồng bộ để đồng bộ hóa dữ liệu từ bộ nhớ RAM (SGA) xuống hệ thống ổ cứng vật lý 1\.  
Cách thức hoạt động chi tiết của từng tiến trình như sau:  
**1\. Tiến trình DBWn (Database Writer)**

* **Mục đích:** Đồng bộ dữ liệu người dùng đã chỉnh sửa từ bộ đệm xuống ổ cứng 1\.  
* **Cách thức hoạt động:** Mọi thao tác thay đổi dữ liệu (DML như Insert, Update, Delete) đều không được ghi thẳng xuống đĩa cứng ngay lập tức, mà được Oracle ưu tiên thực hiện trên vùng nhớ **Database Buffer Cache** thuộc SGA để tối ưu hiệu năng I/O 2\. Các khối dữ liệu (blocks) sau khi bị chỉnh sửa tại vùng RAM này được gọi là các **Dirty blocks** 1, 2\.  
* DBWn có nhiệm vụ dọn dẹp vùng Buffer Cache bằng cách **ghi (Write) các Dirty blocks này từ RAM xuống các tệp dữ liệu vật lý (Datafiles)** nằm trên đĩa cứng 1, 3\. Quá trình này giúp dữ liệu thực tế được lưu trữ vĩnh viễn và tạo ra không gian trống trên RAM cho các dữ liệu mới được đọc lên 1\.

**2\. Tiến trình LGWR (Log Writer)**

* **Mục đích:** Ghi lại nhật ký các giao dịch để đảm bảo an toàn, không mất mát dữ liệu 1\.  
* **Cách thức hoạt động:** Mọi lịch sử thay đổi của dữ liệu (Transaction logs) đều được ghi nhận và lưu trữ tạm thời tại một vùng đệm nhỏ trên RAM gọi là **Redo Log Buffer** 2\. Tiến trình LGWR sẽ hoạt động với tốc độ rất nhanh để **đồng bộ các thông tin thay đổi này từ Redo Log Buffer xuống hệ thống ổ vật lý Redo Log files** trên đĩa 1, 3\.  
* Quá trình ghi nhận của LGWR mang tính quyết định trong việc **chốt các giao dịch (COMMIT)** 1\. Mục tiêu cao nhất là đảm bảo rằng mọi thay đổi (Commit) của người dùng đã được xác nhận sẽ an toàn tuyệt đối và không bị mất đi ngay cả khi có sự cố hệ thống (crash server) xảy ra 2, 4\.

Tóm lại, trong khi **DBWn** tập trung vào việc ghi các dữ liệu thực tế bị thay đổi xuống file lưu trữ (*Datafiles*), thì **LGWR** lại tập trung ghi nhật ký của những sự thay đổi đó xuống file log (*Redo Log files*) để bảo vệ tiến trình và phục hồi dữ liệu 1, 3\.  
