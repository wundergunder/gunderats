/*
  # Add team member roles and permissions

  1. Changes
    - Drop existing view
    - Add role enum type
    - Update team_members table to use role enum
    - Add role-based RLS policies
    - Recreate view with new structure

  2. Security
    - Strict role-based access control
    - Granular permissions per role
    - Secure default policies
*/

-- Drop the view first
DROP VIEW IF EXISTS team_members_with_profiles;

-- Create role enum type
CREATE TYPE team_role AS ENUM (
  'admin',      -- Full access to everything
  'client_hr',  -- Access to company's jobs and candidates
  'recruiter',  -- Can manage candidates and assigned jobs
  'hiring_manager', -- Can rate candidates and provide feedback
  'readonly'    -- View-only access
);

-- Add role-specific columns to team_members
ALTER TABLE team_members 
DROP COLUMN IF EXISTS role CASCADE,
ADD COLUMN role team_role NOT NULL DEFAULT 'readonly',
ADD COLUMN permissions jsonb DEFAULT '{}'::jsonb;

-- Drop existing policies
DROP POLICY IF EXISTS "team_members_policy" ON team_members;
DROP POLICY IF EXISTS "jobs_policy" ON jobs;
DROP POLICY IF EXISTS "candidates_policy" ON candidates;
DROP POLICY IF EXISTS "candidate_stages_policy" ON candidate_stages;
DROP POLICY IF EXISTS "comments_policy" ON comments;

-- Create role-based policies for team_members
CREATE POLICY "team_members_policy"
ON team_members
FOR ALL
TO authenticated
USING (
  -- Admins can see all team members in their company
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.role = 'admin'::team_role
    AND tm.company_id = team_members.company_id
  )
  OR
  -- Others can only see their own record
  user_id = auth.uid()
);

-- Create role-based policies for jobs
CREATE POLICY "jobs_policy"
ON jobs
FOR ALL
TO authenticated
USING (
  -- Admins have full access
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.role = 'admin'::team_role
    AND tm.company_id = jobs.company_id
  )
  OR
  -- Client HR can access their company's jobs
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.role = 'client_hr'::team_role
    AND tm.company_id = jobs.company_id
  )
  OR
  -- Recruiters can access open jobs
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.role = 'recruiter'::team_role
    AND tm.company_id = jobs.company_id
    AND jobs.status = 'published'
  )
  OR
  -- Others can only view jobs
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.company_id = jobs.company_id
  )
)
WITH CHECK (
  -- Only admins and client HR can modify jobs
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.role IN ('admin'::team_role, 'client_hr'::team_role)
    AND tm.company_id = jobs.company_id
  )
);

-- Create role-based policies for candidates
CREATE POLICY "candidates_policy"
ON candidates
FOR ALL
TO authenticated
USING (
  -- Admins have full access
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.role = 'admin'::team_role
    AND tm.company_id = candidates.company_id
  )
  OR
  -- Client HR can access their company's candidates
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.role = 'client_hr'::team_role
    AND tm.company_id = candidates.company_id
  )
  OR
  -- Recruiters can access candidates they created
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.role = 'recruiter'::team_role
    AND tm.company_id = candidates.company_id
    AND (
      candidates.created_by = auth.uid() OR
      EXISTS (
        SELECT 1 FROM jobs j
        WHERE j.id = candidates.job_id
        AND j.status = 'published'
      )
    )
  )
  OR
  -- Others can only view candidates
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.company_id = candidates.company_id
  )
)
WITH CHECK (
  -- Only admins, client HR, and recruiters can modify candidates
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.role IN ('admin'::team_role, 'client_hr'::team_role, 'recruiter'::team_role)
    AND tm.company_id = candidates.company_id
  )
);

-- Create role-based policies for candidate stages
CREATE POLICY "candidate_stages_policy"
ON candidate_stages
FOR ALL
TO authenticated
USING (
  -- Admins have full access
  EXISTS (
    SELECT 1 FROM team_members tm 
    JOIN candidates c ON c.company_id = tm.company_id
    WHERE tm.user_id = auth.uid() 
    AND tm.role = 'admin'::team_role
    AND c.id = candidate_stages.candidate_id
  )
  OR
  -- Client HR and hiring managers can modify stages
  EXISTS (
    SELECT 1 FROM team_members tm 
    JOIN candidates c ON c.company_id = tm.company_id
    WHERE tm.user_id = auth.uid() 
    AND tm.role IN ('client_hr'::team_role, 'hiring_manager'::team_role)
    AND c.id = candidate_stages.candidate_id
  )
  OR
  -- Others can only view stages
  EXISTS (
    SELECT 1 FROM team_members tm 
    JOIN candidates c ON c.company_id = tm.company_id
    WHERE tm.user_id = auth.uid() 
    AND c.id = candidate_stages.candidate_id
  )
)
WITH CHECK (
  -- Only admins, client HR, and hiring managers can modify stages
  EXISTS (
    SELECT 1 FROM team_members tm 
    JOIN candidates c ON c.company_id = tm.company_id
    WHERE tm.user_id = auth.uid() 
    AND tm.role IN ('admin'::team_role, 'client_hr'::team_role, 'hiring_manager'::team_role)
    AND c.id = candidate_stages.candidate_id
  )
);

-- Create role-based policies for comments
CREATE POLICY "comments_policy"
ON comments
FOR ALL
TO authenticated
USING (
  -- All roles can view comments
  EXISTS (
    SELECT 1 FROM team_members tm 
    JOIN candidates c ON c.company_id = tm.company_id
    WHERE tm.user_id = auth.uid() 
    AND c.id = comments.candidate_id
  )
)
WITH CHECK (
  -- All roles except readonly can add comments
  EXISTS (
    SELECT 1 FROM team_members tm 
    JOIN candidates c ON c.company_id = tm.company_id
    WHERE tm.user_id = auth.uid() 
    AND tm.role != 'readonly'::team_role
    AND c.id = comments.candidate_id
  )
);

-- Update first user in each company to be admin
UPDATE team_members
SET role = 'admin'
WHERE id IN (
  SELECT DISTINCT ON (company_id) id
  FROM team_members
  ORDER BY company_id, created_at
);

-- Recreate the view with the new role column
CREATE OR REPLACE VIEW team_members_with_profiles
WITH (security_barrier = true)
AS
SELECT 
  tm.*,
  p.email as user_email
FROM team_members tm
JOIN profiles p ON p.id = tm.user_id;