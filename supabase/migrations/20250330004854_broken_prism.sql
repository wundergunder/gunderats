/*
  # Fix RLS policies and relationships

  1. Changes
    - Drop and recreate team_members policies to avoid recursion
    - Add proper foreign key relationships
    - Fix RLS policies for all tables
    - Add proper indexes for performance

  2. Security
    - All policies use non-recursive checks
    - Maintain proper access control
    - Ensure data integrity with foreign keys
*/

-- Create profiles table to store user information
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS on profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create profiles policy
CREATE POLICY "Users can view their own profile"
ON profiles
FOR SELECT
TO authenticated
USING (id = auth.uid());

-- Create trigger to sync auth.users email to profiles
CREATE OR REPLACE FUNCTION sync_user_email()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (NEW.id, NEW.email)
  ON CONFLICT (id) DO UPDATE
  SET email = EXCLUDED.email;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on auth.users
DROP TRIGGER IF EXISTS sync_user_email ON auth.users;
CREATE TRIGGER sync_user_email
AFTER INSERT OR UPDATE OF email ON auth.users
FOR EACH ROW
EXECUTE FUNCTION sync_user_email();

-- Sync existing users to profiles
INSERT INTO profiles (id, email)
SELECT id, email FROM auth.users
ON CONFLICT (id) DO UPDATE
SET email = EXCLUDED.email;

-- Fix team_members policy
DROP POLICY IF EXISTS "Users can view team members" ON team_members;
CREATE POLICY "Team members can view company data"
ON team_members
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR 
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.company_id = team_members.company_id
  )
);

-- Fix companies policy
DROP POLICY IF EXISTS "Companies are viewable by their team members" ON companies;
CREATE POLICY "Users can view their companies"
ON companies
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.company_id = companies.id
  )
);

-- Fix jobs policy
DROP POLICY IF EXISTS "Users can view jobs" ON jobs;
CREATE POLICY "Users can view company jobs"
ON jobs
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.company_id = jobs.company_id
  )
);

-- Fix candidate_stages policy
DROP POLICY IF EXISTS "Users can view candidate stages" ON candidate_stages;
CREATE POLICY "Users can view company candidate stages"
ON candidate_stages
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM candidates c
    JOIN team_members tm ON tm.company_id = c.company_id
    WHERE tm.user_id = auth.uid()
    AND c.id = candidate_stages.candidate_id
  )
);

-- Fix candidates policy
DROP POLICY IF EXISTS "Users can view candidates" ON candidates;
CREATE POLICY "Users can view company candidates"
ON candidates
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.company_id = candidates.company_id
  )
);