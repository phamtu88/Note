# Module 203 & 204: Advanced Storage (LVM & RAID)

Quản lý lưu trữ quy mô lớn, linh hoạt và an toàn cho doanh nghiệp.

---

## 1. 🏗️ Logical Volume Manager (LVM)

LVM chia việc quản lý ổ đĩa thành 3 lớp:
1. **Physical Volume (PV)**: Ổ đĩa vật lý (`pvcreate /dev/sdb`).
2. **Volume Group (VG)**: Gom các PV vào một nhóm (`vgcreate data_vg /dev/sdb /dev/sdc`).
3. **Logical Volume (LV)**: Phân vùng ảo để mount (`lvcreate -L 50G -n db_lv data_vg`).

### Tính năng mạnh mẽ:
- **Resizing**: `lvextend -L +10G /dev/data_vg/web_lv` và `resize2fs` để mở rộng dung lượng online.
- **Snapshots**: `lvcreate -s -L 5G -n web_snap /dev/data_vg/web_lv` (Tạo bản sao tức thời để backup).

---

## 2. 💿 Software RAID (mdadm)

| RAID | Disks | Ưu điểm |
| :--- | :--- | :--- |
| **RAID 0** | 2 | Tốc độ cực nhanh, không có dự phòng (mất 1 đĩa là mất hết). |
| **RAID 1** | 2 | Mirroring (Dự phòng tốt, chết 1 đĩa vẫn chạy). |
| **RAID 5** | 3 | Cân bằng tốc độ và dự phòng (cho phép hỏng 1 đĩa). |

### Lệnh quản lý:
- **Tạo RAID 5**: `mdadm --create /dev/md0 --level=5 --raid-devices=3 /dev/sdb /dev/sdc /dev/sdd`
- **Xem trạng thái**: `cat /proc/mdstat` hoặc `mdadm --detail /dev/md0`
- **Xử lý đĩa hỏng**:
  - Đánh dấu hỏng: `mdadm /dev/md0 --fail /dev/sdc`
  - Gỡ bỏ: `mdadm /dev/md0 --remove /dev/sdc`
  - Thêm đĩa mới: `mdadm /dev/md0 --add /dev/sde`
