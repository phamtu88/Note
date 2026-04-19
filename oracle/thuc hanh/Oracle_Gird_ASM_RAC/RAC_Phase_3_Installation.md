# Giai đoạn 3: Cài đặt (Installation)

Giai đoạn này tập trung vào quy trình chạy các bộ cài đặt đồ họa (OUI) và cấu hình cụm Cluster.

---

## 1. Cài đặt Grid Infrastructure (GI) 19c
Đây là bước quan trọng nhất, thiết lập "linh hồn" của hệ thống RAC.

### 1.1 Chuẩn bị bộ cài
*   Download file zip Grid Infrastructure 19c.
*   Giải nén **trực tiếp** vào thư mục `GRID_HOME` đã tạo ở Phase 2 (VD: `/u01/app/19.3.0/grid`).
*   **Lưu ý:** Không giải nén ở chỗ khác rồi copy vào, vì sẽ mất các thuộc tính file.

### 1.2 Chạy bộ cài
Đảm bảo bạn đã bật X11 Forwarding và **đăng nhập trực tiếp bằng user `grid`**:
```bash
cd /u01/app/19.3.0/grid
./gridSetup.sh
```

---

### 1.3 Chi tiết 19 bước cài đặt trên Giao diện Đồ họa (GUI)

Dưới đây là hướng dẫn chi tiết từng bước khớp với thanh điều hướng bên trái của Installer:

#### **Step 1: Configuration Option**
*   **[CHỌN] Configure Oracle Grid Infrastructure for a New Cluster**: Dùng để dựng cụm RAC.
*   *Khi nào chọn option khác:* 
    *   **Standalone Server**: Dùng cho máy đơn muốn dùng ASM (Oracle Restart).
    *   **Upgrade**: Khi nâng cấp từ phiên bản cũ (12c, 18c).
    *   **Software Only**: Khi chỉ muốn cài binaries để cấu hình sau (Gold Image).

#### **Step 2: Select Cluster Configuration**
Lựa chọn kiến trúc nền tảng cho hệ thống Cluster:

*   **[CHỌN] Configure an Oracle Standalone Cluster**: Đây là cấu hình RAC phổ biến nhất. Tất cả các thành phần dịch vụ (ASM, GNS, Cluster Health Monitor...) đều được cài đặt và quản lý cục bộ ngay trên các Node của cụm này.
*   **Configure an Oracle Domain Services Cluster**: Một cụm nắm giữ tài nguyên "vùng" (Domain Services). Nó cung cấp các dịch vụ dùng chung (như ASM trung tâm, Storage) cho các cụm khác trong hạ tầng.
*   **Configure an Oracle Member Cluster for Oracle Databases**: Một cụm chỉ chuyên dùng để chạy Oracle Database. Nó không tự quản lý ASM mà kết nối về một *Domain Services Cluster* có sẵn để sử dụng bộ lưu trữ.
*   **Configure an Oracle Member Cluster for Applications**: Tương tự Member Cluster nhưng chỉ để chạy các ứng dụng (không phải Database) cần tính năng sẵn sàng cao (High Availability) của Clusterware.
*   **Configure as an Oracle Extended cluster (Ô tích kèm Site Names)**: 
    *   Sử dụng khi các Node nằm ở các **vị trí địa lý khác nhau** (ví dụ: Node 1 ở Quận 1, Node 2 ở Quận 3). 
    *   Cần cấu hình **Site names** (tên các vị trí) để Oracle biết cách phân bổ dữ liệu (Mirroring) đảm bảo nếu 1 tòa nhà bị sập, tòa nhà kia vẫn có đủ bản sao dữ liệu. Yêu cầu tối thiểu 3 site để quản lý Quorum.

#### **Step 3: Grid Plug and Play**
Cấu hình cách thức định danh và kết nối vào cụm:

*   **[CHỌN] Create Local SCAN**: Tạo bộ 3 địa chỉ SCAN VIP cục bộ cho cụm này.
    *   **Cluster Name**: Tên duy nhất định danh cụm (VD: `oracle-cluster`).
    *   **SCAN Name**: Tên miền ảo để ứng dụng kết nối (VD: `oracle-scan.localdomain`). Phải khớp với khai báo trong `/etc/hosts`.
    *   **SCAN Port**: Cổng Listener trung tâm (mặc định 1521).
*   **Use Shared SCAN**: Chỉ dùng cho **Member Cluster**. Nó cho phép cụm này dùng chung hạ tầng SCAN của một cụm trung tâm (Domain Services Cluster) khác. Bạn cần trỏ tới file tệp dữ liệu khách (Client Data file).
*   **Configure GNS (Grid Naming Service) [Ô tích bên dưới]**:
    *   Đây là dịch vụ giúp tự động cấu hình IP (VIP, SCAN) thông qua DHCP và DNS mà không cần sửa file `/etc/hosts` thủ công trên từng máy.
    *   **Create a new GNS**: Tự dựng một server GNS trên cụm này. Yêu cầu một **GNS VIP Address** và một **Sub Domain** riêng.
    *   **Use Shared GNS**: Dùng chung dịch vụ GNS từ một cụm máy chủ khác.
    * *Lời khuyên:* Với môi trường Lab hoặc hệ thống ít Node, ta **KHÔNG** chọn GNS để đơn giản hóa việc quản trị IP tĩnh.

#### **Step 4: Cluster Node Information**
Quản lý danh sách các máy chủ tham gia vào cụm:

*   **Public Hostname**: Tên máy chủ (Hostname) để các ứng dụng nhìn thấy.
*   **Virtual Hostname**: Tên máy ảo (VIP Hostname) dùng để failover khi một Node bị sập.
*   **Các nút điều khiển**:
    *   **Add...**: Thêm Node mới vào cụm. Bạn cần nhấn vào đây để thêm `oracle2` và `oracle2-vip`.
    *   **Edit.../Remove**: Chỉnh sửa hoặc xóa Node khỏi danh sách.
    *   **Use Cluster Configuration File**: Nhập danh sách Node từ một file cấu hình có sẵn (thường dùng khi số lượng Node cực lớn).
*   **SSH Connectivity**:
    *   Mục này cực kỳ quan trọng để bộ cài có thể copy file sang các Node khác.
    *   **Reuse private and public keys...**: Luôn tích chọn ô này vì chúng ta đã tự cấu hình SSH Passwordless ở Phase 2.
    *   **Setup**: Bộ cài sẽ tự động thiết lập lại SSH nếu bạn chưa làm.
    *   **Test**: Kiểm tra xem kết nối đã thông suốt chưa. Nếu hiện thông báo **"already established"** như ảnh của bạn là đã thành công 100%.

#### **Step 5: Network Interface Usage**
Đây là bước cực kỳ quan trọng để tách biệt luồng dữ liệu khách và luồng dữ liệu nội bộ:

*   **Public**: Dùng cho card mạng kết nối ra ngoài (NAT/Bridged). Đây là đường để các Application kết nối vào Database.
*   **Private**: Dùng cho card mạng Interconnect (truyền tải dữ liệu giữa các Node).
*   **ASM & Private**: **[KHUYÊN DÙNG]** Cho phép card mạng vừa làm nhiệm vụ Interconnect, vừa vận chuyển dữ liệu ASM. Đây là tiêu chuẩn cho Oracle 19c.
*   **ASM**: Chỉ dùng để vận chuyển dữ liệu ASM (nếu bạn có card mạng thứ 3 riêng biệt).
*   **Do Not Use**: Bỏ qua interface (thường là các card ảo như `virbr0`, `docker0`).

**Hành động:**
*   `ens33` (Dải 192.168...): Chọn **Public**.
*   `ens37` (Dải 10.10.10...): Chọn **ASM & Private**.
*   `virbr0`: Chọn **Do Not Use**.

#### **Step 6: Storage Option**
Xác định nơi lưu trữ các file quản trị cốt lõi (OCR và Voting Disk):

*   **[CHỌN] Use Oracle Flex ASM for storage**: Đây là lựa chọn mặc định và tối ưu nhất cho 19c. Nó cho phép các instance ASM chạy linh hoạt và hỗ trợ tốt cho việc mở rộng cụm sau này.
*   **Use Shared File System**: Chỉ chọn nếu bạn định lưu OCR/Voting Disk trên một hệ thống file chia sẻ như NFS hoặc OCFS2. Vì ta dùng đĩa ASM (qua UDEV) nên **KHÔNG** chọn cái này.

#### **Step 7: Grid Infrastructure Management Repository (GIMR)**
*   **[CHỌN] No**: Trong môi trường Lab hoặc hệ thống nhỏ, ta không cần GIMR để tiết kiệm RAM và dung lượng đĩa OCR.

#### **Step 8: Create ASM Disk Group**
Đây là nơi bạn "gom" các đĩa cứng vật lý thành các ổ đĩa logic của Oracle. Màn hình này cần được cấu hình cực kỳ chuẩn xác:

*   **Disk Group Name**: Đặt là **`OCR_VOTE`**. 
    *   *Mục đích:* Nhóm này dùng riêng để chứa các file quản trị Cluster (OCR và Voting Disks). Các nhóm đĩa khác (`DATA`, `FRA`) sẽ được tạo sau khi cài xong.
*   **Redundancy (Độ dư thừa)**: Chọn **`External`**. 
    *   *Lý do:* Phù hợp với môi trường Lab VMware khi ta chỉ dùng 1 đĩa ảo cho mỗi mục đích.
*   **Allocation Unit (AU) Size**: Chọn **`4 MB`** (Chuẩn tối ưu cho hiệu năng Oracle 19c).
*   **Disk Discovery Path**: Bấm **Change Discovery Path** và điền **`/dev/oracleasm/*`**.
*   **Select Disks (Cách tích chọn chuẩn):** 
    *   Tích chọn duy nhất ổ **`/dev/oracleasm/asm_ocr1`** (ổ 10GB). 
    *   Để trống các ổ `asm_data1` và `asm_fra1` để dùng cho bước tạo DB sau này.
*   **Configure Oracle ASM Filter Driver (Ô tích)**: **KHÔNG TÍCH** (Vì ta dùng UDEV ổn định hơn).

#### **Step 9: ASM Password**
Thiết lập mật khẩu bảo mật cho các tài khoản quản trị ASM:

*   **SYS**: Là tài khoản "quyền lực nhất" (SYSASM), có toàn quyền quản trị, thay đổi đĩa, tham số của ASM Instance.
*   **ASMSNMP**: Là tài khoản dành riêng cho việc giám sát (Monitoring). Nó được phần mềm Oracle Enterprise Manager dùng để kiểm tra sức khỏe của đĩa.
*   **Các tùy chọn:**
    - **Use different passwords**: Dùng mật khẩu riêng cho từng user (Quy chuẩn bảo mật Production).
    - **[CHỌN] Use same passwords**: Dùng chung một mật khẩu cho cả hai (Phù hợp cho môi trường Lab/Học tập để dễ nhớ).
*   **Lưu ý:** Mật khẩu nên có cả chữ Hoa, chữ thường và chữ số để vượt qua vòng kiểm tra của bộ cài.

#### **Step 10: Failure Isolation**
Cấu hình cách thức xử lý khi một Node bị lỗi và không phản hồi (Fencing):

*   **Use Intelligent Platform Management Interface (IPMI)**: Chỉ dùng cho các máy chủ vật lý thật (Physical server) có hỗ trợ card quản lý phần cứng IPMI/iDRAC/iLO. Nó cho phép Cluster tự động ngắt nguồn hoặc khởi động lại một Node bị treo thông qua mạng phần cứng riêng.
*   **[CHỌN] Do not use IPMI**: Lựa chọn cho môi trường máy ảo VMware hoặc các máy chủ không có quản lý phần cứng chuyên dụng.
    *   *Lý do:* Trong môi trường ảo hóa, ta không có phần cứng IPMI thực tế để bộ cài kết nối vào.

#### **Step 11: Management Options**
Kết nối hệ thống với các công cụ giám sát tập trung:

*   **Register with Enterprise Manager (EM) Cloud Control**: Nếu công ty bạn có sẵn hệ thống EM Cloud Control để quản lý tập trung, bạn sẽ tích vào đây.
*   **[BỎ TRỐNG]**: Trong môi trường Lab, ta không cần cấu hình mục này để tiết kiệm tài nguyên.

#### **Step 12: Operating System Groups**
*   Wizard sẽ tự nhận diện các group `asmadmin`, `asmdba`, `asmoper` ta đã tạo. Để mặc định.

#### **Step 13: Installation Location**
*   **Oracle base**: `/u01/app/grid`
*   **Software location**: `/u01/app/19.3.0/grid`

#### **Step 14: Create Inventory**
*   **Directory**: `/u01/app/oraInventory` (Chứa danh sách thông tin các phần mềm Oracle đã cài trên máy).

#### **Step 15: Root script execution**
Giai đoạn cuối cùng yêu cầu quyền `root` để cấu hình hệ thống:

*   **Automatically run configuration scripts (Ô tích)**: 
    *   Nếu tích chọn, bạn cần cung cấp mật khẩu `root`. Bộ cài sẽ tự động SSH vào các Node và chạy các file script (`orainstRoot.sh`, `root.sh`) thay cho bạn.
*   **[KHUYÊN DÙNG] Để trống (Không tích)**: 
    *   Bạn sẽ tự mở Terminal, login `root` và chạy từng lệnh thủ công.
    *   *Tại sao nên làm thủ công:* Đây là bước quan trọng nhất của toàn bộ quá trình cài đặt RAC. Làm thủ công giúp bạn kiểm soát hoàn toàn tiến trình, dễ dàng đọc Log và xử lý kịp thời nếu có lỗi phát sinh tại từng Node. 

**Hành động:** 
Bạn hãy **ĐỂ TRỐNG** (không tích ô Automatically...) và nhấn **Next**.

#### **Step 16: Prerequisite Checks**
Đây là bước bộ cài quét toàn bộ hệ thống để đảm bảo mọi thứ sẵn sàng:

*   **Các lỗi thường gặp (Failed) trong môi trường Lab:**
    - **resolv.conf Integrity / DNS name service**: Hiện lỗi **Failed** vì chúng ta không dùng DNS Server thật mà dùng file `/etc/hosts`. Đây là chuyện bình thường.
    - **SCAN**: Hiện cảnh báo **Warning** vì SCAN VIP của chúng ta chỉ có 1 IP (chuẩn DNS cần 3 IP).
*   **Xử lý:** 
    - Vì chúng ta đã tự tin cấu hình đúng theo Phase 1 & 2, bạn hãy tích vào ô **"Ignore All"** (Bỏ qua tất cả) ở góc trên bên phải màn hình.
    - Sau khi tích, nút **Next** sẽ sáng lên để bạn đi tiếp.

#### **Step 17: Summary**
*   Kiểm tra lại lần cuối và nhấn **Install**.

#### **Step 18: Install Product**
*   Đợi đạt 80% sẽ hiện thông báo chạy script. **XEM BƯỚC 1.5 DƯỚI ĐÂY.**

#### **Step 19: Finish**
*   Nhấn **Close** khi hoàn tất.

---

### 1.4 Xử lý lỗi thường gặp (Troubleshooting)

#### **Lỗi [INS-20802]: Oracle Cluster Verification Utility failed**
*   **Nguyên nhân:** Xảy ra ở bước cuối cùng (100%). Đây là cấu phần kiểm tra lại toàn bộ hệ thống (CVU). Trong môi trường Lab không có DNS, CVU thường báo lỗi vì không check được các bản ghi DNS hoặc Multicast.
*   **Cách khắc phục:** 
    1. Nhấn **OK** ở bảng lỗi.
    2. Tại màn hình chính của bộ cài, nhấn nút **Skip** (Bỏ qua) để bộ cài hoàn tất nốt tiến trình.
    3. Nhấn **Finish** để đóng bộ cài.
    4. **Kiểm tra thực tế:** Nếu chạy lệnh `crsctl check cluster -all` mà tất cả hiện **ONLINE** thì lỗi INS-20802 này có thể bỏ qua hoàn toàn.

#### **Lỗi [INS-41208]: None of the available network subnets is marked for use by Oracle ASM**
*   **Nguyên nhân:** Ở Bước 5, bạn chọn card mạng Private nhưng quên không tích chọn quyền **ASM**. Vì từ bản 12c/19c trở đi dùng Flex ASM, hệ thống yêu cầu phải có mạng cho ASM.
*   **Cách khắc phục:** 
    1. Nhấn nút **Back** để quay lại **Bước 5 (Network Interface Usage)**.
    2. Tại dòng `ens37`, thay đổi cột "Use for" từ `Private` thành **`ASM & Private`**.
    3. Nhấn **Next** để quay tiếp.

---

### 1.5 Chạy Script Root (QUY TRÌNH BẮT BUỘC)

Khi hiện cửa sổ yêu cầu, thực hiện theo đúng thứ tự trên 2 Node bằng user `root`:

1.  **Node 1 & 2:** Chạy `/u01/app/oraInventory/orainstRoot.sh`.
2.  **Node 1:** Chạy `/u01/app/19.3.0/grid/root.sh`. (Đợi hoàn thành 100% mới làm bước tiếp theo).
3.  **Node 2:** Chạy `/u01/app/19.3.0/grid/root.sh`.

---

## 2. Kiểm tra Cluster sau cài đặt

Dùng user `grid` chạy lệnh sau:
```bash
crsctl check cluster -all
crsctl status resource -t
```
Nếu tất cả hiện **ONLINE**, bạn đã sẵn sàng cài đặt Database Software và tạo DB RAC!

---

## 3. Cài đặt Oracle Database Software
Sau khi Clusterware đã chạy (trạng thái `realiable`), ta cài đặt phần mềm Database.

1. Login bằng user `oracle`.
2. Giải nén bộ cài Database vào thư mục tạm hoặc Home.
3. Chạy `./runInstaller`.
4. Chọn **Set Up Software Only**.
5. Chọn **Oracle Real Application Clusters database installation**.
6. Chọn cả 2 Node trong danh sách Cluster.

---

## 4. Tạo Cơ sở dữ liệu RAC (DBCA)
Sử dụng công cụ đồ họa để tạo Database dùng chung trên ASM.

1. Chạy lệnh `dbca` bằng user `oracle`.
2. Chọn **Create Database** -> **Advanced Configuration**.
3. **Storage Type:** Chọn **Automatic Storage Management (ASM)**.
4. **Disk Group:** Chọn Disk Group `DATA` (Bạn có thể cần tạo Group này trước trong ASM Configuration Assistant - `asmca` nếu chưa có).
5. Đảm bảo cấu hình **Management Options** để giám sát cluster.

---
> [!SUCCESS]
> Chúc mừng bạn! Sau khi hoàn thành Giai đoạn 3, bạn đã có một hệ thống Oracle 19c RAC hoàn chỉnh trên môi trường VMware.
