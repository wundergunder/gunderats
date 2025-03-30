export interface Company {
  id: string;
  name: string;
  created_at: string;
  updated_at: string;
  settings: Record<string, any>;
  subscription_status: string;
  subscription_ends_at: string;
}

export interface TeamMember {
  id: string;
  user_id: string;
  company_id: string;
  role: string;
  created_at: string;
  updated_at: string;
}

export interface Job {
  id: string;
  company_id: string;
  title: string;
  description: string | null;
  requirements: string | null;
  status: string;
  location: string | null;
  salary_range: {
    min?: number;
    max?: number;
    currency?: string;
  } | null;
  created_at: string;
  updated_at: string;
  created_by: string;
}

export interface PipelineStage {
  id: string;
  company_id: string;
  name: string;
  order_index: number;
  created_at: string;
  updated_at: string;
}

export interface Candidate {
  id: string;
  company_id: string;
  job_id: string;
  first_name: string;
  last_name: string;
  email: string;
  phone: string | null;
  current_stage_id: string | null;
  status: string;
  created_at: string;
  updated_at: string;
  created_by: string;
}

export interface CandidateStage {
  id: string;
  candidate_id: string;
  stage_id: string;
  notes: string | null;
  created_at: string;
  created_by: string;
}

export interface Comment {
  id: string;
  candidate_id: string;
  content: string;
  created_at: string;
  created_by: string;
}

export interface Document {
  id: string;
  candidate_id: string;
  type: string;
  name: string;
  storage_path: string;
  created_at: string;
  created_by: string;
}