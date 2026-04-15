# Các Khái niệm Cơ sở: Oracle Grid Infrastructure và Oracle RAC

Trong kiến trúc hệ thống Oracle Database nâng cao, mọi người rất hay nhầm lẫn giữa hai khái niệm Grid và RAC. Tài liệu này sẽ phân tích sự khác biệt cốt lõi và mối quan hệ tương hỗ của chúng.

---

## 1. Oracle Grid Infrastructure (Grid) là gì?
**Grid đóng vai trò là "nền móng hạ tầng mạng và lưu trữ".** Bạn bắt buộc phải cài đặt xong Grid thì mới có thể tính đến chuyện dùng RAC.

Grid bao gồm 2 thành phần chính:
- **Oracle Clusterware**: Là phần mềm kết nối 2 hoặc nhiều máy chủ vật lý/ảo hóa (Nodes) lại với nhau thành một "Cụm" (Cluster) duy nhất. Nó liên tục giám sát trạng thái của các Server, phát hiện lỗi và tự động thực hiện chuyển đổi dự phòng (Failover).
- **Oracle ASM (Automatic Storage Management)**: Là hệ quản trị tệp tin và volume độc quyền của Oracle. Nó nhận các ổ cứng vật lý (như ổ chia sẻ trên SAN hoặc VMware) và gộp chúng lại, quản lý việc đọc/ghi tập trung một cách an toàn và hiệu suất cao.

> [!NOTE]
> Ngay cả khi bạn chỉ có **1 máy chủ duy nhất** (Single Node), bạn vẫn có thể cài độc lập bộ phần mềm Grid (lúc này tiếng lóng gọi là cài **Oracle Restart**) để sử dụng hệ quản lý lưu trữ ASM mạnh mẽ của nó.

## 2. Oracle RAC (Real Application Clusters) là gì?
**RAC là phần mềm "Cơ sở dữ liệu" (RDBMS), hoạt động bên trên nền tảng của Grid.** Đây là một tùy chọn (Option) cài cắm thêm vào bộ cài Oracle Database Enterprise Edition.

- Oracle RAC cho phép cấu hình **nhiều Instance** (các tiến trình tính toán và RAM chạy trên nhiều Server độc lập).
- Tất cả các Instance này đều kết nối xuống và xử lý chung **một Database duy nhất** (Các file dữ liệu nằm trong ổ chung ASM do Grid quản lý).
- Nhờ cơ chế này, nếu Server 1 (Node 1) bị sập, Server 2 (Node 2) vẫn đang chạy và phục vụ người dùng bình thường (Tính sẵn sàng cao - High Availability). Nó cũng giúp chia sẻ tải công việc (Load Balancing).

---

## 3. Bảng So sánh Trực quan

| Tiêu chí | Oracle Grid Infrastructure | Oracle RAC (Database) |
| :--- | :--- | :--- |
| **Bản chất** | Là cấu trúc Hạ tầng mạng (Cluster) và Lưu trữ (ASM). | Là hệ quản trị CSDL chuyên xử lý dữ liệu. |
| **Thành phần chính** | Oracle Clusterware, Oracle ASM, SCAN Listener. | Oracle DB Instances (SGA Memory, Background Processes). |
| **Vai trò** | Đảm bảo các Nodes nhìn thấy nhau và truy cập được ổ cứng chung một cách đồng bộ. | Xử lý lệnh SQL, cấp phát Role/User, quản lý logic dữ liệu. |
| **Sự phụ thuộc** | Có thể cài độc lập không cần Datbase (Oracle Restart). | **Bắt buộc** phải cài xong Grid mới cài được RAC. Trái tim của RAC (Cache Fusion) dựa hoàn toàn vào mạng nội bộ của Grid. |

> **Ví dụ so sánh dễ hiểu:**
> Hãy tưởng tượng hệ thống giao thông đường sắt:
> - **Oracle Grid:** Là *Đường ray, hệ thống quản lý tín hiệu* (Clusterware) và *Nhà ga* (ASM). Nó giữ cho mọi thứ liên kết lại với nhau.
> - **Oracle RAC:** Là các *Đầu máy xe lửa* (DB Instances) cùng nhau kéo một cấu trúc gồm nhiều toa hàng chung (Data). Nếu 1 đầu kéo hỏng, các đầu khác vẫn tiếp tục kéo tàu đi tới bến.

---

## 4. Thứ tự Quy trình Xây dựng Hệ thống Chuẩn

Để kết hợp hoàn chỉnh các khái niệm trên, khi xây dựng hệ thống mới từ đầu, bạn phải tuân thủ đúng quy trình bậc thang sau:

1. **Chuẩn bị Hệ điều hành (OS):** Cài đặt Linux trên các Nodes, cấu hình UDEV Rules, tạo user chuyên dụng (`grid`, `oracle`).
2. **Cài đặt Grid Infrastructure:** Cài phần mềm Grid, khai báo các mặt đĩa vật lý để tạo môi trường ASM Storage, cấu hình Clusterware kết nối các Nodes.
3. **Cài đặt Oracle Database Software:** Sau khi có Cluster, tiếp tục cài riêng phần mềm Database đi kèm tùy chọn RAC.
4. **Tạo Database (DBCA):** Cuối cùng, dùng lệnh tạo một Cơ sở dữ liệu logic, và yêu cầu nó lưu toàn bộ tệp tin xuống hệ thống ASM đã chuẩn bị ở Bước 2.

*Nếu bạn đã cài sẵn một CSDL Single Node chạy trên File System thông thường (không có Grid, không có ASM), thì việc chuyển đổi kiến trúc đó lên thành một cụm RAC nhiều bài bản là một công việc rất phức tạp, đòi hỏi phải clone (nhân bản nhân) và chạy lệnh Reconfig/Rman Migrate data.*
