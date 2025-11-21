Connect-AzAccount

Get-AzSubscription

#Subscription eintragen

$subId = "f927e2ce-b281-4f72-80ed-cbe3b474fea7"



#RoleDefinition: Die Berechtigung eintragen die man vergeben möchte
#ApplicationID: Die ID des Dienstprinzipals aus der Tabelle

$parameters = @{
    RoleDefinitionName = "Desktop Virtualization Power On Off Contributor"
    ApplicationId = "9cdead84-a844-4324-93f2-b2e6bb768d07"
    Scope = "/subscriptions/$subId"
}

New-AzRoleAssignment @parameters


#Ergebnis:
<#
RoleAssignmentName : 8f5c23b3-af37-469a-9f84-a804cdda63ad
RoleAssignmentId   : /subscriptions/f927e2ce-b281-4f72-80ed-cbe3b474fea7/providers/Microsoft.Authorization/roleAssignments/8f5c23b3-af37-469a-9f84-a804cdda63ad
Scope              : /subscriptions/f927e2ce-b281-4f72-80ed-cbe3b474fea7
DisplayName        : Azure Virtual Desktop
SignInName         : 
RoleDefinitionName : Desktop Virtualization Power On Off Contributor
RoleDefinitionId   : 40c5ff49-9181-41f8-ae61-143b0e78555e
ObjectId           : f54f7bcb-4b4d-4f07-9ff6-4af2fc294e10
ObjectType         : ServicePrincipal
CanDelegate        : False
Description        : 
ConditionVersion   : 
Condition          : 

#>

