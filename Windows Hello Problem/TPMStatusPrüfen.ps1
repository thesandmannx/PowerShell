# TPM_Diagnosis_Complete.ps1
Write-Host "=== Complete TPM Diagnosis for Windows Hello Issue ===" -ForegroundColor Yellow

# 1. TPM Grundstatus
Write-Host "`n1. TPM Basic Status:" -ForegroundColor Cyan
try {
    $tpm = Get-Tpm
    Write-Host "TPM Present: $($tpm.TpmPresent)" -ForegroundColor $(if($tpm.TpmPresent){"Green"}else{"Red"})
    Write-Host "TPM Ready: $($tpm.TpmReady)" -ForegroundColor $(if($tmp.TmpReady){"Green"}else{"Red"})
    Write-Host "TPM Enabled: $($tpm.TmpEnabled)" -ForegroundColor $(if($tmp.TmpEnabled){"Green"}else{"Red"})
    Write-Host "TPM Activated: $($tpm.TmpActivated)" -ForegroundColor $(if($tpm.TmpActivated){"Green"}else{"Red"})
    Write-Host "TPM Owned: $($tpm.TmpOwned)" -ForegroundColor $(if($tpm.TmpOwned){"Green"}else{"Red"})
    Write-Host "Lockout Count: $($tpm.LockoutCount)" -ForegroundColor $(if($tpm.LockoutCount -eq 0){"Green"}else{"Red"})
    Write-Host "Lockout Threshold: $($tpm.LockoutThreshold)" -ForegroundColor White
} catch {
    Write-Host "ERROR: Cannot read TPM status - $($_.Exception.Message)" -ForegroundColor Red
}

# 2. TPM Event Logs
Write-Host "`n2. Recent TPM Errors:" -ForegroundColor Cyan
$tpmEvents = Get-WinEvent -LogName "Microsoft-Windows-TPM-WMI/Operational" -MaxEvents 10 -ErrorAction SilentlyContinue |
    Where-Object {$_.LevelDisplayName -eq "Error"}

if ($tpmEvents) {
    foreach ($event in $tpmEvents) {
        Write-Host "[$($event.TimeCreated)] Event $($event.Id): $($event.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "No recent TPM errors found" -ForegroundColor Green
}

# 3. NGC-spezifische TPM-Nutzung
Write-Host "`n3. NGC TPM Usage:" -ForegroundColor Cyan
$ngcTpmKeys = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\TPM" -Recurse -ErrorAction SilentlyContinue |
    Where-Object {$_.Name -like "*NGC*"}
Write-Host "NGC TPM Keys found: $($ngcTpmKeys.Count)" -ForegroundColor $(if($ngcTpmKeys.Count -gt 0){"Yellow"}else{"Green"})

# 4. BitLocker TPM-Nutzung (kann konfliktieren)
Write-Host "`n4. BitLocker Status:" -ForegroundColor Cyan
$bitlocker = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue
if ($bitlocker) {
    Write-Host "BitLocker Status: $($bitlocker.ProtectionStatus)" -ForegroundColor $(if($bitlocker.ProtectionStatus -eq "On"){"Yellow"}else{"Green"})
    Write-Host "Key Protectors: $($bitlocker.KeyProtector.Count)" -ForegroundColor White
} else {
    Write-Host "BitLocker: Not configured" -ForegroundColor Green
}

# 5. TPM Service Status
Write-Host "`n5. TPM Services:" -ForegroundColor Cyan
$tpmServices = @("TPMSvc", "TBS")
foreach ($service in $tpmServices) {
    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($svc) {
        Write-Host "$service`: $($svc.Status)" -ForegroundColor $(if($svc.Status -eq "Running"){"Green"}else{"Red"})
    } else {
        Write-Host "$service`: Not Found" -ForegroundColor Red
    }
}