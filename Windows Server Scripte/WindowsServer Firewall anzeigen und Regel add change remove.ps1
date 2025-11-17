#Windows Server Firewall Einstellen

#Regeln anzeigen:
Get-NetFirewallRule | Format-Table DisplayName, Enabled, Direction, Action, LocalPort


# Alle erlaubten eingehenden Ports anzeigen
Get-NetFirewallRule -Direction Inbound -Action Allow | 
Where-Object { $_.Enabled -eq 'True' } |
Get-NetFirewallPortFilter | 
Select-Object @{Name = 'Rule'; Expression = { $_.InstanceID.Split('|')[1] } }, 
Protocol, LocalPort, RemotePort |
Sort-Object LocalPort

# Detaillierte Ansicht mit Regelnamen und Ports
Get-NetFirewallRule -Direction Inbound -Action Allow -Enabled True | 
ForEach-Object {
    $rule = $_
    $port = $_ | Get-NetFirewallPortFilter
    [PSCustomObject]@{
        DisplayName   = $rule.DisplayName
        Profile       = $rule.Profile
        Protocol      = $port.Protocol
        LocalPort     = $port.LocalPort
        RemotePort    = $port.RemotePort
        RemoteAddress = ($_ | Get-NetFirewallAddressFilter).RemoteAddress
    }
} | Sort-Object LocalPort | Format-Table -AutoSize


##Aktive Verbdinungen
# Alle lauschenden Ports anzeigen
Get-NetTCPConnection -State Listen | 
Select-Object LocalAddress, LocalPort, State, OwningProcess |
Sort-Object LocalPort

# Mit Prozessnamen
Get-NetTCPConnection -State Listen | 
Select-Object LocalAddress, LocalPort, State,
@{Name = "Process"; Expression = { (Get-Process -Id $_.OwningProcess).ProcessName } } |
Sort-Object LocalPort


# TCP Ports
Write-Host "TCP Listening Ports:" -ForegroundColor Green
Get-NetTCPConnection -State Listen | 
Select-Object LocalPort, 
@{Name = "Process"; Expression = { (Get-Process -Id $_.OwningProcess).ProcessName } } |
Sort-Object LocalPort -Unique

# UDP Ports
Write-Host "`nUDP Listening Ports:" -ForegroundColor Green
Get-NetUDPEndpoint | 
Where-Object { $_.LocalAddress -ne '127.0.0.1' } |
Select-Object LocalPort, LocalAddress,
@{Name = "Process"; Expression = { (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName } } |
Sort-Object LocalPort -Unique


###Kombinierte Übersicht: Firewall-Regeln vs. tatsächlich offene Ports

function Get-PortOverview {
    Write-Host "`n===== FIREWALL ERLAUBTE PORTS =====" -ForegroundColor Yellow
    
    $allowedPorts = Get-NetFirewallRule -Direction Inbound -Action Allow -Enabled True | 
    ForEach-Object {
        $port = $_ | Get-NetFirewallPortFilter
        if ($port.LocalPort -ne 'Any') {
            [PSCustomObject]@{
                DisplayName = $_.DisplayName
                Protocol    = $port.Protocol  
                Port        = $port.LocalPort
            }
        }
    } | Sort-Object Port
    
    $allowedPorts | Format-Table -AutoSize
    
    Write-Host "`n===== TATSÄCHLICH LAUSCHENDE PORTS =====" -ForegroundColor Yellow
    
    Write-Host "`nTCP:" -ForegroundColor Cyan
    Get-NetTCPConnection -State Listen | 
    Select-Object @{Name = "Port"; Expression = { $_.LocalPort } },
    @{Name = "Address"; Expression = { $_.LocalAddress } },
    @{Name = "Process"; Expression = { (Get-Process -Id $_.OwningProcess).ProcessName } } |
    Sort-Object Port -Unique | Format-Table -AutoSize
    
    Write-Host "UDP:" -ForegroundColor Cyan
    Get-NetUDPEndpoint | 
    Where-Object { $_.LocalAddress -ne '::' -and $_.LocalAddress -ne '::1' } |
    Select-Object @{Name = "Port"; Expression = { $_.LocalPort } },
    @{Name = "Address"; Expression = { $_.LocalAddress } },
    @{Name = "Process"; Expression = { (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName } } |
    Sort-Object Port -Unique | Format-Table -AutoSize
}

# Funktion ausführen
Get-PortOverview




############# Port Prüfung

function Test-Port {
    param(
        [int]$Port,
        [string]$Protocol = "TCP"
    )
    
    Write-Host "`nÜberprüfe Port $Port ($Protocol)..." -ForegroundColor Yellow
    
    # Firewall-Regel suchen
    $rules = Get-NetFirewallRule -Direction Inbound -Action Allow -Enabled True | 
    Where-Object {
        $portFilter = $_ | Get-NetFirewallPortFilter
        $portFilter.Protocol -eq $Protocol -and 
        ($portFilter.LocalPort -eq $Port -or $portFilter.LocalPort -eq 'Any')
    }
    
    if ($rules) {
        Write-Host "✓ Firewall-Regel gefunden:" -ForegroundColor Green
        $rules | Select-Object DisplayName, Profile | Format-Table
    }
    else {
        Write-Host "✗ Keine Firewall-Regel für diesen Port" -ForegroundColor Red
    }
    
    # Prüfen ob Port lauscht
    if ($Protocol -eq "TCP") {
        $listening = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
        if ($listening) {
            $process = (Get-Process -Id $listening[0].OwningProcess).ProcessName
            Write-Host "✓ Port wird belauscht von: $process" -ForegroundColor Green
        }
        else {
            Write-Host "✗ Port wird nicht belauscht" -ForegroundColor Yellow
        }
    }
}

# Beispiel
Test-Port -Port 3389 -Protocol TCP
Test-Port -Port 443 -Protocol TCP








############## Regeln hinzufügen ################

# HTTPS-Zugriff erlauben
New-NetFirewallRule -DisplayName "Allow HTTPS" `
    -Direction Inbound `      #Inbound, Outbound
-Protocol TCP `               #UDP , Any 
-LocalPort 443 `
    -Action Allow `
    -Profile Any

# RDP-Zugriff erlauben
New-NetFirewallRule -DisplayName "Allow RDP" `
    -Direction Inbound `     #Inbound, Outbound
-Protocol TCP `      #UDP , Any 
-LocalPort 3389 `
    -Action Allow `
    -Profile Domain, Private, Public



# Ausgehende Verbindung blockieren
New-NetFirewallRule -DisplayName "Block Outbound Port 25" `
    -Direction Outbound `     #Inbound, Outbound
-Protocol TCP `           #UDP , Any 
-RemotePort 25 `
    -Action Block

# Port-Bereich öffnen
New-NetFirewallRule -DisplayName "Dynamic RPC" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 49152-65535 `
    -Action Allow `
    -Profile Domain

# Multiple Ports
New-NetFirewallRule -DisplayName "Web Services" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 80, 443, 8080, 8443 `
    -Action Allow



# Zugriff nur von bestimmten IPs erlauben
New-NetFirewallRule -DisplayName "SQL Server - Specific IPs" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 1433 `
    -RemoteAddress "192.168.1.0/24", "10.0.0.5" `
    -Action Allow `
    -Profile Domain

# Lokale IP-Bereiche definieren
New-NetFirewallRule -DisplayName "Management Access" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 5985 `
    -LocalAddress "192.168.100.10" `
    -RemoteAddress "192.168.100.0/24" `
    -Action Allow


# Regel für spezifisches Programm
New-NetFirewallRule -DisplayName "Allow MyApp" `
    -Direction Inbound `
    -Program "C:\Program Files\MyApp\app.exe" `
    -Action Allow `
    -Profile Domain, Private

# Für alle Programme in einem Ordner
New-NetFirewallRule -DisplayName "Allow IIS" `
    -Direction Inbound `
    -Program "C:\Windows\System32\inetsrv\w3wp.exe" `
    -Protocol TCP `
    -Action Allow



#####Regeln Anzeigen:

# Alle Regeln anzeigen
Get-NetFirewallRule | Format-Table DisplayName, Enabled, Direction, Action

# Spezifische Regel finden
Get-NetFirewallRule -DisplayName "*RDP*"

# Aktive eingehende Regeln
Get-NetFirewallRule -Direction Inbound -Enabled True | 
Select-Object DisplayName, Profile, Action


# Regel aktivieren/deaktivieren
Set-NetFirewallRule -DisplayName "Allow RDP" -Enabled True

# Port ändern
Set-NetFirewallRule -DisplayName "Allow RDP" -LocalPort 3390

# IP-Adressen hinzufügen
Set-NetFirewallRule -DisplayName "SQL Server - Specific IPs" `
    -RemoteAddress @("192.168.1.0/24", "10.0.0.5", "172.16.0.0/16")


# Einzelne Regel löschen
Remove-NetFirewallRule -DisplayName "Test Rule"

# Mehrere Regeln löschen
Get-NetFirewallRule -Group "Test Rules" | Remove-NetFirewallRule
