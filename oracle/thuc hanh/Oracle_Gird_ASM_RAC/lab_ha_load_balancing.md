# Lab Test: Khám phá High Availability (HA) và Load Balancing trên RAC

Mục tiêu của bài Lab này là giúp bạn thấy tận mắt cách RAC xử lý khi có sự cố (Failover) và cách nó phân tải (Load Balancing).

## 1. Kiểm tra Load Balancing (Cân bằng tải)

Chúng ta sẽ mô phỏng việc nhiều người dùng cùng kết nối vào hệ thống để xem RAC phân chia họ như thế nào.

**Các bước thực hiện:**
1.  Sử dụng một máy trạm (hoặc chính node 1) mở 10 luồng kết nối đồng thời qua địa chỉ SCAN IP.
2.  Kiểm tra danh sách session trên từng instance.

**Lệnh thực hiện:**
```sql
-- Chạy lệnh này nhiều lần từ 10 terminal khác nhau (hoặc dùng tool như SQL Developer)
sqlplus system/Oracle123@192.168.56.120:1521/orcl.localdomain
```

**Truy vấn kiểm tra (Chạy từ Node 1):**
```sql
SELECT inst_id, count(*) FROM gv$session WHERE username = 'SYSTEM' GROUP BY inst_id;
```
*Kết quả lý tưởng: Số lượng session sẽ được chia đều (ví dụ 5-5 hoặc 4-6) giữa instance 1 và 2.*

---

## 2. Kiểm tra High Availability (Tính sẵn sàng cao - Failover)

Chúng ta sẽ mô phỏng tình huống một Server bị chết đột ngột.

**Các bước thực hiện:**
1.  Mở một kết nối SQLPlus và giữ nguyên đó.
2.  Tắt cưỡng bức Instance 1 (Node 1) bằng lệnh `srvctl`.
3.  Kiểm tra xem kết nối cũ có bị ngắt không và cụm RAC xử lý thế nào.

**Lệnh thực hiện:**
1.  **Kết nối (Terminal A):**
    ```bash
    sqlplus system/Oracle123@192.168.56.120:1521/orcl.localdomain
    -- Giữ nguyên Terminal này
    ```
2.  **Tắt Instance 1 (Terminal B - Node 1):**
    ```bash
    srvctl stop instance -d orcl -i orcl1 -f
    ```
3.  **Kiểm tra trạng thái (Terminal C):**
    ```bash
    srvctl status database -d orcl
    ```
    *Kết quả: Bạn sẽ thấy `orcl1` báo OFFLINE nhưng `orcl2` vẫn ONLINE.*

4.  **Quay lại Terminal A:** Thử gõ một câu lệnh (ví dụ `select name from v$database;`).
    *Nếu bạn dùng RAC Service cấu hình chuẩn, kết nối sẽ tự động chuyển dời sang node 2 mà không cần bạn phải login lại.*

---

## 3. Kiểm tra tính năng di trú Service (Service Relocation)

Dùng Service để gom nhóm người dùng và di chuyển họ linh hoạt giữa các node mà không làm gián đoạn hệ thống.

**Lệnh thực hiện:**
1.  **Tạo một Service mới:**
    ```bash
    srvctl add service -d orcl -s HR_SERVICE -preferred orcl1 -available orcl2
    srvctl start service -d orcl -s HR_SERVICE
    ```
2.  **Kiểm tra:** Service này đang chạy trên `orcl1`.
3.  **Di chuyển Service:**
    ```bash
    srvctl relocate service -d orcl -s HR_SERVICE -oldinst orcl1 -newinst orcl2
    ```
    *Bạn sẽ thấy Service di chuyển sang node 2 "êm ái", giúp bạn có thể bảo trì node 1 mà không làm gián đoạn người dùng đang dùng HR_SERVICE.*
