# UPN_Analysis_WindowsHello.ps1
Write-Host "=== UPN Analysis for Windows Hello Issues ===" -ForegroundColor Yellow

# Aktueller User-Kontext
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-Host "`nCurrent User: $currentUser" -ForegroundColor Cyan

# AD-UPN des aktuellen Users
try {
    $adUser = Get-ADUser -Identity $env:USERNAME -Properties UserPrincipalName, EmailAddress, ProxyAddresses
    Write-Host "`nActive Directory Information:" -ForegroundColor Cyan
    Write-Host "AD UPN: $($adUser.UserPrincipalName)" -ForegroundColor White
    Write-Host "AD Email: $($adUser.EmailAddress)" -ForegroundColor White
    Write-Host "UPN = Email: $(if($adUser.UserPrincipalName -eq $adUser.EmailAddress){'✓ MATCH'}else{'✗ MISMATCH'})" -ForegroundColor $(if($adUser.UserPrincipalName -eq $adUser.EmailAddress){'Green'}else{'Red'})
    
    # Proxy-Adressen anzeigen
    if ($adUser.ProxyAddresses) {
        Write-Host "`nProxy Addresses:" -ForegroundColor Cyan
        $adUser.ProxyAddresses | ForEach-Object {
            $primary = if ($_ -cmatch '^SMTP:') { " (PRIMARY)" } else { "" }
            Write-Host "  $_$primary" -ForegroundColor White
        }
    }
} catch {
    Write-Host "Cannot query AD user: $($_.Exception.Message)" -ForegroundColor Red
}

# Azure AD Token Informationen (falls verfügbar)
Write-Host "`nDevice Registration Status:" -ForegroundColor Cyan
$dsregStatus = dsregcmd /status
$userEmail = ($dsregStatus | Select-String "UserEmail").ToString().Split(":")[1].Trim()
$userName = ($dsregStatus | Select-String "UserName").ToString().Split(":")[1].Trim()

Write-Host "Device User Email: $userEmail" -ForegroundColor White
Write-Host "Device User Name: $userName" -ForegroundColor White

# Windows Hello spezifische UPN-Probleme
Write-Host "`nWindows Hello Specific Checks:" -ForegroundColor Cyan

# NGC User-spezifische Registry
$userSid = (Get-WmiObject -Class Win32_UserAccount -Filter "Name='$env:USERNAME'").SID
Write-Host "User SID: $userSid" -ForegroundColor White

# NGC Container für diesen User suchen
$ngcUserPath = "C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\Ngc\$userSid"
$ngcUserExists = Test-Path $ngcUserPath
Write-Host "NGC User Container exists: $ngcUserExists" -ForegroundColor $(if($ngcUserExists){'Green'}else{'Red'})

if ($ngcUserExists) {
    $ngcFiles = Get-ChildItem $ngcUserPath -ErrorAction SilentlyContinue
    Write-Host "NGC Files count: $($ngcFiles.Count)" -ForegroundColor White
}