-- =====================================================
-- ADD SECURITY COLUMNS TO app_user
-- Run this AFTER 01_schema_core.sql
-- =====================================================

-- Password change tracking
ALTER TABLE app_user ADD COLUMN IF NOT EXISTS password_changed_at TIMESTAMPTZ;
ALTER TABLE app_user ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN DEFAULT FALSE;

-- Two-Factor Authentication
ALTER TABLE app_user ADD COLUMN IF NOT EXISTS two_factor_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE app_user ADD COLUMN IF NOT EXISTS two_factor_secret VARCHAR(255);
ALTER TABLE app_user ADD COLUMN IF NOT EXISTS two_factor_backup_codes TEXT;
