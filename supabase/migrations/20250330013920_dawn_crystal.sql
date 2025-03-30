/*
  # Create Initial Schema
  
  1. New Tables
    - profiles: User profile information
    - companies: Company information
    - team_members: Company team members
    - jobs: Job postings
    - pipeline_stages: Hiring pipeline stages
    - candidates: Job candidates
    - candidate_stages: Candidate pipeline progress
    - comments: Candidate comments
    - documents: Candidate documents

  2. Security
    - Enable RLS on all tables
    - Add policies for proper data access
    - Set up role-based permissions
*/

-- Create profiles table to store user information
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create companies table
CREATE TABLE IF NOT EXISTS companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  settings jsonb DEFAULT '{}'::jsonb,
  subscription_status text DEFAULT 'trial',
  subscription_ends_at timestamptz DEFAULT (now() + interval '14 days')
);

-- Create team_members table
CREATE TABLE IF NOT EXISTS team_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  company_id uuid REFERENCES companies(id) NOT NULL,
  role text NOT NULL DEFAULT 'member',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, company_id)
);

-- Create jobs table
CREATE TABLE IF NOT EXISTS jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) NOT NULL,
  title text NOT NULL,
  description text,
  requirements text,
  status text DEFAULT 'draft',
  location text,
  salary_range jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id) NOT NULL
);

-- Create pipeline_stages table
CREATE TABLE IF NOT EXISTS pipeline_stages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) NOT NULL,
  name text NOT NULL,
  order_index integer NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(company_id, order_index)
);

-- Create candidates table
CREATE TABLE IF NOT EXISTS candidates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) NOT NULL,
  job_id uuid REFERENCES jobs(id) NOT NULL,
  first_name text NOT NULL,
  last_name text NOT NULL,
  email text NOT NULL,
  phone text,
  current_stage_id uuid REFERENCES pipeline_stages(id),
  status text DEFAULT 'active',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id) NOT NULL,
  UNIQUE(company_id, email, job_id)
);

-- Create candidate_stages table (history)
CREATE TABLE IF NOT EXISTS candidate_stages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  candidate_id uuid REFERENCES candidates(id) NOT NULL,
  stage_id uuid REFERENCES pipeline_stages(id) NOT NULL,
  notes text,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id) NOT NULL
);

-- Create comments table
CREATE TABLE IF NOT EXISTS comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  candidate_id uuid REFERENCES candidates(id) NOT NULL,
  content text NOT NULL,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id) NOT NULL
);

-- Create documents table
CREATE TABLE IF NOT EXISTS documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  candidate_id uuid REFERENCES candidates(id) NOT NULL,
  type text NOT NULL,
  name text NOT NULL,
  storage_path text NOT NULL,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id) NOT NULL
);

-- Create storage bucket for documents if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM storage.buckets WHERE id = 'candidate_documents'
  ) THEN
    INSERT INTO storage.buckets (id, name, public)
    VALUES ('candidate_documents', 'candidate_documents', false);
  END IF;
END $$;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_profiles_updated_at'
  ) THEN
    CREATE TRIGGER update_profiles_updated_at
      BEFORE UPDATE ON profiles
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_companies_updated_at'
  ) THEN
    CREATE TRIGGER update_companies_updated_at
      BEFORE UPDATE ON companies
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_team_members_updated_at'
  ) THEN
    CREATE TRIGGER update_team_members_updated_at
      BEFORE UPDATE ON team_members
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_jobs_updated_at'
  ) THEN
    CREATE TRIGGER update_jobs_updated_at
      BEFORE UPDATE ON jobs
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_pipeline_stages_updated_at'
  ) THEN
    CREATE TRIGGER update_pipeline_stages_updated_at
      BEFORE UPDATE ON pipeline_stages
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_candidates_updated_at'
  ) THEN
    CREATE TRIGGER update_candidates_updated_at
      BEFORE UPDATE ON candidates
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

-- Function to create default pipeline stages
CREATE OR REPLACE FUNCTION create_default_pipeline_stages()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO pipeline_stages (company_id, name, order_index)
  VALUES
    (NEW.id, 'Applied', 0),
    (NEW.id, 'Screening', 1),
    (NEW.id, 'Interview', 2),
    (NEW.id, 'Offer', 3),
    (NEW.id, 'Hired', 4);
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Add trigger to create default pipeline stages
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'create_company_pipeline_stages'
  ) THEN
    CREATE TRIGGER create_company_pipeline_stages
      AFTER INSERT ON companies
      FOR EACH ROW
      EXECUTE FUNCTION create_default_pipeline_stages();
  END IF;
END $$;

-- Function to handle new user registration
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

-- Create trigger for new user registration
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created'
  ) THEN
    CREATE TRIGGER on_auth_user_created
      AFTER INSERT ON auth.users
      FOR EACH ROW
      EXECUTE FUNCTION handle_new_user();
  END IF;
END $$;

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE candidate_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Create RLS policies

-- Profiles
CREATE POLICY IF NOT EXISTS "Users can view their own profile"
ON profiles FOR SELECT
TO authenticated
USING (id = auth.uid());

-- Companies
CREATE POLICY IF NOT EXISTS "Users can view their companies"
ON companies FOR SELECT
TO authenticated
USING (
  id IN (
    SELECT company_id FROM team_members WHERE user_id = auth.uid()
  )
);

-- Team Members
CREATE POLICY IF NOT EXISTS "Users can view team members"
ON team_members FOR SELECT
TO authenticated
USING (
  company_id IN (
    SELECT company_id FROM team_members WHERE user_id = auth.uid()
  )
);

-- Jobs
CREATE POLICY IF NOT EXISTS "Users can view company jobs"
ON jobs FOR SELECT
TO authenticated
USING (
  company_id IN (
    SELECT company_id FROM team_members WHERE user_id = auth.uid()
  )
);

-- Pipeline Stages
CREATE POLICY IF NOT EXISTS "Users can view pipeline stages"
ON pipeline_stages FOR SELECT
TO authenticated
USING (
  company_id IN (
    SELECT company_id FROM team_members WHERE user_id = auth.uid()
  )
);

-- Candidates
CREATE POLICY IF NOT EXISTS "Users can view candidates"
ON candidates FOR SELECT
TO authenticated
USING (
  company_id IN (
    SELECT company_id FROM team_members WHERE user_id = auth.uid()
  )
);

-- Candidate Stages
CREATE POLICY IF NOT EXISTS "Users can view candidate stages"
ON candidate_stages FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM candidates c
    JOIN team_members tm ON tm.company_id = c.company_id
    WHERE tm.user_id = auth.uid()
    AND c.id = candidate_stages.candidate_id
  )
);

-- Comments
CREATE POLICY IF NOT EXISTS "Users can view comments"
ON comments FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM candidates c
    JOIN team_members tm ON tm.company_id = c.company_id
    WHERE tm.user_id = auth.uid()
    AND c.id = comments.candidate_id
  )
);

-- Documents
CREATE POLICY IF NOT EXISTS "Users can view documents"
ON documents FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM candidates c
    JOIN team_members tm ON tm.company_id = c.company_id
    WHERE tm.user_id = auth.uid()
    AND c.id = documents.candidate_id
  )
);

-- Storage policies
CREATE POLICY IF NOT EXISTS "Users can upload documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'candidate_documents' AND
  (EXISTS (
    SELECT 1 FROM candidates c
    JOIN team_members tm ON tm.company_id = c.company_id
    WHERE tm.user_id = auth.uid()
    AND c.id = SPLIT_PART(name, '/', 1)::uuid
  ))
);

CREATE POLICY IF NOT EXISTS "Users can read documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'candidate_documents' AND
  (EXISTS (
    SELECT 1 FROM candidates c
    JOIN team_members tm ON tm.company_id = c.company_id
    WHERE tm.user_id = auth.uid()
    AND c.id = SPLIT_PART(name, '/', 1)::uuid
  ))
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS team_members_user_id_idx ON team_members(user_id);
CREATE INDEX IF NOT EXISTS team_members_company_id_idx ON team_members(company_id);
CREATE INDEX IF NOT EXISTS jobs_company_id_idx ON jobs(company_id);
CREATE INDEX IF NOT EXISTS candidates_company_id_idx ON candidates(company_id);
CREATE INDEX IF NOT EXISTS pipeline_stages_company_id_idx ON pipeline_stages(company_id);