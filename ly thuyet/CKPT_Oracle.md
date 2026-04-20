# CKPT (Checkpoint Process) trong Oracle Database

## 1. Định nghĩa
**CKPT** (viết tắt của **Checkpoint Process**) là một tiến trình nền (background process) bắt buộc trong kiến trúc Oracle Database. Nó đóng vai trò quan trọng trong việc duy trì tính nhất quán của dữ liệu và hỗ trợ quá trình khôi phục hệ thống.

## 2. Các chức năng chính
Mặc dù tên gọi là "Checkpoint", tiến trình này không trực tiếp ghi dữ liệu từ Buffer Cache xuống Data Files (việc này do tiến trình **DBWn** thực hiện). Thay vào đó, CKPT thực hiện các nhiệm vụ sau:

*   **Cập nhật thông tin Header:** Ghi số SCN (System Change Number) hiện tại vào phần tiêu đề (Header) của tất cả các tệp dữ liệu (Data Files) và tệp điều khiển (Control Files). Việc này đánh dấu rằng mọi thay đổi trước SCN này đã được ghi xuống đĩa một cách an toàn.
*   **Điều phối ghi dữ liệu:** Gửi tín hiệu thông báo cho tiến trình **DBWn** để thực hiện việc ghi các "dirty blocks" (các khối dữ liệu đã bị thay đổi) từ Database Buffer Cache vào các tệp dữ liệu.
*   **Ghi log Checkpoint:** Lưu trữ thông tin về điểm kiểm tra vào các Redo Log Files.

## 3. Tầm quan trọng
Mục đích chính của CKPT là tối ưu hóa quá trình **Crash Recovery** (Khôi phục sau sự cố):
*   Khi cơ sở dữ liệu bị sập đột ngột, Oracle sẽ dựa vào điểm Checkpoint gần nhất để biết cần phải áp dụng (redo) các thay đổi từ vị trí nào trong Redo Logs.
*   Checkpoint càng thường xuyên thì lượng dữ liệu cần khôi phục càng ít, giúp hệ thống khởi động lại nhanh hơn sau lỗi.

## 4. Các thời điểm xảy ra Checkpoint
Một sự kiện Checkpoint thường được kích hoạt khi:
*   Xảy ra hiện tượng nhảy tệp nhật ký (**Log Switch**).
*   Thực hiện đóng cơ sở dữ liệu một cách bình thường (`SHUTDOWN NORMAL`, `IMMEDIATE`).
*   Lệnh thủ công từ quản trị viên: `ALTER SYSTEM CHECKPOINT;`.
*   Tới chu kỳ định sẵn dựa trên các tham số cấu hình (như `FAST_START_MTTR_TARGET`).

---
*Tài liệu được tạo tự động bởi Antigravity.*
