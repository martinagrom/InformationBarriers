#------------------------------------------------------------
# 2-Configure-IB.ps1
# Configure Information Barriers v2 (IB)
# 2021-03-27 Martina Grom, atwork.at
#------------------------------------------------------------

# IB supports Teams, OneDrive for Business and SharePoint Online. 
# https://techcommunity.microsoft.com/t5/security-compliance-and-identity/information-barriers-v2-is-now-generally-available-for-all-new/ba-p/3757781
# Follow the steps at
# https://learn.microsoft.com/en-us/microsoft-365/compliance/information-barriers-policies?view=o365-worldwide#step-1-make-sure-prerequisites-are-met

# Note: If the following login does not work properly, switch to Windows PowerShell (x64)
# PowerShell: Show session menu

#------------------------------------------------------------
# Import and Login
#------------------------------------------------------------
# Note: Use the latest EXO v3
Import-Module ExchangeOnlineManagement

# Connect to Exchange Online PowerShell with an interactive login
# https://learn.microsoft.com/en-us/powershell/exchange/connect-to-exchange-online-powershell?view=exchange-ps
Connect-ExchangeOnline -UserPrincipalName <admin@yourtenant.org>

# Connect to Security & Compliance PowerShell PowerShell using modern authentication and ExchangePowerShellV3 module
# https://learn.microsoft.com/en-us/powershell/module/exchange/connect-ippssession?view=exchange-ps
# Required for Set-PolicyConfig... 
Connect-IPPSSession -UserPrincipalName <admin@yourtenant.org>

# Test the EXO connection if needed
Get-PSSession | Select-Object -Property State, Name
# Get-EXORecipient <some-mailbox>

#------------------------------------------------------------
# Check the audit log 
#------------------------------------------------------------
# https://learn.microsoft.com/en-gb/microsoft-365/compliance/audit-log-enable-disable?view=o365-worldwide#verify-the-auditing-status-for-your-organization
Get-AdminAuditLogConfig | Format-List UnifiedAuditLogIngestionEnabled

# Enable audit Log if required
# Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true

#------------------------------------------------------------
# Connect to Azure
#------------------------------------------------------------
Import-Module -Name Az.Resources
Import-Module -Name Az.Accounts

# Connect to Azure with a browser sign in token
Connect-AzAccount

#------------------------------------------------------------
# Add the Multi tenant IB app to the tenant & consent to it
#------------------------------------------------------------
# https://learn.microsoft.com/en-us/microsoft-365/compliance/information-barriers-policies?view=o365-worldwide#step-1-make-sure-prerequisites-are-met
$appId = "bcf62038-e005-436d-b970-2a472f8c1982"
$sp = Get-AzADServicePrincipal -ServicePrincipalName $appId
$sp
# Create the app and consent if it doesn't exist
if ($null -eq $sp) { New-AzADServicePrincipal -ApplicationId $appId }
# Give the consent as Admin
Start-Process "https://login.microsoftonline.com/common/adminconsent?client_id=$appId"

#------------------------------------------------------------
# Configure Information Barriers v2 (IB)
#------------------------------------------------------------

# Check which IB mode is enabled
# https://techcommunity.microsoft.com/t5/security-compliance-and-identity/information-barriers-v2-is-now-generally-available-for-all-new/ba-p/3757781
Get-PolicyConfig
# Filter just the InformationBarrierMode 
Get-PolicyConfig | fl *information*

# We need to setup the Multi-segment support on orgnaizational level first
# https://techcommunity.microsoft.com/t5/security-compliance-and-identity/information-barriers-v2-is-now-generally-available-for-all-new/ba-p/3757781
Get-OrganizationConfig | fl *information*

# If tenant is in Legacy mode: 

<#
PS > Get-OrganizationConfig  | fl *information*

MaxInformationBarrierSegmentsLegacy     :
MaxInformationBarrierSegments           : 5000
MaxInformationBarrierBridges            : 5000
InformationBarriersManagementEnabled    : False
InformationBarriersEnforcementEnabled   : False
InformationBarriersRestrictPeopleSearch : True
InformationBarrierMode                  : Legacy
#>

# Get default tenant domain (or set it hardcoded)
$DefaultDomain = Get-AcceptedDomain  `
    | Where-Object { $PSItem.domainname -like '*onmicrosoft.com' -and $PSItem.domainname -notlike '*.mail.onmicrosoft.com' }

<#
PS > Enable-ExoInformationBarriersMultiSegment -Organization  M365x42927623.onmicrosoft.com

Information : Multi Segment mode successfully enabled.
Success     : True
Identity    :
IsValid     : True
ObjectState : New
#>
Enable-ExoInformationBarriersMultiSegment -Organization $DefaultDomain.DomainName

<# Organization config result should show now:
PS > Get-OrganizationConfig | fl *information*    

MaxInformationBarrierSegmentsLegacy     :
MaxInformationBarrierSegments           : 5000
MaxInformationBarrierBridges            : 5000
InformationBarriersManagementEnabled    : False
InformationBarriersEnforcementEnabled   : False
InformationBarriersRestrictPeopleSearch : True
InformationBarrierMode                  : MultiAllow
#>

# If single mode - enable multimode | only this one command is in the ipps powershell / not exchange only module
Set-PolicyConfig -InformationBarrierMode 'MultiSegment'

# Check it
Get-PolicyConfig  | fl *information*

<#
PS > Get-PolicyConfig  | fl *information*

SensitiveInformationScanTimeWindowExo     :
InformationBarrierMode                    : MultiSegment
InformationBarrierPeopleSearchRestriction : Enabled
#>

#------------------------------------------------------------
# Set the IB policies
#------------------------------------------------------------
New-OrganizationSegment -Name "Retail" -UserGroupFilter "Department -eq 'Retail'"
New-OrganizationSegment -Name "Operations" -UserGroupFilter "Department -eq 'Operations'"
Get-OrganizationSegment | fl 

# Setup policy - active or inactive
New-InformationBarrierPolicy -Name "Operations-to-Retail" -AssignedSegment "Operations" -SegmentsBlocked "Retail" -State Active
New-InformationBarrierPolicy -Name "Retail-to-Operations" -AssignedSegment "Retail" -SegmentsBlocked "Operations" -State Active

# Apply the policies
Start-InformationBarrierPoliciesApplication

# See a list of available policies
Get-InformationBarrierPolicy
Get-InformationBarrierPolicy | Select Name, Guid, State, SegmentsAllowed, SegmentsBlocked | Format-Table 

# Most recent display information about whether policy application completed, failed, or is in progress.
Get-InformationBarrierPoliciesApplicationStatus

# Display information about whether policy application completed, failed, or is in progress.
# Get-InformationBarrierPoliciesApplicationStatus -All $true

#------------------------------------------------------------
# Test the IB policies
#------------------------------------------------------------

# Get a list of all segments
Get-OrganizationSegment

# See the status of IB
# Get-InformationBarrierRecipientStatus -Identity AdeleV@M365x42927623.OnMicrosoft.com -Identity2 DebraB@M365x42927623.onmicrosoft.com
Get-InformationBarrierRecipientStatus -Identity AdeleV -Identity2 DebraB
Get-InformationBarrierRecipientStatus -Identity DebraB -Identity2 AdeleV
Get-InformationBarrierPolicy -ExoPolicyId a4cdf52e-65b5-4fae-ab64-9d707d64829e

# Troubleshooting
# Lookup specific users if they are affected by an IB policy
Get-InformationBarrierRecipientStatus -Identity AdeleV

# Look which segments are included in IB policies
# Get-InformationBarrierPolicy -Identity b42c3d0f-49e9-4506-a0a5-bf2853b5df6f

# Make sure segments are configured correctly
# Get-OrganizationSegment -Identity c96e0837-c232-4a8a-841e-ef45787d8fcd

# Issue: Communications are allowed between users who should be blocked in Microsoft Teams
# Get-InformationBarrierRecipientStatus -Identity <value> -Identity2 <value>

#------------------------------------------------------------
# Configuration for information barriers on SharePoint and OneDrive
# https://learn.microsoft.com/en-us/sharepoint/information-barriers
# https://learn.microsoft.com/en-us/sharepoint/information-barriers-onedrive
# https://learn.microsoft.com/en-us/MicrosoftTeams/information-barriers-in-teams
#------------------------------------------------------------

# Check and update modules first
Get-Module -Name Microsoft.Online.SharePoint.PowerShell -ListAvailable | Select Name,Version
# Install-Module -Name Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser
# Update-Module -Name Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser -Force
Import-Module Microsoft.Online.SharePoint.PowerShell

# Connect to SPO
Connect-SPOService -Url https://<yourtenant>-admin.sharepoint.com

# Enable IB in SharePoint
Set-SPOTenant -InformationBarriersSuspension $false
Set-SPOTenant -IBImplicitGroupBased $true
Get-OrganizationSegment | ft Name, EXOSegmentID

# Microsoft Teams
Set-UnifiedGroup -InformationBarrierMode Implicit

# Disconnect...
# Disconnect-ExchangeOnline
