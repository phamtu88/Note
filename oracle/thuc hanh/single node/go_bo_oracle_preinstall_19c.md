# Hướng Dẫn Gỡ Bỏ Hoàn Toàn Gói oracle-database-preinstall-19c & Dọn Sạch Hệ Thống

Tài liệu này hướng dẫn chi tiết cách **xoá sạch hoàn toàn** mọi thứ mà gói `oracle-database-preinstall-19c` đã cấu hình, đưa hệ thống OS trở về trạng thái nguyên bản trước khi cài Oracle.

> [!WARNING]
> Tất cả các bước dưới đây đều phải thao tác bằng quyền **`root`**. Hãy chắc chắn đã backup dữ liệu quan trọng trước khi thực hiện.

---

## 1. Gỡ bỏ gói RPM oracle-database-preinstall-19c

Có **2 phương pháp** để gỡ gói preinstall. Tuỳ mức độ bạn muốn dọn sạch mà chọn:

### 🔵 Cách 1: `dnf remove` (Gỡ gói chính, giữ lại dependencies)
```bash
# Kiểm tra gói đã cài chưa
rpm -qa | grep oracle-database-preinstall

# Gỡ bỏ gói preinstall (giữ lại các dependency dùng chung của OS)
dnf remove -y oracle-database-preinstall-19c
```
*(Lệnh `dnf remove` chỉ gỡ mỗi gói chính, **không** gỡ các dependency kéo theo và **không** tự dọn các thay đổi cấu hình kernel, user, group mà nó đã tạo ra. Phải dọn thủ công theo các bước tiếp theo).*

### 🔴 Cách 2: `yum history undo` (Rollback nguyên transaction – GỠ TRIỆT ĐỂ cả dependencies)
Đây là phương pháp **mạnh nhất** — undo toàn bộ phiên giao dịch cài đặt, gỡ luôn tất cả các gói phụ thuộc đã kéo theo lúc `dnf install`:
```bash
# Bước 1: Xem lịch sử các transaction đã thực hiện
yum history
# Kết quả sẽ trả về danh sách transaction có đánh số ID, ví dụ:
#   ID | Command line             | Date and time    | Action(s) | Altered
#   ---+--------------------------+------------------+-----------+--------
#    4 | install oracle-database- | 2026-04-10 14:30 | Install   |   75

# Bước 2: Xác định đúng ID transaction đã cài preinstall (ví dụ ID = 4)
yum history info 4    # Xem chi tiết transaction đó đã cài những gói nào

# Bước 3: Undo nguyên transaction đó — gỡ sạch gói chính + toàn bộ dependencies
yum history undo 4 -y
```
> [!TIP]
> **Tại sao nên dùng `yum history undo`?** Khi bạn cài `oracle-database-preinstall-19c`, hệ thống kéo theo hàng chục gói phụ thuộc (compat-libcap, ksh, libaio-devel, sysstat...). Lệnh `dnf remove` chỉ gỡ 1 gói chính, còn `yum history undo` sẽ đảo ngược **toàn bộ transaction** — gỡ sạch cả gói chính lẫn mọi dependency đã cài kèm, đưa OS về đúng trạng thái trước khi cài.

---

## 2. Xoá User `oracle` và Home Directory
```bash
# Kiểm tra user oracle còn tồn tại không
id oracle

# Xoá user oracle kèm toàn bộ thư mục Home
userdel -r oracle
```
> [!CAUTION]
> Cờ `-r` sẽ xoá luôn thư mục `/home/oracle` và mailbox. Hãy chắc chắn đã sao lưu mọi dữ liệu quan trọng (scripts, bash_profile, wallet...) trước khi chạy lệnh này.

---

## 3. Xoá sạch các Group mà Preinstall đã tạo
Gói preinstall tạo ra hàng loạt group hệ thống chuyên dụng. Xoá từng group:
```bash
groupdel oinstall
groupdel dba
groupdel oper
groupdel backupdba
groupdel dgdba
groupdel kmdba
groupdel racdba
```
*(Nếu group nào báo `group 'xxx' does not exist` thì bỏ qua, không ảnh hưởng gì).*

---

## 4. Rollback cấu hình Kernel Parameters (sysctl)
Gói preinstall chèn tham số kernel vào file `/etc/sysctl.d/` hoặc `/etc/sysctl.conf`. Kiểm tra và xoá:
```bash
# Tìm file cấu hình kernel do Oracle tạo
ls -la /etc/sysctl.d/ | grep -i oracle

# Xoá file cấu hình kernel tham số Oracle (tên file có thể khác tuỳ phiên bản)
rm -f /etc/sysctl.d/97-oracle-database-sysctl.conf
rm -f /etc/sysctl.d/98-oracle-database-sysctl.conf

# Nạp lại kernel parameters sạch (loại bỏ giá trị Oracle cũ khỏi bộ nhớ)
sysctl --system
```

---

## 5. Rollback cấu hình Limits (Security Limits)
Gói preinstall chèn giới hạn tài nguyên cho user oracle vào thư mục `/etc/security/limits.d/`:
```bash
# Tìm file limits do Oracle tạo
ls -la /etc/security/limits.d/ | grep -i oracle

# Xoá file limits của Oracle
rm -f /etc/security/limits.d/oracle-database-preinstall-19c.conf
```

---

## 6. Dọn sạch các Dependency Packages thừa (Tuỳ chọn)
> [!NOTE]
> Nếu bạn đã dùng **Cách 2 (`yum history undo`)** ở Bước 1, thì bước này **có thể bỏ qua** vì dependencies đã bị gỡ sạch khi undo transaction. Bước này chỉ cần thiết nếu bạn dùng **Cách 1 (`dnf remove`)**.

Gói preinstall kéo theo hàng loạt dependency packages (thư viện dev, compatibility libs...). Dọn những gói không còn ai dùng:
```bash
# Liệt kê các gói mồ côi (không còn gói nào phụ thuộc)
yum autoremove -y
# Hoặc dùng dnf: dnf autoremove -y

# Dọn cache tải về của yum/dnf
yum clean all
```
> [!IMPORTANT]
> Lệnh `yum autoremove` chỉ gỡ các gói được đánh dấu là "dependency tự động kéo về". Các gói hệ thống cốt lõi sẽ **không bị ảnh hưởng**. Tuy nhiên hãy review danh sách trước khi xác nhận nếu muốn an toàn tuyệt đối: chạy `yum autoremove` (không có `-y`) để xem trước.

---

## 7. Xoá thư mục cài đặt Oracle (Nếu muốn dọn triệt để)
```bash
# Xoá toàn bộ cây thư mục phần mềm Oracle
rm -rf /u01/app/oracle
rm -rf /u02/oradata

# Xoá file cấu hình Oracle còn sót
rm -f /etc/oratab
rm -rf /opt/oracle
rm -rf /etc/oracle
```

---

## 8. Xoá Service Auto-start (Nếu đã cấu hình)
```bash
# Tắt và gỡ service dbora
systemctl stop dbora.service
systemctl disable dbora.service
rm -f /etc/systemd/system/dbora.service
systemctl daemon-reload
```

---

## ✅ Kiểm Tra Xác Nhận Dọn Sạch Hoàn Toàn
Chạy lần lượt các lệnh kiểm tra sau để nghiệm thu kết quả:
```bash
# 1. User oracle không còn tồn tại
id oracle                        # Kỳ vọng: "no such user"

# 2. Không còn group Oracle
grep -E "oinstall|dba|oper|backupdba|dgdba|kmdba|racdba" /etc/group
                                 # Kỳ vọng: Không có kết quả trả về

# 3. Gói RPM đã bị gỡ
rpm -qa | grep oracle-database-preinstall
                                 # Kỳ vọng: Không có kết quả trả về

# 4. Kernel params Oracle đã xoá
sysctl -a 2>/dev/null | grep -i "sem\|shmall\|shmmax\|shmmni"
                                 # Kỳ vọng: Chỉ còn giá trị mặc định OS

# 5. File limits Oracle đã xoá
ls /etc/security/limits.d/ | grep -i oracle
                                 # Kỳ vọng: Không có kết quả trả về
```

======================
*(Tài liệu tách riêng từ bộ Tài Liệu Toàn Tập Oracle 19c Single Instance).*
