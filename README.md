# Hybrid Identity Lab: Active Directory to Microsoft Entra ID

> **Loom walkthrough:** _add link here_

A mock hospital ("Lakeview Health") built to practice the identity work IAM Analyst and IAM Administrator roles ask for: an on premises Active Directory forest synced to Microsoft Entra ID, with Conditional Access, MFA and SAML single sign on layered on top.

All names and data in this repo are fake.

## What this proves

| Skill | Where it shows up |
| --- | --- |
| Active Directory administration | OU design, security groups, bulk user creation with PowerShell |
| Hybrid identity | Entra Cloud Sync from AD to Entra ID |
| Authentication and access policy | Conditional Access: MFA for all users, block legacy auth, break glass exclusions |
| Group based access | Dynamic groups by department |
| Federation | SAML SSO to an enterprise app |
| Automation habits | `-WhatIf` dry runs, JSON run logs, no secrets in source |

## Architecture

![Architecture](diagrams/architecture.png)

```
Azure VM: DC01 (Windows Server, AD DS + DNS, lab.local)
        │  Entra Cloud Sync agent
        ▼
Microsoft Entra ID tenant
   ├── Dynamic groups by department
   ├── Conditional Access (MFA, block legacy auth)
   ├── Break glass accounts (excluded from CA)
   └── Enterprise app with SAML SSO
```

## Repo layout

| Path | What it is |
| --- | --- |
| `scripts/Install-LabDomainController.ps1` | Promotes the VM to the first DC of `lab.local` |
| `scripts/New-LabUsers.ps1` | Creates OUs, department groups, 40 users and managers from CSV; supports `-WhatIf` |
| `data/lab_users.csv` | Fake HR feed: 40 employees across 5 departments |
| `docs/build-log.md` | What I built each day, what broke, how I fixed it |
| `docs/conditional-access/` | Exported Conditional Access policies (JSON) |
| `diagrams/` | Architecture diagram |

## Directory design

```
lab.local
└── OU=Hospital
    ├── OU=Clinical       (nurses, physicians, nurse manager)
    ├── OU=Registration
    ├── OU=Billing
    ├── OU=IT
    ├── OU=Contractors
    └── OU=Groups         (GG-Clinical, GG-Registration, GG-Billing, GG-IT, GG-Contractors)
```

## How to run

```powershell
# On the VM, elevated PowerShell
.\scripts\Install-LabDomainController.ps1 -DomainName lab.local -NetbiosName LAB
# after the reboot
.\scripts\New-LabUsers.ps1 -UpnSuffix <yourtenant>.onmicrosoft.com -WhatIf
.\scripts\New-LabUsers.ps1 -UpnSuffix <yourtenant>.onmicrosoft.com
```

## Lessons learned

_Fill in from docs/build-log.md: the two or three problems worth telling an interviewer about._
