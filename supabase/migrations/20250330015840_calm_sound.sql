/*
  # Fix team members and profiles relationship

  1. Changes
    - Add view to join team_members with profiles
    - Update RLS policies to use the view
    - Fix team members query in Settings page

  2. Security
    - Maintain proper access control
    - Ensure data integrity
*/

-- Create a view to join team_members with profiles
CREATE OR REPLACE VIEW team_members_with_profiles AS
SELECT 
  tm.*,
  p.email as user_email
FROM team_members tm
JOIN profiles p ON p.id = tm.user_id;

-- Drop existing team members policy
DROP POLICY IF EXISTS "team_members_policy" ON team_members;

-- Create new team members policy
CREATE POLICY "team_members_policy"
ON team_members
FOR ALL
TO authenticated
USING (
  user_id = auth.uid() OR
  company_id IN (
    SELECT company_id 
    FROM team_members 
    WHERE user_id = auth.uid()
  )
);

-- Grant access to the view
GRANT SELECT ON team_members_with_profiles TO authenticated;

-- Create policy for the view
CREATE POLICY "view_team_members_with_profiles"
ON team_members_with_profiles
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR
  company_id IN (
    SELECT company_id 
    FROM team_members 
    WHERE user_id = auth.uid()
  )
);

-- Enable RLS on the view
ALTER VIEW team_members_with_profiles ENABLE ROW LEVEL SECURITY;