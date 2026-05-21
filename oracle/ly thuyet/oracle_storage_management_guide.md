# Tổng quan về Quản lý không gian lưu trữ (Storage Space Management) trong Oracle Database

Quản lý không gian lưu trữ trong Oracle là một quá trình tổng thể từ cấp độ vật lý (hệ điều hành, ổ cứng) cho đến cấp độ logic (cấu trúc bên trong CSDL). Oracle cung cấp các cơ chế tự động hóa nhằm giảm thiểu công sức cho DBA và tối ưu hóa hiệu suất.

Để dễ dàng nắm bắt, kiến trúc lưu trữ được chia làm hai thành phần chính: **Vật lý (Physical)** và **Logic (Logical)**.

---

## 1. Quản lý Không gian Vật lý (Physical Space Management)

Thành phần này tập trung vào phần cứng, ổ cứng, hệ điều hành và các tập tin vật lý cấu thành nên cơ sở dữ liệu (`.dbf`, `.log`, `.ctl`).

### Các tính năng và công cụ chính:
- **OMF (Oracle Managed Files):** 
  - Tính năng tự động hóa việc tạo, đặt tên, định vị trí lưu trữ và xóa các file vật lý trên hệ điều hành.
  - *Lợi ích:* Giải phóng DBA khỏi việc quản lý đường dẫn phức tạp và tránh để lại "file rác" khi xóa Tablespace.
- **Autoextend Datafile (Tính năng "Cứu sinh"):**
  - Khả năng cấu hình cho các Datafile tự động mở rộng (phình to) dung lượng khi cần thiết, giúp hệ thống không bị gián đoạn khi dữ liệu tăng đột biến (`ORA-01653`).
- **Giám sát dung lượng ổ cứng:**
  - Đặt các cảnh báo (Alert) để giám sát phân vùng ổ cứng (VD: ổ `C:\` hoặc `/u01`). Nếu dung lượng vật lý cạn kiệt, toàn bộ hệ thống Database sẽ bị treo (hang) hoặc sập (crash).

### Hướng dẫn cấu hình AUTOEXTEND thực chiến:
```sql
-- 1. Nếu cấu hình ngay lúc tạo mới Tablespace
CREATE TABLESPACE my_data 
DATAFILE '/u01/oracle/oradata/my_data_01.dbf' SIZE 1G 
AUTOEXTEND ON NEXT 100M MAXSIZE 32G;

-- 2. Nếu sửa một file vật lý đang có sẵn trên hệ thống
ALTER DATABASE DATAFILE '/u01/oracle/oradata/my_data_01.dbf' 
AUTOEXTEND ON NEXT 100M MAXSIZE 32G;
```
> [!TIP]
> **Mẹo của DBA:** Hạn chế tối đa việc thiết lập `MAXSIZE UNLIMITED` (tăng dung lượng vô hạn). Vì nếu code ứng dụng bị lỗi vòng lặp, nó sẽ ăn sạch 100% dung lượng ổ cứng vật lý (`/u01`) và làm sập toàn bộ hệ thống máy chủ. Luôn phải có giới hạn `MAXSIZE`.

---

## 2. Quản lý Không gian Logic (Logical Space Management)

Thành phần này tập trung vào việc quản lý không gian bên trong cấu trúc của Oracle: **Tablespace ➔ Segment ➔ Extent ➔ Block**.

### Các tính năng và công cụ chính:
- **LMT (Locally Managed Tablespace) & ASSM (Automatic Segment Space Management):**
  - Sử dụng bản đồ bit (bitmap) nằm ở header của phân vùng để tự động hóa việc theo dõi không gian trống bên trong các block.
  - *Lợi ích:* Tối ưu hóa việc chèn dữ liệu, giảm nghẽn (contention) khi có nhiều user cùng chèn dữ liệu, thay thế cho các thao tác cấu hình thủ công cũ.
- **Deferred Segment Creation (Trì hoãn tạo Segment):**
  - Cơ chế tự động của Oracle: Không cấp phát không gian ngay lập tức cho các bảng rỗng khi mới dùng lệnh `CREATE TABLE`. Không gian chỉ được cấp khi có dòng dữ liệu đầu tiên (first row) được chèn vào.
- **Tối ưu và Thu hồi không gian (Space Reclamation):**
  - **Segment Advisor:** Tiện ích tự động quét và phân tích để tìm ra các bảng/chỉ mục bị phân mảnh và lãng phí dung lượng.
  - **Compression (Nén dữ liệu):** Tính năng nén các khối dữ liệu để tiết kiệm tối đa dung lượng đĩa.
  - **Shrink Segment (Tính năng "Dọn nhà"):** Lệnh dồn nén dữ liệu và hạ mức High Water Mark (HWM) xuống, trả lại không gian trống cho Tablespace mà không cần phải dừng hệ thống.

### Hướng dẫn thu hồi dung lượng với SHRINK SPACE:
Khi dữ liệu bị xóa (lệnh `DELETE`), không gian ổ cứng VẪN BỊ CHIẾM DỤNG do mức trần dữ liệu (HWM) không tự động tụt xuống. Lệnh Shrink sẽ bốc các dòng rải rác xếp sát lại, hạ HWM và trả lại dung lượng trống để tái sử dụng.

**Cách thực hiện (Bắt buộc 2 bước):**

**Bước 1: Cho phép di chuyển dữ liệu (Row Movement)**
Việc dồn nén làm thay đổi địa chỉ vật lý (RowID), nên bạn phải cấp quyền cho Oracle dịch chuyển chúng.
```sql
ALTER TABLE my_table ENABLE ROW MOVEMENT;
```

**Bước 2: Chạy lệnh thu hồi**
```sql
-- Cách 1: Thu hồi toàn diện (Có thể gây lock bảng trong một khoảnh khắc rất nhỏ ở bước cuối)
ALTER TABLE my_table SHRINK SPACE;

-- Cách 2: Chỉ dồn dữ liệu lại sát nhau, NHƯNG CHƯA hạ mức HWM xuống, CHƯA trả lại dung lượng (Dùng được trong giờ cao điểm vì không gây lock bảng)
ALTER TABLE my_table SHRINK SPACE COMPACT;
```
> [!IMPORTANT]
> **Lưu ý:** Lệnh `SHRINK SPACE` **chỉ hoạt động** trên các Tablespace được cấu hình **ASSM** (Automatic Segment Space Management).

---

## 3. So sánh OMF và ASSM

Tuy đều mang tính chất "Tự động quản lý", OMF và ASSM hoạt động ở hai tầng hoàn toàn khác biệt. Trong thực tế, DBA sẽ **kết hợp cả hai** để tối ưu toàn diện hệ thống.

| Tiêu chí | OMF (Oracle Managed Files) | ASSM (Automatic Segment Space Management) |
| :--- | :--- | :--- |
| **Tầng hoạt động** | **Tầng Vật lý:** Quản lý File trên Hệ điều hành. | **Tầng Logic:** Quản lý không gian bên trong Block dữ liệu. |
| **Mục đích** | Tự động sinh ra tên file, cấp chỗ lưu, và xóa file. | Tự động quét và tìm khoảng trống trong block để chèn dữ liệu. |
| **Ví dụ ẩn dụ** | **Nhà thầu xây dựng:** Nhận lệnh xây khu nhà mới, tự tìm đất, tự cấp địa chỉ. | **Lễ tân khách sạn:** Cầm sơ đồ phòng, xem phòng nào còn giường trống để xếp khách. |
| **Ví dụ câu lệnh** | `CREATE TABLESPACE users;` | `CREATE TABLESPACE ... SEGMENT SPACE MANAGEMENT AUTO;` |

---

## 4. Giao thoa giữa Vật lý và Logic: Tính năng quản trị nâng cao

Có những tính năng và công việc quản trị đòi hỏi sự kết nối chặt chẽ giữa cả hai mặt Vật lý và Logic:

- **Resumable Space Allocation (Tính năng tự hồi phục):** 
  Khi cơ sở dữ liệu cạn kiệt dung lượng (có thể là hết dung lượng logic của Tablespace, hoặc hết dung lượng vật lý của ổ cứng), tính năng này sẽ tạm "treo" các tác vụ lớn (như Import/Export data, tạo Index lớn) thay vì đánh lỗi văng ra ngoài. Điều này cho phép DBA có thời gian cấp thêm dung lượng, sau đó tiến trình sẽ tự động chạy tiếp.
- **Capacity Planning (Lên kế hoạch lưu trữ):** 
  Kết hợp các báo cáo tăng trưởng dữ liệu bên trong CSDL (AWR Reports, EM Cloud Control) để đưa ra quyết định mua sắm hoặc nâng cấp ổ cứng vật lý (Disk/SAN) trong tương lai.
