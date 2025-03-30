/*
  # Add storage policies for document uploads

  1. Security
    - Enable storage policies for document uploads
    - Add policy for authenticated users to upload documents
    - Add policy for authenticated users to read their company's documents
*/

-- Create storage bucket for documents
INSERT INTO storage.buckets (id, name, public) 
VALUES ('candidate_documents', 'candidate_documents', false);

-- Create policy to allow authenticated users to upload documents
CREATE POLICY "Users can upload documents" ON storage.objects FOR INSERT TO authenticated WITH CHECK (
  bucket_id = 'candidate_documents' AND
  (EXISTS (
    SELECT 1 FROM candidates c
    JOIN team_members tm ON tm.company_id = c.company_id
    WHERE tm.user_id = auth.uid() AND c.id = SPLIT_PART(name, '/', 1)::uuid
  ))
);

-- Create policy to allow authenticated users to read their company's documents
CREATE POLICY "Users can read their company's documents" ON storage.objects FOR SELECT TO authenticated USING (
  bucket_id = 'candidate_documents' AND
  (EXISTS (
    SELECT 1 FROM candidates c
    JOIN team_members tm ON tm.company_id = c.company_id
    WHERE tm.user_id = auth.uid() AND c.id = SPLIT_PART(name, '/', 1)::uuid
  ))
);