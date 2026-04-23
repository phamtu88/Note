# Kiến Trúc Oracle: CDB (Có PDB) vs Non-CDB (Không Có PDB)

Sự khác biệt giữa việc **không có PDB** (Kiến trúc Non-CDB truyền thống) và **có PDB** (Kiến trúc Multitenant/CDB) là một trong những bước ngoặt lớn nhất trong lịch sử phát triển của Oracle Database. 

Dưới đây là so sánh chi tiết về sự khác nhau, ưu/nhược điểm và mức độ ảnh hưởng của chúng:

---

## 1. Sự khác biệt cốt lõi (Khái niệm)

*   **Không có PDB (Non-CDB - Kiến trúc cũ):** 
    Mỗi một Database (CSDL) là một khối độc lập và phải đi kèm với 1 Instance (một bộ nhớ RAM SGA/PGA + các tiến trình CPU nền) riêng biệt. 
    *Ví dụ:* Nếu công ty bạn có 3 phầm mềm (Nhân sự, Kế toán, CRM) cần 3 CSDL tách biệt, bạn phải cài đặt và chạy 3 bộ Non-CDB hoàn toàn riêng biệt. Chúng không chia sẻ gì với nhau cả.
*   **Có PDB (CDB/Multitenant - Kiến trúc mới):** 
    Oracle tạo ra một "Cái vỏ" gọi là **CDB (Container Database)**. Cái vỏ này sẽ là nơi duy nhất khởi tạo bộ nhớ SGA/PGA và các tiến trình nền. Bên trong cái vỏ đó, bạn có thể tạo ra nhiều **PDB (Pluggable Database)**.
    *Ví dụ:* Bạn khởi chạy 1 CDB duy nhất (tốn 1 lần RAM/CPU). Sau đó tạo ra 3 PDB tương ứng cho Nhân sự, Kế toán, CRM. Đối với người dùng và phần mềm quản lý, mỗi PDB trông y hệt như một Database độc lập, dữ liệu hoàn toàn cô lập, nhưng ở tầng dưới chúng đang "dùng chung" tài nguyên của CDB.

---

## 2. Ưu điểm và Nhược điểm của kiến trúc có PDB (Multitenant)

### ✅ Ưu điểm (Lý do Oracle hướng mọi người dùng PDB)
1. **Tiết kiệm tài nguyên phần cứng cực lớn:** Nhờ việc dùng chung vùng nhớ SGA, PGA và các Background Processes (PMON, SMON, DBWn...), một máy chủ chạy 50 PDB sẽ tốn dụng lượng RAM/CPU ít hơn đi rất rất nhiều so với việc duy trì 50 Non-CDB.
2. **Quản trị tập trung (Nhanh và Nhàn):** 
   - Thay vì phải nâng cấp (upgrade) hay vá lỗi (patch) cho từng DB riêng lẻ, DBA chỉ cần thao tác 1 lần duy nhất trên Container gốc (CDB Root), tất cả các PDB bên trong sẽ được hưởng lợi.
   - Backup (sao lưu) toàn bộ CDB cùng lúc.
3. **Tính di động (Plug & Rút):** Đúng như chữ "Pluggable" (Cắm rút). Bạn có thể dễ dàng "rút" (unplug) một PDB từ máy chủ này và "cắm" (plug) nó vào một máy chủ CDB khác chỉ trong vài nốt nhạc. Điều này cực kỳ lý tưởng để chuyển dữ liệu vào môi trường Dev/Test hoặc lên Cloud.
4. **Nhân bản tĩnh (Cloning):** Có thể clone một PDB đang chạy ra thêm một bản y hệt trong chớp mắt với vài câu lệnh đơn giản.

### ❌ Nhược điểm / Thách thức
1. **Tạo ra "Điểm chết tập trung" (Single Point of Failure):** Nếu Container (CDB) bị hỏng, bị tắt để bảo trì, hoặc gặp sự cố, THÌ TẤT CẢ các PDB bên trong nó đều sẽ bị "sập" và không thể truy cập. (Tuy nhiên Oracle khắc phục điều này bằng RAC hoặc Data Guard).
2. **Độ phức tạp trong quản trị:** Các DBA sẽ bắt buộc phải học thêm tập lệnh mới, làm quen với khái niệm chuyển đổi "ngữ cảnh" (Session). Bạn phải biết mình đang chạy lệnh trên CDB hay đang đứng trong một PDB nào đó.
3. **Phân chia tài nguyên khó hơn:** Dù chung chạ là tốt để tiết kiệm, nhưng nếu một PDB (ví dụ PDB Kế toán) chạy các câu query quá nặng, nó có thể "ăn" hết System Memory và làm chậm các PDB khác. DBA phải biết tối ưu cấu hình Resource Manager.

---

## 3. Mức độ ảnh hưởng và Lời khuyên của thời đại (Cực kỳ quan trọng)

*   **Về mặt Bản quyền (License):** Ở phiên bản 12c, tính năng PDB (Multitenant) phải trả thêm tiền bản quyền rất đắt. Nhưng từ **Oracle 19c trở đi**, Oracle cho phép bạn tạo tối đa **3 PDB miễn phí** (user-created PDBs) song hành trong 1 CDB mà không cần giấy phép Multitenant Option.
*   **Sự khai tử của Non-CDB:** Từ phiên bản **Oracle 21c (và tương lai là 23c)**, Oracle đã **LOẠI BỎ HOÀN TOÀN kiến trúc Non-CDB**. Nghĩa là bạn không còn quyền lựa chọn nữa, kiến trúc PDB/CDB là BẮT BUỘC.

**TÓM LẠI:** 
Khi triển khai Oracle 19c, hãy luôn **cài đặt và cấu hình ở chế độ CDB (Container Database)**. Việc tìm hiểu, học cách sử dụng và quen với PDB giờ không còn là tính năng "thêm thắt" nữa, mà nó là **kỹ năng sống còn bắt buộc** của bất kỳ ai làm quản trị Oracle từ thời điểm hiện tại trở về sau.
