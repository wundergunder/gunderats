/*
  # Fix company creation during registration

  1. Changes
    - Add function to handle company creation during registration
    - Add trigger to automatically create company and team member
    - Remove old policies that are no longer needed

  2. Security
    - Use security definer function to bypass RLS
    - Maintain data integrity during registration
*/

-- Drop old policies that are no longer needed
DROP POLICY IF EXISTS "Users can create their company" ON companies;
DROP POLICY IF EXISTS "Users can create their team membership" ON team_members;

-- Create function to handle company creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  company_id uuid;
BEGIN
  -- Create company
  INSERT INTO companies (
    name,
    subscription_status,
    subscription_ends_at
  ) VALUES (
    (NEW.raw_user_meta_data->>'company_name'),
    'trial',
    NOW() + INTERVAL '14 days'
  )
  RETURNING id INTO company_id;

  -- Create team member
  INSERT INTO team_members (
    user_id,
    company_id,
    role
  ) VALUES (
    NEW.id,
    company_id,
    'member'
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();