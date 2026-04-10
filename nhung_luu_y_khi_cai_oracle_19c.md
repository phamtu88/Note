# Cẩm nang Bắt bệnh & Khắc phục Lỗi cài đặt Oracle Database 19c
*Dành riêng cho máy chủ Oracle Linux 7 / 8*

Tài liệu này tổng hợp lại toàn bộ những lỗi chặn đứng (blocker), những điểm gây hiểu lầm trong các bài hướng dẫn trên mạng, và những thủ thuật "bảo hiểm" đã được thực chứng trong suốt quá trình cài đặt Oracle 19c của bạn.

---

## 1. Bí quyết Truyền file (Upload) lên Server
- **Vấn đề hay gặp:** Thường bị báo lỗi "Permission denied" (từ chối quyền truy cập) khi giải nén file `.zip`.
- **Quy tắc vàng:** Luôn đẩy đẩy bộ cài `.zip` thẳng vào Linux thông qua tài khoản user **`oracle`**. File nên được đẩy vào `/home/oracle` hoặc thư mục cấu hình `$ORACLE_HOME`.
- **Cách chữa cháy:** Nếu lỡ dùng `root` hoặc tool WinSCP lỡ đẩy bằng quyền root, bạn bắt buộc phải cướp lại quyền cho oracle bằng lệnh:
  ```bash
  chown oracle:oinstall /đường_dẫn_tới_file_cài_đặt_LINUX...zip
  ```

## 2. Lưu ý Mạng & Môi trường (`setEnv.sh`, `.bash_profile`)
- **Tạo script:** Bài viết gốc thường dùng quyền `root` gõ lệnh tạo script trong thư mục của oracle. Hãy khôn ngoan hơn: Mở hẳn tab tài khoản `oracle` (`su - oracle`) rồi mới gõ tạo file, để Linux tự động chuẩn hoá quyền sở hữu cho file đó.
- **Hệ quả của lệnh `cat >>`:** Các lệnh gõ trên mạng thực chất chỉ "in chữ" vào lưu thành file text trên mặt đĩa. Nghĩa là gõ xong bạn vẫn không test được biến (ví dụ `echo $ORACLE_HOME` in ra khoảng trắng). Muốn có ngay, bạn phải chạy lệnh `source /home/oracle/scripts/setEnv.sh` để nạp nó vào thanh RAM.
- **Biến `ORACLE_HOSTNAME`:** Tuyệt đối **KHÔNG COPY** mù quáng giá trị hostname của tác giả bài viết (VD: `ol7-19...`). Bắt buộc phải thay bằng hostname của chính bạn (VD: `oracle1.localdomain`) nếu không sau này Listener trỏ mạng mạng sẽ lỗi sạch.

## 3. Lỗi mù màu hệ thống: Thiếu Các Groups (`oinstall`, `dba`)
- **Triệu chứng:** Ở màn chọn OS Groups, bảng sổ xuống trắng trơn hoặc bị gán nhầm thành chữ `wheel` (group Linux mặc định).
- **Tại sao "cài tự động" lại vô dụng?** Gói `oracle-database-preinstall-19c` có khả năng tự động tạo user và toàn bộ group tự động. NẾU: phía trên đó bạn lỡ tay chạy lệnh tạo sẵn user `oracle` thì gói RPM này sẽ quay xe, không làm gì cả để bảo vệ cấu trúc user cũ. Đó là lý do bạn bị thiếu group.
- **Cách Khắc Phục:** 
  Bảo đảm ở User `root`, bạn phang loạt lệnh tạo bù và gán lại Group như sau:
  ```bash
  # Tạo không kèm mã ID ép buộc (-g) để hệ thống tự do sắp xếp
  groupadd -f oinstall
  groupadd -f dba
  groupadd -f oper
  groupadd -f backupdba
  groupadd -f dgdba
  groupadd -f kmdba
  groupadd -f racdba

  # Gán nhóm xong nhớ phân lại quyền chủ thư mục
  usermod -g oinstall -G dba,oper,backupdba,dgdba,kmdba,racdba oracle
  chown -R oracle:oinstall /u01
  chown -R oracle:oinstall /u02
  ```
- **Lưu ý siêu cấp:** Khắc phục lỗi Group xong, phải bấm `Cancel` đóng bảng cài đặt cũ đi. Tắt luôn cái sổ SSH chứa user oracle cũ đi để Linux xoá bộ nhớ đệm, sau đó mở tab ssh oracle mới thì mới hiện đủ danh sách Group.

## 4. Tốc độ giải nén: ý nghĩa của `unzip -oq`
- Bạn phải tuân thủ Luật của Oracle 19c: Phải chui vào tận nơi thư mục `$ORACLE_HOME` (thường là `.../dbhome_1`) rồi mới giải nén thả trực tiếp file tại đây.
- Lệnh `unzip -oq`: 
  - `-o` (Overwrite): Ép buộc ghi đè không hỏi han YES_NO các file bị trùng.
  - `-q` (Quiet): Giải nén "tàng hình". Tuyệt đối không in vạn dòng nhật kí giải nén xuống màn hình gây đứng máy và rác terminal.

## 5. Lỗi Tử Thần: X11 Display (Không bật được giao diện đồ hoạ)
- **Triệu chứng:** Bấm `./runInstaller` văng lỗi tanh bành xanh đỏ: *Unable to verify the graphical display setup...*
- **Chân Ái "MobaXterm":** Là dân chơi dùng SSH trên Windows cài Oracle, phải cậy nhờ anh MobaXterm. 
  1. Login Thẳng 1 phát một vào **`oracle`**, bỏ qua cửa trung gian Root.
  2. Bất cứ lệnh nào trên mạng có chỉ dạy bạn `xhost +` hay `export DISPLAY=...` -> Bỏ hết, gõ là treo đấy!
  3. Chỉ cần gõ `./runInstaller`, nhịp nhàng chờ 3-5 giây đồ hoạ sẽ bốc thẳng từ Server xuyên lên PC Windows của bạn ngay lập tức.

## 6. Lỗi doạ dẫm [INS-32047] (Thư mục oraInventory not empty)
- **Triệu chứng:** Nó báo thư mục ko trống, hỏi bạn "Có chắc muốn đi tiếp không?"
- **Bản chất:** Chỉ là cảnh báo, do bạn cài "sịt" một lần ở trước rồi tắt Cancel phần mềm đi, nên bộ cài rớt vài cọng rác log vào thư mục `/u01/app/oraInventory`. Nó nhìn thấy có rác nên nó dội lại hỏi cho chắc nhỡ ghi đè thôi. Cứ tự tin **`Yes`**.

## 7. Thao Tác Chốt Hạ: 2 Scripts thần thánh của `root`
- Ở bước áp chót, bảng *Execute Configuration Scripts* hiện lên, cấm tay nhanh ấn nút OK trước. Đừng vội!
- Mở Terminal **`root`** mới. Chạy từng script bằng tay:
  1. `/.../.../orainstRoot.sh`
  2. `/.../.../root.sh` 
  *(Ở lệnh số 2, khi hệ thống chững lại hỏi `[usr/local/bin]`, dứt khoát ấn Enter là xong)*.
- Khi chữ `[root@... ~]#` trả về yên bình, quay lại bảng giao diện Graphic ấn OK kết thúc.

## 8. Nỗi Oan Thị Kính của file `/etc/oratab`
- **Tác giả bài gốc viết luộm thuộm:** *"Edit /etc/oratab chạy theo script ~/scripts/start_all.sh"*.
- **Hành động SAI LẦM (Tuyệt đối tránh):** Cứ tưởng bở rồi copy nguyên dòng chữ `~/scripts/start_all.sh` dán bừa vào làm nội dung của file `/etc/oratab`. (Nhắc lại: Tuyệt đối không dán text lạ vào đây, nó sẽ làm phá vỡ form cấu trúc file hệ thống, khiến tool `dbstart` không đọc được mã và sập nguồn).
- **Sự thật số 1:** Ở những bước setup đầu tiên (khi lập biến môi trường), bạn tìm cả máy cũng chả thấy file oratab đâu. Vì nó chỉ được thai nghén và "đẻ" ra thông qua lệnh `root.sh` ở Mục 7 phía trên. Tuy nhiên lúc mới đẻ ra, nó chỉ chứa toàn dòng comment (có dấu `#`), chưa có data thật.
- **Sự thật số 2 (Quy trình làm ĐÚNG 100%):** Ở chặng cuối cùng, khi bạn chạy xong phần mềm **`dbca`** để cài cắm ra hình thù một cái Database rồi, bot `dbca` sẽ tự động thòng thêm 1 dòng ở dưới cùng của file, ví dụ:
  `cdb1:/u01/app/oracle/product/19.0.0/dbhome_1:N`.
  Lúc đó bạn mới mở file `/etc/oratab` ra, xoá đúng chữ **`N`** lẻ loi ở điểm cuối, đổi thành chữ **`Y`** (Yes) rồi lưu lại. Từ khoảnh khắc đó, 2 cái kịch bản phím tắt `start_all` và `stop_all` của bạn mới chính thức có tác dụng kích hoạt chạy ngầm!

## 9. Ý nghĩa thực sự của file `start_all.sh`, `stop_all.sh` và `setEnv.sh`
- Rất nhiều người thắc mắc: "Tại sao trong ảnh bài gốc hướng dẫn viết đống script này từ rất sớm, nhưng mình bỏ qua không tạo thì ở bước sau cài đặt mềm vẫn báo successful thành công?"
- **Bản chất của `setEnv.sh`:** Nhiệm vụ của nó duy nhất là "chỉ đường" lưu thông số môi trường cho hệ điều hành. Nếu bạn làm lơ không tạo nó từ đầu, lúc cài đặt tiến trình vẫn diễn ra bình thường. Điểm khác biệt duy nhất là lúc bạn muốn bật tiếp ứng dụng `dbca`, bạn gõ `dbca` hệ điều hành sẽ báo trơ trơ lỗi *Command not found*. Khi đó bạn bắt buộc phải gõ lại đường dẫn tuyệt đối đầy đủ: `/u01/app/oracle/product/19.0.0/dbhome_1/bin/dbca` thì nó mới chạy được.
- **Bản chất của `start_all.sh` và `stop_all.sh`:** Thực chất đây không phải file hệ thống của Oracle. Đây chỉ là **"kịch bản phím tắt"** do tác giả bài viết tự lập ra để tiện cho việc nổ máy/tắt máy nguyên trùm server thông qua một câu lệnh duy nhất (vì các file kia gọi lệnh `dbstart` và `dbshut`). Do đó, khuyên thật lòng là phần hướng dẫn tạo 2 file phím tắt tiện ích này nên được dời xuống bước tận cùng (tức là sau khi bạn đã tạo thành công DataBase bằng DBCA) thì nó mới thực sự mang ý nghĩa và tính logic!

