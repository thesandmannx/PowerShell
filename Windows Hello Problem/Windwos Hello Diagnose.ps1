# Step1_Diagnose_0xc000005e.ps1
Write-Host "=== Windows Hello Error 0xc000005e Diagnosis ===" -ForegroundColor Yellow

Write-Host "`n1. Device Registration Status:" -ForegroundColor Cyan
dsregcmd /status | findstr -i "azureadjoined domainjoined ngcset wamdefaultset azureadprt"

Write-Host "`n2. NGC Services Status:" -ForegroundColor Cyan
$ngcServices = @("NgcSvc", "NgcCtnrSvc", "KeyIso", "VaultSvc")
foreach ($service in $ngcServices) {
    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($svc) {
        Write-Host "$service`: $($svc.Status)" -ForegroundColor $(if($svc.Status -eq "Running"){"Green"}else{"Red"})
    } else {
        Write-Host "$service`: Not Found" -ForegroundColor Red
    }
}

Write-Host "`n3. PIN Credential Provider Status:" -ForegroundColor Cyan
$pinProvider = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers\{D6886603-9D2F-4EB2-B667-1971041FA96B}"
if (Test-Path $pinProvider) {
    $disabled = Get-ItemProperty -Path $pinProvider -Name "Disabled" -ErrorAction SilentlyContinue
    Write-Host "PIN Provider: $(if($disabled.Disabled -eq 0){"Enabled"}else{"Disabled"})" -ForegroundColor $(if($disabled.Disabled -eq 0){"Green"}else{"Red"})
} else {
    Write-Host "PIN Provider: Not Found" -ForegroundColor Red
}

Write-Host "`n4. Windows Hello Policies:" -ForegroundColor Cyan
$whfbPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork"
if (Test-Path $whfbPolicy) {
    $enabled = Get-ItemProperty -Path $whfbPolicy -Name "Enabled" -ErrorAction SilentlyContinue
    Write-Host "WHFB Policy: $(if($enabled.Enabled -eq 1){"Enabled"}else{"Disabled"})" -ForegroundColor $(if($enabled.Enabled -eq 1){"Green"}else{"Red"})
} else {
    Write-Host "WHFB Policy: Not Configured" -ForegroundColor Yellow
}

Write-Host "`n5. NGC Containers:" -ForegroundColor Cyan
$ngcPath = "C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\Ngc"
$userNgcPath = "$env:LOCALAPPDATA\Microsoft\Ngc"

$systemNgc = Get-ChildItem -Path $ngcPath -ErrorAction SilentlyContinue
$userNgc = Get-ChildItem -Path $userNgcPath -ErrorAction SilentlyContinue

Write-Host "System NGC Containers: $($systemNgc.Count)" -ForegroundColor $(if($systemNgc.Count -gt 0){"Green"}else{"Yellow"})
Write-Host "User NGC Containers: $($userNgc.Count)" -ForegroundColor $(if($userNgc.Count -gt 0){"Green"}else{"Yellow"})

Write-Host "`n6. Recent Windows Hello Events:" -ForegroundColor Cyan
$helloEvents = Get-WinEvent -LogName "Microsoft-Windows-HelloForBusiness/Operational" -MaxEvents 5 -ErrorAction SilentlyContinue |
    Where-Object {$_.LevelDisplayName -eq "Error"}
if ($helloEvents) {
    $helloEvents | ForEach-Object {
        Write-Host "[$($_.TimeCreated)] $($_.Id): $($_.LevelDisplayName)" -ForegroundColor Red
    }
} else {
    Write-Host "No recent Windows Hello errors found" -ForegroundColor Green
}

#Read-Host "`nPress Enter to continue with the fix"