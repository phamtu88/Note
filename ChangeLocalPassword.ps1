<#
.SYNOPSIS
Script đổi mật khẩu cho user cục bộ (Local User) trên Windows.
Tương thích tốt từ Windows Server 2008 đến Windows Server 2022.
#>

# Tắt cảnh báo lỗi mặc định để xử lý bằng try-catch
$ErrorActionPreference = "Stop"

$userName = Read-Host "Nhập tên tài khoản (Username) cần đổi mật khẩu"
# Sử dụng AsSecureString để che ký tự khi người dùng gõ mật khẩu
$newPassword = Read-Host "Nhập mật khẩu mới" -AsSecureString

# Chuyển SecureString thành PlainText vì phương thức của ADSI yêu cầu mật khẩu dạng text thường
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($newPassword)
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

try {
    Write-Host "Đang xử lý..." -ForegroundColor Cyan

    # Gọi đến API User Cục bộ của máy tính bằng ADSI WinNT
    $user = [adsi]"WinNT://$env:COMPUTERNAME/$userName,user"
    
    # Thực hiện đổi password
    $user.SetPassword($plainPassword)
    $user.SetInfo()
    
    Write-Host "=================================" -ForegroundColor Green
    Write-Host "[THÀNH CÔNG] Đã đổi mật khẩu xong cho tài khoản: $userName" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green

} catch {
    Write-Host "=================================" -ForegroundColor Red
    Write-Host "[THẤT BẠI] Lỗi trong quá trình đổi mật khẩu!" -ForegroundColor Red
    Write-Host "Chi tiết lỗi: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "-> MẸO: Hãy chắc chắn bạn đã click chuột phải vào PowerShell và chọn 'Run as Administrator'." -ForegroundColor Yellow
    Write-Host "=================================" -ForegroundColor Red
} finally {
    # Bảo mật: Dọn dẹp mật khẩu bằng clear text ra khỏi bộ nhớ (RAM) sau khi chạy
    if ($bstr) {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}
