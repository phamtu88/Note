# Module 105: Shells & Shell Scripts

Làm chủ môi trường làm việc và tự động hóa các tác vụ lặp đi lặp lại.

---

## 1. ⚙️ Môi Trường Shell (Environment)

- **Biến môi trường**:
  - `echo $PATH`: Danh sách các thư mục chứa lệnh thực thi.
  - `export MY_VAR="Hello"`: Tạo biến môi trường.
  - `env`: Xem tất cả các biến đang có.
- **File cấu hình**:
  - `~/.bashrc`: Cấu hình cho Interactive shell (dùng hàng ngày).
  - `/etc/profile`: Cấu hình chung cho toàn bộ hệ thống.
  - `source ~/.bashrc`: Nạp lại cấu hình ngay lập tức.

---

## 2. 📜 Lập Trình Bash Script Nâng Cao

### Ví dụ Script Backup Đầy Đủ:
```bash
#!/bin/bash
# Script backup thư mục quan trọng
BACKUP_DIR="/backup"
SOURCE_DIR="/home"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/home_${DATE}.tar.gz"

# Kiểm tra thư mục backup tồn tại
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    echo "Created backup directory: $BACKUP_DIR"
fi

# Tạo backup
echo "Starting backup of $SOURCE_DIR..."
tar -czf "$BACKUP_FILE" "$SOURCE_DIR" 2>/dev/null

# Kiểm tra kết quả
if [ $? -eq 0 ]; then
    echo "✓ Backup successful: $BACKUP_FILE"
    ls -lh "$BACKUP_FILE"
else
    echo "X Backup failed!" >&2
    exit 1
fi

# Xóa backup cũ hơn 7 ngày
find "$BACKUP_DIR" -name "home_*.tar.gz" -mtime +7 -delete
echo "Old backups cleaned."
```

### Cấu Trúc Điều Khiển (Control Structures)

#### Vòng lặp (Loops)
```bash
# For loop
for server in web1 web2 web3; do
    ping -c 1 $server &>/dev/null && echo "$server UP" || echo "$server DOWN"
done

# While loop
count=0
while [ $count -lt 5 ]; do
    echo "Count: $count"
    ((count++))
done
```

#### Câu lệnh Case & Function
```bash
# Case statement
case "$1" in
    start) systemctl start nginx ;;
    stop)  systemctl stop nginx ;;
    *)     echo "Usage: $0 {start|stop}" ;;
esac

# Function
check_service() {
    systemctl is-active --quiet "$1" && echo "$1 is running" || echo "$1 is stopped"
}
check_service nginx
```

---

## ❓ Câu Hỏi Ôn Tập

**1. Lệnh nào dùng để biến một biến local thành biến môi trường có thể truy cập bởi các tiến trình con?**
- A. `set`
- B. `export` (Đúng!)
- C. `alias`

**2. File nào thường được dùng để lưu các Custom Alias của cá nhân người dùng?**
- A. `/etc/profile`
- B. `~/.bashrc` (Đúng!)
