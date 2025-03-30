/*
  # Fix team members auth users relationship

  1. Changes
    - Add foreign key constraint to link team_members.user_id to auth.users.id
    - Add index on team_members.user_id for better query performance

  2. Notes
    - Uses IF NOT EXISTS to prevent duplicate index creation
    - References auth.users instead of public.users
*/

-- Drop existing foreign key if it exists
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'team_members_user_id_fkey'
    AND table_name = 'team_members'
  ) THEN
    ALTER TABLE team_members DROP CONSTRAINT team_members_user_id_fkey;
  END IF;
END $$;

-- Add foreign key constraint to auth.users
ALTER TABLE team_members
ADD CONSTRAINT team_members_user_id_fkey
FOREIGN KEY (user_id) REFERENCES auth.users(id)
ON DELETE CASCADE;

-- Add index for better performance
CREATE INDEX IF NOT EXISTS team_members_user_id_idx ON team_members(user_id);