/*
  # Fix registration flow and company creation

  1. Changes
    - Drop existing trigger and function
    - Add unique constraint on company name
    - Create improved trigger function with better error handling
    - Add proper RLS policies

  2. Security
    - Ensure atomic operations for user registration
    - Handle unique constraint violations
    - Clean up on failure
*/

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- Add unique constraint on company name if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'companies_name_key'
  ) THEN
    ALTER TABLE companies ADD CONSTRAINT companies_name_key UNIQUE (name);
  END IF;
END $$;

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
    DELETE FROM auth.users WHERE id = NEW.id;
    RAISE EXCEPTION 'Company name is required' USING ERRCODE = 'CMPNY';
  END IF;

  -- Create profile, company, and team member in a transaction
  BEGIN
    -- Create profile first (if it doesn't exist)
    INSERT INTO profiles (
      id,
      email
    ) VALUES (
      NEW.id,
      NEW.email
    )
    ON CONFLICT (id) DO NOTHING;

    -- Then create company
    INSERT INTO companies (
      name,
      subscription_status,
      subscription_ends_at
    ) VALUES (
      v_company_name,
      'trial',
      NOW() + INTERVAL '14 days'
    )
    RETURNING id INTO v_company_id;

    -- Finally create team member
    INSERT INTO team_members (
      user_id,
      company_id,
      role
    ) VALUES (
      NEW.id,
      v_company_id,
      'member'
    );

  EXCEPTION 
    WHEN unique_violation THEN
      -- Delete the auth user since we couldn't complete the setup
      DELETE FROM auth.users WHERE id = NEW.id;
      
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
      -- Delete the auth user since we couldn't complete the setup
      DELETE FROM auth.users WHERE id = NEW.id;
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