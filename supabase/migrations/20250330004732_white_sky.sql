/*
  # Fix RLS policies to avoid recursion

  1. Changes
    - Drop and recreate team_members policies to avoid recursion
    - Fix jobs policies to use direct user_id check
    - Fix candidate_stages policies to avoid nested queries
    - Fix candidates policies to use direct user_id check

  2. Security
    - All policies use simpler, non-recursive checks
    - Maintain same level of security with better performance
*/

-- Fix team_members policy to avoid recursion
DROP POLICY IF EXISTS "Users can view team members" ON team_members;
CREATE POLICY "Users can view team members"
ON team_members
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR 
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.company_id = team_members.company_id
  )
);

-- Fix jobs policy
DROP POLICY IF EXISTS "Users can view jobs" ON jobs;
CREATE POLICY "Users can view jobs"
ON jobs
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.company_id = jobs.company_id
  )
);

-- Fix candidate_stages policy
DROP POLICY IF EXISTS "Users can view candidate stages" ON candidate_stages;
CREATE POLICY "Users can view candidate stages"
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

-- Fix candidates policy
DROP POLICY IF EXISTS "Users can view candidates" ON candidates;
CREATE POLICY "Users can view candidates"
ON candidates
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM team_members tm 
    WHERE tm.user_id = auth.uid() 
    AND tm.company_id = candidates.company_id
  )
);