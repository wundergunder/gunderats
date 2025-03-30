/*
  # Add admin company access policies

  1. Changes
    - Add policies for admin access to all companies
    - Fix team members policies for admin role
    - Add company view policies

  2. Security
    - Maintain proper access control
    - Allow admins to view all companies
*/

-- Drop existing policies
DROP POLICY IF EXISTS "team_members_policy" ON team_members;
DROP POLICY IF EXISTS "companies_policy" ON companies;

-- Create policy for companies
CREATE POLICY "companies_policy"
ON companies
FOR ALL
TO authenticated
USING (
  -- Users can see companies they are members of
  id IN (
    SELECT company_id 
    FROM team_members 
    WHERE user_id = auth.uid()
  )
  OR
  -- Admins can see all companies
  EXISTS (
    SELECT 1 
    FROM team_members 
    WHERE user_id = auth.uid() 
    AND role = 'admin'
  )
);

-- Create policy for team members
CREATE POLICY "team_members_policy"
ON team_members
FOR ALL
TO authenticated
USING (
  -- Users can see their own record
  user_id = auth.uid()
  OR
  -- Users can see other members in their companies
  company_id IN (
    SELECT company_id 
    FROM team_members 
    WHERE user_id = auth.uid()
  )
  OR
  -- Admins can see all team members
  EXISTS (
    SELECT 1 
    FROM team_members 
    WHERE user_id = auth.uid() 
    AND role = 'admin'
  )
);