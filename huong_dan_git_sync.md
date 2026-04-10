# Hướng dẫn Đồng bộ Dữ liệu từ Máy cục bộ lên GitHub

Tài liệu này hướng dẫn cách xử lý và đồng bộ hóa các thay đổi khi bạn thực hiện sắp xếp lại cấu trúc thư mục (như di chuyển tệp vào thư mục con `oracle/`) trong dự án Oracle Setup.

## 1. Tình trạng hiện tại
Dựa trên lệnh `git status`, hệ thống ghi nhận:
- **Deleted**: Các tệp cũ ở thư mục gốc đã bị xóa (do bạn đã di chuyển chúng đi).
- **Untracked files**: Các tệp mới xuất hiện trong thư mục `oracle/`.

Để đồng bộ lên GitHub, chúng ta cần gộp các thay đổi này thành một "lần chuyển giao" (commit).

---

## 2. Quy trình thực hiện chi tiết

### Bước 1: Đưa tất cả thay đổi vào vùng chờ (Staging Area)
Lệnh này sẽ quét toàn bộ thư mục, ghi nhận cả hành động xóa tệp cũ và thêm tệp mới ở vị trí mới.
```bash
git add .
```
*Lưu ý: Dấu chấm `.` đại diện cho toàn bộ thư mục hiện hành.*

### Bước 2: Tạo ghi chú thay đổi (Commit)
Lệnh này giúp bạn lưu lại trạng thái hiện tại của mã nguồn với một lời giải thích ngắn gọn.
```bash
git commit -m "Chỉnh sửa cấu trúc: Di chuyển các tệp cài đặt vào thư mục oracle"
```

### Bước 3: Đẩy dữ liệu lên GitHub (Push)
Đưa các thay đổi đã commit từ máy của bạn lên kho lưu trữ trực tuyến.
```bash
git push origin main
```
*(Thay `main` bằng `master` nếu nhánh chính của bạn tên là master).*

---

## 3. Xử lý các tình huống thường gặp

### Trường hợp lỗi "Rejected - non-fast-forward"
Lỗi này xảy ra nếu trên GitHub có những thay đổi mới mà máy bạn chưa có.
**Cách xử lý:**
```bash
# Lấy dữ liệu mới nhất về và gộp vào máy mình
git pull origin main --rebase

# Sau đó thực hiện lại lệnh push
git push origin main
```

### Cách kiểm tra kết nối với GitHub
Nếu bạn không nhớ mình đang đẩy code vào repository nào:
```bash
git remote -v
```

---

## 4. Xác nhận hoàn tất
Sau khi chạy xong lệnh `git push`, bạn có thể kiểm tra lại bằng cách:
1. Truy cập vào đường link GitHub của dự án.
2. Kiểm tra xem các tệp đã nằm trong thư mục `oracle/` hay chưa.
3. Chạy lại lệnh `git status` trên máy, nếu hiện `nothing to commit, working tree clean` là bạn đã đồng bộ thành công.

> [!TIP]
> Hãy luôn thực hiện `git status` trước và sau mỗi bước để nắm rõ trạng thái của mã nguồn.
