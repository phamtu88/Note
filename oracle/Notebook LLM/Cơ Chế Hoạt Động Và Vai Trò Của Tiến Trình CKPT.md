Tiến trình **CKPT (Checkpoint Process)** sẽ thực hiện cập nhật **Control Files** mỗi khi có **chu kỳ báo hiệu (signaling checkpoints) xác nhận rằng các thao tác ghi dữ liệu từ vùng đệm (RAM) xuống đĩa cứng đã hoàn tất** 1, 2\.  
Cụ thể, trong quá trình này, CKPT sẽ thực hiện các nhiệm vụ:

* **Cập nhật trạng thái vào Control Files:** Tiến trình sẽ ghi lại thông tin về **trạng thái Checkpoint** và **chỉ số thời gian điểm chốt hệ thống (SCN \- System Change Number)** vào Control Files, nơi được xem là "bộ não" lưu trữ sơ yếu lý lịch để kiểm soát trạng thái vật lý của toàn bộ cơ sở dữ liệu 1, 3\.  
* **Cập nhật phần đầu (headers) của Datafiles:** Bên cạnh Control Files, CKPT cũng đồng thời cập nhật mốc thời gian điểm chốt/SCN này vào phần header của các tệp lưu trữ dữ liệu thực tế **Datafiles** 1\.

Như chúng ta đã trao đổi ở phần trước về chức năng của các tiến trình nền, hoạt động của CKPT có sự liên kết chặt chẽ với tiến trình **DBWn (Database Writer)**. Sau khi DBWn hoàn thành nhiệm vụ đồng bộ các khối dữ liệu bị chỉnh sửa (Dirty blocks) từ bộ đệm Database Buffer Cache xuống ổ cứng một cách an toàn, tiến trình CKPT sẽ đứng ra làm nhiệm vụ "đánh dấu" cột mốc hoàn tất này để hệ thống luôn được kiểm soát chặt chẽ và nhất quán 1\.  
