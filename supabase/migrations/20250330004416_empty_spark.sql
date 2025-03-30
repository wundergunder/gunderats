/*
  # Fix RLS policies and add missing policies

  1. Changes
    - Drop and recreate team members policy to avoid recursion
    - Add RLS policies for jobs table
    - Add RLS policies for candidate_stages table
    - Add RLS policies for candidates table

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users to access their company's data
*/

-- Fix team_members policy
DROP POLICY IF EXISTS "Users can view team members in their company" ON team_members;
CREATE POLICY "Team members can view their company data"
ON team_members
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.company_id = team_members.company_id
  )
);

-- Enable RLS on jobs table
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;

-- Add jobs policies
CREATE POLICY "Users can view jobs in their company"
ON jobs
FOR SELECT
TO authenticated
USING (
  company_id IN (
    SELECT company_id FROM team_members 
    WHERE user_id = auth.uid()
  )
);

-- Enable RLS on candidate_stages table
ALTER TABLE candidate_stages ENABLE ROW LEVEL SECURITY;

-- Add candidate_stages policies
CREATE POLICY "Users can view candidate stages in their company"
ON candidate_stages
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM candidates c
    JOIN team_members tm ON tm.company_id = c.company_id
    WHERE tm.user_id = auth.uid()
    AND c.id = candidate_stages.candidate_id
  )
);

-- Enable RLS on candidates table
ALTER TABLE candidates ENABLE ROW LEVEL SECURITY;

-- Add candidates policies
CREATE POLICY "Users can view candidates in their company"
ON candidates
FOR SELECT
TO authenticated
USING (
  company_id IN (
    SELECT company_id FROM team_members 
    WHERE user_id = auth.uid()
  )
);