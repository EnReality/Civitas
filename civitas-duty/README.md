CIVITAS Duty

Server-only resource that manages authoritative duty state for government organizations.

Usage
- Toggle duty for your primary government organization: `/duty`
- Toggle duty for a specific org: `/duty <orgId>`

Exports
- `SetDuty(characterId, orgId, on)` -> `{ ok, reason, on }`
- `ToggleDuty(characterId, orgId)` -> `{ ok, reason, on }`
- `IsOnDuty(characterId, orgId)` -> bool
- `GetDutyOrgs(characterId)` -> array orgIds
- `GetAllOnDuty()` -> array of `{ source, characterId, orgId, role }`

Events
- Emits `civitas:dutyChanged` and `civitas:transaction` on changes.

Config
- `config.lua` contains `role_rules` (substring matching) and `permission_code`.

Notes
- Only organizations with `organization_type == 'government'` may toggle duty.
- Permission gate soft-allows if permission is not registered.
- Temporary in-memory state only; no persistence.
