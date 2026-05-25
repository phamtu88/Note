# Hướng dẫn Quản lý Dung lượng với DELETE và TRUNCATE trong Oracle

Tài liệu này tổng hợp các kiến thức thực chiến về cách Oracle quản lý dung lượng (Space) và mốc trần dữ liệu (High Water Mark - HWM) khi thực hiện các thao tác xóa dữ liệu, kèm theo các ví dụ thực tế.

---

## 1. Khái niệm cốt lõi: High Water Mark (HWM)
Trong Oracle, **High Water Mark (HWM)** giống như một "mức nước biển cao nhất" mà dữ liệu đã từng chạm tới trong bảng. 
- Khi bạn thêm dữ liệu (INSERT), HWM sẽ tăng lên và Oracle cấp phát thêm không gian vật lý (Blocks/Extents).
- **Tuy nhiên**, khi bạn xóa dữ liệu thông thường, HWM **không tự động hạ xuống**. Điều này dẫn đến hiện tượng "rác" (phân mảnh), tức là bảng trống rỗng nhưng vẫn chiếm dung lượng lớn trên ổ cứng.

---

## 2. Xóa dữ liệu bằng lệnh DELETE

### Bản chất của DELETE
Lệnh `DELETE` chỉ xóa nội dung bên trong các block dữ liệu. Nó **để lại tất cả không gian** đã được phân bổ cho bảng và **không hạ mốc HWM**.

### Ví dụ thực tế
Giả sử bạn có một bảng `DATA_BIG` chứa 1.000.000 dòng, đang chiếm **160MB** dung lượng vật lý.
Bạn thực hiện xóa đi một nửa số dữ liệu (500.000 dòng):

```sql
DELETE FROM data_big WHERE ROWNUM <= 500000;
COMMIT;
```

**Kết quả:** Khi bạn kiểm tra lại bằng view `DBA_SEGMENTS`, dung lượng bảng **vẫn y nguyên là 160MB**. Không có byte nào được trả lại cho hệ thống.

### Cách thu hồi dung lượng sau khi DELETE
Để thu hồi dung lượng rỗng này, bạn phải sử dụng tính năng dồn nén dữ liệu `SHRINK SPACE`. Chú ý sự khác biệt của tùy chọn `COMPACT`:

1. **Chuẩn bị (Bắt buộc):** Cho phép dịch chuyển dữ liệu vật lý
   ```sql
   ALTER TABLE data_big ENABLE ROW MOVEMENT;
   ```
2. **Dồn nén KHÔNG hạ HWM (Dung lượng không giảm):**
   ```sql
   ALTER TABLE data_big SHRINK SPACE COMPACT;
   ```
   *(Tùy chọn này chỉ dồn các dòng lại gần nhau cho gọn, thích hợp chạy trong giờ hành chính để không gây lock bảng lâu, nhưng dung lượng `dba_segments` chưa giảm).*
3. **Dồn nén VÀ hạ HWM (Thu hồi dung lượng thực sự):**
   ```sql
   ALTER TABLE data_big SHRINK SPACE;
   ```
   *(Chạy lệnh này xong, dung lượng 160MB mới thực sự giảm xuống).*

---

## 3. Xóa dữ liệu bằng lệnh TRUNCATE

Lệnh `TRUNCATE` mạnh mẽ hơn `DELETE` rất nhiều trong việc xử lý không gian lưu trữ. Có 4 tùy chọn khi sử dụng TRUNCATE tác động trực tiếp đến dung lượng:

### 3.1. TRUNCATE TABLE ... REUSE STORAGE
- **Tác dụng:** Xóa toàn bộ dữ liệu, hạ mốc HWM về mức ban đầu, nhưng **giữ lại toàn bộ không gian vật lý** đang chiếm dụng.
- **Khi nào dùng:** Khi bạn muốn xóa bảng để ngay lập tức `INSERT` lại một lượng dữ liệu khổng lồ tương đương. Việc giữ lại không gian giúp Oracle không tốn thời gian đi cấp phát lại ổ cứng.
- **Ví dụ:**
  ```sql
  TRUNCATE TABLE data_big REUSE STORAGE;
  ```

### 3.2. TRUNCATE TABLE ... DROP STORAGE (Mặc định)
- **Tác dụng:** Xóa dữ liệu, hạ HWM và **giải phóng tất cả không gian phía trên mức khởi tạo (MINEXTENTS)** trả về cho Tablespace.
- **Lưu ý:** Nếu bạn chỉ gõ `TRUNCATE TABLE ten_bang;`, Oracle sẽ ngầm hiểu là bạn đang dùng `DROP STORAGE`.

### 3.3. Sự cố: Truncate xong nhưng không giảm dung lượng
- **Nguyên nhân:** Đôi khi bạn Truncate (mặc định) nhưng dung lượng không giảm. Lý do là lúc tạo bảng, tham số `INITIAL` hoặc `MINEXTENTS` được thiết lập quá lớn (ví dụ `INITIAL 100M`). Tùy chọn `DROP STORAGE` không thể thu hồi phần không gian khởi tạo này.
- **Cách xử lý thủ công:** Export dữ liệu (Data Pump) -> `DROP TABLE` -> Tạo lại bảng với `INITIAL` nhỏ hơn -> Import lại.

### 3.4. TRUNCATE TABLE ... DROP ALL STORAGE (Giải pháp triệt để)
- **Tác dụng:** Xóa dữ liệu và **giải phóng TẤT CẢ không gian** được phân bổ cho bảng (bất chấp cả thông số MINEXTENTS). Bảng sẽ trở về dung lượng 0 thực sự.
- **Ví dụ thực tế:** Khi bạn muốn tiêu diệt hoàn toàn bảng `DATA_BIG` (304MB) để lấy lại 100% dung lượng ổ cứng một cách nhanh gọn:
  ```sql
  TRUNCATE TABLE data_big DROP ALL STORAGE;
  ```

---

## 4. Phụ lục: Bài tập thực hành tổng hợp (Lab Exercise)

Dưới đây là kịch bản thực hành xuyên suốt toàn bộ các kỹ thuật quản lý dung lượng trên, được xây dựng trực tiếp từ các yêu cầu bài tập thực tế.

### Yêu cầu 1: Thêm 1.000.000 dòng dữ liệu và kiểm tra dung lượng
*Đề bài: Thêm ít nhất 1.000.000 dòng dữ liệu vào bảng, sau đó kiểm tra dung lượng bảng (dùng lệnh `create table … as select * from dba_objects`, `insert into xxx select * from dba_objects`).*

```sql
-- Bước 1.1: Tạo bảng rỗng
-- Có 2 cách để tạo bảng, lập trình viên thường dùng Cách 1, nhưng DBA chuyên nghiệp luôn dùng Cách 2.

-- CÁCH 1: Tạo bảng bình thường (Không khuyến nghị)
-- Bảng sẽ tự động được tạo cho User hiện tại đang kết nối. Rất nguy hiểm nếu bạn đang đăng nhập nhầm bằng user SYS (bảng sẽ trở thành rác hệ thống nằm trong SYSTEM).
-- CREATE TABLE my_table AS SELECT * FROM dba_objects WHERE 1=0;

-- CÁCH 2: Gán đích danh User và Tablespace (Khuyên dùng tuyệt đối)
-- Đảm bảo an toàn 100%. Bất kể bạn đang mở kết nối bằng tài khoản nào, bảng vẫn được khởi tạo đúng vào nhà của c##tupt và lưu vào ổ đĩa USERS.
CREATE TABLE c##tupt.my_table TABLESPACE users AS 
SELECT * FROM dba_objects WHERE 1=0;

-- Bước 1.2: Sinh tự động 1 triệu dòng dữ liệu
DECLARE 
    l_cnt NUMBER; 
    l_rows NUMBER := 1000000; 
BEGIN 
    INSERT /*+ APPEND */ INTO c##tupt.my_table 
    SELECT * FROM dba_objects; 
    
    l_cnt := SQL%ROWCOUNT; 
    COMMIT; 
    
    WHILE (l_cnt < l_rows) LOOP 
        INSERT /*+ APPEND */ INTO c##tupt.my_table 
        SELECT * FROM c##tupt.my_table WHERE ROWNUM <= l_rows - l_cnt; 
        l_cnt := l_cnt + SQL%ROWCOUNT; 
        COMMIT; 
    END LOOP; 
END; 
/

-- Bước 1.3: Kiểm tra dung lượng vật lý sau khi chèn
SELECT owner, segment_name, tablespace_name, ROUND(bytes / 1024 / 1024, 2) AS size_mb, blocks
FROM dba_segments 
WHERE segment_name = 'MY_TABLE' AND owner = 'C##TUPT';
```

### Yêu cầu 2: Xóa 500.000 bản ghi bằng DELETE
*Đề bài: Xóa 500.000 bản ghi khỏi bảng vừa tạo.*

```sql
-- Chạy lệnh DELETE (Dung lượng DBA_SEGMENTS sẽ không đổi)
DELETE FROM c##tupt.my_table WHERE ROWNUM <= 500000;
COMMIT;
```

### Yêu cầu 3: Thu hồi dung lượng bằng Shrink
*Đề bài: Shrink lại bảng (bằng tùy chọn COMPACT) và check lại dung lượng.*

```sql
-- Bước 3.1: Bật tính năng Row Movement
ALTER TABLE c##tupt.my_table ENABLE ROW MOVEMENT;

-- Bước 3.2: Chạy Shrink Compact (Ghi chú: COMPACT không hạ HWM nên dung lượng vẫn chưa giảm)
ALTER TABLE c##tupt.my_table SHRINK SPACE COMPACT;

-- Bước 3.3: Kiểm tra lại dung lượng
SELECT owner, segment_name, tablespace_name, ROUND(bytes / 1024 / 1024, 2) AS size_mb
FROM dba_segments 
WHERE segment_name = 'MY_TABLE' AND owner = 'C##TUPT';
```

### Yêu cầu 4: Thu hồi dung lượng triệt để bằng TRUNCATE
*Đề bài: Xóa bằng truncate thu hồi dung lượng bằng cách nào?*

```sql
-- Dùng DROP ALL STORAGE để dọn sạch sẽ 100% không gian lưu trữ (bao gồm cả mức INITIAL/MINEXTENTS)
TRUNCATE TABLE c##tupt.my_table DROP ALL STORAGE;
```

---
*Tài liệu được biên soạn dựa trên các bài học thực hành quản trị lưu trữ Oracle Database và tham chiếu từ kiến thức chuyên gia.*
