-- CIVITAS starter seeds (idempotent)
-- This file is for reference; the civitas-starter resource runs equivalent upserts via DB API.

-- Permissions (idempotent)
INSERT IGNORE INTO permissions (code, description) VALUES
('org.duty.toggle', 'Allow toggling duty'),
('org.access', 'Base access to org assets'),
('org.access.building', 'Access organization buildings'),
('org.access.asset', 'Access organization assets'),
('org.access.armory', 'Access armory'),
('org.access.evidence', 'Access evidence storage'),
('org.manage.members', 'Manage organization members'),
('org.manage.assets', 'Manage organization assets'),
('org.manage.buildings', 'Manage organization buildings')
;

-- Organizations (government)
INSERT IGNORE INTO organizations (name, tag, organization_type, description) VALUES
('Police Department','police','government','Local police department'),
('Fire Department','fire','government','Local fire department'),
('EMS / Medical','ems','government','Emergency medical services'),
('Courts','courts','government','Judicial courts'),
('City Administration','city','government','City administration and staff')
;

-- Note: Ranks and rank_permissions are applied via civitas-starter resource to ensure correct org ids are used.
