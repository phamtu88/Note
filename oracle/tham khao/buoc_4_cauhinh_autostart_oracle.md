# Bước 4 - Cấu Hình Tự Động Bật Database Khi Khởi Động Máy (Auto-Start)

Dựa theo đúng chuẩn hướng dẫn cấu hình môi trường của Oracle và áp dụng các Script từ bài viết gốc của (Chuyên gia Trần Văn Bình), thao tác sẽ chia làm 3 phần như sau.

> **LƯU Ý:** Các thao tác chuẩn bị Script phải dùng tài khoản `oracle`. Thao tác làm việc với hệ thống (systemd) phải dùng tài khoản `root`.

---

### PHẦN 1: TẠO BỘ SCRIPT ĐIỀU KHIỂN TẬP TRUNG (Sử dụng user `oracle`)

**Mở Terminal hoặc kết nối SSH bằng user `oracle`, sau đó chạy toàn bộ cụm lệnh sau (Copy và dán chạy 1 lần):**

```bash
# 1. Tạo thư mục chứa các script vận hành
mkdir -p /home/oracle/scripts
cd /home/oracle/scripts

# 2. Tạo Script khai báo biến môi trường (setEnv.sh)
cat > /home/oracle/scripts/setEnv.sh <<EOF
# Oracle Settings
export TMP=/tmp
export TMPDIR=\$TMP
export ORACLE_HOSTNAME=oracle1.localdomain   # <- Đã cập nhật đúng chuẩn Hostname của máy bạn
export ORACLE_UNQNAME=orcl
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=\$ORACLE_BASE/product/19.0.0/dbhome_1
export ORA_INVENTORY=/u01/app/oraInventory
export ORACLE_SID=orcl
export ORACLE_HOME_LISTNER=\$ORACLE_HOME   # Bắt buộc có để dbstart khởi động được Listener
export PDB_NAME=pdb1
export DATA_DIR=/u02/oradata
export PATH=/usr/sbin:/usr/local/bin:\$PATH
export PATH=\$ORACLE_HOME/bin:\$PATH
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib
EOF

# 3. Tạo Script Khởi động tự động (start_all.sh)
cat > /home/oracle/scripts/start_all.sh <<EOF
#!/bin/bash
. /home/oracle/scripts/setEnv.sh
dbstart \$ORACLE_HOME
EOF

# 4. Tạo Script Tắt tự động (stop_all.sh) 
cat > /home/oracle/scripts/stop_all.sh <<EOF
#!/bin/bash
. /home/oracle/scripts/setEnv.sh
dbshut \$ORACLE_HOME
EOF

# 5. Cấp quyền thực thi cho các Script vừa tạo
chmod u+x /home/oracle/scripts/*.sh
```

---

### PHẦN 2: CHUYỂN TRẠNG THÁI KHỞI ĐỘNG CỦA DATABASE (Sử dụng user `root`)

Mặc định Oracle sẽ khóa cơ chế khởi động nền. Bạn phải "Bật chốt" trong file hệ thống `/etc/oratab`.

**1. Mở Terminal bằng user `root` (Hoặc gõ `su - root`).**
**2. Mở file để chỉnh sửa:**
```bash
vi /etc/oratab
```
**3. Kéo xuống dòng cuối cùng, bạn sẽ thấy dòng cấu hình dạng:**
`orcl:/u01/app/oracle/product/19.0.0/dbhome_1:N`

👉 **Thao tác:** Đổi chữ in hoa **`N`** (No) ở cuối dòng thành **`Y`** (Yes).
*Sau khi đổi xong, ấn phím `ESC`, gõ `:wq!` và ấn Enter để lưu lại.*

---

### PHẦN 3: ĐĂNG KÝ SERVICE VỚI HỆ ĐIỀU HÀNH LINUX (Sử dụng user `root`)

Bài viết tham khảo ở trên đã tạo trạm Script thành công, nhưng để Hệ điều hành tự động "bấm nút" chạy Script đó lúc bật máy tính thì ta phải tạo cho nó một Service chạy nền (Daemon).

**Cũng ở tài khoản `root`, copy và dán vào máy chủ cụm lệnh sau để thiết lập:**

```bash
# Tạo file service giao phó cho Linux tên là dbora.service
cat > /etc/systemd/system/dbora.service <<EOF
[Unit]
Description=Oracle Database 19c AutoStart
After=network.target

[Service]
Type=simple
# Mọi lệnh chạy ứng dụng này sẽ được ủy quyền cho thao tác dưới dạng user oracle
User=oracle
Group=oinstall
# Trỏ đường dẫn vào kịch bản Bật mà ta thiết lập ở Phần 1
ExecStart=/home/oracle/scripts/start_all.sh
# Trỏ đường dẫn vào kịch bản Tắt an toàn
ExecStop=/home/oracle/scripts/stop_all.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Load lại nhân hệ thống và Cập nhật bật Tính năng khởi động ngầm 
systemctl daemon-reload
systemctl enable dbora.service
systemctl start dbora.service

# Kiểm tra trạng thái màu xanh hoạt động của hệ thống
systemctl status dbora.service
```

> **🎉 NGHIỆM THU XONG:** Chỉ cần `systemctl status` báo chữ `active (running)` màu xanh lá là Database của bạn đã trở nên bất tử. Bất kỳ lúc nào bạn khởi động lại máy ảo (reboot), Database sẽ tự động vào tư thế `OPEN` sẵn sàng nhận truy vấn mà không phải đụng thêm 1 phím lệnh gõ tay nào!
