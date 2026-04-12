# Hướng dẫn Cấu hình Mạng và Hostname cho Oracle RAC 2-Nodes

Trong Oracle RAC, cấu hình mạng là phần quan trọng nhất. Nếu IP hoặc Hostname bị sai, Clusterware sẽ không thể khởi động hoặc giao tiếp giữa các node.

---

## 1. Quy hoạch Địa chỉ IP (IP Planning)

Mỗi Node trong cụm RAC yêu cầu ít nhất 3 loại địa chỉ IP. Giả sử dải mạng của bạn là `192.168.153.x`.

| Loại IP | Mục đích | Node 1 | Node 2 |
| :--- | :--- | :--- | :--- |
| **Public IP** | Kết nối chính (Quản trị, SSH) | `192.168.153.131` | `192.168.153.132` |
| **Virtual IP (VIP)** | Chuyển đổi dự phòng cho Client | `192.168.153.111` | `192.168.153.112` |
| **Private IP** | Đồng bộ dữ liệu (Interconnect) | `10.10.10.101` | `10.10.10.102` |
| **SCAN IP** | Điểm truy cập chung cho cả cụm | `192.168.153.120` | (Dùng chung) |

> [!IMPORTANT]
> - **Public IP** và **Private IP** phải được cấu hình cứng (Static) trong file cấu hình card mạng của OS (`ifcfg-ethX` hoặc `nmcli`).
> - **Virtual IP (VIP)** và **SCAN IP** KHÔNG ĐƯỢC cấu hình vào card mạng. Khi Grid Infrastructure cài đặt xong, nó sẽ tự động gán các IP này lên card mạng tương ứng.

---

## 2. Cấu hình file `/etc/hosts`

File này giúp các Node nhận diện nhau mà không cần DNS Server. Bạn cần copy nội dung dưới đây vào file `/etc/hosts` trên **CẢ 2 NODES**.

```text
# --- Public IP ---
192.168.153.131   oracle1.localdomain   oracle1
192.168.153.132   oracle2.localdomain   oracle2

# --- Virtual IP (VIP) ---
192.168.153.111   oracle1-vip.localdomain   oracle1-vip
192.168.153.112   oracle2-vip.localdomain   oracle2-vip

# --- Private IP (Interconnect) ---
10.10.10.101     oracle1-priv.localdomain   oracle1-priv
10.10.10.102     oracle2-priv.localdomain   oracle2-priv

# --- Single Client Access Name (SCAN) ---
192.168.153.120   oracle-scan.localdomain       oracle-scan
```

---

## 3. Kiểm tra thông mạng (Ping test)

Sau khi cấu hình xong Card mạng và Hostname, hãy thử ping từ Node 1 sang Node 2:

```bash
# Ping Public IP
ping 192.168.153.132

# Ping Private IP
ping 10.10.10.102
```

> [!WARNING]
> Nếu bạn không ping được IP Private (`10.10.10.x`), bước cài đặt Clusterware sẽ thất bại ở đoạn kiểm tra Interconnect. Hãy đảm bảo 2 VM cùng chung một VMnet (Ví dụ: `Host-only`) trong VMware.

---

## 4. Tắt tường lửa và SELinux

Để tránh các lỗi kết nối không đáng có trong quá trình cài đặt Lab:

```bash
# Tắt Firewall
systemctl stop firewalld
systemctl disable firewalld

# Tắt SELinux (Yêu cầu restart máy sau khi sửa)
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
setenforce 0
```

---

## 5. Giải thích các khái niệm quan trọng (Q&A)

Dưới đây là một số lưu ý kỹ thuật quan trọng trong quá trình thiết lập mạng cho Oracle RAC:

**1. Tại sao có thêm card mạng ảo `virbr0`?**
- Card mạng mạng bridge `virbr0` là do dịch vụ ảo hóa Linux (libvirtd) tự động sinh ra khi cài OS. Card này hoàn toàn không ảnh hưởng đến cụm RAC, bạn có thể bỏ qua nó và chỉ tập trung vào cấu hình các card vật lý (ens33, ens37).

**2. Tại sao KHÔNG gán địa chỉ VIP trực tiếp vào Card mạng của Hệ điều hành?**
- Oracle Grid Infrastructure quản lý Virtual IP. Bộ cài đặt sẽ tự lấy các IP VIP (đã khai báo trong `/etc/hosts`) và tự động khởi tạo card mạng ảo (như `ens33:1`) trên mức hệ điều hành. Nếu bạn tự gán IP đó tĩnh vào card mạng trước, Oracle sẽ lập tức báo lỗi *"IP này đang được sử dụng ở nơi khác"* và không cài đặt được.

**3. Tại sao lại có nhiều VIP (111, 112) mà không phải 1 VIP chung cho cả cụm?**
- Khác với cụm Active-Passive (HA cơ bản) chỉ dùng 1 VIP, **Oracle RAC là Active-Active**. MỐI Node có 1 VIP riêng. Tác dụng lớn nhất của nó là **Fast Application Failover**. Khi một Node bị cúp điện, Node còn lại sẽ cướp lấy VIP đó và chủ động từ chối kết nối TCP. Việc này giúp App của phía Client văng lỗi ngay lập tức (không bị treo TCP timeout vài phút) và tự chuyển sang Node sống. 
- Vai trò "1 IP chung cho cả cụm" trong Oracle được đảm nhiệm bởi **SCAN IP** (Single Client Access Name). Phần mềm bên ngoài thực tế sẽ chỉ kết nối vào 1 cái tên duy nhất là SCAN IP (`.120`).

**4. Tại sao tên máy trong `/etc/hosts` phải cực kỳ chính xác?**
- Bộ cài đặt của Oracle cực kì khắt khe về FQDN. Khi chạy kiểm tra, nó sẽ gọi lệnh `hostname` của OS. Nếu OS trả về `oracle1`, thì trong file `/etc/hosts` bắt buộc phải có tên `oracle1` trỏ về IP tĩnh (`192.168.153.131`). Nếu bạn khai báo lệch (ví dụ: OS là `oracle1` nhưng file hosts là `racnode1`), quy trình cài Grid sẽ bị dừng lại ngay.

**5. Có được phép dùng tính năng Snapshot của VMware lúc này không?**
- Bạn **HOÀN TOÀN ĐƯỢC PHÉP** (và rất nên) Snapshot OS ngay tại thời điểm cấu hình xong Network này, nhưng với ĐIỀU KIỆN TIÊN QUYẾT: Tất cả các ổ cứng chia sẻ `asm_disk` đã được tick chọn chế độ **Independent - Persistent**. Chế độ này giúp quá trình Snapshot chỉ sao lưu và khôi phục ổ đĩa Hệ điều hành (OS), không làm hỏng dữ liệu chia sẻ của Cụm RAC. (Lưu ý: Nếu bạn có lỡ Revert máy về bản Snapshot này, hãy nhớ dùng lệnh `dd` để xóa sạch toàn bộ header của phân vùng chia sẻ trước khi cài lại Grid).
