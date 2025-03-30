import React from 'react';
import { supabase } from '../lib/supabase';
import type { Candidate, Job, PipelineStage } from '../types/database';

interface CandidateFormProps {
  candidate?: Candidate;
  onClose: () => void;
  onSave: () => void;
}

export default function CandidateForm({ candidate, onClose, onSave }: CandidateFormProps) {
  const [firstName, setFirstName] = React.useState(candidate?.first_name || '');
  const [lastName, setLastName] = React.useState(candidate?.last_name || '');
  const [email, setEmail] = React.useState(candidate?.email || '');
  const [phone, setPhone] = React.useState(candidate?.phone || '');
  const [jobId, setJobId] = React.useState(candidate?.job_id || '');
  const [stageId, setStageId] = React.useState(candidate?.current_stage_id || '');
  const [jobs, setJobs] = React.useState<Job[]>([]);
  const [stages, setStages] = React.useState<PipelineStage[]>([]);
  const [loading, setLoading] = React.useState(false);
  const [error, setError] = React.useState('');

  React.useEffect(() => {
    async function fetchData() {
      try {
        // Fetch jobs
        const { data: jobsData, error: jobsError } = await supabase
          .from('jobs')
          .select('*')
          .eq('status', 'published');

        if (jobsError) throw jobsError;
        setJobs(jobsData || []);

        // Fetch pipeline stages
        const { data: stagesData, error: stagesError } = await supabase
          .from('pipeline_stages')
          .select('*')
          .order('order_index', { ascending: true });

        if (stagesError) throw stagesError;
        setStages(stagesData || []);

        // Set default stage if creating new candidate
        if (!candidate && stagesData && stagesData.length > 0) {
          setStageId(stagesData[0].id);
        }
      } catch (error) {
        console.error('Error fetching form data:', error);
      }
    }

    fetchData();
  }, [candidate]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      if (candidate) {
        // Update existing candidate
        const { error } = await supabase
          .from('candidates')
          .update({
            first_name: firstName,
            last_name: lastName,
            email,
            phone,
            job_id: jobId,
            current_stage_id: stageId,
            updated_at: new Date().toISOString(),
          })
          .eq('id', candidate.id);

        if (error) throw error;
      } else {
        // Create new candidate
        const { error } = await supabase
          .from('candidates')
          .insert([{
            first_name: firstName,
            last_name: lastName,
            email,
            phone,
            job_id: jobId,
            current_stage_id: stageId,
          }]);

        if (error) throw error;
      }

      onSave();
      onClose();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="px-4 py-5 sm:p-6">
            <h3 className="text-lg font-medium leading-6 text-gray-900">
              {candidate ? 'Edit Candidate' : 'Add New Candidate'}
            </h3>

            {error && (
              <div className="mt-4 bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-md text-sm">
                {error}
              </div>
            )}

            <div className="mt-6 grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6">
              <div className="sm:col-span-3">
                <label htmlFor="first-name" className="block text-sm font-medium text-gray-700">
                  First Name
                </label>
                <div className="mt-1">
                  <input
                    type="text"
                    name="first-name"
                    id="first-name"
                    required
                    value={firstName}
                    onChange={(e) => setFirstName(e.target.value)}
                    className="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  />
                </div>
              </div>

              <div className="sm:col-span-3">
                <label htmlFor="last-name" className="block text-sm font-medium text-gray-700">
                  Last Name
                </label>
                <div className="mt-1">
                  <input
                    type="text"
                    name="last-name"
                    id="last-name"
                    required
                    value={lastName}
                    onChange={(e) => setLastName(e.target.value)}
                    className="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  />
                </div>
              </div>

              <div className="sm:col-span-4">
                <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                  Email
                </label>
                <div className="mt-1">
                  <input
                    type="email"
                    name="email"
                    id="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  />
                </div>
              </div>

              <div className="sm:col-span-4">
                <label htmlFor="phone" className="block text-sm font-medium text-gray-700">
                  Phone
                </label>
                <div className="mt-1">
                  <input
                    type="tel"
                    name="phone"
                    id="phone"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    className="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  />
                </div>
              </div>

              <div className="sm:col-span-4">
                <label htmlFor="job" className="block text-sm font-medium text-gray-700">
                  Job Position
                </label>
                <div className="mt-1">
                  <select
                    id="job"
                    name="job"
                    required
                    value={jobId}
                    onChange={(e) => setJobId(e.target.value)}
                    className="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  >
                    <option value="">Select a position</option>
                    {jobs.map((job) => (
                      <option key={job.id} value={job.id}>
                        {job.title}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="sm:col-span-4">
                <label htmlFor="stage" className="block text-sm font-medium text-gray-700">
                  Pipeline Stage
                </label>
                <div className="mt-1">
                  <select
                    id="stage"
                    name="stage"
                    required
                    value={stageId}
                    onChange={(e) => setStageId(e.target.value)}
                    className="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  >
                    {stages.map((stage) => (
                      <option key={stage.id} value={stage.id}>
                        {stage.name}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            </div>
          </div>

          <div className="px-4 py-3 bg-gray-50 text-right sm:px-6 space-x-3">
            <button
              type="button"
              onClick={onClose}
              className="inline-flex justify-center py-2 px-4 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              className="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
            >
              {loading ? 'Saving...' : 'Save'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}