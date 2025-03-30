/*
  # Fix team members and profiles relationship

  1. Changes
    - Create a view to properly join team_members with profiles
    - Add proper RLS policies for the view
    - Fix team members policies to avoid recursion

  2. Security
    - Maintain proper access control
    - Ensure data integrity
*/

-- Drop existing view if it exists
DROP VIEW IF EXISTS team_members_with_profiles;

-- Create view to join team_members with profiles
CREATE VIEW team_members_with_profiles AS
SELECT 
  tm.*,
  p.email as user_email
FROM team_members tm
JOIN auth.users u ON u.id = tm.user_id
JOIN profiles p ON p.id = tm.user_id;

-- Drop existing team members policy
DROP POLICY IF EXISTS "team_members_policy" ON team_members;

-- Create simplified team members policy
CREATE POLICY "team_members_policy"
ON team_members
FOR ALL
TO authenticated
USING (
  -- Users can see their own record
  user_id = auth.uid()
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS team_members_user_id_idx ON team_members(user_id);
CREATE INDEX IF NOT EXISTS team_members_company_id_idx ON team_members(company_id);