/*
  # Drop All Tables and Dependencies
  
  1. Changes
    - Drop all storage policies
    - Drop all RLS policies
    - Disable RLS on all tables
    - Drop all triggers and functions
    - Drop all tables in correct order
    - Clean up storage buckets

  2. Notes
    - Handles dependencies properly
    - Uses CASCADE where needed
    - Safe to run multiple times
*/

-- First drop all policies
DO $$
DECLARE
  pol record;
BEGIN
  -- Drop storage policies
  FOR pol IN (
    SELECT policyname 
    FROM pg_policies 
    WHERE schemaname = 'storage' 
    AND tablename = 'objects'
  ) LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', pol.policyname);
  END LOOP;

  -- Drop policies on public schema tables
  FOR pol IN (
    SELECT schemaname, tablename, policyname 
    FROM pg_policies 
    WHERE schemaname = 'public'
  ) LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
      pol.policyname, pol.schemaname, pol.tablename);
  END LOOP;
END $$;

-- Disable RLS
ALTER TABLE IF EXISTS profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS companies DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS team_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS jobs DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS pipeline_stages DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS candidates DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS candidate_stages DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS comments DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS documents DISABLE ROW LEVEL SECURITY;

-- Drop triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
DROP TRIGGER IF EXISTS update_companies_updated_at ON companies;
DROP TRIGGER IF EXISTS update_team_members_updated_at ON team_members;
DROP TRIGGER IF EXISTS update_jobs_updated_at ON jobs;
DROP TRIGGER IF EXISTS update_pipeline_stages_updated_at ON pipeline_stages;
DROP TRIGGER IF EXISTS update_candidates_updated_at ON candidates;
DROP TRIGGER IF EXISTS create_company_pipeline_stages ON companies;

-- Drop functions
DROP FUNCTION IF EXISTS handle_new_user();
DROP FUNCTION IF EXISTS update_updated_at_column();
DROP FUNCTION IF EXISTS create_default_pipeline_stages();

-- Drop tables with CASCADE to handle dependencies
DROP TABLE IF EXISTS documents CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS candidate_stages CASCADE;
DROP TABLE IF EXISTS candidates CASCADE;
DROP TABLE IF EXISTS pipeline_stages CASCADE;
DROP TABLE IF EXISTS jobs CASCADE;
DROP TABLE IF EXISTS team_members CASCADE;
DROP TABLE IF EXISTS companies CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- Clean up storage
DELETE FROM storage.buckets WHERE id = 'candidate_documents';