# Hướng dẫn Tải và Chuẩn bị bộ cài Oracle Grid Infrastructure

Bộ cài Oracle Grid Infrastructure hoàn toàn tách biệt với bộ cài Oracle Database. Dưới đây là quy trình từng bước (Step-by-step) để lấy bộ cài và chuẩn bị cài đặt một cách chính xác nhất.

---

## Phần 1: Tải bộ cài đặt (Download)

Bạn phải có một tài khoản Oracle (đăng ký miễn phí) để tải phần mềm. Lựa chọn 1 trong 2 cách tải sau:

### Cách 1: Tải từ Oracle Technology Network (Khuyên dùng)
*Đây là cách nhanh nhất cho các phiên bản phổ cập như 19c.*

1. Truy cập vào link: [Oracle Database Software Downloads](https://www.oracle.com/database/technologies/oracle-database-software-downloads.html)
2. Chọn phiên bản bạn cần cài (Ví dụ: **19c**).
3. Đọc danh sách và kéo xuống phần dành cho hệ điều hành của bạn (VD: **Oracle Database 19c for Linux x86-64**).
4. Sẽ có 2 tệp cho bạn chọn:
   - *Oracle Database* (Bỏ qua tệp này nếu mục tiêu là Grid).
   - **Oracle Grid Infrastructure**: Đây là tệp bạn cần. Nhấp vào file định dạng ZIP (VD: `LINUX.X64_193000_grid_home.zip`) để tải xuống máy tính của bạn.

### Cách 2: Tải từ eDelivery (Dành cho việc lấy các bản patch cũ/mới rải rác)
1. Truy cập [edelivery.oracle.com](https://edelivery.oracle.com/) và đăng nhập bằng tài khoản Oracle.
2. Tại thanh tìm kiếm, gõ: `Oracle Database Grid Infrastructure`.
3. Nhấp vào phiên bản phần mềm để đưa nó vào Giỏ hàng (Cart).
4. Chuyển sang màn hình thanh toán/tải xuống, chọn hệ điều hành bạn đang dùng (**Linux x86-64**).
5. Đồng ý với các điều khoản để lấy link tải trực tiếp.

> [!WARNING]
> **Quy tắc về Phiên bản:** Phiên bản của Grid Infrastructure BẮT BUỘC phải **bằng hoặc cao hơn** phiên bản Oracle Database bạn định cài. (VD: Nếu cài Database 19c, bạn phải dùng Grid 19c hoặc Grid 21c).

---

## Phần 2: Đưa bộ cài lên Server và Cài đặt (Setup)

**QUAN TRỌNG:** Ở các phiên bản cũ (11g hạ xuống), bạn làm thao tác giải nén file ZIP rồi chạy file `runInstaller`. Nhưng ở các bản mới từ 12cR2 (12.2) trở lên (bao gồm 18c, 19c, 21c), Grid được phân phối theo kiểu **"Image Based"**. Bạn phải làm theo đúng các bước sau đây để không bị lỗi.

### Bước 1: Tạo cấu trúc thư mục chứa Grid Home
Mở terminal trên máy chũ Linux bằng quyền `root` và tạo thư mục. (Ví dụ cài Grid trong `/u01/app/19.3.0/grid`):
```bash
mkdir -p /u01/app/19.3.0/grid
chown -R grid:oinstall /u01/app/19.3.0/grid
chmod -R 775 /u01/app/19.3.0/grid
```

### Bước 2: Chuyển file ZIP vào đúng thư mục Grid Home
Khác với lúc trước, bây giờ bạn cần đưa trực tiếp file ZIP tải về (VD: `LINUX.X64_193000_grid_home.zip`) copy thẳng vào thư mục cài đặt gốc bạn vừa tạo.
```bash
# Giả sử bạn vừa dùng WinSCP copy file ZIP lên thư mục /tmp/ của Linux
mv /tmp/LINUX.X64_193000_grid_home.zip /u01/app/19.3.0/grid/
# Cấp lại quyền cho user grid
chown grid:oinstall /u01/app/19.3.0/grid/LINUX.X64_193000_grid_home.zip
```

### Bước 3: Giải nén bộ cài bằng User Grid
Chuyển đổi sang `grid` user và giải nén (Không dùng quyền root giải nén):
```bash
su - grid
cd /u01/app/19.3.0/grid
unzip -q LINUX.X64_193000_grid_home.zip
```
*(Quá trình này tốn vài phút tùy thuộc vào tốc độ ổ đĩa)*

### Bước 4: Khởi chạy bộ Setup
Sau khi giải nén xong, file `gridSetup.sh` sẽ xuất hiện ngay cùng thư mục đó. Bạn bắt đầu gọi giao diện cài đặt:
```bash
# Vẫn đang đăng nhập bằng user grid, với MobaXterm/X11 Forwarding đã bật
cd /u01/app/19.3.0/grid
./gridSetup.sh
```

Lúc này, giao diện cài đặt (GUI) của Oracle Grid Infrastructure sẽ hiện lên. Bạn chọn option phù hợp cài RAC hay Standalone, và tại bước điền Disk Manager, bạn chỉ đường dẫn tới udev rules như trong [Hướng dẫn Cấu hình VMware VMware](oracle_grid_vmware_guide.md).
