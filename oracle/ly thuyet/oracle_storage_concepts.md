# Khái niệm lưu trữ logic trong Oracle: Segment và Block

Để hiểu rõ về **Segment (Phân đoạn)** và **Block (Khối dữ liệu)** trong Oracle, chúng ta cần nhìn vào cách Oracle tổ chức lưu trữ dữ liệu. Oracle sử dụng một cấu trúc phân cấp logic từ lớn đến nhỏ.

Hãy tưởng tượng cơ sở dữ liệu của bạn giống như một **"Tủ hồ sơ"**, và dưới đây là cách Oracle chia nhỏ nó ra:

### 1. Data Block (Khối dữ liệu) - Đơn vị cơ bản nhất
*   **Định nghĩa:** Block là đơn vị lưu trữ dữ liệu và I/O (Đọc/Ghi) **nhỏ nhất** trong Oracle. Oracle quản lý không gian lưu trữ ở cấp độ block.
*   **Kích thước:** Khi bạn tạo cơ sở dữ liệu, bạn sẽ xác định kích thước chuẩn của block (thường là 4KB hoặc **8KB**). Điều này có nghĩa là mỗi khi Oracle muốn ghi hay đọc dữ liệu vào ổ cứng, nó sẽ xử lý theo từng khối 8KB, kể cả khi bạn chỉ cập nhật 1 byte dữ liệu.
*   **Cấu tạo:** Một block chứa phần tiêu đề (thông tin quản lý, địa chỉ hàng) và phần không gian để chứa dữ liệu thực tế (các dòng dữ liệu của bảng).
*   **Ví dụ dễ hiểu:** Hãy coi Data Block như **"1 trang giấy"** trong một cuốn sổ. Bạn viết thông tin lên trang giấy này. Kể cả bạn chỉ viết 1 chữ thì bạn cũng đã dùng một trang, và khi đọc, bạn phải giở cả trang đó ra để xem.

### 2. Extent (Khoảng mở rộng) - Cấp độ trung gian
*   **Định nghĩa:** Trước khi đến Segment, có một khái niệm là Extent. Extent là tập hợp của **nhiều Data Block liền kề nhau** trên đĩa vật lý.
*   **Chức năng:** Oracle cấp phát không gian theo từng Extent chứ không cấp phát từng Block một để tăng hiệu suất (để lấy được một lượng dữ liệu lớn liên tục thay vì nhặt nhạnh từng block rời rạc).
*   **Ví dụ dễ hiểu:** Extent giống như **"1 xấp giấy"** (gồm nhiều trang giấy trắng liên tục). Khi bạn cần nháp, Oracle không đưa bạn từng tờ một mà đưa cả 1 xấp.

### 3. Segment (Phân đoạn) - Thực thể dữ liệu
*   **Định nghĩa:** Segment là một tập hợp các **Extent** nằm trong cùng một Tablespace (Không gian bảng) được phân bổ để lưu trữ dữ liệu cho **một cấu trúc cơ sở dữ liệu logic cụ thể**.
*   **Chức năng:** Bất cứ khi nào bạn tạo ra một đối tượng lưu trữ dữ liệu trong Oracle, một Segment sẽ được tạo ra cho đối tượng đó. Segment có thể phát triển lớn lên bằng cách xin thêm các Extent mới khi bản thân nó đã chứa đầy dữ liệu.
*   **Các loại Segment phổ biến:**
    *   **Data Segment (Table):** Khi bạn tạo một bảng (ví dụ bảng `NHAN_VIEN`), Oracle sẽ tạo một data segment riêng để chỉ chứa dữ liệu của bảng đó.
    *   **Index Segment:** Khi bạn tạo Index để tìm kiếm nhanh, dữ liệu của index đó sẽ được lưu trong một index segment.
    *   **Undo/Rollback Segment:** Chứa các dữ liệu cũ trước khi bị thay đổi (dùng để rollback giao dịch nếu có sự cố xảy ra).
*   **Ví dụ dễ hiểu:** Segment giống như **"1 chương"** trong cuốn sổ của bạn. Ví dụ: Chương 1 chuyên ghi danh sách "Nhân viên" (Table Segment 1), Chương 2 chuyên ghi "Mục lục" để tìm nhanh (Index Segment). Một "chương" (Segment) sẽ bao gồm nhiều "xấp giấy" (Extent). Khi hết giấy, "chương" này sẽ yêu cầu xin thêm các "xấp giấy" mới để viết tiếp.

---

### Tóm tắt mối quan hệ theo thứ bậc (Nhỏ -> Lớn)

1.  **Block (Trang giấy):** Đơn vị I/O nhỏ nhất. Chứa các bản ghi dữ liệu (rows).
2.  **Extent (Xấp giấy):** Cấp phát không gian một lần gồm nhiều Block liên tiếp.
3.  **Segment (Chương sách):** Chứa dữ liệu của một đối tượng cụ thể (như 1 Table hoặc 1 Index). Gồm nhiều Extent. Kích thước của Data segment chính là kích thước của Table đó.
4.  **Tablespace (Cuốn sổ):** Chứa nhiều Segment.

**Tóm lại:**
Khi bạn `INSERT` (thêm mới) một dòng dữ liệu vào bảng. Dữ liệu sẽ được nhét vào phần không gian trống của một **Block**. Block đó nằm trong một **Extent**, và Extent đó thuộc quyền sở hữu của một **Segment** (đại diện cho cái Bảng mà bạn vừa insert dữ liệu vào).
