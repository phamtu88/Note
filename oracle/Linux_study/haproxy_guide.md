# Hướng Dẫn Cài Đặt, Cấu Hình và Vận Hành HAProxy trên Linux

## 1. Giới thiệu về HAProxy
HAProxy (High Availability Proxy) là một phần mềm mã nguồn mở mạnh mẽ, cung cấp tính năng cân bằng tải (Load Balancer) và Proxy TCP/HTTP với tính sẵn sàng cao. Nó đặc biệt phù hợp cho các trang web có lưu lượng truy cập lớn, cung cấp khả năng xử lý hàng chục nghìn kết nối đồng thời và được sử dụng rộng rãi bởi nhiều hệ thống lớn.

## 2. Cài đặt HAProxy

### Trên Ubuntu/Debian
```bash
# Cập nhật danh sách gói
sudo apt update

# Cài đặt HAProxy
sudo apt install haproxy -y

# Kiểm tra phiên bản sau khi cài đặt
haproxy -v
```

### Trên CentOS/RHEL/Oracle Linux (8/9)
```bash
# Cài đặt EPEL repository (nếu cần)
sudo dnf install epel-release -y

# Cài đặt HAProxy
sudo dnf install haproxy -y

# Kiểm tra phiên bản
haproxy -v
```

## 3. Cấu hình cơ bản (haproxy.cfg)

Tệp cấu hình chính của HAProxy nằm tại `/etc/haproxy/haproxy.cfg`. 
Tệp này thường được chia thành 4 phần chính: `global`, `defaults`, `frontend`, và `backend`.

**Luôn sao lưu cấu hình mặc định trước khi sửa:**
```bash
sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak
```

### Cấu trúc cơ bản
Dưới đây là một ví dụ cấu hình cân bằng tải HTTP cơ bản:

```haproxy
# 1. GLOBAL: Các cài đặt áp dụng cho toàn bộ tiến trình HAProxy
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

# 2. DEFAULTS: Cài đặt mặc định cho các frontend và backend kế tiếp
defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000

# 3. FRONTEND: Định nghĩa cách các request đi vào HAProxy
frontend http_front
    bind *:80
    default_backend web_servers

# 4. BACKEND: Định nghĩa các server xử lý request phía sau
backend web_servers
    balance roundrobin      # Thuật toán cân bằng tải (có thể dùng leastconn, source...)
    # Định nghĩa các server (check = bật tính năng Health Check)
    server web1 192.168.1.10:80 check
    server web2 192.168.1.11:80 check
```

## 4. Các tính năng nâng cao

### 4.1. Bật trang thống kê (Stats Page)
Để theo dõi tình trạng của các server, bạn có thể cấu hình trang thống kê trực quan.
Thêm đoạn sau vào cuối tệp `haproxy.cfg`:

```haproxy
listen stats
    bind *:8404
    mode http
    stats enable
    stats uri /stats
    stats refresh 10s
    # Bật xác thực người dùng cho trang stats (nếu cần)
    stats auth admin:MatKhauManh123 
```
Truy cập qua trình duyệt: `http://<IP_HAPROXY>:8404/stats`

### 4.2. Cấu hình SSL/TLS (HTTPS)
Để HAProxy xử lý HTTPS (SSL Termination), bạn cần gộp chứng chỉ (certificate) và khóa riêng (private key) vào chung một tệp `.pem`.

```bash
# Ví dụ gộp file:
cat cert.crt private.key > /etc/haproxy/certs/domain.pem
```

Cấu hình trong HAProxy:
```haproxy
frontend https_front
    bind *:80
    bind *:443 ssl crt /etc/haproxy/certs/domain.pem
    
    # Tự động chuyển hướng HTTP sang HTTPS
    http-request redirect scheme https unless { ssl_fc }
    
    default_backend web_servers
```

### 4.3. Các thuật toán cân bằng tải (Balance Algorithms)
Thay đổi giá trị `balance` trong phần `backend` tùy theo nhu cầu:
- `roundrobin`: Lần lượt chia đều request cho các server (mặc định, phù hợp cho web tĩnh).
- `leastconn`: Chuyển request đến server đang có ít kết nối nhất (phù hợp cho các kết nối dài như WebSocket, Database).
- `source`: Dựa vào IP của client để băm (hash), đảm bảo một client (cùng 1 IP) luôn truy cập vào cùng một server cố định (cần thiết cho Session).

## 5. Vận hành và Quản trị (Systemd)

Sau khi chỉnh sửa cấu hình, **luôn kiểm tra cú pháp** trước khi khởi động lại dịch vụ để tránh làm sập hệ thống:

### Kiểm tra cú pháp cấu hình
```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```
*Kết quả lý tưởng phải trả về: `Configuration file is valid`*

### Các lệnh quản lý dịch vụ
```bash
# Bật khởi động cùng hệ thống (Auto-start)
sudo systemctl enable haproxy

# Khởi động HAProxy
sudo systemctl start haproxy

# Dừng HAProxy
sudo systemctl stop haproxy

# Xem trạng thái dịch vụ
sudo systemctl status haproxy
```

**Lưu ý quan trọng khi cập nhật cấu hình:**
```bash
# KHÔNG sử dụng restart trừ khi bắt buộc, vì nó sẽ cắt đứt các kết nối đang có
sudo systemctl restart haproxy

# HÃY sử dụng reload, nó sẽ tạo tiến trình mới với cấu hình mới và từ từ kết thúc tiến trình cũ (Zero-downtime)
sudo systemctl reload haproxy
```

## 6. Xử lý sự cố (Troubleshooting) & Logs

### Xem Log
Theo mặc định, HAProxy gửi log cho dịch vụ `rsyslog`. Bạn có thể xem log thời gian thực bằng:
```bash
sudo tail -f /var/log/haproxy.log
```
*(Nếu không thấy file này, bạn có thể kiểm tra log qua `sudo journalctl -u haproxy`)*

### Các vấn đề thường gặp:
1. **HAProxy không khởi động được (Failed to start):** 
   - Kiểm tra xem cổng (port) bạn `bind` có bị ứng dụng khác (như Nginx/Apache) trên cùng máy chủ chiếm dụng không bằng lệnh: `sudo netstat -tulpn | grep 80`.
   - Kiểm tra kỹ lỗi cú pháp trong file config: `haproxy -c -f /etc/haproxy/haproxy.cfg`.
2. **Server backend bị đánh dấu màu đỏ (DOWN) trong trang Stats:**
   - Đảm bảo dịch vụ web trên server backend vẫn đang chạy.
   - Kiểm tra Firewall trên server backend có đang chặn IP của máy HAProxy truy cập vào port 80/443 không.
   - Tính năng `check` gửi gói tin TCP đến port backend. Nếu backend không phản hồi, nó sẽ bị đánh dấu DOWN để ngừng nhận traffic cho đến khi UP trở lại.
