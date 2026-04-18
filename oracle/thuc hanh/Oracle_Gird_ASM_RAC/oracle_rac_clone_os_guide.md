# [TÀI LIỆU CŨ] - Đã hợp nhất vào [02_OS_Preparation_and_Cloning.md](file:///d:/DB/setup/oracle/thuc%20hanh/Oracle_Gird_ASM_RAC/02_OS_Preparation_and_Cloning.md)

# Hướng dẫn Cấu hình sau khi Clone Server (OS Clean) cho Oracle RAC

Tài liệu này tập trung vào việc **xử lý định danh** để biến Node 2 thành bản sao không gây xung đột với Node 1. Các bước cấu hình IP, VIP, SCAN chi tiết vui lòng xem tại tài liệu mạng.

---

## 1. Thay đổi Hostname (Trên Node 2)
Đảm bảo máy ảo thứ 2 có tên duy nhất ngay khi khởi động.
```bash
hostnamectl set-hostname racnode2.localdomain
```

## 2. Reset Machine ID (Rất quan trọng cho Linux hiện đại)
Nhiều dịch vụ (như DHCP, logging) dựa vào `machine-id`. Nếu clone, ID này sẽ trùng.
```bash
# Xóa machine-id cũ và sinh cái mới
rm -f /etc/machine-id /var/lib/dbus/machine-id
systemd-machine-id-setup
```

## 3. Cập nhật MAC Address (VMware)
Khi clone máy ảo trên VMware:
- Hãy chọn **"I copied it"** khi được hỏi lúc bật máy lần đầu.
- Nếu không chắc, hãy vào **VM Settings -> Network Adapter -> Advanced -> Generate** một MAC address mới. Điều này tránh xung đột tầng vật lý (L2) trong mạng LAN.

## 4. Cấu hình IP cơ bản (Không cấu hình VIP)
Bạn chỉ cần đổi IP Public/Private của máy để có thể truy cập SSH.
- Sử dụng `nmtui` hoặc `nmcli` để đổi IP sang thông số của Node 2.
- **Lưu ý:** Tuyệt đối không để Node 2 khởi động với IP cũ của Node 1 cùng lúc trên mạng.

## 5. Xử lý định danh trong Biến môi trường
Nếu bạn clone khi đã có user `oracle` hoặc `grid`:
- Mở file `~/.bash_profile`.
- Sửa `ORACLE_HOSTNAME=racnode2.localdomain`.
- Sửa `ORACLE_SID` (ví dụ từ `orcl1` sang `orcl2`).

## 6. Làm sạch SSH Keys (Tránh lỗi bảo mật)
Khi clone, các Host Keys của SSH sẽ bị trùng. Hãy reset lại để bảo mật.
```bash
rm -f /etc/ssh/ssh_host_*
ssh-keygen -A
```

## 7. Kiểm tra UDEV Rules (Chỉ kiểm tra, không sửa)
Nếu bạn đã cấu hình UDEV cho ASM ở Node 1:
- Chạy lệnh `ll /dev/oracleasm/*`.
- Vì VMware dùng chung file đĩa SCSI với UUID cố định, thường Node 2 sẽ tự nhận diện đúng alias đĩa mà không cần sửa code.

---
> [!TIP]
> Sau khi xử lý xong các bước "tránh xung đột" này, bạn hãy thực hiện theo tài liệu cấu hình mạng chuyên sâu để thiết lập VIP và Interconnect.
