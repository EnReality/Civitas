# API

This document lists the primary exports and events provided by the CIVITAS
resources included in this repository. It is intentionally minimal and
serves as an implementation reference for server-side integrations.

## civitas-organizations
- Exports:
	- `CreateOrganization(orgType, name)` -> org table
	- `GetOrganization(orgId)` -> org table
	- `ListOrganizations()` -> array of orgs
	- `CreateRank(orgId, rankData)` -> rank
	- `UpdateRank(rankId, attrs)` -> rank
	- `RemoveRank(rankId)` -> bool
	- `AddMember(orgId, characterId, rankId)` -> membership
	- `RemoveMember(orgId, characterId)` -> bool
	- `GrantPermissionToRank(rankId, permissionCode)` -> bool
	- `RevokePermissionFromRank(rankId, permissionCode)` -> bool
	- `RegisterPermission(code)` -> bool
	- `HasPermission(characterId, permissionCode)` -> bool
	- `HasPermissionInOrg(characterId, orgId, permissionCode)` -> bool
	- `GetOrganizations(characterId)` -> array of membership records
	- `ListPermissionsForRank(rankId)` -> table

## civitas-access
- Exports:
	- `RegisterBuilding(buildingId, data)`
	- `GetBuilding(buildingId)`
	- `ListBuildings()`
	- `CanAccessBuilding(characterId, buildingId)` -> `{ allowed, reason, org }`
	- `CanAccessAsset(characterId, assetTable)` -> `{ allowed, reason, org }`
	- `RegisterDoor(id, data)`, `GetDoor(id)`, `ListDoors()`, `CanAccessDoor(characterId, doorId)`
	- `RegisterInterior(id, data)`, `GetInterior(id)`, `ListInteriors()`, `CanAccessInterior(characterId, interiorId)`
	- `RegisterVehicleAccess(id, data)`, `GetVehicleAccess(id)`, `ListVehicleAccess()`, `CanAccessVehicle(characterId, id)`
	- `RegisterStorage(id, data)`, `GetStorage(id)`, `ListStorage()`, `CanAccessStorage(characterId, id)`

## civitas-assets
- Exports:
	- `RegisterAsset(assetData)` -> asset
	- `GetAsset(assetId)` -> asset
	- `ListAssets()` -> array
	- `CanAccessAsset(characterId, assetId)` -> delegates to civitas-access and returns structured result
	- Thin wrappers: armories, evidence, vehicles, storage modules expose register/get/list for their types

## civitas-core
- Exports:
	- `GetIdentifier(source)` -> string|nil
	- `GetCharacterId(source)` -> number|nil
	- `GetSourceFromCharacterId(characterId)` -> number|nil
	- `IsCharacterLoaded(source)` -> bool
	- `GetCharacter(source)` -> table|nil (full cached character table)
	- `GetCoreObject()` -> table { name, version, author }
- Events:
	- `civitas:characterLoaded` (source, characterId, identifier)
	- `civitas:transaction` used for character create/load actions; payload: `{ actor=source, action='character_loaded'|'character_created'|'db_unavailable_fallback', details=..., timestamp=os.time() }`

## civitas-duty
- Exports:
	- `SetDuty(characterId, orgId, on)` -> `{ ok, reason, on }`
	- `ToggleDuty(characterId, orgId)` -> `{ ok, reason, on }`
	- `IsOnDuty(characterId, orgId)` -> bool
	- `GetDutyOrgs(characterId)` -> array orgIds
	- `GetAllOnDuty()` -> array of `{ source, characterId, orgId, role }`
- Events:
	- `civitas:dutyChanged` -> `{ source, characterId, orgId, on, role }`
	- Also emits `civitas:transaction` with `action` set to `duty_on`/`duty_off`.

## civitas-duty-blips
- Events / NetEvents:
	- Client requests: `civitas:dutyBlips:request` (server event)
	- Server -> client: `civitas:dutyBlips:update` with duty list, or `civitas:dutyBlips:clear` to remove blips.

## civitas-starter
- Commands:
	- `/civitas_seed` -> Run starter seeds (permissions, organizations, ranks, rank_permissions). Requires console or admin privilege.
- Events:
	- Emits `civitas:transaction` with `action = 'db_seed_applied'` and `details` containing counts on completion.

## Events
- `civitas:orgCreated`, `civitas:orgUpdated`, `civitas:orgRemoved`
- `civitas:memberAdded`, `civitas:memberRemoved`
- `civitas:buildingRegistered`, `civitas:doorRegistered`, `civitas:interiorRegistered`
- `civitas:assetRegistered`, `civitas:assetAccessAttempt`, `civitas:transaction`

This API document is intentionally concise. See source files in each
resource for exact field names and behaviors.
