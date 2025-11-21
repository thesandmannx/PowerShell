<#
.SYNOPSIS
   Azure AD Connect manuellen Hard-Match ausführen
 
.DESCRIPTION
   Die Befehle in diesem Skript sind idealerweise einzeln auszuführen.
   Die Anmerkungen der einzelnen Schritte sind zu beachten.
.NOTES
  Version:        1.0
  Author:         Thomas Thaler
  Creation Date:  2023-04-04
  Purpose/Change: Creation

  https://github.com/itelioCloudUncovered/cloud-uncovered/tree/main/Azure%20AD/Hard-%20und%20Soft-Match

#>

Install-Module MSOnline
Import-Module MSOnline
Import-Module ActiveDirectory

#Mit Global Admin verbunden
Connect-MsolService


#Variablen ausfüllen
$ADUser = "sonja.lemmer" 
$AzureADUser = "sonja.lemmer@schreinereilemmer.de"
$NewAzureADUser = "sonja.lemmer@lemmergmbh.onmicrosoft.com"

$guid =(Get-ADUser $ADUser).Objectguid

$immutableID=[system.convert]::ToBase64String($guid.tobytearray())

####ProxyAdressen ändern

$proxyAddresses = @(
    "SMTP:sonja.lemmer@schreinereilemmer.de"
    "smtp:sonja.lemmer@lemmergmbh.de"
    "smtp:s.lemmer@schreinereilemmer.de"
    
    )


Set-ADUser -Identity $ADUser -Replace @{proxyAddresses=$proxyAddresses}
####



Set-MsolUser -UserPrincipalName $NewAzureADUser -ImmutableId "$null"

Get-MsolUser -UserPrincipalName $NewAzureADUser | select ImmutableId

set-msolUser -userprincipalname $NewAzureADUser -immutableID $immutableID

Get-MsolUser -UserPrincipalName $NewAzureADUser | select ImmutableId

Set-MsolUserPrincipalName  -UserPrincipalName $NewAzureADUser -NewUserPrincipalName $AzureADUser

Get-MsolUser -UserPrincipalName $AzureADUser | select ImmutableId

#Set-MsolUser -UserPrincipalName $AzureADUser -ImmutableId $immutableID

# Retrieve the ImmutableId for a specific user

#$user = Get-MsolUser -UserPrincipalName $AzureADUser
#$immutableId = $user.ImmutableId

#$nuser = Get-MsolUser -UserPrincipalName $NewAzureADUser
#$nimmutableId = $nuser.ImmutableId

# Display the ImmutableId
#Write-Output "The ImmutableId for $AzureADUser is $immutableId"
#Write-Output "The ImmutableId for $NewAzureADUser is $nimmutableId"




#Set-MsolUserPrincipalName -UserPrincipalName $AzureADUser  -NewUserPrincipalName $NewAzureADUser





