<#
.SYNOPSIS
    Builds the mock hospital directory: OUs, department groups and users from a CSV.

.DESCRIPTION
    Creates OU=Hospital with one child OU per department, a global security group per
    department (GG-<Department>), then creates each user from data\lab_users.csv,
    sets HR attributes, assigns managers and adds group membership.
    Supports -WhatIf for a dry run and writes a JSON log of every action.

.PARAMETER CsvPath
    Path to the HR style CSV. Defaults to ..\data\lab_users.csv.

.PARAMETER UpnSuffix
    UPN suffix for users. Use your verified Entra domain (for example
    yourtenant.onmicrosoft.com) so synced users sign in with a routable name.
    The suffix is added to the forest automatically if it is missing.

.EXAMPLE
    .\New-LabUsers.ps1 -UpnSuffix contoso.onmicrosoft.com -WhatIf
    .\New-LabUsers.ps1 -UpnSuffix contoso.onmicrosoft.com
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$CsvPath = (Join-Path $PSScriptRoot '..\data\lab_users.csv'),
    [Parameter(Mandatory)][string]$UpnSuffix,
    [string]$RootOuName = 'Hospital'
)

$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory

$domainDn = (Get-ADDomain).DistinguishedName
$rootOu   = "OU=$RootOuName,$domainDn"
$log      = [System.Collections.Generic.List[object]]::new()

function Write-LabLog {
    param([string]$Action, [string]$Target, [string]$Result)
    $entry = [pscustomobject]@{
        Time   = (Get-Date).ToString('s')
        Action = $Action
        Target = $Target
        Result = $Result
    }
    $log.Add($entry)
    Write-Host ("{0,-14} {1,-50} {2}" -f $Action, $Target, $Result)
}

# 1. UPN suffix on the forest so users get a routable sign in name
$forest = Get-ADForest
if ($forest.UPNSuffixes -notcontains $UpnSuffix) {
    if ($PSCmdlet.ShouldProcess($forest.Name, "Add UPN suffix $UpnSuffix")) {
        Set-ADForest -Identity $forest.Name -UPNSuffixes @{ Add = $UpnSuffix }
    }
    Write-LabLog 'UpnSuffix' $UpnSuffix 'added'
}

# 2. OUs
$users = Import-Csv -Path $CsvPath
if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$rootOu'" -ErrorAction SilentlyContinue)) {
    if ($PSCmdlet.ShouldProcess($rootOu, 'Create OU')) {
        New-ADOrganizationalUnit -Name $RootOuName -Path $domainDn -ProtectedFromAccidentalDeletion $true
    }
    Write-LabLog 'CreateOU' $rootOu 'created'
}

foreach ($ou in ($users.OU + 'Groups' | Sort-Object -Unique)) {
    $ouDn = "OU=$ou,$rootOu"
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouDn'" -ErrorAction SilentlyContinue)) {
        if ($PSCmdlet.ShouldProcess($ouDn, 'Create OU')) {
            New-ADOrganizationalUnit -Name $ou -Path $rootOu -ProtectedFromAccidentalDeletion $true
        }
        Write-LabLog 'CreateOU' $ouDn 'created'
    }
}

# 3. Department groups
foreach ($dept in ($users.Department | Sort-Object -Unique)) {
    $groupName = "GG-$dept"
    if (-not (Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue)) {
        if ($PSCmdlet.ShouldProcess($groupName, 'Create group')) {
            New-ADGroup -Name $groupName -GroupScope Global -GroupCategory Security `
                -Path "OU=Groups,$rootOu" -Description "Birthright access for $dept"
        }
        Write-LabLog 'CreateGroup' $groupName 'created'
    }
}

# 4. Users. One initial password for the lab, typed at runtime, never saved.
$initialPassword = Read-Host -AsSecureString -Prompt 'Initial password for lab users'

foreach ($u in $users) {
    $sam = $u.SamAccountName
    $upn = "$sam@$UpnSuffix"
    if (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue) {
        Write-LabLog 'CreateUser' $upn 'skipped (exists)'
        continue
    }
    if ($PSCmdlet.ShouldProcess($upn, 'Create user')) {
        New-ADUser `
            -Name "$($u.FirstName) $($u.LastName)" `
            -GivenName $u.FirstName -Surname $u.LastName `
            -DisplayName "$($u.FirstName) $($u.LastName)" `
            -SamAccountName $sam -UserPrincipalName $upn `
            -EmailAddress $upn `
            -EmployeeID $u.EmployeeId -Department $u.Department -Title $u.Title `
            -Company 'Lakeview Health (lab)' `
            -Path "OU=$($u.OU),$rootOu" `
            -AccountPassword $initialPassword -ChangePasswordAtLogon $true -Enabled $true
        Add-ADGroupMember -Identity "GG-$($u.Department)" -Members $sam
    }
    Write-LabLog 'CreateUser' $upn "created, GG-$($u.Department)"
}

# 5. Managers (second pass, so every manager exists first)
foreach ($u in $users | Where-Object ManagerTitle) {
    $manager = $users | Where-Object { $_.Title -eq $u.ManagerTitle } | Select-Object -First 1
    if ($manager -and $PSCmdlet.ShouldProcess($u.SamAccountName, "Set manager $($manager.SamAccountName)")) {
        Set-ADUser -Identity $u.SamAccountName -Manager $manager.SamAccountName
    }
    Write-LabLog 'SetManager' $u.SamAccountName $manager.SamAccountName
}

# 6. JSON log, one file per run
$logDir  = Join-Path $PSScriptRoot '..\logs'
New-Item -ItemType Directory -Path $logDir -Force -WhatIf:$false | Out-Null
$logFile = Join-Path $logDir ("new-labusers-{0:yyyyMMdd-HHmmss}{1}.json" -f (Get-Date), $(if ($WhatIfPreference) { '-whatif' } else { '' }))
$log | ConvertTo-Json -Depth 3 | Set-Content -Path $logFile -Encoding UTF8 -WhatIf:$false
Write-Host "`nLog written to $logFile" -ForegroundColor Green
