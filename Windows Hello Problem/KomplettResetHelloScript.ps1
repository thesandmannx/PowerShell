# Step2_Complete_Fix_0xc000005e.ps1
Write-Host "=== Complete Windows Hello Fix for Error 0xc000005e ===" -ForegroundColor Yellow

# Phase 1: Services stoppen
Write-Host "`nPhase 1: Stopping NGC Services..." -ForegroundColor Cyan
$servicesToStop = @("NgcSvc", "NgcCtnrSvc", "KeyIso", "VaultSvc")
foreach ($service in $servicesToStop) {
    try {
        Stop-Service -Name $service -Force -ErrorAction Stop
        Write-Host "✓ Stopped: $service" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Failed to stop: $service - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Start-Sleep -Seconds 5

# Phase 2: Registry komplett bereinigen
Write-Host "`nPhase 2: Cleaning Registry..." -ForegroundColor Cyan

# PIN Credential Provider löschen
$pinProviderPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers\{D6886603-9D2F-4EB2-B667-1971041FA96B}"
if (Test-Path $pinProviderPath) {
    Remove-Item -Path $pinProviderPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✓ Removed PIN Credential Provider registry" -ForegroundColor Green
}

# Windows Hello Policy Registry bereinigen
$whfbPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork"
if (Test-Path $whfbPolicyPath) {
    Remove-Item -Path $whfbPolicyPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✓ Cleaned WHFB Policy registry" -ForegroundColor Green
}

# User-spezifische NGC Registry
$userCredPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers"
if (Test-Path $userCredPath) {
    Remove-Item -Path $userCredPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✓ Cleaned user credential provider registry" -ForegroundColor Green
}

# Phase 3: NGC Container und Caches löschen
Write-Host "`nPhase 3: Cleaning NGC Containers and Caches..." -ForegroundColor Cyan

# System NGC Container
$systemNgcPath = "C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\Ngc"
if (Test-Path $systemNgcPath) {
    Remove-Item -Path $systemNgcPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✓ Removed system NGC containers" -ForegroundColor Green
}

# User NGC Container
$userNgcPath = "$env:LOCALAPPDATA\Microsoft\Ngc"
if (Test-Path $userNgcPath) {
    Remove-Item -Path $userNgcPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✓ Removed user NGC containers" -ForegroundColor Green
}

# Token Broker Cache
$tokenBrokerPath = "$env:LOCALAPPDATA\Microsoft\TokenBroker\Cache"
if (Test-Path $tokenBrokerPath) {
    Remove-Item -Path $tokenBrokerPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✓ Cleared TokenBroker cache" -ForegroundColor Green
}

# Credential Manager
$credManagerPath = "$env:LOCALAPPDATA\Microsoft\Credentials"
if (Test-Path $credManagerPath) {
    Remove-Item -Path $credManagerPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✓ Cleared Credential Manager" -ForegroundColor Green
}

# Vault
$vaultPath = "$env:LOCALAPPDATA\Microsoft\Vault"
if (Test-Path $vaultPath) {
    Remove-Item -Path $vaultPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✓ Cleared Vault data" -ForegroundColor Green
}

# Phase 4: Registry neu konfigurieren
Write-Host "`nPhase 4: Reconfiguring Registry..." -ForegroundColor Cyan

# PIN Credential Provider neu erstellen
New-Item -Path $pinProviderPath -Force | Out-Null
Set-ItemProperty -Path $pinProviderPath -Name "Disabled" -Value 0 -Type DWord
Write-Host "✓ Recreated PIN Credential Provider" -ForegroundColor Green

# Windows Hello for Business Policy
New-Item -Path $whfbPolicyPath -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path $whfbPolicyPath -Name "Enabled" -Value 1 -Type DWord
Set-ItemProperty -Path $whfbPolicyPath -Name "RequireSecurityDevice" -Value 0 -Type DWord
Write-Host "✓ Configured WHFB Policy" -ForegroundColor Green

# Domain PIN Login explizit erlauben
$systemPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
New-Item -Path $systemPolicyPath -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path $systemPolicyPath -Name "AllowDomainPINLogon" -Value 1 -Type DWord
Write-Host "✓ Enabled Domain PIN Login" -ForegroundColor Green

# PIN Complexity
$pinComplexityPath = "$whfbPolicyPath\PINComplexity"
New-Item -Path $pinComplexityPath -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path $pinComplexityPath -Name "MinimumPINLength" -Value 4 -Type DWord
Set-ItemProperty -Path $pinComplexityPath -Name "MaximumPINLength" -Value 127 -Type DWord
Set-ItemProperty -Path $pinComplexityPath -Name "RequireDigits" -Value 1 -Type DWord
Set-ItemProperty -Path $pinComplexityPath -Name "RequireLowercase" -Value 0 -Type DWord
Set-ItemProperty -Path $pinComplexityPath -Name "RequireUppercase" -Value 0 -Type DWord
Set-ItemProperty -Path $pinComplexityPath -Name "RequireSpecialCharacters" -Value 0 -Type DWord
Write-Host "✓ Configured PIN Complexity" -ForegroundColor Green

# Phase 5: Services starten
Write-Host "`nPhase 5: Starting Services..." -ForegroundColor Cyan
$servicesToStart = @("KeyIso", "NgcCtnrSvc", "NgcSvc", "VaultSvc")
foreach ($service in $servicesToStart) {
    try {
        Start-Service -Name $service -ErrorAction Stop
        Write-Host "✓ Started: $service" -ForegroundColor Green
        Start-Sleep -Seconds 2
    }
    catch {
        Write-Host "✗ Failed to start: $service - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Phase 6: Intune Sync forcieren
Write-Host "`nPhase 6: Forcing Intune Sync..." -ForegroundColor Cyan
$enrollments = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Enrollments" -ErrorAction SilentlyContinue
foreach ($enrollment in $enrollments) {
    $enrollmentPath = $enrollment.PSPath
    $providerID = Get-ItemProperty -Path $enrollmentPath -Name "ProviderID" -ErrorAction SilentlyContinue
    
    if ($providerID -and $providerID.ProviderID -eq "MS DM Server") {
        $guid = $enrollment.PSChildName
        Start-ScheduledTask -TaskName "PushLaunch" -TaskPath "\Microsoft\Windows\EnterpriseMgmt\$guid\" -ErrorAction SilentlyContinue
        Write-Host "✓ Triggered Intune sync for enrollment: $guid" -ForegroundColor Green
    }
}

Write-Host "`nPhase 7: Final Status Check..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

# Services Status
Write-Host "`nService Status:" -ForegroundColor White
foreach ($service in $servicesToStart) {
    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($svc) {
        Write-Host "$service`: $($svc.Status)" -ForegroundColor $(if($svc.Status -eq "Running"){"Green"}else{"Red"})
    }
}

# Device Status
Write-Host "`nDevice Status:" -ForegroundColor White
dsregcmd /status | findstr -i "domainjoined\|azureadjoined\|ngcset\|wamdefaultset"

Write-Host "`n=== FIX COMPLETED ===" -ForegroundColor Green
Write-Host "Wait 5-10 minutes, then try Windows Hello PIN setup" -ForegroundColor Yellow
Write-Host "Go to: Settings → Accounts → Sign-in options → Windows Hello PIN" -ForegroundColor Yellow

Read-Host "`nPress Enter to continue with PIN setup verification"