# Kiến trúc Lưu trữ Oracle: Phép ẩn dụ "Phòng lưu trữ hồ sơ"

Để dễ dàng nắm bắt các khái niệm quản lý vật lý và logic trong hệ quản trị cơ sở dữ liệu Oracle, chúng ta có thể hình dung toàn bộ hệ thống lưu trữ giống như một **Hệ thống phòng lưu trữ hồ sơ** trong một công ty lớn.

Trong Oracle, kiến trúc được chia làm 2 phần: **Kiến trúc Logic** (cách chúng ta tư duy, phân loại) và **Kiến trúc Vật lý** (cách chúng thực sự tồn tại trên ổ cứng).

---

## 1. Mức Tổng thể

### Database (Cơ sở dữ liệu) = Căn phòng lưu trữ
* **Ý nghĩa:** Là tập hợp toàn bộ dữ liệu của hệ thống lưu trữ trên đĩa.
* **Hình ảnh thực tế:** Toàn bộ căn phòng chứa hồ sơ của công ty.

### Instance (Thực thể / Phiên làm việc) = Nhân viên quản lý & Bàn làm việc
* **Ý nghĩa:** Là bộ nhớ (RAM) và các tiến trình chạy ngầm (Background Processes) giúp quản lý và lấy dữ liệu. Một Database muốn hoạt động phải có Instance quản lý.
* **Hình ảnh thực tế:** Nhân viên thủ thư và chiếc bàn làm việc của họ. Dữ liệu (hồ sơ) nằm trong phòng lưu trữ chờ đó, khi có người yêu cầu, nhân viên (Instance) sẽ chạy đi tìm trong phòng (Database), mang ra bàn làm việc (bộ nhớ RAM) để xử lý rồi mới trả kết quả hoặc cất đi.

---

## 2. Kiến trúc Cấp cao (Tablespace và Datafile)

### Tablespace (Không gian bảng logic) = Tủ hồ sơ
* **Kiến trúc:** Logic
* **Ý nghĩa:** Là một nhóm bộ nhớ trong Database, dùng để phân nhóm và quản lý dữ liệu hiệu quả hơn.
* **Hình ảnh thực tế:** Một chiếc **tủ hồ sơ lớn**. Bạn có "Tủ hồ sơ Kế toán" (Tablespace cho dữ liệu tài chính), "Tủ hồ sơ Nhân sự" (Tablespace cho dữ liệu nhân viên). 

### Datafile (Tệp dữ liệu vật lý) = Các ngăn kéo hoặc chất liệu đóng tủ
* **Kiến trúc:** Vật lý
* **Ý nghĩa:** Là các tệp tin lưu trữ thực tế (.dbf) nằm trên ổ cứng máy chủ. Một Tablespace được tạo thành từ một hoặc nhiều Datafiles.
* **Hình ảnh thực tế:** Là các **ngăn kéo vật lý** được ráp lại thành cái tủ hồ sơ đó. Nhìn từ xa thì thấy 1 cái tủ (Tablespace logic), nhưng thực tế nó là do nhiều cái ngăn kéo (Datafiles vật lý) ghép lại. Nếu tủ đầy, bạn phải gắn thêm ngăn kéo (add datafile).

---

## 3. Kiến trúc Chi tiết (Segment, Extent, Block)

### Segment (Phân đoạn - ví dụ: Table, Index) = Kẹp tài liệu / Bìa còng
* **Kiến trúc:** Logic
* **Ý nghĩa:** Là bất kỳ đối tượng nào chiếm không gian lưu trữ thực tế trong Database (thường gặp nhất là các Bảng/Table hoặc Chỉ mục/Index).
* **Hình ảnh thực tế:** Các **kẹp tài liệu (bìa còng)** nằm trong tủ hồ sơ. Ví dụ: Kẹp tài liệu "Lương tháng 3", Kẹp tài liệu "Hợp đồng lao động".

### Extent (Mức cấp phát) = Một xấp giấy trắng
* **Kiến trúc:** Logic
* **Ý nghĩa:** Là đơn vị cấp phát không gian trong Oracle. Khi một Bảng (Segment) hết chỗ chứa, Oracle sẽ không đi nối thêm từng byte một, mà sẽ cấp phát hẳn một đoạn bộ nhớ liên tục (Extent).
* **Hình ảnh thực tế:** Khi kẹp tài liệu sắp hết giấy, bạn sẽ không lấy từng tờ lẻ tẻ nhét vào, mà bạn sẽ ra tiệm mua **cả một xấp 100 tờ giấy trắng đục lỗ sẵn** và kẹp vào bìa còng. Xấp 100 tờ giấy đó gọi là 1 Extent.

### Data Block (Khối dữ liệu) = Một trang giấy
* **Kiến trúc:** Logic (nhưng ánh xạ trực tiếp xuống hệ điều hành)
* **Ý nghĩa:** Là đơn vị lưu trữ nhỏ nhất trong Oracle Database. Khác với khối của Hệ điều hành (thường là 4KB), khối của Oracle thường được đặt ở 8KB. Một Extent được tạo nên từ nhiều Data Blocks liền kề nhau.
* **Hình ảnh thực tế:** **Từng tờ giấy đơn lẻ** trong xấp giấy. Nó đã được kẻ sẵn ô, căn lề đúng chuẩn mực của công ty (kích thước fix cứng, ví dụ 8KB).

### Row / Record = Một dòng ghi chép
* **Ý nghĩa:** Dữ liệu thực tế được ghi vào cơ sở dữ liệu.
* **Hình ảnh thực tế:** Ban đầu mỗi tờ giấy (Data block) đều trống. Khi bạn dùng bút ghi thông tin một nhân viên vào đó, đó là một Row. Nhiều dòng điền đầy 1 tờ giấy. Nhiều tờ giấy tạo thành 1 xấp giấy.

---

## Tóm tắt quy trình vận hành

Khi doanh nghiệp phát triển và cần lưu một **Bảng (Table/Segment)** mới:
1. Oracle nhìn vào **Tủ hồ sơ (Tablespace)** xem còn trống chỗ trong **Ngăn kéo vật lý (Datafile)** nào.
2. Oracle tạo một **Kẹp tài liệu (Segment)** mới để quản lý bảng này.
3. Vì kẹp tài liệu mới nên cần giấy viết, Oracle cấp phát ngay cho kẹp tài liệu đó 1 **Xấp giấy trắng (Extent)** để dùng dần.
4. Mỗi khi có dòng dữ liệu mới chèn vào, bạn ghi dữ liệu đó thành 1 **dòng (Row)** trên **từng trang giấy (Data Block)**.
5. Khi xấp giấy này hết sạch trang trống, Oracle lại tự động đi cắt 1 **xấp giấy mới (Extent tiếp theo)** bỏ vào chiếc kẹp tài liệu đó để lưu trữ tiếp.

Cách thiết kế phân chia thành nhiều tầng này (tủ -> ngăn -> kẹp -> xấp giấy -> tờ giấy) giúp Oracle quản lý hàng Terabytes dữ liệu nhưng mọi thứ vẫn luôn ngăn nắp, dễ dàng truy vấn một cách cực kỳ nhanh chóng.
