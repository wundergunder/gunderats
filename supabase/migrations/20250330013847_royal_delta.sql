/*
  # Clean Database Schema
  
  1. Changes
    - Drop all storage policies first
    - Drop all RLS policies
    - Drop all triggers
    - Drop all functions
    - Drop all tables in correct dependency order
    - Clean up storage buckets
    
  2. Notes
    - This is a destructive operation that removes all data
    - Run this only when you want to start fresh
*/

-- First drop storage policies since they depend on the candidates table
DROP POLICY IF EXISTS "Users can upload documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can read documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can read their company's documents" ON storage.objects;

-- Disable row level security first to avoid policy conflicts
ALTER TABLE IF EXISTS profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS companies DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS team_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS jobs DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS pipeline_stages DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS candidates DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS candidate_stages DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS comments DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS documents DISABLE ROW LEVEL SECURITY;

-- Drop all RLS policies
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view their companies" ON companies;
DROP POLICY IF EXISTS "Users can view team members" ON team_members;
DROP POLICY IF EXISTS "Users can view company jobs" ON jobs;
DROP POLICY IF EXISTS "Users can view pipeline stages" ON pipeline_stages;
DROP POLICY IF EXISTS "Users can view candidates" ON candidates;
DROP POLICY IF EXISTS "Users can view candidate stages" ON candidate_stages;
DROP POLICY IF EXISTS "Users can view comments" ON comments;
DROP POLICY IF EXISTS "Users can view documents" ON documents;

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

-- Drop tables in correct order to handle dependencies
DROP TABLE IF EXISTS documents;
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS candidate_stages;
DROP TABLE IF EXISTS candidates;
DROP TABLE IF EXISTS pipeline_stages;
DROP TABLE IF EXISTS jobs;
DROP TABLE IF EXISTS team_members;
DROP TABLE IF EXISTS companies;
DROP TABLE IF EXISTS profiles;

-- Clean up storage
DELETE FROM storage.buckets WHERE id = 'candidate_documents';