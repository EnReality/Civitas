-- CIVITAS RP Framework SQL Schema
-- Normalized schema for characters, organizations, ranks, permissions,
-- buildings, assets, and transaction logging.

SET FOREIGN_KEY_CHECKS = 0;

-- Drop tables in dependency order (safe to run repeatedly)
DROP TABLE IF EXISTS rank_permissions;
DROP TABLE IF EXISTS organization_members;
DROP TABLE IF EXISTS organization_ranks;
DROP TABLE IF EXISTS permissions;
DROP TABLE IF EXISTS vehicles;
DROP TABLE IF EXISTS storages;
DROP TABLE IF EXISTS armories;
DROP TABLE IF EXISTS evidences;
DROP TABLE IF EXISTS assets;
DROP TABLE IF EXISTS buildings;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS organizations;
DROP TABLE IF EXISTS characters;

SET FOREIGN_KEY_CHECKS = 1;

-- Characters
CREATE TABLE IF NOT EXISTS characters (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(128) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NULL,
    gender VARCHAR(32) NULL,
    metadata JSON NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- NOTE: Application must enforce that organization_members.rank_id
-- belongs to the same organization_id. SQL constraints alone cannot
-- reliably enforce this cross-table consistency across all engines.
-- The application should validate on insert/update that the `rank_id`
-- referenced by an organization_members record is a rank that belongs
-- to the same `organization_id` value.

-- Organizations
CREATE TABLE IF NOT EXISTS organizations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    tag VARCHAR(32) NULL,
    organization_type VARCHAR(32) NOT NULL DEFAULT 'civil',
    description TEXT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    metadata JSON NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY ux_organizations_name (name),
    UNIQUE KEY ux_organizations_tag (tag),
    INDEX ix_organizations_type (organization_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Organization ranks (per-organization)
CREATE TABLE IF NOT EXISTS organization_ranks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    level INT NOT NULL DEFAULT 0,
    is_default TINYINT(1) NOT NULL DEFAULT 0,
    description TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_org_ranks_organization FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    UNIQUE KEY ux_org_rank_org_name (organization_id, name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Global permissions catalog (RBAC permissions)
CREATE TABLE IF NOT EXISTS permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(150) NOT NULL UNIQUE,
    description TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Map ranks to permissions (granted/denied per rank)
CREATE TABLE IF NOT EXISTS rank_permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    rank_id INT NOT NULL,
    permission_id INT NOT NULL,
    granted TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT fk_rank_permissions_rank FOREIGN KEY (rank_id) REFERENCES organization_ranks(id) ON DELETE CASCADE,
    CONSTRAINT fk_rank_permissions_permission FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
    UNIQUE KEY ux_rank_permission (rank_id, permission_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Organization membership: one character may belong to many organizations
CREATE TABLE IF NOT EXISTS organization_members (
    id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    character_id INT NOT NULL,
    rank_id INT NULL,
    joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(32) NOT NULL DEFAULT 'active',
    metadata JSON NULL,
    CONSTRAINT fk_org_members_organization FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    CONSTRAINT fk_org_members_character FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE,
    CONSTRAINT fk_org_members_rank FOREIGN KEY (rank_id) REFERENCES organization_ranks(id) ON DELETE SET NULL,
    UNIQUE KEY ux_org_member_org_character (organization_id, character_id),
    INDEX ix_org_members_character (character_id),
    INDEX ix_org_members_org (organization_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Buildings owned by organizations
CREATE TABLE IF NOT EXISTS buildings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    name VARCHAR(150) NOT NULL,
    access_mode VARCHAR(32) NOT NULL DEFAULT 'organization',
    address VARCHAR(255) NULL,
    pos_x DOUBLE NULL,
    pos_y DOUBLE NULL,
    pos_z DOUBLE NULL,
    heading DOUBLE NULL,
    capacity INT NULL,
    metadata JSON NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_buildings_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Generic assets owned by organizations. Specialized asset types are linked one-to-one below.
CREATE TABLE IF NOT EXISTS assets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    character_id INT NULL,
    type VARCHAR(32) NOT NULL,
    name VARCHAR(150) NULL,
    description TEXT NULL,
    building_id INT NULL,
    location_extra VARCHAR(255) NULL,
    metadata JSON NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_assets_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    CONSTRAINT fk_assets_character FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE SET NULL,
    CONSTRAINT fk_assets_building FOREIGN KEY (building_id) REFERENCES buildings(id) ON DELETE SET NULL,
    INDEX ix_assets_org_type (organization_id, type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Vehicles (specialized asset)
CREATE TABLE IF NOT EXISTS vehicles (
    asset_id INT PRIMARY KEY,
    plate VARCHAR(32) NULL,
    model VARCHAR(100) NULL,
    properties JSON NULL,
    CONSTRAINT fk_vehicles_asset FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE,
    UNIQUE KEY ux_vehicles_plate (plate)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Storages (specialized asset)
CREATE TABLE IF NOT EXISTS storages (
    asset_id INT PRIMARY KEY,
    capacity INT NOT NULL DEFAULT 0,
    inventory JSON NULL,
    CONSTRAINT fk_storages_asset FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Armories (specialized asset)
CREATE TABLE IF NOT EXISTS armories (
    asset_id INT PRIMARY KEY,
    capacity INT NOT NULL DEFAULT 0,
    weapons JSON NULL,
    CONSTRAINT fk_armories_asset FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Evidence (specialized asset)
CREATE TABLE IF NOT EXISTS evidences (
    asset_id INT PRIMARY KEY,
    case_number VARCHAR(128) NULL,
    chain_of_custody JSON NULL,
    notes TEXT NULL,
    CONSTRAINT fk_evidences_asset FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE,
    UNIQUE KEY ux_evidence_case (case_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Transactions log (audit-only)
CREATE TABLE IF NOT EXISTS transactions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    actor_character_id INT NULL,
    organization_id INT NULL,
    asset_id INT NULL,
    action VARCHAR(100) NOT NULL,
    details JSON NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_transactions_actor FOREIGN KEY (actor_character_id) REFERENCES characters(id) ON DELETE SET NULL,
    CONSTRAINT fk_transactions_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE SET NULL,
    CONSTRAINT fk_transactions_asset FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE SET NULL,
    INDEX ix_transactions_actor (actor_character_id),
    INDEX ix_transactions_org (organization_id),
    INDEX ix_transactions_asset (asset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Example permission codes (insert as needed by application)
-- INSERT IGNORE INTO permissions (code, description) VALUES
-- ('org.manage.members', 'Manage organization members'),
-- ('org.manage.assets', 'Manage organization assets'),
-- ('org.manage.buildings', 'Manage organization buildings');

