/*
  # Ensure single company per user

  1. Changes
    - Add unique constraint on user_id in team_members table
    - Remove admin role from team_members
    - Update existing role to 'member'

  2. Security
    - Ensures each user can only belong to one company
    - Simplifies permissions by removing admin role
*/

-- First update all roles to 'member'
UPDATE team_members
SET role = 'member'
WHERE role = 'admin';

-- Add unique constraint on user_id to ensure one company per user
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'team_members_user_id_unique'
    AND table_name = 'team_members'
  ) THEN
    ALTER TABLE team_members
    ADD CONSTRAINT team_members_user_id_unique UNIQUE (user_id);
  END IF;
END $$;