/*
  # Add storage policies for document uploads

  1. Security
    - Add storage policies for document uploads if they don't exist
    - Add policy for authenticated users to upload documents
    - Add policy for authenticated users to read their company's documents

  Note: This migration handles the case where the policies may already exist
*/

-- Create storage bucket if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM storage.buckets WHERE id = 'candidate_documents'
  ) THEN
    INSERT INTO storage.buckets (id, name, public) 
    VALUES ('candidate_documents', 'candidate_documents', false);
  END IF;
END $$;

-- Create upload policy if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'objects' 
    AND policyname = 'Users can upload documents'
  ) THEN
    CREATE POLICY "Users can upload documents" ON storage.objects FOR INSERT TO authenticated WITH CHECK (
      bucket_id = 'candidate_documents' AND
      (EXISTS (
        SELECT 1 FROM candidates c
        JOIN team_members tm ON tm.company_id = c.company_id
        WHERE tm.user_id = auth.uid() AND c.id = SPLIT_PART(name, '/', 1)::uuid
      ))
    );
  END IF;
END $$;

-- Create read policy if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'objects' 
    AND policyname = 'Users can read their company''s documents'
  ) THEN
    CREATE POLICY "Users can read their company's documents" ON storage.objects FOR SELECT TO authenticated USING (
      bucket_id = 'candidate_documents' AND
      (EXISTS (
        SELECT 1 FROM candidates c
        JOIN team_members tm ON tm.company_id = c.company_id
        WHERE tm.user_id = auth.uid() AND c.id = SPLIT_PART(name, '/', 1)::uuid
      ))
    );
  END IF;
END $$;