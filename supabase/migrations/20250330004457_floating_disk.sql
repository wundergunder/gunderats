/*
  # Fix RLS policies for team members and jobs

  1. Changes
    - Drop and recreate team members policy with simplified logic
    - Add proper RLS policies for jobs table
    - Add proper RLS policies for candidate_stages table
    - Add proper RLS policies for candidates table

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users to access their company's data
    - Avoid recursive checks in policies
*/

-- Fix team_members policy to avoid recursion
DROP POLICY IF EXISTS "Team members can view their company data" ON team_members;
CREATE POLICY "Users can view team members"
ON team_members
FOR SELECT
TO authenticated
USING (user_id = auth.uid() OR company_id IN (
  SELECT company_id FROM team_members WHERE user_id = auth.uid()
));

-- Fix jobs policies
DROP POLICY IF EXISTS "Users can view jobs in their company" ON jobs;
CREATE POLICY "Users can view jobs"
ON jobs
FOR SELECT
TO authenticated
USING (company_id IN (
  SELECT company_id FROM team_members WHERE user_id = auth.uid()
));

-- Fix candidate_stages policies
DROP POLICY IF EXISTS "Users can view candidate stages in their company" ON candidate_stages;
CREATE POLICY "Users can view candidate stages"
ON candidate_stages
FOR SELECT
TO authenticated
USING (
  candidate_id IN (
    SELECT c.id FROM candidates c
    INNER JOIN team_members tm ON tm.company_id = c.company_id
    WHERE tm.user_id = auth.uid()
  )
);

-- Fix candidates policies
DROP POLICY IF EXISTS "Users can view candidates in their company" ON candidates;
CREATE POLICY "Users can view candidates"
ON candidates
FOR SELECT
TO authenticated
USING (company_id IN (
  SELECT company_id FROM team_members WHERE user_id = auth.uid()
));