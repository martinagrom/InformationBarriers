#------------------------------------------------------------
# 1-Install-requirements.ps1
# Configure Information Barriers v2 (IB)
# 2021-03-27 Martina Grom, atwork.at
#------------------------------------------------------------

# Check all installed PS modules
Get-InstalledModule | more
Get-InstalledModule -Name *ex* 

# if you need to check where your PowerShell modules are installed, you can use the following command:
$env:PSModulePath -split ';'
# C:\Users\<username>\OneDrive - atwork gmbh\Documents\WindowsPowerShell\Modules - When modules are installed with the scope – CurrentUser parameter.
# C:\Program Files\WindowsPowerShell\Modules - Modules are stored in this path when AllUsers Scope is provided.
# C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules - default path. Whenever Microsoft updates any PowerShell  version or module, it is installed on this location.
# c:\Users\<username>\.vscode\extensions\ms-vscode.powershell-2023.2.1\modules

# Use the latest EXO v3
Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser
# Update-Module -Name ExchangeOnlineManagement -force

# Azure AD
Install-Module -Name Az -Scope CurrentUser
# Update-Module -Name Az -force

Install-Module -Name Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser
# Update-Module -Name Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser -Force

# End of requirements.
