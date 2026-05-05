# RTO và RPO trong Kế hoạch Phục hồi Thảm họa (Disaster Recovery)

Khi xây dựng các chiến lược sao lưu (Backup) và phục hồi (Recovery) cho Cơ sở dữ liệu, hai chỉ số quan trọng nhất mà mọi người quản trị (DBA) hay kiến trúc sư hệ thống phải quan tâm là **RTO** và **RPO**. Đây là những thỏa thuận mức dịch vụ (SLA - Service Level Agreement) giữa bộ phận IT và doanh nghiệp.

---

## 1. RTO - Recovery Time Objective (Mục tiêu Thời gian Phục hồi)

**RTO là khoảng thời gian tối đa được phép trôi qua kể từ lúc hệ thống gặp sự cố cho đến khi hệ thống hoạt động trở lại.**
Nói cách khác: *"Hệ thống được phép sập tối đa trong bao lâu trước khi gây ra thiệt hại nghiêm trọng cho doanh nghiệp?"*

* **Ví dụ:** Nếu doanh nghiệp quy định RTO là **4 giờ**, điều đó có nghĩa là nếu Database bị sập lúc 8:00 sáng, bộ phận IT phải tìm cách sửa chữa, khôi phục dữ liệu, đưa hệ thống online trở lại chậm nhất là 12:00 trưa.
* **Đại diện cho:** Thời gian ngừng hoạt động (Downtime).
* **Công cụ trong Oracle giúp giảm RTO:** 
  * Oracle RAC (Real Application Clusters) giúp hệ thống không bị downtime khi một server chết (RTO gần bằng 0 cho sự cố phần cứng Node).
  * Data Guard (Active Data Guard) giúp chuyển đổi (Failover) sang server dự phòng rất nhanh (RTO tính bằng phút).
  * RMAN (Càng nhiều dữ liệu, RTO khi dùng RMAN để restore càng lâu).

## 2. RPO - Recovery Point Objective (Mục tiêu Điểm Phục hồi)

**RPO là lượng dữ liệu tối đa (đo bằng thời gian) mà doanh nghiệp chấp nhận có thể bị mất mát khi sự cố xảy ra.**
Nói cách khác: *"Khi hệ thống được khôi phục, dữ liệu bị mất lùi về quá khứ tối đa bao nhiêu lâu?"*

* **Ví dụ:** Nếu doanh nghiệp quy định RPO là **1 giờ**, hệ thống gặp sự cố lúc 10:00 sáng, thì khi khôi phục lại, dữ liệu bắt buộc phải đảm bảo trọn vẹn ít nhất đến 9:00 sáng. (Chấp nhận mất trắng toàn bộ giao dịch từ 9:00 đến 10:00).
* **Đại diện cho:** Mức độ mất mát dữ liệu (Data Loss).
* **Công cụ trong Oracle giúp giảm RPO:**
  * Đồng bộ hóa dữ liệu thời gian thực bằng **Oracle Data Guard (Synchronous mode)** (RPO = 0, không mất một byte dữ liệu nào).
  * Tần suất chạy backup RMAN liên tục (Backup Archive Log mỗi giờ sẽ giúp RPO nằm trong khoảng 1 giờ).
  * Oracle GoldenGate.

---

## 3. Tóm tắt sự khác biệt qua ví dụ thực tế

Giả sử bạn đang gõ một file báo cáo Word (Word Document):
- Nếu 1 tiếng đồng hồ bạn bấm "Save" một lần, và đột nhiên máy tính bị cúp điện. Bạn bị mất toàn bộ nội dung đã gõ trong 1 tiếng vừa rồi => **RPO của bạn là 1 giờ**.
- Sau khi có điện lại, bạn mất 15 phút để khởi động máy tính, bật lại Word và mở lại file báo cáo cũ đó lên => **RTO của bạn là 15 phút**.

## 4. Mối quan hệ giữa RTO, RPO và Chi phí
Quy tắc vàng: **RTO và RPO càng tiến gần về 0 thì chi phí đầu tư càng đắt đỏ theo cấp số nhân.**

1. **RTO / RPO cao (Vài giờ đến vài ngày):** 
   - Giải pháp: Chỉ cần Backup định kỳ (RMAN Full + Incremental) ra ổ cứng hoặc Tape.
   - Chi phí: Rất rẻ.
2. **RTO / RPO trung bình (Vài chục phút):**
   - Giải pháp: Replication bất đồng bộ (Asynchronous Data Guard).
   - Chi phí: Trung bình (cần thêm Server phụ).
3. **RTO = 0 / RPO = 0 (Không mất dữ liệu, Không có downtime):**
   - Giải pháp: Chạy song song Oracle RAC (chống chết Server) + Active Data Guard đồng bộ (chống sập cả trung tâm dữ liệu).
   - Chi phí: Cực kỳ đắt (Cần mua nhiều License, Server cấu hình khủng, đường truyền mạng tốc độ cực cao giữa 2 Data Center).
