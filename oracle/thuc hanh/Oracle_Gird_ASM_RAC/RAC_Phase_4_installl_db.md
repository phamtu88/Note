# Bước 5: Cài đặt Software và Tạo Database RAC 19c

Đây là bước cuối cùng để hoàn thiện hệ thống. Sau khi Clusterware đã chạy (ONLINE), chúng ta sẽ cài đặt phần mềm Database Core và tạo Cơ sở dữ liệu chạy trên ASM.

---

## 1. Chuẩn bị thư mục và bộ cài (Thực hiện TRÊN NODE 1)

Tương tự như Grid, Oracle Database 19c cũng sử dụng kiến trúc **Image-based Setup**. Bạn phải tạo thư mục Home trước, sau đó giải nén bộ cài trực tiếp vào đó.

### Bước A: Tạo thư mục Oracle Home (Quyền root)
Đăng nhập bằng user `root` trên **Node 1** để tạo thư mục:
```bash
mkdir -p /u01/app/oracle/product/19.3.0/dbhome_1
chown -R oracle:oinstall /u01/app/oracle/product/19.3.0/dbhome_1
chmod -R 775 /u01/app/oracle/product/19.3.0/dbhome_1
```

### Bước B: Giải nén bộ cài (Quyền oracle)
Đăng nhập bằng user `oracle` trên **Node 1**:
```bash
# 1. Chuyển vào thư mục Oracle Home
cd /u01/app/oracle/product/19.3.0/dbhome_1

# 2. Giải nén trực tiếp bộ cài vào thư mục hiện tại
# Giả sử file zip nằm trong /tmp
unzip -q /tmp/LINUX.X64_193000_db_home.zip

# 3. Sau khi giải nén xong, có thể xóa file zip để tiết kiệm dung lượng
# rm -f /tmp/LINUX.X64_193000_db_home.zip
```

### Bước C: Khởi chạy trình cài đặt (GUI)
Đảm bảo đã bật X11 Forwarding và đang đứng tại thư mục `$ORACLE_HOME`:
```bash
./runInstaller
```

### Bước D: Chi tiết các bước trên Giao diện Đồ họa (GUI)

Khởi chạy trình cài đặt bằng lệnh `./runInstaller`. Dưới đây là hướng dẫn chi tiết từng lựa chọn để đảm bảo hệ thống RAC hoạt động tối ưu:

#### **Step 1: Configuration Option**
Xác định mục đích cài đặt:
*   **[CHỌN] Set Up Software Only**: Đối với cài đặt RAC, chúng ta luôn chọn cài đặt phần mềm trước, sau đó mới dùng công cụ DBCA để tạo Database. Điều này giúp tách biệt quá trình cài đặt binaries và cấu hình dữ liệu, dễ dàng kiểm soát lỗi.
*   *Create and configure a single instance database*: Chỉ dành cho máy đơn (Non-RAC).

#### **Step 2: Database Installation Options**
Lựa chọn loại hình triển khai:
*   **[CHỌN] Oracle Real Application Clusters database installation**: Đây là lựa chọn bắt buộc để cài đặt cho cụm RAC nhiều Node.
*   *Oracle RAC One Node database installation*: Một phiên bản "lai" chỉ chạy trên 1 node nhưng có khả năng failover sang node khác (ít dùng trong môi trường Lab).
*   *Single instance database installation*: Cài đặt bản đơn.

#### **Step 3: Node Selection**
*   Trình cài đặt sẽ tự động nhận diện các Node từ Clusterware (Grid) đã cài trước đó.
*   **Hành động**: Tick chọn cả **`oracle1`** và **`oracle2`**.
*   **SSH Connectivity**: Nếu bạn đã cấu hình SSH Passwordless ở Phase 2, bước này sẽ tự động trôi qua. Nếu chưa, bạn có thể dùng nút **`Setup...`** để bộ cài tự làm.

#### **Step 4: Database Edition**
*   **[CHỌN] Enterprise Edition**: Phiên bản đầy đủ nhất, hỗ trợ 100% các tính năng cao cấp của RAC như Partitioning, In-Memory, và quản trị tải.
*   *Standard Edition 2*: Hạn chế hơn về số lượng CPU và một số tính năng HA.

#### **Step 5: Installation Location**
Xác định nơi lưu trữ phần mềm:
*   **Oracle base**: `/u01/app/oracle`
*   **Software location (Oracle Home)**: `/u01/app/oracle/product/19.3.0/dbhome_1`
*   **Lưu ý**: Hãy đảm bảo đường dẫn này khớp hoàn toàn với thư mục bạn đã tạo ở Bước A.

#### **Step 6: Operating System Groups**
Xác định quyền hạn quản trị ở mức Hệ điều hành. Trình cài đặt sẽ tự nhận diện các group chúng ta đã tạo:
*   **Database Administrator (OSDBA)**: `dba`
*   **Database Operator (OSOPER)**: `oper`
*   **Database Backup and Recovery (OSBACKUPDBA)**: `backupdba`
*   **Data Guard Admin (OSDGDBA)**: `dgdba`
*   **Encryption Key Mgmt (OSKMDBA)**: `kmdba`
*   **Real Application Clusters Admin (OSRACDBA)**: `racdba`

#### **Step 7: Root script execution**
*   **[KHÔNG TÍCH]** "Automatically run configuration scripts".
*   *Lý do:* Tương tự như khi cài Grid, việc tự chạy script `root.sh` giúp bạn quan sát được tiến trình cấu hình hệ thống và xử lý lỗi ngay lập tức.

#### **Step 8: Prerequisite Checks**
*   Oracle sẽ kiểm tra tài nguyên (RAM, Swap, Kernel...).
*   Trong môi trường Lab, có thể xuất hiện cảnh báo (Warning) về DNS hoặc SCAN. Bạn hãy tick chọn **"Ignore All"** để tiếp tục.

#### **Step 9: Summary**
*   Xem lại toàn bộ thông số đã chọn. Nhấn **Install** để bắt đầu copy dữ liệu sang cả 2 Node.

#### **Step 10: Install Product & Run Root Scripts**
*   Khi tiến trình đạt khoảng 80%, bảng thông báo yêu cầu chạy script `root.sh` sẽ hiện ra.
*   **Thứ tự thực hiện (Bắt buộc):**
    1.  **Trên Node 1:** Chạy `/u01/app/oracle/product/19.3.0/dbhome_1/root.sh` bằng quyền `root`.
    2.  **Trên Node 2:** Chỉ chạy sau khi Node 1 đã hoàn thành 100%.
*   Sau khi xong, quay lại giao diện nhấn **OK**.

#### **Step 11: Finish**
*   Nhấn **Close** để hoàn tất cài đặt Software. Bây giờ bạn đã có bộ binaries Database sẵn sàng trên cả 2 máy.

### Chú ý: Xử lý các cảnh báo ở Bước 8 (Prerequisite Checks)

Trong môi trường Lab thực hành trên VMware, việc bảng kiểm tra hiện màu Đỏ (Failed) hoặc Vàng (Warning) ở Bước 8 là **hoàn toàn bình thường**. Dưới đây là giải thích cho các lỗi trong ảnh của bạn:

1.  **resolv.conf Integrity**:
    *   *Nguyên nhân:* Bộ cài kiểm tra file `/etc/resolv.conf` để tìm DNS Server. Vì chúng ta dùng file `/etc/hosts` để định danh node thay vì DNS thật, bộ cài sẽ báo lỗi này.
2.  **Clock Synchronization (NTP/Chrony)**:
    *   *Nguyên nhân:* Oracle yêu cầu thời gian trên 2 Node phải khớp tuyệt đối thông qua dịch vụ NTP hoặc Chrony. Trong máy ảo, đôi khi dịch vụ này chưa kịp đồng bộ hoặc có sai lệch vài mili giây.
3.  **SCAN và DNS/NIS name service**:
    *   *Nguyên nhân:* Oracle muốn `oracle-scan` được phân giải bởi DNS Server (để hỗ trợ 3 IP SCAN). Vì ta chỉ khai báo 1 IP SCAN trong `/etc/hosts`, nó sẽ báo lỗi Failed.

**Hành động:** 
Bạn hãy tích vào ô **"Ignore All"** (ở góc trên bên phải cửa sổ trình cài đặt). Khi đó, nút **Next** sẽ sáng lên để bạn nhấn và đi tiếp. Các lỗi này không ảnh hưởng đến việc chạy Database RAC trong môi trường thử nghiệm.

---

## 2. Tạo Disk Group DATA & FRA (ASMCA)

Trước khi tạo DB, ta cần gán 2 ổ đĩa còn lại (`asm_data1`, `asm_fra1`) vào các Disk Group.

Đăng nhập bằng user `grid` trên **Node 1**:
```bash
asmca
```
- Vào tab **Disk Groups**, bấm **Create**.
- **Tạo `DATA`:**
  - Disk Group Name: `DATA`
  - Redundancy: Chọn **External (None)** *(bắt buộc vì ta chỉ cấp 1 ổ đĩa cho DATA)*
  - Tick chọn đĩa `/dev/oracleasm/asm_data1` rồi bấm OK.
- **Tạo `FRA`:** Lặp lại bước trên, đặt tên là `FRA`, chọn Redundancy **External** và tick chọn đĩa `asm_fra1`.
- Đảm bảo trạng thái báo là `MOUNTED` trên cả 2 node tại màn hình chính của ASMCA.

---

## 3. Tạo Database bằng giao diện DBCA (16 Bước)

Đăng nhập bằng user `oracle` trên **Node 1**:
```bash
dbca
```

### Bước 3: Chi tiết các bước tạo Database bằng DBCA (16 Bước)

Đăng nhập bằng user `oracle` trên **Node 1** và chạy lệnh `dbca`. Đây là trình thuật sĩ sẽ giúp bạn cấu hình "trái tim" của hệ thống RAC:

#### **Step 1: Database Operation**
Xác định hành động bạn muốn thực hiện:
*   **[CHỌN] Create a database**: Tạo mới hoàn toàn hệ thống CSDL. 
*   *Configure an existing database*: Thay đổi cấu hình (RAM, Storage...) cho DB đã có.
*   *Delete database*: Xóa DB và toàn bộ file dữ liệu.
*   *Manage templates*: Lưu/Chỉnh sửa các mẫu cấu hình DB để dùng lại sau này.
*   *Manage Pluggable databases*: Quản trị các PDB trong mô hình Multitenant.
*   *Oracle RAC database instance management*: Thêm hoặc xóa một Instance (Node) khỏi cụm RAC hiện có.

#### **Step 2: Creation Mode**
*   **[CHỌN] Advanced configuration**: **BẮT BUỘC** chọn chế độ này để có thể tùy chỉnh các tham số quan trọng cho RAC như ASM Storage, RAM, và Character Set. Chế độ *Typical* sẽ không cho phép cấu hình RAC chuẩn.

#### **Step 3: Deployment Type**
Lựa chọn kiểu triển khai và mẫu dữ liệu:
*   **Database Type**: Chọn **Oracle Real Application Clusters (RAC) database** (Mô hình nhiều instance chia sẻ 1 database).
*   **Configuration Type**: Chọn **Admin-Managed** (DBA tự quản lý vị trí Instance, phù hợp cho Lab).
*   **Template**: Chọn **General Purpose or Transaction Processing** (Cân bằng giữa giao dịch và truy vấn, hỗ trợ file tạo sẵn giúp cài nhanh).

#### **Step 4: Nodes Selection**
*   Bộ cài sẽ liệt kê các máy chủ trong Cluster.
*   **Hành động**: Tick chọn cả **`oracle1`** và **`oracle2`**. Đảm bảo cột *Status* báo là `READY`.

#### **Step 5: Database Identification**
*   **Global Database Name**: `orcl.localdomain` (Phải bao gồm cả Domain).
*   **SID Prefix**: `orcl` (Oracle sẽ tự động thêm số 1, 2 vào sau cho từng node: `orcl1`, `orcl2`).
*   **Create as Container Database (CDB)**: 
    *   **[KHUYÊN DÙNG] BỎ TÍCH**: Đối với môi trường máy ảo Lab hạn chế về tài nguyên, việc tạo CDB/PDB sẽ ngốn rất nhiều RAM (thường yêu cầu thêm 1-2GB RAM). Nếu bạn chỉ muốn học về RAC, hãy bỏ tích để tạo Database kiểu truyền thống cho nhẹ máy.

#### **Step 6: Storage Option**
Xác định nơi lưu trữ các tệp dữ liệu vật lý:
*   **Database files storage type**: Luôn chọn **Automatic Storage Management (ASM)**. Trong môi trường RAC, đây là hạ tầng lưu trữ chia sẻ duy nhất giúp các node cùng đọc/ghi đồng thời.
*   **Database files location**: Nhập **`+DATA`**. Hệ thống sẽ tự tạo thư mục con theo tên DB của bạn (ví dụ: `+DATA/orcl/`).
*   **Use Oracle-Managed Files (OMF) [Ô tích]**: 
    *   **[NÊN CHỌN]**: Khi tích ô này, Oracle sẽ tự động đặt tên và quản lý đường dẫn cho các tệp dữ liệu. Bạn không cần phải nhớ tên file loằng ngoằng như `system01.dbf`, giúp việc quản trị ASM trở nên cực kỳ đơn giản.
*   **Multiplex redo logs and control files**: Tùy chọn này cho phép bạn nhân bản (mirror) các file quan trọng nhất của DB sang nhiều Disk Group khác nhau (ví dụ vừa lưu ở `+DATA` vừa lưu ở `+FRA`) để tăng độ an toàn dữ liệu.

#### **Step 7: Fast Recovery Option**
Xác định nơi lưu trữ các tệp phục hồi (Archive Logs, Backups):
*   **[TÍCH] Specify Fast Recovery Area**:
    *   **Recovery files storage type**: Chọn **ASM**.
    *   **Fast Recovery Area**: Nhập **`+FRA`**.
    *   **Fast Recovery Area size**: Đây là hạn mức dung lượng cho vùng phục hồi. Trong môi trường Lab, bạn có thể để mặc định hoặc cấp khoảng 10-15GB tùy dung lượng ổ FRA.
*   **[TÍCH] Enable Archiving**: 
    *   **[BẮT BUỘC]**: Việc bật chế độ Archive Log giúp Database có thể phục hồi dữ liệu đến từng giây (Point-in-time Recovery) và là điều kiện cần để thực hiện sao lưu nóng (Hot Backup).

#### **Step 8: Data Vault Option**
Lựa chọn các tính năng bảo mật nâng cao:
*   **[BỎ TRỐNG]**: Không tích vào *Oracle Database Vault* hay *Oracle Label Security*.
*   *Lý do:* Đây là các tính năng bảo mật tầng sâu (ngăn chặn ngay cả quản trị viên `SYS` truy cập dữ liệu nhạy cảm). Chúng sẽ làm Database tiêu tốn thêm nhiều RAM/CPU và làm quá trình khởi động chậm lại đáng kể, không cần thiết cho môi trường Lab thực hành RAC.

#### **Step 9: Configuration Options**
Đây là một trong những bước quan trọng nhất để tinh chỉnh hiệu suất và ngôn ngữ của Database. Bạn cần lưu ý 5 Tab sau:

*   **Tab Memory**:
    *   **SGA (System Global Area)**: Vùng nhớ dùng chung (chứa dữ liệu, mã SQL). Trong cụm RAC, các instance sẽ có SGA riêng trên từng node.
    *   **PGA (Program Global Area)**: Vùng nhớ riêng cho mỗi kết nối (dùng để sắp xếp dữ liệu, join bảng).
    *   **[NÊN CHỌN] Automatic Shared Memory Management (ASMM)**: Để Oracle tự động điều phối RAM giữa các thành phần bên trong SGA tùy theo tải của hệ thống.
*   **Tab Sizing**:
    *   **Processes**: Số lượng tiến trình (kết nối) tối đa cùng lúc. Giá trị mặc định khoảng 300-320 là đủ cho môi trường Lab.
*   **Tab Character sets**:
    *   **[QUAN TRỌNG] Use Unicode (AL32UTF8)**: Đây là chuẩn quốc tế, giúp Database lưu trữ được tiếng Việt và các ngôn ngữ khác mà không bị lỗi font.
*   **Tab Connection Mode**:
    *   **[CHỌN] Dedicated server mode**: Mỗi kết nối từ người dùng sẽ được cấp một tiến trình riêng. Đây là chế độ an toàn và ổn định nhất cho đa số các ứng dụng.
*   **Tab Sample schemas**:
    *   Nếu bạn tích chọn **Add sample schemas**, Oracle sẽ cài thêm các bộ dữ liệu mẫu (như nhân sự HR, bán hàng...) để bạn tiện thực hành Lab SQL. Tuy nhiên, nó sẽ làm Database chiếm thêm một chút dung lượng đĩa.

#### **Step 10: Management Options**
Cấu hình các công cụ quản trị và kiểm tra:
*   **Run Cluster Verification Utility (CVU) checks periodically**: Tự động chạy các bài kiểm tra sức khỏe của cụm RAC định kỳ. Giúp bạn phát hiện sớm các vấn đề về mạng hoặc lưu trữ.
*   **Configure Enterprise Manager (EM) database express**: 
    *   Đây là giao diện web quản trị gọn nhẹ tích hợp sẵn vào Database.
    *   **Lưu ý**: Nếu máy ảo Lab của bạn có ít RAM (dưới 8GB), bạn có thể **BỎ TÍCH** ô này để tiết kiệm tài nguyên. Nếu vẫn muốn dùng, hãy ghi nhớ cổng (thường là `5500`) để truy cập sau này.
*   **Register with Enterprise Manager (EM) cloud control**: Chỉ dùng khi bạn có một máy chủ quản trị EM trung tâm chuyên nghiệp. Trong môi trường Lab, hãy để trống.

#### **Step 11: User Credentials**
*   **[CHỌN] Use the same administrative password for all accounts**.
*   Nhập mật khẩu cho `SYS`, `SYSTEM` (Ví dụ: `Oracle123`).

#### **Step 12: Creation Option**
Xác định cách thức triển khai cuối cùng:
*   **[TÍCH] Create database**: Để thực hiện cài đặt và cấu hình DB ngay lập tức lên các node.
*   **Save as a database template**: Lưu lại toàn bộ các bước bạn đã chọn nãy giờ thành một "khuôn mẫu". Rất hữu ích nếu bạn muốn tạo nhiều DB giống hệt nhau trong tương lai mà không cần bấm lại từng bước.
*   **Generate database creation scripts**: Thay vì cài ngay, Oracle sẽ xuất ra một bộ các câu lệnh SQL và Shell script. Bạn có thể dùng bộ script này để cài đặt DB qua dòng lệnh (Silent Mode) sau này.
*   **All Initialization Parameters**: Cho phép bạn xem và chỉnh sửa các tham số hệ thống (`SGA_TARGET`, `PROCESSES`, `DB_BLOCK_SIZE`...) trước khi nhấn Finish.

#### **Step 13: Prerequisite Checks**
*   Hệ thống sẽ quét lại lần cuối. Nếu có Warning về SCAN hay Memory, tích **Ignore All** và nhấn **Next**.

#### **Step 14: Summary**
*   Kiểm tra lại danh sách các SID và Disk Group. Nhấn **Finish**.

#### **Step 15: Progress Page**
*   Quá trình này diễn ra khá lâu (từ 15-30 phút tùy tốc độ ổ cứng). Bạn có thể mở Terminal login user `grid` và gõ `crsctl status resource -t` để thấy các Instance `orcl1`, `orcl2` từ từ hiện lên trạng thái `STARTING` rồi `ONLINE`.

#### **Step 16: Finish**
*   Bấm **Close** khi có thông báo thành công.

---


## 4. Kiểm tra và Vận hành Database

Sau khi cài đặt xong, bạn có thể kiểm tra trạng thái của cụm và database bằng các công cụ quản trị của Oracle.

### 4.1. Các lệnh kiểm tra quan trọng

**Kiểm tra trạng tháiInstance qua Clusterware (quyền oracle):**
```bash
srvctl status database -d orcl
```

**Kiểm tra chi tiết bên trong Database (quyền sysdba):**
```sql
sqlplus / as sysdba
-- Truy vấn danh sách các Instance đang chạy trong cụm
SELECT instance_name, host_name, status FROM gv$instance;
```

> [!TIP]
> Luôn sử dụng lệnh `srvctl` để quản lý (START/STOP) Database RAC thay vì dùng lệnh `shutdown` trực tiếp trong SQLPlus. `srvctl` giúp Clusterware hiểu được trạng thái mong muốn của bạn và quản lý tài nguyên tốt hơn.

---

## Kết luận

Bây giờ bạn đã có một hệ thống Oracle RAC 19c 2-Node hoàn chỉnh. Bạn có thể sử dụng SQLPlus để kết nối và thực hiện các bài Lab về High Availability (HA) và Load Balancing.

> [!TIP]
> Đừng quên ghi chú lại địa chỉ SCAN IP (`192.168.56.120`) và SCAN Name để cấu hình kết nối từ máy Client (như SQL Developer).
