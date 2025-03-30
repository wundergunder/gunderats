/*
  # Fix registration flow and error handling

  1. Changes
    - Add proper error handling to trigger function
    - Add validation for required fields
    - Use transaction to ensure atomic operations
    - Add detailed error messages

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
BEGIN
  -- Validate required metadata
  IF NEW.raw_user_meta_data IS NULL OR NEW.raw_user_meta_data->>'company_name' IS NULL THEN
    RAISE EXCEPTION 'Company name is required in user metadata';
  END IF;

  -- Use a transaction to ensure atomic operations
  BEGIN
    -- Create company
    WITH new_company AS (
      INSERT INTO companies (
        name,
        subscription_status,
        subscription_ends_at
      ) VALUES (
        TRIM((NEW.raw_user_meta_data->>'company_name')),
        'trial',
        NOW() + INTERVAL '14 days'
      )
      RETURNING id
    )
    -- Create team member
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

    RETURN NEW;
  EXCEPTION
    WHEN OTHERS THEN
      -- Log the error details
      RAISE WARNING 'Error in handle_new_user: %', SQLERRM;
      -- Re-raise the error
      RAISE EXCEPTION 'Failed to create company: %', SQLERRM;
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create new trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();