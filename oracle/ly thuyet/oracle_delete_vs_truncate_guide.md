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

Lệnh `TRUNCATE` mạnh mẽ hơn `DELETE` rất nhiều trong việc xử lý không gian lưu trữ. Dưới đây là các tùy chọn khi sử dụng `TRUNCATE` tác động trực tiếp đến dung lượng:

### 3.1. TRUNCATE TABLE ... REUSE STORAGE
- **Tác dụng:** Xóa toàn bộ dữ liệu, hạ mốc HWM về mức ban đầu, nhưng **giữ lại toàn bộ không gian vật lý** đang chiếm dụng.
- **Khi nào dùng:** Khi bạn muốn làm trống bảng để ngay lập tức `INSERT` lại một lượng dữ liệu khổng lồ tương tự. Việc giữ lại không gian giúp Oracle không tốn thời gian đi cấp phát lại ổ đĩa vật lý (Extents).
- **Ví dụ:**
  ```sql
  TRUNCATE TABLE c##tupt.data_test REUSE STORAGE;
  ```

### 3.2. TRUNCATE TABLE ... DROP STORAGE (Mặc định)
- **Tác dụng:** Xóa dữ liệu, hạ HWM và **giải phóng tất cả không gian phía trên mức khởi tạo (MINEXTENTS / INITIAL extent)** trả về cho Tablespace.
- **Lưu ý:** Nếu bạn chỉ gõ `TRUNCATE TABLE ten_bang;`, Oracle sẽ ngầm hiểu là bạn đang dùng tùy chọn mặc định `DROP STORAGE`.
- **Ví dụ:**
  ```sql
  TRUNCATE TABLE c##tupt.data_test; 
  -- Tương đương với: TRUNCATE TABLE c##tupt.data_test DROP STORAGE;
  ```

### 3.3. Sự cố thường gặp: Truncate xong nhưng dung lượng vẫn lớn
- **Nguyên nhân:** Khi tạo bảng, nếu tham số khởi tạo dung lượng `INITIAL` được thiết lập quá lớn (ví dụ: `CREATE TABLE ... STORAGE (INITIAL 100M)`), Oracle sẽ xí trước 100MB ổ đĩa. Tùy chọn mặc định `DROP STORAGE` **không thể thu hồi** phần dung lượng khởi tạo này (dung lượng bảng sau khi Truncate vẫn giữ nguyên ở mức 100MB dù bảng trống rỗng).
- **Cách xử lý truyền thống:** Phải Export dữ liệu -> `DROP TABLE` -> Tạo lại bảng với `INITIAL` nhỏ hơn -> Import lại (rất mất thời gian).
- **Giải pháp hiện đại:** Sử dụng tùy chọn `DROP ALL STORAGE` (Xem mục 3.4 bên dưới).

### 3.4. TRUNCATE TABLE ... DROP ALL STORAGE (Giải pháp triệt để)
- **Tác dụng:** Xóa dữ liệu và **giải phóng 100% dung lượng** cấp phát cho bảng, bất chấp tham số `INITIAL` hay `MINEXTENTS` của bảng. Dung lượng bảng sẽ thực sự trở về **0 bytes** (Segment của bảng tạm thời bị xóa khỏi ổ đĩa cho đến khi có dữ liệu mới được chèn vào - nhờ tính năng *Deferred Segment Creation*).
- **Ví dụ thực tế:** Khi muốn giải phóng hoàn toàn dung lượng ổ cứng của bảng `data_test`:
  ```sql
  TRUNCATE TABLE c##tupt.data_test DROP ALL STORAGE;
  ```

### 3.5. So sánh trực quan: DROP STORAGE (Mặc định) vs DROP ALL STORAGE

| Tiêu chí | `DROP STORAGE` (Mặc định) | `DROP ALL STORAGE` |
| :--- | :--- | :--- |
| **Xóa dữ liệu & Hạ HWM** | Có | Có |
| **Giải phóng Extents phụ** | Có (Thu hồi các extents phát sinh thêm). | Có |
| **Giải phóng Extent khởi tạo** | **KHÔNG** (Giữ lại dung lượng tối thiểu ban đầu `INITIAL`). | **CÓ** (Giải phóng toàn bộ 100%, đưa bảng về 0 bytes). |
| **Dung lượng sau lệnh** | Bằng kích thước `INITIAL` (Ví dụ: 100MB nếu cấu hình ban đầu là 100MB). | **Bằng 0 bytes** (Không còn segment chiếm đĩa). |
| **Khi nào dùng** | Khi dung lượng khởi tạo (`INITIAL`) nhỏ hoặc muốn giữ nguyên dung lượng ban đầu để nạp tiếp. | Khi dung lượng khởi tạo (`INITIAL`) quá lớn hoặc muốn dọn dẹp sạch sẽ 100% bộ nhớ. |

---

## 4. Các câu lệnh kiểm tra dung lượng và số lượng bảng thực chiến

Để quản lý tốt dung lượng và giám sát hiệu quả các thao tác DELETE/TRUNCATE, dưới đây là các câu lệnh kiểm tra không thể thiếu trong túi đồ của một DBA hoặc Developer.

### 4.1. Kiểm tra số lượng bảng đang tồn tại
Tùy vào quyền hạn của bạn và phạm vi cần quét:
*   **Đếm số bảng thuộc sở hữu của User hiện tại:**
    ```sql
    SELECT COUNT(*) FROM USER_TABLES;
    ```
*   **Đếm số bảng mà User hiện tại có quyền truy cập:**
    ```sql
    SELECT COUNT(*) FROM ALL_TABLES;
    ```
*   **Đếm toàn bộ số bảng trong toàn hệ thống Database (Yêu cầu quyền DBA):**
    ```sql
    SELECT OWNER, COUNT(*) FROM DBA_TABLES GROUP BY OWNER ORDER BY COUNT(*) DESC;
    ```
*   **Đếm số bảng trong toàn bộ môi trường Multitenant (CDB/PDB):**
    ```sql
    SELECT CON_ID, COUNT(*) FROM CDB_TABLES GROUP BY CON_ID;
    ```

### 4.2. Kiểm tra dung lượng vật lý và xác định Schema sở hữu
Khi có các bảng trùng tên nhau nằm ở nhiều tablespace khác nhau (như trường hợp bảng `DATA_BIG` nằm ở cả `SYSTEM` và `USERS`), sử dụng câu lệnh tích hợp cả thông tin **Chủ sở hữu (Owner)** và **Số lượng Block** để kiểm soát dung lượng một cách an toàn và chi tiết nhất:
```sql
SELECT owner, segment_name, tablespace_name, segment_type, ROUND(bytes / 1024 / 1024, 2) AS size_mb, blocks
FROM dba_segments 
WHERE segment_name = 'DATA_BIG';
```
*   **Cột `owner`:** Giúp xác định ai tạo bảng để tránh xóa nhầm dữ liệu (ví dụ: `SYS` tạo nhầm trong tablespace `SYSTEM`).
*   **Cột `blocks`:** Số lượng block vật lý đang cấp phát cho bảng, hữu dụng để đánh giá độ phình của HWM.

### 4.3. Kiểm tra số dòng logic (`SELECT COUNT(*)`) và bẫy hiệu năng
Sau khi thực hiện xóa dữ liệu, câu lệnh đếm số dòng logic sẽ cho kết quả giống nhau nhưng có sự khác biệt khổng lồ về hiệu năng:
```sql
SELECT COUNT(*) FROM data_big;
```
*   **Nếu vừa dùng `DELETE`:** Kết quả trả về `0` nhưng tốc độ chạy **rất chậm (Full Table Scan)** vì Oracle vẫn phải quét toàn bộ các block dữ liệu cũ cho đến mốc HWM.
*   **Nếu vừa dùng `TRUNCATE`:** Kết quả trả về `0` chạy **tức thời** vì HWM đã được reset về 0, Oracle không cần đọc bất kỳ block dữ liệu cũ nào.

### 4.4. Xóa vĩnh viễn bảng để thu hồi dung lượng tức thì (DROP TABLE ... PURGE)
Khi bạn muốn loại bỏ hoàn toàn một bảng khỏi database (ví dụ bảng rác `DATA_BIG` trong tablespace `SYSTEM`), lệnh `DROP TABLE` thông thường sẽ đưa bảng vào Recycle Bin (Thùng rác) và **chưa giải phóng** dung lượng vật lý trên đĩa.

*   **Cú pháp an toàn (có chỉ định rõ Owner và từ khóa PURGE):**
    ```sql
    DROP TABLE owner.table_name PURGE;
    ```
    *Ví dụ thực tế để giải phóng 304MB khỏi tablespace SYSTEM:*
    ```sql
    DROP TABLE SYS.DATA_BIG PURGE;
    ```
*   **Tác dụng của `PURGE`:** Bỏ qua Recycle Bin, xóa vĩnh viễn bảng và hoàn trả toàn bộ dung lượng vật lý ngay lập tức về cho Tablespace.
*   *Lưu ý đặc biệt với tài khoản `SYS`:* Đối với tài khoản `SYS`, Oracle không sử dụng Recycle Bin (các bảng thuộc `SYS` khi DROP luôn bị xóa vĩnh viễn), nhưng sử dụng thêm từ khóa `PURGE` vẫn là một thói quen thực hành an toàn và chuẩn mực.

### 4.5. Phân biệt Siêu dữ liệu (Metadata) và Phân đoạn vật lý (Segment) sau TRUNCATE
Khi thực hiện lệnh `TRUNCATE TABLE c##tupt.my_table DROP ALL STORAGE;`, ta sẽ thấy một hiện tượng thú vị:
*   **Lệnh truy vấn `DBA_SEGMENTS` trả về kết quả rỗng:** Do tùy chọn `DROP ALL STORAGE` đã giải phóng 100% dung lượng vật lý và xóa bỏ phân đoạn (Segment) của bảng đó khỏi đĩa cứng.
*   **Lệnh truy vấn `USER_TABLES` vẫn hiển thị thông tin bảng:** Vì bảng chỉ bị làm rỗng chứ chưa bị xóa (`DROP TABLE`), cấu trúc logic của bảng vẫn tồn tại trong từ điển dữ liệu để sẵn sàng nhận dữ liệu mới.
*   **Các thông số `num_rows` và `blocks` trong `USER_TABLES` vẫn giữ số liệu cũ (Stale Statistics):** Các cột này là thông số tĩnh của Optimizer (Optimizer Statistics) và không tự động cập nhật thời gian thực sau khi TRUNCATE. 
    *   *Cách cập nhật lại thông số chính xác về 0:*
        ```sql
        EXEC DBMS_STATS.GATHER_TABLE_STATS('C##TUPT', 'MY_TABLE');
        ```

### 4.6. Cơ chế và Chính sách lưu trữ của Recycle Bin (Thùng rác)
Ngoại trừ tài khoản `SYS`, khi chạy lệnh `DROP TABLE table_name;` thông thường, đối tượng sẽ được đưa vào Recycle Bin (Thùng rác hệ thống):
*   **Cơ chế đổi tên:** Oracle sẽ đổi tên bảng thành một tên ngẫu nhiên do hệ thống quản lý dạng `BIN$xxxx==$0`. Do đó các câu lệnh kiểm tra thông thường tìm theo tên cũ sẽ không trả về kết quả.
*   **Chính sách lưu trữ (Retention Policy):**
    *   **Không giới hạn thời gian (Time-based):** Thùng rác Oracle không tự động xóa file sau một khoảng thời gian cố định (như 30 ngày).
    *   **Xóa tự động theo Áp lực dung lượng (Space Pressure):** Các đối tượng trong thùng rác sẽ nằm đó vô thời hạn cho đến khi Tablespace chứa nó bị hết dung lượng trống. Lúc đó, Oracle sẽ tự động thực hiện xóa vĩnh viễn (Purge) các đối tượng trong thùng rác theo nguyên tắc **FIFO (First In, First Out - đối tượng cũ nhất xóa trước)** để giải phóng không gian cho dữ liệu mới.
*   **Các câu lệnh quản trị Recycle Bin thực chiến:**
    *   *Kiểm tra các đối tượng trong thùng rác:*
        ```sql
        SELECT object_name, original_name, operation, type FROM user_recyclebin;
        ```
    *   *Khôi phục (Hồi sinh) bảng đã xóa:*
        ```sql
        FLASHBACK TABLE c##tupt.my_table TO BEFORE DROP;
        ```
    *   *Chủ động dọn sạch hoàn toàn thùng rác:*
        ```sql
        PURGE RECYCLEBIN;
        ```
    *   *Xóa vĩnh viễn bảng ngay lập tức khi DROP (không qua thùng rác):*
        ```sql
        DROP TABLE c##tupt.my_table PURGE;
        ```

---

## 5. Phụ lục: Bài tập thực hành tổng hợp (Lab Exercise)

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
