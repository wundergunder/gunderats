/*
  # Fix RLS policies and add proper access control

  1. Changes
    - Drop and recreate all RLS policies to prevent recursion
    - Add proper access control for all operations
    - Add missing policies for companies table
    - Fix team members policies

  2. Security
    - Maintain proper access control
    - Prevent infinite recursion
    - Ensure data integrity
*/

-- Drop all existing policies to start fresh
DROP POLICY IF EXISTS "view_team_members" ON team_members;
DROP POLICY IF EXISTS "view_jobs" ON jobs;
DROP POLICY IF EXISTS "view_candidates" ON candidates;
DROP POLICY IF EXISTS "view_candidate_stages" ON candidate_stages;
DROP POLICY IF EXISTS "create_company" ON companies;
DROP POLICY IF EXISTS "create_team_member" ON team_members;
DROP POLICY IF EXISTS "Users can view their companies" ON companies;

-- Create base policy for companies
CREATE POLICY "companies_policy"
ON companies
FOR ALL
TO authenticated
USING (
  id IN (
    SELECT company_id 
    FROM team_members 
    WHERE user_id = auth.uid()
  )
);

-- Create base policy for team_members
CREATE POLICY "team_members_policy"
ON team_members
FOR ALL
TO authenticated
USING (
  -- User can only see their own membership
  user_id = auth.uid()
);

-- Create base policy for jobs
CREATE POLICY "jobs_policy"
ON jobs
FOR ALL
TO authenticated
USING (
  company_id IN (
    SELECT company_id 
    FROM team_members 
    WHERE user_id = auth.uid()
  )
);

-- Create base policy for candidates
CREATE POLICY "candidates_policy"
ON candidates
FOR ALL
TO authenticated
USING (
  company_id IN (
    SELECT company_id 
    FROM team_members 
    WHERE user_id = auth.uid()
  )
);

-- Create base policy for candidate_stages
CREATE POLICY "candidate_stages_policy"
ON candidate_stages
FOR ALL
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

-- Add special insert policies for registration flow
CREATE POLICY "registration_company_policy"
ON companies
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "registration_team_member_policy"
ON team_members
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS team_members_user_id_idx ON team_members(user_id);
CREATE INDEX IF NOT EXISTS team_members_company_id_idx ON team_members(company_id);
CREATE INDEX IF NOT EXISTS jobs_company_id_idx ON jobs(company_id);
CREATE INDEX IF NOT EXISTS candidates_company_id_idx ON candidates(company_id);
CREATE INDEX IF NOT EXISTS candidate_stages_candidate_id_idx ON candidate_stages(candidate_id);