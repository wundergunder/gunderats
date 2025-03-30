import React from 'react';
import { supabase } from '../lib/supabase';
import type { Candidate, Comment, PipelineStage, Job } from '../types/database';
import CommentForm from './CommentForm';
import DocumentUpload from './DocumentUpload';
import { formatDistanceToNow } from 'date-fns';

interface CandidateDetailsProps {
  candidate: Candidate;
  onClose: () => void;
  onUpdate: () => void;
}

export default function CandidateDetails({ candidate, onClose, onUpdate }: CandidateDetailsProps) {
  const [comments, setComments] = React.useState<Comment[]>([]);
  const [stages, setStages] = React.useState<PipelineStage[]>([]);
  const [currentStage, setCurrentStage] = React.useState<PipelineStage | null>(null);
  const [job, setJob] = React.useState<Job | null>(null);
  const [loading, setLoading] = React.useState(true);
  const [activeTab, setActiveTab] = React.useState<'details' | 'documents'>('details');

  React.useEffect(() => {
    async function fetchData() {
      try {
        // Fetch comments
        const { data: commentsData, error: commentsError } = await supabase
          .from('comments')
          .select(`
            *,
            created_by (
              email
            )
          `)
          .eq('candidate_id', candidate.id)
          .order('created_at', { ascending: false });

        if (commentsError) throw commentsError;
        setComments(commentsData || []);

        // Fetch pipeline stages
        const { data: stagesData, error: stagesError } = await supabase
          .from('pipeline_stages')
          .select('*')
          .order('order_index', { ascending: true });

        if (stagesError) throw stagesError;
        setStages(stagesData || []);

        // Find current stage
        const currentStage = stagesData?.find(stage => stage.id === candidate.current_stage_id) || null;
        setCurrentStage(currentStage);

        // Fetch job details
        const { data: jobData, error: jobError } = await supabase
          .from('jobs')
          .select('*')
          .eq('id', candidate.job_id)
          .single();

        if (jobError) throw jobError;
        setJob(jobData);
      } catch (error) {
        console.error('Error fetching candidate details:', error);
      } finally {
        setLoading(false);
      }
    }

    fetchData();
  }, [candidate]);

  const handleStageChange = async (stageId: string) => {
    try {
      const { error: updateError } = await supabase
        .from('candidates')
        .update({ current_stage_id: stageId })
        .eq('id', candidate.id);

      if (updateError) throw updateError;

      const { error: historyError } = await supabase
        .from('candidate_stages')
        .insert([{
          candidate_id: candidate.id,
          stage_id: stageId,
        }]);

      if (historyError) throw historyError;

      onUpdate();
      const newStage = stages.find(stage => stage.id === stageId) || null;
      setCurrentStage(newStage);
    } catch (error) {
      console.error('Error updating candidate stage:', error);
    }
  };

  const handleCommentSave = async () => {
    try {
      const { data, error } = await supabase
        .from('comments')
        .select(`
          *,
          created_by (
            email
          )
        `)
        .eq('candidate_id', candidate.id)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setComments(data || []);
    } catch (error) {
      console.error('Error fetching updated comments:', error);
    }
  };

  if (loading) {
    return (
      <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-white"></div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-4xl max-h-[90vh] overflow-hidden">
        <div className="flex flex-col h-full">
          <div className="px-4 py-5 sm:px-6 border-b border-gray-200">
            <div className="flex justify-between items-start">
              <div>
                <h3 className="text-lg font-medium leading-6 text-gray-900">
                  {candidate.first_name} {candidate.last_name}
                </h3>
                <p className="mt-1 text-sm text-gray-500">
                  Applied for {job?.title}
                </p>
              </div>
              <button
                onClick={onClose}
                className="rounded-md text-gray-400 hover:text-gray-500 focus:outline-none"
              >
                <span className="sr-only">Close</span>
                <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          </div>

          <div className="border-b border-gray-200">
            <nav className="-mb-px flex">
              <button
                onClick={() => setActiveTab('details')}
                className={`w-1/2 py-4 px-1 text-center border-b-2 text-sm font-medium ${
                  activeTab === 'details'
                    ? 'border-indigo-500 text-indigo-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                Details
              </button>
              <button
                onClick={() => setActiveTab('documents')}
                className={`w-1/2 py-4 px-1 text-center border-b-2 text-sm font-medium ${
                  activeTab === 'documents'
                    ? 'border-indigo-500 text-indigo-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                Documents
              </button>
            </nav>
          </div>

          <div className="flex-1 overflow-y-auto">
            <div className="px-4 py-5 sm:p-6">
              {activeTab === 'details' ? (
                <div className="grid grid-cols-1 gap-6">
                  <div>
                    <h4 className="text-sm font-medium text-gray-500">Contact Information</h4>
                    <div className="mt-2 space-y-2">
                      <p className="text-sm text-gray-900">{candidate.email}</p>
                      {candidate.phone && (
                        <p className="text-sm text-gray-900">{candidate.phone}</p>
                      )}
                    </div>
                  </div>

                  <div>
                    <h4 className="text-sm font-medium text-gray-500">Pipeline Stage</h4>
                    <select
                      value={currentStage?.id || ''}
                      onChange={(e) => handleStageChange(e.target.value)}
                      className="mt-2 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                    >
                      {stages.map((stage) => (
                        <option key={stage.id} value={stage.id}>
                          {stage.name}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <h4 className="text-sm font-medium text-gray-500">Comments</h4>
                    <CommentForm
                      candidateId={candidate.id}
                      onSave={handleCommentSave}
                    />
                    <div className="mt-6 space-y-4">
                      {comments.map((comment) => (
                        <div key={comment.id} className="bg-gray-50 rounded-lg p-4">
                          <div className="flex space-x-3">
                            <div className="flex-1">
                              <p className="text-sm text-gray-900">{comment.content}</p>
                              <div className="mt-1 text-xs text-gray-500">
                                {(comment as any).created_by?.email} · {formatDistanceToNow(new Date(comment.created_at), { addSuffix: true })}
                              </div>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              ) : (
                <div>
                  <h4 className="text-sm font-medium text-gray-500 mb-4">Documents</h4>
                  <DocumentUpload candidateId={candidate.id} />
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}