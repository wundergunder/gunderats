/*
  # Fix team members relationship with auth users

  1. Changes
    - Drop existing foreign key if it exists
    - Add foreign key constraint to auth.users
    - Add unique constraint on user_id
    - Add index for better performance
    - Enable RLS on team_members table
    - Add RLS policies for team members table
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

-- Add index for better performance
CREATE INDEX IF NOT EXISTS team_members_user_id_idx ON team_members(user_id);

-- Enable RLS
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view team members in their company"
ON team_members
FOR SELECT
TO authenticated
USING (
  company_id IN (
    SELECT company_id FROM team_members WHERE user_id = auth.uid()
  )
);