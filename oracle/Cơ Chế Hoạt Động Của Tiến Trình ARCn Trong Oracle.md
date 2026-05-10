Tiến trình **ARCn (Archiver / Redo Background)** sẽ thực hiện sao lưu log dựa trên các điều kiện và thời điểm cụ thể sau:

* **Điều kiện tiên quyết:** Hệ thống cơ sở dữ liệu (Database) phải được thiết lập cấu hình ở chế độ **ARCHIVELOG** 1\.  
* **Thời điểm kích hoạt:** ARCn sẽ thực hiện công việc của mình khi các tệp **Redo Logs đã vận hành đầy** 1\.  
* **Cách thức thực hiện:** Tại thời điểm Redo Logs đầy, tiến trình ARCn sẽ tiến hành copy và đẩy các bản ghi log này sang một không gian ổ chứa backup dạng ngoại tuyến 1\. Hành động này bắt buộc phải diễn ra **trước khi tiến trình LGWR quay vòng và ghi đè** lên các file Redo Logs này, nhằm đảm bảo không bị mất đi các dữ liệu giao dịch cũ 1\.

