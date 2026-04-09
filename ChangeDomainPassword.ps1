Import-Module ActiveDirectory
$userName = Read-Host "Nhập username Domain cần đổi"
$plainPassword = Read-Host "Nhập mật khẩu mới" -AsSecureString

try {
    # Lệnh đổi pass User AD và bỏ đánh dấu yêu cầu đổi pass vào lần đăng nhập tới
    Set-ADAccountPassword -Identity $userName -NewPassword $plainPassword -Reset:$true
    Write-Host "Thành công!" -ForegroundColor Green
} catch {
    Write-Host "Gặp lỗi: $($_.Exception.Message)" -ForegroundColor Red
}
