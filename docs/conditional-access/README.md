# Conditional Access policies

Exported from the Entra admin center with **Download JSON** (Microsoft Graph format), after testing in Report only mode and the What If tool.

| Policy | Who | Resources | Condition | Control |
| --- | --- | --- | --- | --- |
| `CA001-AllUsers-RequireMFA` | All users | All resources | Any client | Require MFA |
| `CA002-AllUsers-BlockLegacyAuth` | All users | All resources | Exchange ActiveSync and other clients (legacy auth) | Block |

Both policies exclude one group, `CA-Exclude-BreakGlass` (object ID `ce803141-fb02-45c3-b2c5-e8adbb1ea2ff`), which holds the two emergency access accounts.

## How they were rolled out

1. Created in **Report only** mode.
2. Checked with the **What If** tool: a normal user gets MFA, a legacy client is blocked, and a break glass account is excluded from both.
3. Switched to **On** and confirmed with a real sign in: the test user was stopped and asked to register Microsoft Authenticator.

## Next steps I would take in production

- Replace "Require MFA" with an **authentication strength** that requires phishing resistant methods (passkeys, FIDO2) for admins.
- Alert on any sign in by a break glass account.
- Review the exclusion group on a schedule.
