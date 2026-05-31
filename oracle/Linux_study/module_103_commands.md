# Module 103: GNU & Unix Commands

Làm chủ dòng lệnh là kỹ năng "sống còn" của SysAdmin. Module này bao gồm 7 chủ đề trọng tâm.

## 📋 Danh Sách Chủ Đề
| Topic | Nội dung |
| :--- | :--- |
| 103.1 | Làm việc với command line shell |
| 103.2 | Xử lý văn bản (grep, awk, sed, cut, sort) |
| 103.3 | Quản lý files và thư mục |
| 103.4 | Streams, pipes, và I/O redirection |
| 103.5 | Tạo, theo dõi, tắt processes |
| 103.6 | Tìm kiếm với `find` |
| 103.7 | Tìm kiếm với `locate`, `which`, `whereis` |

---

## 1. 🐚 103.1 - Command Line Shell
Sử dụng Bash shell hiệu quả với phím tắt và biến môi trường.
- **`history`**: Xem lại các lệnh đã gõ.
- **`alias`**: Tạo tên viết tắt cho câu lệnh dài.
- **`export`**: Thiết lập biến môi trường.

---

## 2. ✍️ 103.2 - Xử Lý Văn Bản Nâng Cao

| Lệnh | Mô tả | Ví dụ |
| :--- | :--- | :--- |
| **grep** | Tìm kiếm pattern | `grep -i "error" /var/log/syslog` (Case-insensitive) |
| | | `grep -v "^#" /etc/fstab` (Loại bỏ dòng comment) |
| **cut** | Cắt theo delimiter | `cut -d: -f1,3 /etc/passwd` |
| **sort** | Sắp xếp | `sort -nk3 -t: /etc/passwd` (Theo UID cột 3, dạng số) |
| **awk** | Xử lý cột mạnh mẽ | `awk -F: '$3 > 1000 {print $1}' /etc/passwd` |
| **sed** | Chỉnh sửa stream | `sed -i 's/old/new/g' file.txt` (Thay thế trực tiếp) |

---

## 4. 🔀 103.4 - Streams, Pipes, Redirect

### I/O Redirection
- `ls > output.txt`: Ghi đè (stdout)
- `ls >> output.txt`: Ghi nối tiếp
- `ls /nonexist 2> err.txt`: Chỉ redirect thông báo lỗi (stderr)
- `ls /tmp &> all.txt`: Redirect cả stdout và stderr
- `ls | tee file.txt`: Vừa ghi file vừa hiển thị lên màn hình.

### Pipes (`|`)
Kết nối output của lệnh này làm input cho lệnh kia:
```bash
cat /var/log/auth.log | grep "Failed" | wc -l
```

---

## 5. ⚡ 103.5 - Quản Lý Processes

- **Xem tiến trình**: `ps aux` (BSD style), `top` (Real-time), `htop` (Trực quan hơn).
- **Gửi tín hiệu (Signals)**:
  - `kill -9 <PID>`: SIGKILL (Ép dừng ngay lập tức).
  - `kill -15 <PID>`: SIGTERM (Dừng an toàn).
  - `killall nginx`: Tắt theo tên service.
- **Background Jobs**:
  - `sleep 100 &`: Chạy nền.
  - `jobs`: Xem các job đang chạy.
  - `fg %1`: Đưa job 1 ra foreground.
  - `nohup script.sh &`: Chạy không bị ngắt khi logout.

---

## 6. 🔍 103.6 - Tìm Kiếm Với `find`

Cú pháp: `find [đường_dẫn] [tiêu_chí] [hành_động]`

- `find /home -name "*.log"`: Tìm theo tên.
- `find /tmp -mtime +7 -delete`: Xóa file cũ hơn 7 ngày.
- `find / -perm -4000`: Tìm các file có quyền SUID (bảo mật).
- `find /var -size +100M`: Tìm file lớn hơn 100MB.

---

## ❓ Câu Hỏi Ôn Tập

**1. Lệnh nào in ra cột 1 và 3 của file `/etc/passwd` với dấu phân cách là `:`?**
- A. `awk -d: '{print $1, $3}' /etc/passwd`
- B. `cut -d: -f1,3 /etc/passwd` (Đúng!)

**2. Để gửi cả stdout và stderr vào file `all.log`, lệnh nào đúng?**
- A. `command &> all.log` (Đúng!)
- B. `command 2>&1 all.log`

**3. Lệnh `sed` nào thay thế TẤT CẢ chữ "http" bằng "https" trong file `config.txt` và lưu trực tiếp?**
- A. `sed -i 's/http/https/g' config.txt` (Đúng! `-i` để sửa trực tiếp, `g` để thay thế tất cả).

> [!NOTE]
> **Đáp án**: 1-B, 2-A, 3-A.
