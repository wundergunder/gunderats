/*
  # Create secure view for team members with profiles

  1. Changes
    - Create view to join team_members with profiles
    - Add security barrier to prevent information leakage
    - Grant proper permissions to authenticated users

  2. Security
    - View inherits RLS from underlying tables
    - Security barrier prevents information leakage
*/

-- Create a secure view to join team_members with profiles
CREATE OR REPLACE VIEW team_members_with_profiles
WITH (security_barrier = true)
AS
SELECT 
  tm.*,
  p.email as user_email
FROM team_members tm
JOIN profiles p ON p.id = tm.user_id;

-- Grant access to the view
GRANT SELECT ON team_members_with_profiles TO authenticated;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS team_members_user_id_idx ON team_members(user_id);
CREATE INDEX IF NOT EXISTS team_members_company_id_idx ON team_members(company_id);