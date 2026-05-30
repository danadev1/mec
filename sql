-- =====================================================
-- MEC Student Voice Platform - Complete Database Setup
-- Run this in Supabase > SQL Editor
-- =====================================================

-- 1. Create main reports table
CREATE TABLE IF NOT EXISTS mec_reports (
  id            TEXT PRIMARY KEY,
  college_id    TEXT NOT NULL,
  building_name TEXT NOT NULL,
  service       TEXT NOT NULL,
  root_cause    TEXT NOT NULL,
  details       TEXT NOT NULL,
  type          TEXT NOT NULL CHECK (type IN ('complaint', 'suggestion')),
  status        TEXT NOT NULL DEFAULT 'New' CHECK (status IN ('New', 'In Progress', 'Resolved')),
  priority      TEXT NOT NULL DEFAULT 'Low' CHECK (priority IN ('Low', 'Normal', 'Urgent')),
  employee      TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ
);

-- 2. Create logs table (optional)
CREATE TABLE IF NOT EXISTS mec_logs (
  id         BIGSERIAL PRIMARY KEY,
  user_id    TEXT,
  action     TEXT NOT NULL,
  extra      TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Create admins table (optional)
CREATE TABLE IF NOT EXISTS mec_admins (
  id         BIGSERIAL PRIMARY KEY,
  email      TEXT UNIQUE NOT NULL,
  full_name  TEXT NOT NULL,
  role       TEXT DEFAULT 'Admin',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- Enable Row Level Security (RLS)
-- =====================================================
ALTER TABLE mec_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE mec_logs    ENABLE ROW LEVEL SECURITY;
ALTER TABLE mec_admins  ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- Drop old policies to avoid conflicts
-- =====================================================
DROP POLICY IF EXISTS "Students can insert reports" ON mec_reports;
DROP POLICY IF EXISTS "Anyone can read reports" ON mec_reports;
DROP POLICY IF EXISTS "Anyone can update status" ON mec_reports;
DROP POLICY IF EXISTS "Enable insert for anon users" ON mec_reports;
DROP POLICY IF EXISTS "Enable select for anon users" ON mec_reports;
DROP POLICY IF EXISTS "Enable update for anon users" ON mec_reports;
DROP POLICY IF EXISTS "Allow public read access for reports" ON mec_reports;

DROP POLICY IF EXISTS "Allow insert logs" ON mec_logs;
DROP POLICY IF EXISTS "Allow read logs" ON mec_logs;

DROP POLICY IF EXISTS "Allow read admins" ON mec_admins;
DROP POLICY IF EXISTS "Allow insert admins" ON mec_admins;

-- =====================================================
-- Create NEW policies for mec_reports (FIXED)
-- =====================================================

-- Policy 1: Allow anyone (students) to INSERT reports
CREATE POLICY "Enable insert for anon users"
ON mec_reports FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Policy 2: Allow anyone (admin dashboard) to SELECT reports
CREATE POLICY "Allow public read access for reports"
ON mec_reports FOR SELECT
TO anon, authenticated
USING (true);

-- Policy 3: Allow anyone to UPDATE status (admin dashboard)
CREATE POLICY "Enable update for anon users"
ON mec_reports FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- =====================================================
-- Create policies for mec_logs
-- =====================================================
CREATE POLICY "Allow insert logs" ON mec_logs FOR INSERT
TO anon, authenticated
WITH CHECK (true);

CREATE POLICY "Allow read logs" ON mec_logs FOR SELECT
TO anon, authenticated
USING (true);

-- =====================================================
-- Create policies for mec_admins
-- =====================================================
CREATE POLICY "Allow read admins" ON mec_admins FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "Allow insert admins" ON mec_admins FOR INSERT
TO authenticated
WITH CHECK (true);

-- =====================================================
-- Create Indexes for performance
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_mec_reports_status     ON mec_reports (status);
CREATE INDEX IF NOT EXISTS idx_mec_reports_type       ON mec_reports (type);
CREATE INDEX IF NOT EXISTS idx_mec_reports_created_at ON mec_reports (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_mec_logs_user_id       ON mec_logs (user_id);
CREATE INDEX IF NOT EXISTS idx_mec_admins_email       ON mec_admins (email);

-- =====================================================
-- Insert TEST DATA (for admin dashboard testing)
-- =====================================================
INSERT INTO mec_reports (id, college_id, building_name, service, root_cause, details, type, status, priority)
VALUES 
  ('MEC-260129-001', '23f24545', 'IBR', 'IT Support / LMS', 'Technical Issue', 'Test complaint - LMS not loading properly', 'complaint', 'New', 'Normal'),
  ('MEC-260129-002', '23f24343', 'AKZ', 'Facilities / Maintenance', 'Parking', 'Parking area is too small for students', 'suggestion', 'In Progress', 'Low'),
  ('MEC-260129-003', '23f24557', 'IBK', 'Academic Affairs', 'Session', 'Need more lab sessions for programming course', 'complaint', 'Resolved', 'Normal'),
  ('MEC-260129-004', '23f24261', 'STUDENT HUB', 'Student Activities', 'Other', 'More student clubs needed', 'suggestion', 'New', 'Low'),
  ('MEC-260129-005', '12a34567', 'AKH', 'Library Services', 'Library Services', 'Library closing time is too early', 'complaint', 'New', 'Normal')
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- Verify setup
-- =====================================================
SELECT 'Total Reports' as info, COUNT(*) as count FROM mec_reports
UNION ALL
SELECT 'New Tickets', COUNT(*) FROM mec_reports WHERE status = 'New'
UNION ALL
SELECT 'Resolved', COUNT(*) FROM mec_reports WHERE status = 'Resolved'
UNION ALL
SELECT 'Suggestions', COUNT(*) FROM mec_reports WHERE type = 'suggestion';

-- =====================================================
-- Setup Complete! ✅
-- =====================================================

-- =====================================================
-- Create table for admin login tracking
-- =====================================================
CREATE TABLE IF NOT EXISTS admin_logins (
  id         BIGSERIAL PRIMARY KEY,
  admin_id   TEXT NOT NULL,
  login_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status     TEXT DEFAULT 'success'
);

ALTER TABLE admin_logins ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies
DROP POLICY IF EXISTS "Enable insert for admin logins" ON admin_logins;

-- Policy to allow login record insertion from any user (anon/authenticated)
CREATE POLICY "Enable insert for admin logins"
ON admin_logins FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- ✅ Verify table creation
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name = 'admin_logins';
