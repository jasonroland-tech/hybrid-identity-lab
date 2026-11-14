# Command cheat sheet

Nobody memorizes these. Keep this file open, copy what you need, and use the discovery commands at the bottom when you forget something.

## The pattern behind every command

PowerShell commands are **Verb-Noun**. Learn the verbs and the nouns, and you can guess most commands.

| Verb | Means | Example |
| --- | --- | --- |
| `Get` | Read, change nothing | `Get-ADUser aadams` |
| `New` | Create | `New-ADUser ...` |
| `Set` | Change | `Set-ADUser aadams -Title "Charge Nurse"` |
| `Remove` | Delete | `Remove-ADUser nruiz` |
| `Add` | Put into something | `Add-ADGroupMember GG-IT -Members eevans` |
| `Enable` / `Disable` | Turn on or off | `Disable-ADAccount nruiz` |
| `Move` | Relocate | `Move-ADObject` |

Nouns: `ADUser`, `ADGroup`, `ADGroupMember`, `ADOrganizationalUnit`, `ADDomain` on premises. `MgUser`, `MgGroup` in Microsoft Graph (Entra).

## Active Directory (on DC01)

```powershell
# Who am I, and what domain is this?
whoami
Get-ADDomain | Select-Object DNSRoot, NetBIOSName, PDCEmulator

# Look at one user, including extra attributes
Get-ADUser aadams -Properties Department, Title, Manager

# Count users in an OU
(Get-ADUser -Filter * -SearchBase "OU=Hospital,DC=lab,DC=local").Count

# Find a user's full path (needed for Cloud Sync provision on demand)
(Get-ADUser nruiz).DistinguishedName

# Who is in a group?
Get-ADGroupMember GG-Clinical | Select-Object Name

# Joiner
New-ADUser -Name "First Last" -SamAccountName flast -UserPrincipalName flast@premierroland.onmicrosoft.com `
  -Department Clinical -Title "Registered Nurse" -Path "OU=Clinical,OU=Hospital,DC=lab,DC=local" `
  -AccountPassword (Read-Host -AsSecureString "Password") -ChangePasswordAtLogon $true -Enabled $true

# Mover
Set-ADUser flast -Department Billing -Title "Billing Specialist" -Manager ddunn
Get-ADUser flast | Move-ADObject -TargetPath "OU=Billing,OU=Hospital,DC=lab,DC=local"

# Leaver
Disable-ADAccount flast
```

## Microsoft Graph PowerShell (Entra, from the Mac)

```powershell
pwsh                                             # start PowerShell 7
Connect-MgGraph -Scopes "User.ReadWrite.All"     # sign in with only the rights you need
Get-MgUser -All -Property DisplayName,UserPrincipalName,Department |
  Select-Object DisplayName,UserPrincipalName,Department
Disconnect-MgGraph
```

## Safety habits

- Run anything that changes data with `-WhatIf` first. It prints what would happen and changes nothing.
- `Set-ExecutionPolicy -Scope Process Bypass` allows scripts in this window only.
- Never put passwords in a command or a file. Use `Read-Host -AsSecureString`.

## When you forget (this is what admins actually do)

```powershell
Get-Command *ADUser*            # every command with ADUser in the name
Get-Help Set-ADUser -Examples   # working examples for a command
Get-ADUser aadams -Properties * # every attribute a user has, to find the name you need
```

Press **Tab** while typing a command or parameter and PowerShell completes it for you.
