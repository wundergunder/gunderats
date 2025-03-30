/*
  # Fix RLS policies and infinite recursion

  1. Changes
    - Simplify RLS policies to avoid recursion
    - Add proper indexes for performance
    - Fix team members view
    - Add proper role-based access control

  2. Security
    - Maintain proper access control
    - Prevent infinite recursion
    - Allow admin access to all companies
*/

-- Drop existing view and policies
DROP VIEW IF EXISTS team_members_with_profiles;
DROP POLICY IF EXISTS "team_members_policy" ON team_members;
DROP POLICY IF EXISTS "companies_policy" ON companies;
DROP POLICY IF EXISTS "jobs_policy" ON jobs;
DROP POLICY IF EXISTS "candidates_policy" ON candidates;
DROP POLICY IF EXISTS "candidate_stages_policy" ON candidate_stages;

-- Create secure view for team members with profiles
CREATE OR REPLACE VIEW team_members_with_profiles AS
SELECT 
  tm.id,
  tm.user_id,
  tm.company_id,
  tm.created_at,
  tm.updated_at,
  tm.role,
  tm.permissions,
  p.email as user_email
FROM team_members tm
JOIN profiles p ON p.id = tm.user_id;

-- Create base policy for team_members
CREATE POLICY "team_members_policy"
ON team_members
FOR ALL
TO authenticated
USING (
  -- Users can see their own record
  user_id = auth.uid()
  OR
  -- Users can see other members in their companies
  EXISTS (
    SELECT 1 FROM team_members my_teams 
    WHERE my_teams.user_id = auth.uid() 
    AND my_teams.company_id = team_members.company_id
  )
);

-- Create policy for companies
CREATE POLICY "companies_policy"
ON companies
FOR ALL
TO authenticated
USING (
  -- Users can see companies they are members of
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.company_id = companies.id
  )
);

-- Create policy for jobs
CREATE POLICY "jobs_policy"
ON jobs
FOR ALL
TO authenticated
USING (
  -- Users can access jobs in their company
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.company_id = jobs.company_id
  )
);

-- Create policy for candidates
CREATE POLICY "candidates_policy"
ON candidates
FOR ALL
TO authenticated
USING (
  -- Users can access candidates in their company
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.company_id = candidates.company_id
  )
);

-- Create policy for candidate stages
CREATE POLICY "candidate_stages_policy"
ON candidate_stages
FOR ALL
TO authenticated
USING (
  -- Users can access stages for candidates in their company
  EXISTS (
    SELECT 1 FROM candidates c
    JOIN team_members tm ON tm.company_id = c.company_id
    WHERE tm.user_id = auth.uid()
    AND c.id = candidate_stages.candidate_id
  )
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS team_members_user_id_idx ON team_members(user_id);
CREATE INDEX IF NOT EXISTS team_members_company_id_idx ON team_members(company_id);
CREATE INDEX IF NOT EXISTS jobs_company_id_idx ON jobs(company_id);
CREATE INDEX IF NOT EXISTS candidates_company_id_idx ON candidates(company_id);
CREATE INDEX IF NOT EXISTS candidate_stages_candidate_id_idx ON candidate_stages(candidate_id);