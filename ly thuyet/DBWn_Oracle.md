# DBWn (Database Writer) trong Oracle Database

## 1. Định nghĩa
**DBWn** (viết tắt của **Database Writer**) là một tiến trình nền quan trọng chịu trách nhiệm ghi dữ liệu từ bộ nhớ xuống đĩa cứng. Chữ "n" biểu thị rằng có thể có nhiều tiến trình Database Writer (DBW0, DBW1,...) tùy thuộc vào cấu hình hệ thống.

## 2. Chức năng chính
Nhiệm vụ duy nhất và quan trọng nhất của DBWn là:
*   **Ghi Dirty Buffers:** Ghi các khối dữ liệu đã bị thay đổi (dirty buffers) từ Database Buffer Cache vào các Data Files trên ổ đĩa.
*   **Giải phóng bộ nhớ:** Bằng cách ghi dữ liệu xuống đĩa, DBWn giúp làm trống các buffer trong bộ nhớ để các tiến trình khác có thể sử dụng.

## 3. Khi nào DBWn hoạt động?
Để tối ưu hóa hiệu năng (I/O), DBWn không ghi dữ liệu ngay lập tức sau mỗi lần có thay đổi. Nó hoạt động theo cơ chế "lười" (lazy writer) và được kích hoạt khi:
*   **Checkpoint xảy ra:** Tiến trình CKPT yêu cầu ghi dữ liệu.
*   **Buffer Cache đầy:** Khi một tiến trình người dùng cần nạp dữ liệu vào bộ nhớ nhưng không còn buffer trống.
*   **Threshold (Ngưỡng):** Số lượng dirty buffers đạt đến một giới hạn nhất định.
*   **Timeout:** Sau một khoảng thời gian định sẵn nếu không có sự kiện nào xảy ra.

## 4. Đặc điểm quan trọng
*   DBWn ghi dữ liệu theo lô (multiblock writes) để tăng tốc độ I/O.
*   Nó hoạt động không đồng bộ, nghĩa là các tiến trình người dùng không phải chờ DBWn ghi xong thì mới tiếp tục làm việc được (trừ khi bộ nhớ quá đầy).

---
*Tài liệu được tạo tự động bởi Antigravity.*
