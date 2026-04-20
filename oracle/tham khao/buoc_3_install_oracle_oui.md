# Bước 3 - Hướng Dẫn Cài Đặt Oracle Database 19c (Giao diện OUI)

Sau khi đã giải nén xong bộ cài vào thư mục `$ORACLE_HOME` ở bước trước, bước tiếp theo là khởi chạy trình cài đặt đồ họa (Oracle Universal Installer - OUI) để tiến hành thiết lập Database bằng các thao tác trực quan.

### 1. Khởi chạy trình cài đặt OUI

Do OUI là giao diện cửa sổ trực quan (GUI), bạn cần thao tác trực tiếp trên giao diện màn hình ảo của VMware (Nếu bạn đang kết nối SSH qua Putty sẽ không gọi được giao diện trừ khi cấu hình X11 Forwarding).

1. Đăng nhập vào giao diện Desktop của máy ảo bằng tài khoản **`oracle`**. *(Nếu đang login bằng root thì hãy Log out ra và chọn vào user oracle).*
2. Mở ứng dụng **Terminal** bằng cách chuột phải lên màn hình Desktop.
3. Đầu tiên, hãy kiểm tra lại biến môi trường đã nhận đúng:
   ```bash
   echo $ORACLE_HOME
   ```
   *(Nếu kết quả in ra là: `/u01/app/oracle/product/19.0.0/dbhome_1` thì môi trường đã chuẩn).*
4. Di chuyển vào thư mục gốc bằng lệnh và khởi chạy file setup:
   ```bash
   cd $ORACLE_HOME
   ./runInstaller
   ```
   *(Lúc này logo Oracle xuất hiện và cửa sổ đồ họa **Oracle Universal Installer** có viền đỏ sẽ bật lên. Quá trình load Java này có mất vài chục giây).*

---

### 2. Các bước cấu hình trên màn hình OUI (Click By Click)

Dưới đây là các thiết lập theo tiêu chuẩn (Best Practice) cho môi trường VM được thiết kế trước:

1. **Configuration Option:** Tích chọn **`Create and configure a single instance database`** (Cài đặt trọn gói phần mềm gốc và đồng thời giúp chúng ta tạo sẵn luôn 1 DB trống để xài). -> *Next*.
2. **System Class:** Tích chọn **`Server class`** (Để báo bộ Core tối ưu tài nguyên như một máy chủ thay vì máy tính để bàn). -> *Next*.
3. **Database Edition:** Trỏ chọn **`Enterprise Edition`** (Bản cao cấp nhất có xài đủ mọi tính năng, đầy đủ option cho thực tập). -> *Next*.
4. **Installation Location:**
   * Lựa chọn `Oracle Base` sẽ tự động nhận giá trị: `/u01/app/oracle`
   * Đường dẫn `Software Location` cũng tự động ăn theo đường dẫn thư mục giải nén. -> Nhấn *Next*.
5. **Create Inventory:** Chọn Path: `/u01/app/oraInventory`, Group Name: `oinstall`. -> *Next*.
6. **Configuration Type:** Tích chọn **`General Purpose / Transaction Processing`**. -> *Next*.
7. **Database Identifiers:**
   * Global database name: `orcl` (hoặc tên database tùy ý của bạn)
   * Oracle Service Identifier (SID): hệ thống tự sinh theo tên giống ở trên (`orcl`).
   > [!IMPORTANT]
   > Nút thắt cực kỳ quan trọng: Ghi nhớ kỹ cái tên SID này (Ví dụ: `orcl` hoặc `cdb1`). Nó chính là "chìa khóa" để thực hiện các lệnh cấu hình Tự Động Bật Database (Auto-start) sau này. Nếu bạn thiết lập sai lệnh gọi SID, Database sẽ treo lỗi chết ngắc như Error 127.
   * *Nên tick vào ô:* **`Create as Container database`** (Vì từ bản DB 12c trở đi tới 19c, kiến trúc Multitenant là bắt buộc đi theo xu hướng ảo hóa của hãng). Mặc định Pluggable database name sẽ là `pdb1` -> Nhấn *Next*.
8. **Configuration Options:** Bảng này gồm nhiều thẻ tab rất quan trọng:
   * **Thẻ Memory:** Tích chọn `Enable Automatic Memory Management` (Hệ thống sẽ tự động quét và phân bổ sử dụng khoảng 40% RAM thật của máy ảo làm bộ đệm cực lớn cho SGA + PGA).
   * **Thẻ Character sets:** Cực kỳ quan trọng, trỏ lựa chọn chữ chạy dọc xuống và **chọn chuẩn Unicode (AL32UTF8)** để DB hỗ trợ lưu trữ gõ tiếng Việt có dấu.
   * *Thẻ Sample schemas:* Bạn có thể tích vào ô `Install sample schemas in the database` nếu muốn Oracle nhúng cho sẵn data mô phỏng phòng HR để thực tập code SQL. -> Nhấn *Next*.
9. **Database Storage:** Nơi quy định chỗ cất file dữ liệu vật lý
   * Tích chọn `File system`.
   * Khung Database file location: Nhập đường dẫn thư mục tạo ở Bước 2 là: **`/u02/oradata`**. -> Nhấn *Next*.
10. **Management Options:** Hiện tại cứ bỏ tích ô Enterprise Manager Cloud Control lúc này để cấu hình sau. -> *Next*.
11. **Recovery Options:** Hệ thống kiểm soát Archive Log (Nếu ở bước 1 chia đĩa bạn có làm ổ đĩa /u03). 
    * Tích chọn cái ô vuông **`Enable Recovery`**.
    * Khung Recovery Area location sửa thành: **`/u03/fast_recovery_area`**. -> *Next*.
    *(Mẹo: Nếu lúc chia disk ở VMware không có chia ra cái Ổ lưu /u03 thì bạn không được tích chọn phần này).*
12. **Schema Passwords:** Quản lý mật khẩu Sys. Chọn dòng số hai: **`Use the same password for all accounts`** và gõ chung 1 mật khẩu cho lẹ (Ví dụ: `oracle123`). Nếu màn hình mắng mật khẩu không đủ tiêu chuẩn phức tạp hay độ dài, cứ ấn nút *Yes* để bỏ qua cảnh báo cứng đầu. -> Nhấn *Next*.
13. **Operating System Groups:** Không sửa các thông số nhóm (dba, oper, backupdba...) để yên theo OS tự nhận tự map. -> Nhấn *Next*.
14. **Root script execution:** Bí quyết rảnh tay - Tick vào ô hình  vuông **`Automatically run configuration scripts`** và điền cái *Mật khẩu của tài khoản `root`* (Cái tạo ở bước 1 cấp độ OS). Thao tác này giúp tiến trình setup xài quyền root âm thầm cấp quyền cho folder tự động mà không thèm réo tay bạn bắt chạy lệnh. -> *Next*.
15. **Prerequisite Checks:** 
    * OUI sẽ tự chạy một thanh progress test càn quét lại toàn bộ CPU, RAM, Swap, Packges OS. 
    * Nếu lỡ máy nó báo chê máy ít Swap hay các Warning đỏ chót về package lặt vặt. Đừng lo lắng, nhìn trên góc bo viền mạn phải tích ngâm cái ô vuông vức nhỏ là **`Ignore All`** -> Sau đó bấm nút *Next*. (Nên nhớ là warning thì lờ đi được chứ Fail cứng thì bắt buộc sửa).
16. **Summary:** Nhìn ngắm lại chặng đường các option vừa click ra -> Bấm nút quyết định **Install**.

---

### 3. Tiến hành cho chạy bộ cài đặt

Thanh tiến trình sẽ chạy xả bung file rồi config Database. Có thể đi pha cà phê vì quá trình này chạy từ khoảng 15 cho tới 45 phút trên VMware.

*(Lưu ý: Nếu ở bước số 14 bạn lật kèo không cấp mật khẩu root tự động, nó sẽ đứng cứng màn hình và kêu đòi chạy 2 thông số script). Lúc đó phải dùng account root chạy thủ công:*
```bash
/u01/app/oraInventory/orainstRoot.sh
/u01/app/oracle/product/19.0.0/dbhome_1/root.sh
```
Sau đó bấm chữ OK mới cho setup cho DB chạy tiếp. (Còn đã giao pass cho nó như bước số 14 thì nó báo một cái popup nhỏ yes một nhát là OK).

Cuối cùng, màn hình ăn mừng với dòng trạng thái **"The setup of Oracle Database was successful"**. Máy báo gửi kèm 1 cái URL quản lý dạng kiểu `https://ora19c.localdomain:5500/em`. 

Bấm nút **Close** để hoàn thành toàn bộ công việc setup Oracle trần trụi cực nhọc đắn đo phân bổ RAM và ổ cứng.

---

### 4. Lệnh kiểm tra Database vừa cài ra lò

Mở màn hình Terminal ra (Nhớ là với tài khoản là `oracle`), gõ chắp lệnh gọi bộ lõi Core quản lý cao nhất để log vô:
```bash
sqlplus / as sysdba
```
Màn hình xổ ra thông điệp báo như vầy:
`Connected to: Oracle Database 19c Enterprise Edition Release 19.0.0.0.0`
Làm một câu check tình trạng Database đang hoạt động:
```sql
SQL> select status from v$instance;
```
Trạng thái in ra `OPEN`

Để nhìn tổng quát tất cả các vùng cấy DB PDB bên trong đang vận động:
```sql
SQL> show pdbs;
```

**Hoàn tất!!** Xin chúc mừng bạn, con Database đồ sộ đã sẵn sàng cho mọi thao tác truy vấn Data của bạn! Bạn cần tôi cung cấp hướng dẫn cách Setup Khởi động tự động **Auto-Start** Services cùng với hệ điều hành luôn không?
