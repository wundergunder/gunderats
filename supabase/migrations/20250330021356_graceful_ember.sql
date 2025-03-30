/*
  # Fix RLS policies to prevent recursion

  1. Changes
    - Simplify RLS policies to avoid recursion
    - Use direct user_id checks where possible
    - Add proper indexes for performance

  2. Security
    - Maintain proper access control
    - Ensure data integrity
    - Prevent infinite recursion
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
  -- User can see their own team membership
  user_id = auth.uid()
);

-- Create simplified jobs policy
CREATE POLICY "jobs_policy"
ON jobs
FOR ALL
TO authenticated
USING (
  -- User can access jobs in their company
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.company_id = jobs.company_id
    AND (
      -- Admin and client_hr can see all jobs
      tm.role IN ('admin', 'client_hr')
      OR
      -- Recruiter can only see published jobs
      (tm.role = 'recruiter' AND jobs.status = 'published')
      OR
      -- Others can only view jobs
      tm.role IN ('hiring_manager', 'readonly')
    )
  )
)
WITH CHECK (
  -- Only admins and client HR can modify jobs
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.company_id = jobs.company_id
    AND tm.role IN ('admin', 'client_hr')
  )
);

-- Create simplified candidates policy
CREATE POLICY "candidates_policy"
ON candidates
FOR ALL
TO authenticated
USING (
  -- User can access candidates in their company
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.company_id = candidates.company_id
    AND (
      -- Admin and client_hr can see all candidates
      tm.role IN ('admin', 'client_hr')
      OR
      -- Recruiter can see candidates they created or for published jobs
      (tm.role = 'recruiter' AND (
        candidates.created_by = auth.uid()
        OR EXISTS (
          SELECT 1 FROM jobs j
          WHERE j.id = candidates.job_id
          AND j.status = 'published'
        )
      ))
      OR
      -- Others can only view candidates
      tm.role IN ('hiring_manager', 'readonly')
    )
  )
)
WITH CHECK (
  -- Only admins, client HR, and recruiters can modify candidates
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.company_id = candidates.company_id
    AND tm.role IN ('admin', 'client_hr', 'recruiter')
  )
);

-- Create simplified candidate stages policy
CREATE POLICY "candidate_stages_policy"
ON candidate_stages
FOR ALL
TO authenticated
USING (
  -- User can access stages for candidates in their company
  EXISTS (
    SELECT 1 FROM candidates c
    JOIN team_members tm ON tm.company_id = c.company_id
    WHERE tm.user_id = auth.uid() 
    AND c.id = candidate_stages.candidate_id
  )
)
WITH CHECK (
  -- Only admins, client HR, and hiring managers can modify stages
  EXISTS (
    SELECT 1 FROM candidates c
    JOIN team_members tm ON tm.company_id = c.company_id
    WHERE tm.user_id = auth.uid() 
    AND c.id = candidate_stages.candidate_id
    AND tm.role IN ('admin', 'client_hr', 'hiring_manager')
  )
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS team_members_user_id_idx ON team_members(user_id);
CREATE INDEX IF NOT EXISTS team_members_company_id_idx ON team_members(company_id);
CREATE INDEX IF NOT EXISTS jobs_company_id_idx ON jobs(company_id);
CREATE INDEX IF NOT EXISTS candidates_company_id_idx ON candidates(company_id);
CREATE INDEX IF NOT EXISTS candidate_stages_candidate_id_idx ON candidate_stages(candidate_id);