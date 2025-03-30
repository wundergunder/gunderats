/*
  # Fix recursive RLS policies

  1. Changes
    - Simplify RLS policies to avoid recursion
    - Use direct user_id checks where possible
    - Use subqueries with IN clauses instead of EXISTS
    - Add proper indexes for performance

  2. Security
    - Maintain proper access control
    - Ensure data integrity
    - Prevent infinite recursion
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view team members" ON team_members;
DROP POLICY IF EXISTS "Users can view their companies" ON companies;
DROP POLICY IF EXISTS "Users can view company jobs" ON jobs;
DROP POLICY IF EXISTS "Users can view company candidate stages" ON candidate_stages;
DROP POLICY IF EXISTS "Users can view company candidates" ON candidates;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS team_members_company_id_idx ON team_members(company_id);
CREATE INDEX IF NOT EXISTS candidates_company_id_idx ON candidates(company_id);
CREATE INDEX IF NOT EXISTS jobs_company_id_idx ON jobs(company_id);

-- Create base policy for team_members
CREATE POLICY "Users can view team members"
ON team_members
FOR SELECT
TO authenticated
USING (
  -- User can see their own team membership
  user_id = auth.uid()
);

-- Create policy for companies
CREATE POLICY "Users can view their companies"
ON companies
FOR SELECT
TO authenticated
USING (
  -- User can see companies they are a member of
  id IN (
    SELECT company_id 
    FROM team_members 
    WHERE user_id = auth.uid()
  )
);

-- Create policy for jobs
CREATE POLICY "Users can view company jobs"
ON jobs
FOR SELECT
TO authenticated
USING (
  -- User can see jobs in their companies
  company_id IN (
    SELECT company_id 
    FROM team_members 
    WHERE user_id = auth.uid()
  )
);

-- Create policy for candidates
CREATE POLICY "Users can view company candidates"
ON candidates
FOR SELECT
TO authenticated
USING (
  -- User can see candidates in their companies
  company_id IN (
    SELECT company_id 
    FROM team_members 
    WHERE user_id = auth.uid()
  )
);

-- Create policy for candidate_stages
CREATE POLICY "Users can view company candidate stages"
ON candidate_stages
FOR SELECT
TO authenticated
USING (
  -- User can see stages for candidates in their companies
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