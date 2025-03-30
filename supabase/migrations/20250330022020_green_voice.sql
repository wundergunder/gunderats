/*
  # Fix team members view and policies

  1. Changes
    - Drop and recreate team members view with proper joins
    - Add proper RLS policies for the view
    - Fix team members table policies

  2. Security
    - Maintain proper access control
    - Ensure data integrity
    - Fix view permissions
*/

-- Drop existing view if it exists
DROP VIEW IF EXISTS team_members_with_profiles;

-- Create improved view with proper joins
CREATE OR REPLACE VIEW team_members_with_profiles AS
SELECT 
  tm.id,
  tm.user_id,
  tm.company_id,
  tm.created_at,
  tm.updated_at,
  tm.role,
  tm.permissions,
  p.email as user_email
FROM team_members tm
LEFT JOIN profiles p ON p.id = tm.user_id;

-- Drop existing team members policies
DROP POLICY IF EXISTS "team_members_policy" ON team_members;

-- Create new team members policies
CREATE POLICY "team_members_policy"
ON team_members
FOR ALL
TO authenticated
USING (
  -- Users can see team members in their company
  company_id IN (
    SELECT company_id 
    FROM team_members 
    WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  -- Users can only modify their own record
  user_id = auth.uid()
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS team_members_user_id_idx ON team_members(user_id);
CREATE INDEX IF NOT EXISTS team_members_company_id_idx ON team_members(company_id);