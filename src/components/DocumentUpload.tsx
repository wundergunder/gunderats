import React from 'react';
import { supabase } from '../lib/supabase';
import { Upload, File, Trash2 } from 'lucide-react';
import type { Document } from '../types/database';

interface DocumentUploadProps {
  candidateId: string;
  onUpload?: () => void;
}

export default function DocumentUpload({ candidateId, onUpload }: DocumentUploadProps) {
  const [documents, setDocuments] = React.useState<Document[]>([]);
  const [uploading, setUploading] = React.useState(false);
  const [error, setError] = React.useState('');
  const fileInputRef = React.useRef<HTMLInputElement>(null);

  React.useEffect(() => {
    fetchDocuments();
  }, [candidateId]);

  const fetchDocuments = async () => {
    try {
      const { data, error } = await supabase
        .from('documents')
        .select('*')
        .eq('candidate_id', candidateId);

      if (error) throw error;
      setDocuments(data || []);
    } catch (err: any) {
      console.error('Error fetching documents:', err);
      setError(err.message);
    }
  };

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files || e.target.files.length === 0) return;

    setUploading(true);
    setError('');

    try {
      const file = e.target.files[0];
      const fileExt = file.name.split('.').pop();
      const fileName = `${candidateId}/${Math.random().toString(36).slice(2)}.${fileExt}`;

      // Upload file to storage
      const { error: uploadError } = await supabase.storage
        .from('candidate_documents')
        .upload(fileName, file);

      if (uploadError) throw uploadError;

      // Create document record
      const { error: dbError } = await supabase
        .from('documents')
        .insert([{
          candidate_id: candidateId,
          type: file.type,
          name: file.name,
          storage_path: fileName,
        }]);

      if (dbError) throw dbError;

      await fetchDocuments();
      if (onUpload) onUpload();
    } catch (err: any) {
      console.error('Error uploading document:', err);
      setError(err.message);
    } finally {
      setUploading(false);
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    }
  };

  const handleDelete = async (document: Document) => {
    if (!confirm('Are you sure you want to delete this document?')) return;

    try {
      // Delete from storage
      const { error: storageError } = await supabase.storage
        .from('candidate_documents')
        .remove([document.storage_path]);

      if (storageError) throw storageError;

      // Delete from database
      const { error: dbError } = await supabase
        .from('documents')
        .delete()
        .eq('id', document.id);

      if (dbError) throw dbError;

      await fetchDocuments();
    } catch (err: any) {
      console.error('Error deleting document:', err);
      setError(err.message);
    }
  };

  const handleDownload = async (document: Document) => {
    try {
      const { data, error } = await supabase.storage
        .from('candidate_documents')
        .download(document.storage_path);

      if (error) throw error;

      // Create download link
      const url = URL.createObjectURL(data);
      const a = document.createElement('a');
      a.href = url;
      a.download = document.name;
      a.click();
      URL.revokeObjectURL(url);
    } catch (err: any) {
      console.error('Error downloading document:', err);
      setError(err.message);
    }
  };

  return (
    <div className="space-y-4">
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-md text-sm">
          {error}
        </div>
      )}

      <div className="flex items-center justify-between">
        <input
          type="file"
          ref={fileInputRef}
          onChange={handleFileChange}
          disabled={uploading}
          className="hidden"
        />
        <button
          type="button"
          onClick={() => fileInputRef.current?.click()}
          disabled={uploading}
          className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
        >
          <Upload className="h-4 w-4 mr-2" />
          {uploading ? 'Uploading...' : 'Upload Document'}
        </button>
      </div>

      <div className="space-y-2">
        {documents.map((document) => (
          <div
            key={document.id}
            className="flex items-center justify-between bg-gray-50 rounded-md p-3"
          >
            <div className="flex items-center space-x-3">
              <File className="h-5 w-5 text-gray-400" />
              <span className="text-sm font-medium text-gray-900">
                {document.name}
              </span>
            </div>
            <div className="flex items-center space-x-2">
              <button
                onClick={() => handleDownload(document)}
                className="text-indigo-600 hover:text-indigo-900"
              >
                Download
              </button>
              <button
                onClick={() => handleDelete(document)}
                className="text-red-600 hover:text-red-900"
              >
                <Trash2 className="h-4 w-4" />
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}