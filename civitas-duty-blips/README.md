CIVITAS Duty Blips

Shows on-duty government members to other government members via blips.

Behavior
- Only viewers who are members of any government organization see blips.
- Only on-duty government members generate blips.
- Blips are created for roles `police`, `fire`, and `ems`.

Usage
- Blips are requested automatically on resource start and player spawn.
- The client listens for `civitas:dutyBlips:update` and `civitas:dutyBlips:clear`.

Config
- `config.lua` defines `blip_colors` and `blip_names` per role.

Notes
- Event-driven; no constant loops.
- Server broadcasts updates only to eligible viewers.
