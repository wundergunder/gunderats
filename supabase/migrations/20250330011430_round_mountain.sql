/*
  # Fix User Registration Process

  1. Changes
    - Drop and recreate trigger function with profile handling
    - Add proper error handling with specific error codes
    - Check for existing policies before creating them
    - Ensure atomic transactions for all operations

  2. Security
    - Maintain RLS on all tables
    - Add proper policies for data access
    - Use security definer for trigger function
*/

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- Create improved function with better error handling and profile creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_company_name text;
BEGIN
  -- Get and validate company name
  v_company_name := NULLIF(TRIM(NEW.raw_user_meta_data->>'company_name'), '');
  IF v_company_name IS NULL THEN
    RAISE EXCEPTION 'Company name is required' USING ERRCODE = 'CMPNY';
  END IF;

  -- Create profile, company, and team member in a transaction
  BEGIN
    -- Create profile first
    INSERT INTO profiles (
      id,
      email
    ) VALUES (
      NEW.id,
      NEW.email
    );

    -- Then create company
    WITH new_company AS (
      INSERT INTO companies (
        name,
        subscription_status,
        subscription_ends_at
      ) VALUES (
        v_company_name,
        'trial',
        NOW() + INTERVAL '14 days'
      )
      RETURNING id
    )
    -- Finally create team member
    INSERT INTO team_members (
      user_id,
      company_id,
      role
    )
    SELECT 
      NEW.id,
      new_company.id,
      'member'
    FROM new_company;

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

  -- If we get here, everything worked
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create new trigger that runs BEFORE INSERT
CREATE TRIGGER on_auth_user_created
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Ensure RLS is enabled on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Allow trigger function to create companies" ON companies;
DROP POLICY IF EXISTS "Allow trigger function to create team members" ON team_members;

-- Add RLS policies for profiles
CREATE POLICY "Users can view their own profile"
ON profiles
FOR SELECT
TO authenticated
USING (id = auth.uid());

-- Add policies to allow the trigger function to create records
CREATE POLICY "Allow trigger function to create companies"
ON companies
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow trigger function to create team members"
ON team_members
FOR INSERT
TO authenticated
WITH CHECK (true);