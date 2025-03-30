/*
  # Fix user registration and company creation

  1. Changes
    - Drop existing trigger and function
    - Create improved function with better error handling
    - Add proper RLS policies for registration flow
    - Fix team_role handling

  2. Security
    - Maintain proper access control
    - Ensure data integrity
    - Handle errors gracefully
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
    VALUES (NEW.id, NEW.email)
    ON CONFLICT (id) DO NOTHING;

    -- Create company
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

    -- Create team member with admin role
    INSERT INTO team_members (
      user_id,
      company_id,
      role,
      permissions
    ) VALUES (
      NEW.id,
      v_company_id,
      'admin',
      '{}'::jsonb
    );

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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create new trigger that runs AFTER INSERT
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Drop existing policies
DROP POLICY IF EXISTS "registration_company_policy" ON companies;
DROP POLICY IF EXISTS "registration_team_member_policy" ON team_members;

-- Create policies to allow registration flow
CREATE POLICY "registration_company_policy"
ON companies
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "registration_team_member_policy"
ON team_members
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());