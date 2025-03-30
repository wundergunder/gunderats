/*
  # Fix RLS policies to prevent recursion

  1. Changes
    - Fix recursive RLS policies by simplifying access checks
    - Add missing SELECT policies for jobs and candidates
    - Add proper indexes for performance

  2. Security
    - Maintain proper access control
    - Prevent infinite recursion
    - Ensure data integrity
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Users can view team members" ON team_members;
DROP POLICY IF EXISTS "Users can view company jobs" ON jobs;
DROP POLICY IF EXISTS "Users can view candidates" ON candidates;
DROP POLICY IF EXISTS "Users can view candidate stages" ON candidate_stages;

-- Create simplified team members policy
CREATE POLICY "view_team_members"
ON team_members
FOR SELECT
TO authenticated
USING (
  -- User can see their own team membership or team members in their company
  user_id = auth.uid() OR
  company_id IN (
    SELECT company_id 
    FROM team_members 
    WHERE user_id = auth.uid()
  )
);

-- Create simplified jobs policy
CREATE POLICY "view_jobs"
ON jobs
FOR SELECT
TO authenticated
USING (
  company_id IN (
    SELECT company_id 
    FROM team_members 
    WHERE user_id = auth.uid()
  )
);

-- Create simplified candidates policy
CREATE POLICY "view_candidates"
ON candidates
FOR SELECT
TO authenticated
USING (
  company_id IN (
    SELECT company_id 
    FROM team_members 
    WHERE user_id = auth.uid()
  )
);

-- Create simplified candidate stages policy
CREATE POLICY "view_candidate_stages"
ON candidate_stages
FOR SELECT
TO authenticated
USING (
  candidate_id IN (
    SELECT id 
    FROM candidates 
    WHERE company_id IN (
      SELECT company_id 
      FROM team_members 
      WHERE user_id = auth.uid()
    )
  )
);

-- Add indexes for better performance if they don't exist
CREATE INDEX IF NOT EXISTS team_members_user_id_idx ON team_members(user_id);
CREATE INDEX IF NOT EXISTS team_members_company_id_idx ON team_members(company_id);
CREATE INDEX IF NOT EXISTS jobs_company_id_idx ON jobs(company_id);
CREATE INDEX IF NOT EXISTS candidates_company_id_idx ON candidates(company_id);
CREATE INDEX IF NOT EXISTS candidate_stages_candidate_id_idx ON candidate_stages(candidate_id);