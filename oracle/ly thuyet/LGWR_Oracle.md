# LGWR (Log Writer) trong Oracle Database

## 1. Định nghĩa
**LGWR** (viết tắt của **Log Writer**) là tiến trình nền chịu trách nhiệm quản lý bộ đệm nhật ký (Redo Log Buffer) và ghi các thay đổi vào các tệp nhật ký trên đĩa.

## 2. Chức năng chính
*   **Ghi Redo Logs:** Ghi các bản ghi thay đổi từ Redo Log Buffer vào các Online Redo Log Files trên đĩa.
*   **Đảm bảo tính bền vững:** Đây là tiến trình nòng cốt thực hiện nguyên tắc "Write-Ahead Logging" (ghi nhật ký trước khi ghi dữ liệu), đảm bảo rằng mọi giao dịch đã commit sẽ không bao giờ bị mất.

## 3. Khi nào LGWR hoạt động?
LGWR làm việc rất tích cực và được kích hoạt trong các trường hợp sau:
*   **Khi Commit:** Ngay khi người dùng thực hiện lệnh `COMMIT`.
*   **Định kỳ 3 giây:** Ít nhất mỗi 3 giây một lần.
*   **Buffer đầy 1/3:** Khi Redo Log Buffer đã đầy một phần ba dung lượng.
*   **Trước khi DBWn ghi:** Trước khi tiến trình DBWn ghi các dirty buffers xuống đĩa, LGWR phải đảm bảo các bản ghi redo tương ứng đã nằm an toàn trong log files.

## 4. Tại sao LGWR lại quan trọng?
Nếu DBWn chịu trách nhiệm về dữ liệu thực tế, thì LGWR chịu trách nhiệm về **khả năng phục hồi**. Nhờ có LGWR ghi nhật ký cực nhanh, Oracle có thể khôi phục lại mọi thay đổi ngay cả khi ổ đĩa dữ liệu chưa kịp cập nhật.

---
*Tài liệu được tạo tự động bởi Antigravity.*
