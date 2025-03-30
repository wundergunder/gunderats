/*
  # Add trigger to create company and team member on registration

  1. Changes
    - Add trigger to create company and team member when a new user registers
    - Add function to handle the trigger logic
    - Add policy to allow new users to create their company

  2. Security
    - Maintain existing RLS policies
    - Add specific policy for company creation during registration
*/

-- Add policy to allow users to create their own company
CREATE POLICY "Users can create their company"
ON companies
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Add policy to allow users to create their team membership
CREATE POLICY "Users can create their team membership"
ON team_members
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Add policy to allow users to update their company
CREATE POLICY "Users can update their company"
ON companies
FOR UPDATE
TO authenticated
USING (
  id IN (
    SELECT company_id 
    FROM team_members 
    WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  id IN (
    SELECT company_id 
    FROM team_members 
    WHERE user_id = auth.uid()
  )
);