/*
  # Fix RLS policies to prevent recursion

  1. Changes
    - Drop existing problematic policies
    - Create simplified policies that avoid recursion
    - Add proper indexes for performance

  2. Security
    - Maintain proper access control
    - Fix infinite recursion issues
    - Ensure data integrity
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "team_members_policy" ON team_members;
DROP POLICY IF EXISTS "jobs_policy" ON jobs;
DROP POLICY IF EXISTS "candidates_policy" ON candidates;
DROP POLICY IF EXISTS "candidate_stages_policy" ON candidate_stages;

-- Create simplified team members policy
CREATE POLICY "team_members_policy"
ON team_members
FOR ALL
TO authenticated
USING (
  -- Users can see their own record
  user_id = auth.uid()
);

-- Create simplified jobs policy
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

-- Create simplified candidates policy
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

-- Create simplified candidate stages policy
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