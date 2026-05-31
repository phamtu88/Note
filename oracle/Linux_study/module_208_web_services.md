# Module 208: Dịch Vụ Web (Apache & Nginx)

Hướng dẫn cấu hình Virtual Hosts, SSL/TLS và Proxy cho các web server hàng đầu.

---

## 1. 🌐 Apache Web Server

### Virtual Host với SSL/TLS (`/etc/apache2/sites-available/example.conf`):
```apache
<VirtualHost *:443>
    ServerName example.com
    DocumentRoot /var/www/example

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/example.crt
    SSLCertificateKeyFile /etc/ssl/private/example.key

    <Directory /var/www/example>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```
**Kích hoạt**: `a2ensite example.conf` -> `systemctl reload apache2`.

---

## 2. ⚡ Nginx Web Server

### Nginx Virtual Host & Reverse Proxy:
```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    root /var/www/example;

    ssl_certificate /etc/ssl/certs/example.crt;
    ssl_certificate_key /etc/ssl/private/example.key;

    location / {
        try_files $uri $uri/ =404;
    }

    # Reverse Proxy cho ứng dụng chạy port 8080
    location /api {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
    }
}
```
**Kiểm tra**: `nginx -t` -> `systemctl reload nginx`.

---

## ❓ Câu Hỏi Ôn Tập

**1. Lệnh nào dùng để kiểm tra lỗi cú pháp trong file cấu hình Nginx?**
- A. `nginx -check`
- B. `nginx -t` (Đúng!)

**2. Trong Apache, chỉ thị nào dùng để chỉ đường dẫn chứa mã nguồn trang web?**
- A. `SourcePath`
- B. `DocumentRoot` (Đúng!)
