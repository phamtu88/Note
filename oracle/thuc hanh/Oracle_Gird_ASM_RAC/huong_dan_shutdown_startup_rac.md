# Hướng dẫn Shutdown và Startup cụm Oracle RAC 19c

Để bảo vệ dữ liệu và cấu hình Cluster, việc tắt và bật cụm RAC cần tuân thủ đúng thứ tự. Khác với Single Node, RAC được quản lý bởi Oracle Grid Infrastructure (Clusterware).

---

## 1. Quy trình Shutdown (Tắt cụm máy chủ)

Thực hiện lệnh theo đúng thứ tự từ trên xuống dưới.

### Bước 1: Dừng Database (Thực hiện trên Node 1 - User oracle)
Bình thường bạn chỉ cần chạy lệnh này trên 1 node, nó sẽ tự động ra lệnh dừng các Instance trên toàn bộ các node trong cụm.

```bash
su - oracle
srvctl stop database -d orcl
```
*(Thay `orcl` bằng tên DB của bạn nếu khác)*.

### Bước 2: Dừng Clusterware (Thực hiện trên CẢ 2 NODE - User root)
Sau khi Database đã dừng, bạn cần dừng Grid Infrastructure trên từng node. Lệnh này chỉ tác động đến node hiện tại, vì vậy bạn cần thực hiện lần lượt (hoặc song song) trên cả 2 máy.

```bash
# Trên Node 1
su -
/u01/app/19.3.0/grid/bin/crsctl stop crs

# Trên Node 2
su -
/u01/app/19.3.0/grid/bin/crsctl stop crs
```

> [!TIP]
> Bạn có thể dùng lệnh sau từ một node để dừng toàn bộ cụm (Cluster Stack) trên tất cả các node cùng lúc:
> `/u01/app/19.3.0/grid/bin/crsctl stop cluster -all`
> Tuy nhiên, lệnh `stop crs` ở trên là lệnh triệt để nhất để chuẩn bị tắt máy (nó tắt cả tầng hỗ trợ OHAS).

> [!NOTE]
> Bạn có thể phải đợi 1-3 phút để các dịch vụ như ASM, Network, Clusterware dừng hoàn toàn. Nếu lệnh báo dừng thành công là ổn.

### Bước 3: Tắt Máy ảo (VM)
Sau khi Clusterware đã OFFLINE, bạn có thể tắt máy ảo an toàn từ VMware hoặc dùng lệnh:
```bash
shutdown -h now
```

---

## 2. Quy trình Startup (Bật cụm máy chủ)

### Bước 1: Bật các máy ảo (Node 1 trước, Node 2 sau)
Thứ tự bật thường là Node 1 (chứa các dịch vụ quản trị ban đầu) rồi đến Node 2. Đợi Linux khởi động xong.

### Bước 2: Kiểm tra trạng thái Clusterware (User root hoặc grid)
Thông thường, Oracle Grid Infrastructure được cấu hình tự động bật cùng OS. Bạn nên kiểm tra xem nó đã lên chưa:

```bash
su - grid
crsctl check crs
```
*Kết quả mong đợi (Tất cả phải báo là `is online`):*

```text
CRS-4638: Oracle High Availability Services is online
CRS-4537: Cluster Ready Services is online
CRS-4529: Cluster Synchronization Services is online
CRS-4533: Event Manager is online
```


Để xem chi tiết các tài nguyên (ASM, VIP, Listener...):
```bash
crsctl status resource -t
```
*Kết quả mong đợi (Ví dụ):*
```text
--------------------------------------------------------------------------------
Name           Target  State        Server                   State details       
--------------------------------------------------------------------------------
Local Resources
--------------------------------------------------------------------------------
ora.LISTENER.lsnr
               ONLINE  ONLINE       oracle1                  STABLE
               ONLINE  ONLINE       oracle2                  STABLE
ora.asm
               ONLINE  ONLINE       oracle1                  Started,STABLE
               ONLINE  ONLINE       oracle2                  Started,STABLE
ora.ons
               ONLINE  ONLINE       oracle1                  STABLE
               ONLINE  ONLINE       oracle2                  STABLE
--------------------------------------------------------------------------------
Cluster Resources
--------------------------------------------------------------------------------
ora.LISTENER_SCAN1.lsnr
      1        ONLINE  ONLINE       oracle1                  STABLE
ora.asmdg
      1        ONLINE  ONLINE       oracle1                  STABLE
      2        ONLINE  ONLINE       oracle2                  STABLE
ora.orcl.db
      1        ONLINE  ONLINE       oracle1                  Open,HOME=/u01/app/oracle/product/19.3.0/dbhome_1,STABLE
      2        ONLINE  ONLINE       oracle2                  Open,HOME=/u01/app/oracle/product/19.3.0/dbhome_1,STABLE
ora.scan1.vip
      1        ONLINE  ONLINE       oracle1                  STABLE
...
```
*Đảm bảo các cột `State` và `Target` đều là `ONLINE` cho các dịch vụ quan trọng.*


### Bước 3: Kiểm tra Database (User oracle)
Database RAC cũng thường được cấu hình tự động bật khi Clusterware sẵn sàng.

```bash
su - oracle
srvctl status database -d orcl
```
*Nếu báo "Instance orcl1 is running..." là đã thành công.* 
*Nếu chưa lên, bạn có thể bật thủ công:*
```bash
srvctl start database -d orcl
```

---

## Các lưu ý quan trọng:
1. **Không tắt ngang máy ảo:** Tắt máy ảo đột ngột khi RAC đang chạy có thể gây lỗi Disk Group ASM hoặc lỗi File System.
2. **Ưu tiên dùng `srvctl`:** Luôn dùng `srvctl` để quản lý DB trong RAC. Hạn chế dùng lệnh `shutdown` trong SQLPlus vì nó làm Clusterware hiểu nhầm là Instance bị lỗi và sẽ cố gắng restart lại nó.
3. **Log files:** Nếu gặp lỗi khi tắt/bật, hãy kiểm tra log tại:
   - GI Log: `$GRID_HOME/log/<hostname>/alert<hostname>.log`
   - DB Log: `$ORACLE_BASE/diag/rdbms/<db_name>/<sid>/trace/alert_<sid>.log`
