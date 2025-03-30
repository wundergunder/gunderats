/*
  # Create profiles table and update relationships

  1. New Tables
    - `profiles`
      - `id` (uuid, matches auth.users id)
      - `email` (text, matches auth.users email)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Changes
    - Create profiles table to store user information
    - Add trigger to sync auth.users email to profiles
    - Update team_members foreign key to reference profiles

  3. Security
    - Enable RLS on profiles table
    - Add policies for authenticated users
*/

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view all profiles" ON profiles
  FOR SELECT TO authenticated
  USING (true);

-- Create trigger to sync auth.users email to profiles
CREATE OR REPLACE FUNCTION sync_user_email()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (NEW.id, NEW.email)
  ON CONFLICT (id) DO UPDATE
  SET email = EXCLUDED.email,
      updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on auth.users
DROP TRIGGER IF EXISTS sync_user_email ON auth.users;
CREATE TRIGGER sync_user_email
  AFTER INSERT OR UPDATE OF email ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION sync_user_email();

-- Sync existing users
INSERT INTO profiles (id, email)
SELECT id, email FROM auth.users
ON CONFLICT (id) DO UPDATE
SET email = EXCLUDED.email,
    updated_at = now();