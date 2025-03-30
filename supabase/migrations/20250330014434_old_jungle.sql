/*
  # Fix user registration trigger
  
  1. Changes
    - Drop existing trigger and function
    - Create improved function with better error handling
    - Add proper RLS policies for registration flow

  2. Security
    - Maintain proper access control
    - Handle registration errors gracefully
*/

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- Create improved function with better error handling
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_company_name text;
  v_company_id uuid;
BEGIN
  -- Get and validate company name
  v_company_name := NULLIF(TRIM(NEW.raw_user_meta_data->>'company_name'), '');
  IF v_company_name IS NULL THEN
    RAISE EXCEPTION 'Company name is required' USING ERRCODE = 'CMPNY';
  END IF;

  -- Create profile, company, and team member in a transaction
  BEGIN
    -- Create profile first
    INSERT INTO profiles (id, email)
    VALUES (NEW.id, NEW.email);

    -- Create company
    INSERT INTO companies (name)
    VALUES (v_company_name)
    RETURNING id INTO v_company_id;

    -- Create team member
    INSERT INTO team_members (user_id, company_id, role)
    VALUES (NEW.id, v_company_id, 'member');

  EXCEPTION 
    WHEN unique_violation THEN
      -- Check which unique constraint was violated
      CASE 
        WHEN SQLERRM LIKE '%profiles_email_key%' THEN
          RAISE EXCEPTION 'Email already registered' USING ERRCODE = 'EMAIL';
        WHEN SQLERRM LIKE '%companies_name_key%' THEN
          RAISE EXCEPTION 'Company name already exists' USING ERRCODE = 'CMPNY';
        ELSE
          RAISE EXCEPTION 'Registration failed: %', SQLERRM USING ERRCODE = 'RGERR';
      END CASE;
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Registration failed: %', SQLERRM USING ERRCODE = 'RGERR';
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create new trigger that runs AFTER INSERT
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Ensure RLS is enabled
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Allow trigger function to create companies" ON companies;
DROP POLICY IF EXISTS "Allow trigger function to create team members" ON team_members;

-- Add policies to allow registration flow
CREATE POLICY "Allow registration to create companies"
ON companies
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow registration to create team members"
ON team_members
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());