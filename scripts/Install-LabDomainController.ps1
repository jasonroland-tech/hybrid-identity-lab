<#
.SYNOPSIS
    Promotes a fresh Windows Server VM to the first domain controller of a new lab forest.

.DESCRIPTION
    Run on the Azure VM in an elevated PowerShell window. Installs AD DS and DNS,
    then creates the forest. The server reboots automatically when it finishes.

.EXAMPLE
    .\Install-LabDomainController.ps1 -DomainName lab.local -NetbiosName LAB
#>
[CmdletBinding()]
param(
    [string]$DomainName  = 'lab.local',
    [string]$NetbiosName = 'LAB'
)

$ErrorActionPreference = 'Stop'

Write-Host "Installing AD DS role and management tools..." -ForegroundColor Cyan
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools | Out-Null

# Directory Services Restore Mode password. Typed at the prompt, never stored in the repo.
$dsrm = Read-Host -AsSecureString -Prompt 'Enter a DSRM (safe mode) password'

Write-Host "Creating forest $DomainName ..." -ForegroundColor Cyan
Install-ADDSForest `
    -DomainName $DomainName `
    -DomainNetbiosName $NetbiosName `
    -InstallDns `
    -SafeModeAdministratorPassword $dsrm `
    -Force
# The VM restarts here. Sign back in as LAB\<your admin user>.
