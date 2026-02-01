# CIVITAS Installation (Starter Pack)

Prerequisites
- MySQL database reachable by your FiveM server.
- `oxmysql` resource installed and configured.

Folder structure (resources)
- civitas-core
- civitas-organizations
- civitas-access
- civitas-assets
- civitas-admin
- civitas-duty
- civitas-duty-blips
- civitas-starter

Ensure order
Add the following to your `server.cfg` or txAdmin resource start list in this order:
```
ensure civitas-core
ensure civitas-organizations
ensure civitas-access
ensure civitas-assets
ensure civitas-admin
ensure civitas-duty
ensure civitas-duty-blips
ensure civitas-starter
```

How to run seeds (manual only)
1. Start your server with the resources above.
2. From server console run:
```
/civitas_seed
```
Or run the same command in-game from an identifier present in `civitas-admin/config.lua` or `civitas-starter/config.lua`.

What `/civitas_seed` does
- Inserts the permission catalog (idempotent).
- Inserts government organizations (police, fire, ems, courts, city) (idempotent).
- Creates ranks for each government org (Chief, Captain, Lieutenant, Officer, Recruit) (idempotent upsert).
- Grants rank_permissions according to the starter policy (Chief=all, Captain=access/manage.*, etc.) (idempotent upsert).
- Emits a `civitas:transaction` event with action `db_seed_applied` containing counts and caller identifier.

What `/civitas_seed` does NOT do
- It does NOT automatically run on resource start.
- It does NOT apply schema changes (`database/schema.sql`) automatically.
- It does NOT modify gameplay, add jobs, or enable UI.

Expected console output
- During seed: `[civitas-starter] Starting seed process...`
- On completion: `[civitas-starter] Seed complete: permissions=X orgs=Y ranks=Z rank_permissions=W`

CIVITAS philosophy
CIVITAS is authority-first: core identity and RBAC are provided, while gameplay modules remain separate. The starter pack provides a safe, idempotent starting point.
