/*
  # Initial Schema Setup for Gunder ATS

  1. New Tables
    - companies
      - Company profile information
    - jobs
      - Job postings and requirements
    - candidates
      - Candidate information and status
    - pipeline_stages
      - Customizable stages for hiring process
    - candidate_stages
      - Track candidate progress through pipeline
    - team_members
      - Team member information and roles
    - comments
      - Comments on candidates
    - documents
      - Store document metadata (resumes, etc.)

  2. Security
    - Enable RLS on all tables
    - Add policies for proper data access
    - Set up role-based permissions
*/

-- Companies table (without policy initially)
CREATE TABLE IF NOT EXISTS companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  settings jsonb DEFAULT '{}'::jsonb,
  subscription_status text DEFAULT 'trial',
  subscription_ends_at timestamptz DEFAULT (now() + interval '14 days')
);

-- Team members table
CREATE TABLE IF NOT EXISTS team_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  company_id uuid REFERENCES companies NOT NULL,
  role text NOT NULL DEFAULT 'member',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, company_id)
);

-- Now we can enable RLS and create policies that reference team_members
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Companies are viewable by their team members"
  ON companies
  FOR SELECT
  USING (
    id IN (
      SELECT company_id FROM team_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Team members can view their own companies"
  ON team_members
  FOR SELECT
  USING (user_id = auth.uid());

-- Jobs table
CREATE TABLE IF NOT EXISTS jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies NOT NULL,
  title text NOT NULL,
  description text,
  requirements text,
  status text DEFAULT 'draft',
  location text,
  salary_range jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users NOT NULL
);

ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Jobs are viewable by company team members"
  ON jobs
  FOR SELECT
  USING (
    company_id IN (
      SELECT company_id FROM team_members
      WHERE user_id = auth.uid()
    )
  );

-- Pipeline stages table
CREATE TABLE IF NOT EXISTS pipeline_stages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies NOT NULL,
  name text NOT NULL,
  order_index integer NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(company_id, order_index)
);

ALTER TABLE pipeline_stages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pipeline stages are viewable by company team members"
  ON pipeline_stages
  FOR SELECT
  USING (
    company_id IN (
      SELECT company_id FROM team_members
      WHERE user_id = auth.uid()
    )
  );

-- Candidates table
CREATE TABLE IF NOT EXISTS candidates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies NOT NULL,
  job_id uuid REFERENCES jobs NOT NULL,
  first_name text NOT NULL,
  last_name text NOT NULL,
  email text NOT NULL,
  phone text,
  current_stage_id uuid REFERENCES pipeline_stages,
  status text DEFAULT 'active',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users NOT NULL,
  UNIQUE(company_id, email, job_id)
);

ALTER TABLE candidates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Candidates are viewable by company team members"
  ON candidates
  FOR SELECT
  USING (
    company_id IN (
      SELECT company_id FROM team_members
      WHERE user_id = auth.uid()
    )
  );

-- Candidate stages (history)
CREATE TABLE IF NOT EXISTS candidate_stages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  candidate_id uuid REFERENCES candidates NOT NULL,
  stage_id uuid REFERENCES pipeline_stages NOT NULL,
  notes text,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users NOT NULL
);

ALTER TABLE candidate_stages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Candidate stages are viewable by company team members"
  ON candidate_stages
  FOR SELECT
  USING (
    candidate_id IN (
      SELECT id FROM candidates
      WHERE company_id IN (
        SELECT company_id FROM team_members
        WHERE user_id = auth.uid()
      )
    )
  );

-- Comments table
CREATE TABLE IF NOT EXISTS comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  candidate_id uuid REFERENCES candidates NOT NULL,
  content text NOT NULL,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users NOT NULL
);

ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Comments are viewable by company team members"
  ON comments
  FOR SELECT
  USING (
    candidate_id IN (
      SELECT id FROM candidates
      WHERE company_id IN (
        SELECT company_id FROM team_members
        WHERE user_id = auth.uid()
      )
    )
  );

-- Documents table
CREATE TABLE IF NOT EXISTS documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  candidate_id uuid REFERENCES candidates NOT NULL,
  type text NOT NULL,
  name text NOT NULL,
  storage_path text NOT NULL,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users NOT NULL
);

ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Documents are viewable by company team members"
  ON documents
  FOR SELECT
  USING (
    candidate_id IN (
      SELECT id FROM candidates
      WHERE company_id IN (
        SELECT company_id FROM team_members
        WHERE user_id = auth.uid()
      )
    )
  );

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_companies_updated_at
  BEFORE UPDATE ON companies
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_jobs_updated_at
  BEFORE UPDATE ON jobs
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pipeline_stages_updated_at
  BEFORE UPDATE ON pipeline_stages
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_candidates_updated_at
  BEFORE UPDATE ON candidates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Insert default pipeline stages for new companies
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

CREATE TRIGGER create_company_pipeline_stages
  AFTER INSERT ON companies
  FOR EACH ROW
  EXECUTE FUNCTION create_default_pipeline_stages();