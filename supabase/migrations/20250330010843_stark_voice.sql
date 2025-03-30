/*
  # Fix registration trigger function

  1. Changes
    - Move trigger to BEFORE INSERT to prevent user creation on error
    - Add proper error handling and validation
    - Use transaction to ensure atomic operations
    - Add detailed error messages
    - Fix potential NULL handling issues

  2. Security
    - Maintain SECURITY DEFINER for proper permissions
    - Keep RLS policies intact
*/

-- Drop old trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- Create improved function with better error handling
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

  -- Create company and team member in a transaction
  BEGIN
    -- Create company first
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
    -- Then create team member
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
      RAISE EXCEPTION 'Company name already exists' USING ERRCODE = 'CMPNY';
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Failed to create company: %', SQLERRM USING ERRCODE = 'CMPNY';
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

-- Ensure RLS is enabled
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;

-- Add policy to allow the trigger function to create records
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