import React from 'react';
import { supabase } from '../lib/supabase';

interface CommentFormProps {
  candidateId: string;
  onSave: () => void;
}

export default function CommentForm({ candidateId, onSave }: CommentFormProps) {
  const [content, setContent] = React.useState('');
  const [loading, setLoading] = React.useState(false);
  const [error, setError] = React.useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!content.trim()) return;

    setLoading(true);
    setError('');

    try {
      const { error } = await supabase
        .from('comments')
        .insert([{
          candidate_id: candidateId,
          content: content.trim(),
        }]);

      if (error) throw error;

      setContent('');
      onSave();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="mt-4">
      {error && (
        <div className="mb-4 bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-md text-sm">
          {error}
        </div>
      )}

      <div>
        <label htmlFor="comment" className="sr-only">
          Add comment
        </label>
        <textarea
          id="comment"
          name="comment"
          rows={3}
          value={content}
          onChange={(e) => setContent(e.target.value)}
          placeholder="Add a comment..."
          className="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
        />
      </div>

      <div className="mt-3 flex justify-end">
        <button
          type="submit"
          disabled={loading || !content.trim()}
          className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
        >
          {loading ? 'Posting...' : 'Post'}
        </button>
      </div>
    </form>
  );
}