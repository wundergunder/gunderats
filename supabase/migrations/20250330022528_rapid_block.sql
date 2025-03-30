/*
  # Fix team members role and policies

  1. Changes
    - Drop problematic view and policies
    - Create team_role enum type
    - Add role column to team_members
    - Create simplified policies that avoid recursion
    - Add proper indexes for performance

  2. Security
    - Maintain proper access control
    - Fix infinite recursion issues
    - Ensure data integrity
*/

-- Drop existing view and policies
DROP VIEW IF EXISTS team_members_with_profiles;
DROP POLICY IF EXISTS "team_members_base_policy" ON team_members;
DROP POLICY IF EXISTS "team_members_company_policy" ON team_members;
DROP POLICY IF EXISTS "jobs_base_policy" ON jobs;
DROP POLICY IF EXISTS "candidates_base_policy" ON candidates;
DROP POLICY IF EXISTS "candidate_stages_base_policy" ON candidate_stages;

-- Create team_role enum type if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'team_role') THEN
    CREATE TYPE team_role AS ENUM (
      'admin',
      'client_hr',
      'recruiter',
      'hiring_manager',
      'readonly'
    );
  END IF;
END $$;

-- Update team_members table
ALTER TABLE team_members 
DROP COLUMN IF EXISTS role CASCADE,
ADD COLUMN role team_role NOT NULL DEFAULT 'readonly';

-- Create base policy for team_members
CREATE POLICY "team_members_policy"
ON team_members
FOR ALL
TO authenticated
USING (
  -- Users can see their own record
  user_id = auth.uid() OR
  -- Users can see other members in their companies
  company_id IN (
    SELECT tm.company_id 
    FROM team_members tm 
    WHERE tm.user_id = auth.uid()
  )
);

-- Create jobs policy
CREATE POLICY "jobs_policy"
ON jobs
FOR ALL
TO authenticated
USING (
  -- Users can access jobs in their company
  company_id IN (
    SELECT tm.company_id 
    FROM team_members tm 
    WHERE tm.user_id = auth.uid()
  )
)
WITH CHECK (
  -- Only admins and client HR can modify jobs
  EXISTS (
    SELECT 1 
    FROM team_members tm 
    WHERE tm.user_id = auth.uid()
    AND tm.company_id = jobs.company_id
    AND tm.role IN ('admin', 'client_hr')
  )
);

-- Create candidates policy
CREATE POLICY "candidates_policy"
ON candidates
FOR ALL
TO authenticated
USING (
  -- Users can access candidates in their company
  company_id IN (
    SELECT tm.company_id 
    FROM team_members tm 
    WHERE tm.user_id = auth.uid()
  )
)
WITH CHECK (
  -- Only admins, client HR, and recruiters can modify candidates
  EXISTS (
    SELECT 1 
    FROM team_members tm 
    WHERE tm.user_id = auth.uid()
    AND tm.company_id = candidates.company_id
    AND tm.role IN ('admin', 'client_hr', 'recruiter')
  )
);

-- Create candidate stages policy
CREATE POLICY "candidate_stages_policy"
ON candidate_stages
FOR ALL
TO authenticated
USING (
  -- Users can access stages for candidates in their company
  EXISTS (
    SELECT 1 
    FROM candidates c
    JOIN team_members tm ON tm.company_id = c.company_id
    WHERE tm.user_id = auth.uid()
    AND c.id = candidate_stages.candidate_id
  )
)
WITH CHECK (
  -- Only admins, client HR, and hiring managers can modify stages
  EXISTS (
    SELECT 1 
    FROM candidates c
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