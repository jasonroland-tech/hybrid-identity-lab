# Build log

One entry per session. The "what broke" lines are the best material for your Loom and interviews.

| Date | What I built | What broke | How I fixed it |
| --- | --- | --- | --- |
| 2026-11-09 | Entra ID P2 trial, GitHub repo, SC-300 lab 01 (roles, Graph PowerShell users) | Git commit failed: no identity, then push blocked by email privacy | Set user.name and the GitHub no-reply email |
| 2026-11-12 | DC01 VM deployed (D2as v5, static 172.16.0.4, RDP locked to my IP), promoted to lab.local, VNet DNS set to DC01 | B2s and D2s v3 unavailable on the free subscription; 10.0.0.4 rejected | Used D2as v5; the subnet is 172.16.0.0/24 |
| 2026-11-12 | OUs, groups, 40 users from CSV with New-LabUsers.ps1 (WhatIf first) | WhatIf run skipped writing its own log | Added -WhatIf:$false to the log writes |
| 2026-11-12 | Cloud Sync agent with a gMSA, scoped to OU=Hospital, password hash sync; 40 users in Entra | | Created a KDS root key first so the gMSA could be created |
| 2026-11-13 | DYN-Clinical-Staff dynamic group; two break glass Global Admins in CA-Exclude-BreakGlass; JML test (joiner, mover, leaver) | Provision on demand said the user was not found | It needs the distinguished name, not the username |
| | Conditional Access: MFA, block legacy auth | | |
| | SAML SSO enterprise app | | |
| | README, diagram, Loom recorded | | |
