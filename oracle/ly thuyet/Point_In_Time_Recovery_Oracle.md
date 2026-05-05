# Oracle Point-in-Time Recovery (PITR)

## 1. Khái niệm cơ bản
**Database Point-in-Time Recovery (DBPITR)** hay Phục hồi CSDL theo một thời điểm là quá trình khôi phục cơ sở dữ liệu về lại một trạng thái tại một thời điểm cụ thể trong quá khứ (một ngày giờ cụ thể, hoặc một số System Change Number - SCN cụ thể).

Trong Oracle, thao tác này còn được gọi là **Incomplete Recovery** (Phục hồi không hoàn toàn), vì bạn không khôi phục dữ liệu cho đến thời điểm hiện tại nhất (thời điểm xảy ra sự cố), mà chủ động dừng lại ở một thời điểm trong quá khứ.

## 2. Khi nào cần sử dụng PITR?
Bạn thường sử dụng PITR trong các trường hợp lỗi do **người dùng hoặc ứng dụng (Logical Failure)**, chẳng hạn như:
- Một người quản trị (DBA) vô tình chạy lệnh `DROP TABLE` hoặc `TRUNCATE TABLE` xóa nhầm một bảng quan trọng.
- Một script ứng dụng chạy sai, thực hiện lệnh `UPDATE` hoặc `DELETE` làm hỏng một lượng lớn dữ liệu mà không thể undo lại được.
- Bạn cần khôi phục lại dữ liệu của một bảng ở trạng thái trước khi một batch job chạy lỗi.

*(Lưu ý: Nếu lỗi là do hỏng hóc phần cứng (ví dụ hỏng ổ cứng chứa Datafile), bạn thường sẽ dùng Complete Recovery để khôi phục đến thời điểm mới nhất).*

## 3. Điều kiện bắt buộc (Prerequisites)
Để có thể thực hiện PITR, hệ thống của bạn bắt buộc phải thỏa mãn các điều kiện sau:
1. Cơ sở dữ liệu phải đang chạy ở chế độ **ARCHIVELOG mode**.
2. Bạn phải có **bản Backup Datafile** (Full hoặc Incremental) được tạo ra *trước* thời điểm bạn muốn khôi phục về.
3. Bạn phải có toàn bộ các **Archived Redo Logs** sinh ra trong khoảng thời gian từ lúc tạo bản backup đó cho đến cái thời điểm bạn muốn khôi phục.

## 4. Hai phương pháp chính để thực hiện PITR trong Oracle

### Phương pháp 1: Dùng công cụ RMAN (Truyền thống)
Cách này sẽ lấy các Datafile từ bản backup cũ ra đè lên các file hiện tại, sau đó "chạy lại" các thay đổi (Redo) cho đến đúng thời điểm bạn chỉ định rồi dừng lại.
* **Quy trình tóm tắt:**
  1. `SHUTDOWN IMMEDIATE` (Tắt Database).
  2. `STARTUP MOUNT` (Khởi động ở chế độ Mount để có thể can thiệp vào Datafile).
  3. Chạy lệnh RMAN: 
     ```sql
     RUN {
       SET UNTIL TIME "TO_DATE('2026-05-05 10:00:00','YYYY-MM-DD HH24:MI:SS')";
       RESTORE DATABASE;
       RECOVER DATABASE;
     }
     ```
  4. `ALTER DATABASE OPEN RESETLOGS;` (Bắt buộc phải có `RESETLOGS` để tạo ra một "nhánh thời gian" mới cho Database).

### Phương pháp 2: Dùng Flashback Database (Nhanh chóng)
Nếu Database của bạn đã bật tính năng **Flashback Database**, Oracle sẽ liên tục lưu lại các hình ảnh cũ của block dữ liệu (Flashback Logs). Cách này nhanh hơn rất nhiều vì không cần phải copy/restore lại Datafile từ bản backup lớn. Nó chỉ cần "tua ngược" (rewind) các Datafile về quá khứ.
* **Quy trình tóm tắt:**
  1. `SHUTDOWN IMMEDIATE;`
  2. `STARTUP MOUNT;`
  3. `FLASHBACK DATABASE TO TIMESTAMP TO_TIMESTAMP('2026-05-05 10:00:00', 'YYYY-MM-DD HH24:MI:SS');`
  4. `ALTER DATABASE OPEN RESETLOGS;`

## 5. Những lưu ý cực kỳ quan trọng
- **RESETLOGS:** Sau khi làm PITR, bạn bắt buộc phải mở CSDL bằng lệnh `OPEN RESETLOGS`. Hành động này sẽ reset lại sequence của Redo Log, tạo ra một "hóa thân" (Incarnation) mới của Database.
- **Backup ngay lập tức:** Sau khi mở CSDL bằng `RESETLOGS`, **BẠN PHẢI THỰC HIỆN FULL BACKUP DATABASE NGAY LẬP TỨC**. Vì cấu trúc log đã bị thay đổi, các bản backup cũ ở Incarnation trước sẽ rất khó (và phức tạp) để dùng cho việc khôi phục ở Incarnation mới.
- **Toàn cục:** PITR (mức database) sẽ đưa *toàn bộ* cơ sở dữ liệu về quá khứ. Điều này có nghĩa là kể cả những dữ liệu tốt, không bị lỗi được thêm vào sau thời điểm lỗi cũng sẽ bị mất. 
  *(Nếu chỉ muốn khôi phục 1 bảng, bạn nên tham khảo các tính năng như **Flashback Table**, **Flashback Drop**, hoặc **RMAN Tablespace/Table Point-In-Time Recovery - TSPITR**).*
