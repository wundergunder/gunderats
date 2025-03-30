/*
  # Fix team members users relationship

  1. Changes
    - Add index for team_members.user_id if it doesn't exist
    - Skip foreign key creation since it already exists

  2. Notes
    - Uses IF NOT EXISTS to prevent duplicate index creation
    - Skips foreign key creation since it's already present
*/

-- Add index for better performance if it doesn't exist
CREATE INDEX IF NOT EXISTS team_members_user_id_idx ON team_members(user_id);