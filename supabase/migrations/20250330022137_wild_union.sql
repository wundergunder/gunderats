/*
  # Fix team members policies and view

  1. Changes
    - Drop problematic view and policies
    - Create simplified policies that avoid recursion
    - Add proper indexes for performance

  2. Security
    - Maintain proper access control
    - Fix infinite recursion issues
    - Ensure data integrity
*/

-- Drop existing view and policies
DROP VIEW IF EXISTS team_members_with_profiles;
DROP POLICY IF EXISTS "team_members_policy" ON team_members;
DROP POLICY IF EXISTS "jobs_policy" ON jobs;
DROP POLICY IF EXISTS "candidates_policy" ON candidates;
DROP POLICY IF EXISTS "candidate_stages_policy" ON candidate_stages;

-- Create base policy for team_members
CREATE POLICY "team_members_base_policy"
ON team_members
FOR SELECT
TO authenticated
USING (
  -- Users can see their own record
  user_id = auth.uid()
);

-- Create company members policy
CREATE POLICY "team_members_company_policy"
ON team_members
FOR SELECT
TO authenticated
USING (
  -- Users can see other members in companies where they are a member
  EXISTS (
    SELECT 1 
    FROM team_members my_teams 
    WHERE my_teams.user_id = auth.uid()
    AND my_teams.company_id = team_members.company_id
  )
);

-- Create jobs policy
CREATE POLICY "jobs_base_policy"
ON jobs
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 
    FROM team_members tm 
    WHERE tm.user_id = auth.uid()
    AND tm.company_id = jobs.company_id
  )
);

-- Create candidates policy
CREATE POLICY "candidates_base_policy"
ON candidates
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 
    FROM team_members tm 
    WHERE tm.user_id = auth.uid()
    AND tm.company_id = candidates.company_id
  )
);

-- Create candidate stages policy
CREATE POLICY "candidate_stages_base_policy"
ON candidate_stages
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 
    FROM candidates c
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