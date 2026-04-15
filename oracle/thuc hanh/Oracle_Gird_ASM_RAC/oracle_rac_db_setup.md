# Bước 5: Cài đặt Software và Tạo Database RAC 19c

Đây là bước cuối cùng để hoàn thiện hệ thống. Sau khi Clusterware đã chạy (ONLINE), chúng ta sẽ cài đặt phần mềm Database Core và tạo Cơ sở dữ liệu chạy trên ASM.

---

## 1. Chuẩn bị thư mục và bộ cài (Thực hiện TRÊN NODE 1)

Tương tự như Grid, Oracle Database 19c cũng sử dụng kiến trúc **Image-based Setup**. Bạn phải tạo thư mục Home trước, sau đó giải nén bộ cài trực tiếp vào đó.

### Bước A: Tạo thư mục Oracle Home (Quyền root)
Đăng nhập bằng user `root` trên **Node 1** để tạo thư mục:
```bash
mkdir -p /u01/app/oracle/product/19.0.0/dbhome_1
chown -R oracle:oinstall /u01/app/oracle/product/19.0.0/dbhome_1
chmod -R 775 /u01/app/oracle/product/19.0.0/dbhome_1
```

### Bước B: Giải nén bộ cài (Quyền oracle)
Đăng nhập bằng user `oracle` trên **Node 1**:
```bash
# 1. Chuyển vào thư mục Oracle Home
cd /u01/app/oracle/product/19.0.0/dbhome_1

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

### Bước B.1: Cấu hình SSH Passwordless cho User Oracle (Cực kỳ quan trọng)

Bộ cài Database RAC cần user `oracle` có thể điều khiển các node từ xa mà không hỏi mật khẩu. Ta thực hiện các bước tương tự như đã làm với user `grid`.

**Bước 1: Trên Node 1 (User oracle)**
```bash
su - oracle
ssh-keygen -t rsa   # Nhấn Enter liên tục cho đến khi xong
ssh-copy-id oracle1
ssh-copy-id oracle2
```

**Bước 2: Trên Node 2 (User oracle)**
```bash
su - oracle
ssh-keygen -t rsa
ssh-copy-id oracle1
ssh-copy-id oracle2
```

**Bước 3: Kiểm tra (Thực hiện trên cả 2 node)**
```bash
# Phải login qua lại được mà không hỏi mật khẩu
ssh oracle1 date
ssh oracle2 date
```

> [!TIP]
> Nếu bạn đã lỡ thiết lập bằng nút **SSH connectivity** của trình GUI và các lệnh `date` ở trên đã chạy thông suốt, bạn có thể bỏ qua bước này.

---

### Bước C: Các bước trên giao diện đồ họa (11 bước)
Khởi chạy trình cài đặt bằng lệnh `./runInstaller` và thực hiện theo 11 bước sau:

1.  **Step 1 — Configuration Option:** Chọn **Set Up Software Only** → Bâm **Next**.
2.  **Step 2 — Database Installation Options:** Chọn **Oracle Real Application Clusters database installation** → Bấm **Next**.
3.  **Step 3 — Node Selection:** Tick chọn cả 2 Node (`oracle1` và `oracle2`). Nhấn **Next**. (Tại đây nếu chưa có SSH thì dùng nút **SSH connectivity...**)
4.  **Step 4 — Database Edition:** Chọn **Enterprise Edition** → Bấm **Next**.
5.  **Step 5 — Installation Location:** Kiểm tra Oracle Base là `/u01/app/oracle` và Home là `/u01/app/oracle/product/19.0.0/dbhome_1`.
6.  **Step 6 — Operating System Groups:** Để mặc định (`dba`, `oper`, `backupdba`, `dgdba`, `kmdba`, `racdba`).
7.  **Step 7 — Root script execution:** Để trống (ta sẽ chạy thủ công sau).
8.  **Step 8 — Prerequisite Checks:** Chờ Oracle kiểm tra. Nếu có Warning nhẹ, tick **Ignore All** và nhấn **Next**.
9.  **Step 9 — Summary:** Kiểm tra lại lần cuối rồi nhấn **Install**.
10. **Step 10 — Install Product:** Quá trình cài đặt diễn ra. Khi hiện bảng yêu cầu chạy script, hãy mở Terminal (quyền `root`) và chạy lần lượt:
    - **Trên Node 1:** `/u01/app/oracle/product/19.0.0/dbhome_1/root.sh` *(Chờ chạy xong 100%)*
    - **Trên Node 2:** `/u01/app/oracle/product/19.0.0/dbhome_1/root.sh`
    - Cài xong trên cả 2 node thì quay lại màn hình GUI bấm **OK**.
11. **Step 11 — Finish:** Bấm **Close** để đóng trình cài đặt.

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

Khi giao diện cấu hình hiện lên, bạn thực hiện theo đúng 16 bước sau:

1.  **Step 1 — Database Operation:** Chọn **Create a database** → Bấm **Next**.
2.  **Step 2 — Creation Mode:** Chọn **Advanced configuration** (bắt buộc để cấu hình được lưu trữ ASM) → Bấm **Next**.
3.  **Step 3 — Deployment Type:**
    - Database type: **Oracle Real Application Cluster (RAC) database**
    - Chọn template: **General Purpose or Transaction Processing**
4.  **Step 4 — Nodes Selection:**
    - Đảm bảo tick chọn cả 2 Node: `oracle1` và `oracle2`.
5.  **Step 5 — Database Identification:**
    - Global database name: `orcl.localdomain`
    - SID prefix: `orcl`
    - Bỏ tick ô **Create as Container database** (Khuyên dùng: tắt đi để tạo database kiểu truyền thống, giúp tiết kiệm cực nhiều RAM và CPU cho máy ảo Lab).
6.  **Step 6 — Storage Option:**
    - Chọn **Use following for the database storage attributes**.
    - Database files storage type: **Automatic Storage Management (ASM)**.
    - Database files location: Nhập `+DATA`
7.  **Step 7 — Fast Recovery Option:**
    - Tick chọn **Specify Fast Recovery Area**.
    - Fast Recovery Area: Nhập `+FRA`.
    - Fast Recovery Area size: Nhập dung lượng tùy ý (thường nhỏ hơn tổng dung lượng FRA, ví dụ 15GB).
    - Có thể tick chọn **Enable archiving** luôn lúc này nếu muốn.
8.  **Step 8 — Data Vault Option:** Để mặc định (Không tick chọn Data Vault hay Label Security) → Bấm **Next**.
9.  **Step 9 — Configuration Options:**
    - Tab *Memory*: Chọn **Use Automatic Memory Management (AMM)** hoặc cấp phát RAM tự động (ASMM). Khuyến nghị để máy ảo cấp RAM khoảng 2-4GB tùy cấu hình của bạn.
    - Tab *Character sets*: Chọn `AL32UTF8` (rất quan trọng nếu lưu tiếng Việt).
    - Các tab khác để mặc định.
10. **Step 10 — Management Options:** Có thể bỏ tick EM Database Express để giảm tải cho máy ảo Lab.
11. **Step 11 — User Credentials:** Chọn **Use the same administrative password for all accounts** và nhập mật khẩu (ví dụ: `oracle123`).
12. **Step 12 — Creation Option:** Tick chọn **Create database** → Bấm **Next**.
13. **Step 13 — Prerequisite Checks:** Chờ hệ thống tự động quét lỗi (Nếu có cảnh báo nhé thì tick **Ignore All**).
14. **Step 14 — Summary:** Kiểm tra lại toàn bộ thông tin → Bấm **Finish** để bắt đầu.
15. **Step 15 — Progress Page:** Đợi quá trình tạo Database và chạy script cấu hình phân bổ lên 2 node (khá lâu).
16. **Step 16 — Finish:** Hoàn thành! Tùy chọn lưu lại URL của EM và bấm **Close**.

---

## 4. Kiểm tra và Cấu hình sau cài đặt

Sau khi cài đặt xong, bạn cần thực hiện các bước sau để đảm bảo môi trường làm việc thuận tiện:

### 4.1. Thiết lập môi trường tự động (User oracle)

Để không phải chạy lệnh `. oraenv` thủ công mỗi khi mở Terminal, bạn nên cấu hình tự động. Bạn có thể thực hiện việc này từ quyền `root` bằng cách chuyển sang `oracle`.

**Các bước thực hiện trên cả 2 Node:**

1.  **Chuyển sang user oracle:** 
    ```bash
    su - oracle
    ```
    *(Dấu "-" rất quan trọng để Oracle tải đúng profile của user)*.

2.  **Mở file cấu hình:**
    ```bash
    vi ~/.bash_profile
    ```

3.  **Chèn các dòng sau vào cuối file:**
    ```bash
    # Oracle Environment
    export ORACLE_SID=orcl1  # (Riêng Node 2 thì đặt là orcl2)
    export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
    export PATH=$ORACLE_HOME/bin:$PATH
    ```

4.  **Lưu file và kích hoạt ngay:**
    ```bash
    source ~/.bash_profile
    ```

Bây giờ bạn chỉ cần gõ `sqlplus / as sysdba` là hệ thống sẽ tự động kết nối vào đúng instance của Node đó.

### 4.2. Các lệnh kiểm tra quan trọng

**Kiểm tra trạng thái qua Clusterware (quyền oracle):**
```bash
srvctl status database -d orcl
```

**Kiểm tra bên trong Database (quyền sysdba):**
```sql
sqlplus / as sysdba
-- Truy vấn danh sách các Instance đang chạy trong cụm
SELECT instance_name, host_name, status FROM gv$instance;
```

> [!TIP]
> Luôn sử dụng lệnh `srvctl` để quản lý (START/STOP) Database RAC thay vì dùng lệnh `shutdown` trực tiếp trong SQLPlus, vì `srvctl` sẽ giúp Clusterware hiểu được trạng thái mong muốn của bạn.

---

## 4. Kiểm tra thành quả

Sau khi kết thúc DBCA, hãy kiểm tra trạng thái Instance trên cả 2 node:

```bash
# Sử dụng user oracle
srvctl status database -d <Tên_DB_của_bạn>
```

Kết quả mong đợi:
```text
Instance orcl1 is running on node racnode1
Instance orcl2 is running on node racnode2
```

---

## Kết luận

Bây giờ bạn đã có một hệ thống Oracle RAC 19c 2-Node hoàn chỉnh. Bạn có thể sử dụng SQLPlus để kết nối và thực hiện các bài Lab về High Availability (HA) và Load Balancing.

> [!TIP]
> Đừng quên ghi chú lại địa chỉ SCAN IP (`192.168.56.120`) và SCAN Name để cấu hình kết nối từ máy Client (như SQL Developer).
