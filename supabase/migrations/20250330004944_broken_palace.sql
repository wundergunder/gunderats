/*
  # Fix RLS policies and add indexes

  1. Changes
    - Simplify RLS policies to avoid recursion
    - Add proper indexes for performance
    - Fix team_members policies
    - Fix related table policies

  2. Security
    - Maintain proper access control
    - Ensure data integrity
    - Optimize query performance
*/

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS team_members_company_id_idx ON team_members(company_id);
CREATE INDEX IF NOT EXISTS candidates_company_id_idx ON candidates(company_id);
CREATE INDEX IF NOT EXISTS jobs_company_id_idx ON jobs(company_id);

-- Fix team_members policy
DROP POLICY IF EXISTS "Team members can view company data" ON team_members;
DROP POLICY IF EXISTS "Users can view team members" ON team_members;

CREATE POLICY "Users can view team members"
ON team_members
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR 
  company_id IN (
    SELECT tm.company_id 
    FROM team_members tm 
    WHERE tm.user_id = auth.uid()
  )
);

-- Fix companies policy
DROP POLICY IF EXISTS "Users can view their companies" ON companies;

CREATE POLICY "Users can view their companies"
ON companies
FOR SELECT
TO authenticated
USING (
  id IN (
    SELECT tm.company_id 
    FROM team_members tm 
    WHERE tm.user_id = auth.uid()
  )
);

-- Fix jobs policy
DROP POLICY IF EXISTS "Users can view company jobs" ON jobs;

CREATE POLICY "Users can view company jobs"
ON jobs
FOR SELECT
TO authenticated
USING (
  company_id IN (
    SELECT tm.company_id 
    FROM team_members tm 
    WHERE tm.user_id = auth.uid()
  )
);

-- Fix candidate_stages policy
DROP POLICY IF EXISTS "Users can view company candidate stages" ON candidate_stages;

CREATE POLICY "Users can view company candidate stages"
ON candidate_stages
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 
    FROM candidates c
    WHERE c.id = candidate_stages.candidate_id
    AND c.company_id IN (
      SELECT tm.company_id 
      FROM team_members tm 
      WHERE tm.user_id = auth.uid()
    )
  )
);

-- Fix candidates policy
DROP POLICY IF EXISTS "Users can view company candidates" ON candidates;

CREATE POLICY "Users can view company candidates"
ON candidates
FOR SELECT
TO authenticated
USING (
  company_id IN (
    SELECT tm.company_id 
    FROM team_members tm 
    WHERE tm.user_id = auth.uid()
  )
);