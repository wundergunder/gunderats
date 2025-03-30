import React from 'react';
import Layout from '../components/Layout';
import JobForm from '../components/JobForm';
import { useAuth } from '../lib/auth';
import { supabase } from '../lib/supabase';
import type { Job } from '../types/database';
import { Trash2, Edit, Plus } from 'lucide-react';

export default function Jobs() {
  const { user } = useAuth();
  const [jobs, setJobs] = React.useState<Job[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [showForm, setShowForm] = React.useState(false);
  const [selectedJob, setSelectedJob] = React.useState<Job | undefined>();

  const fetchJobs = React.useCallback(async () => {
    try {
      const { data, error } = await supabase
        .from('jobs')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setJobs(data || []);
    } catch (error) {
      console.error('Error fetching jobs:', error);
    } finally {
      setLoading(false);
    }
  }, []);

  React.useEffect(() => {
    fetchJobs();
  }, [fetchJobs]);

  const handleEdit = (job: Job) => {
    setSelectedJob(job);
    setShowForm(true);
  };

  const handleDelete = async (jobId: string) => {
    if (!confirm('Are you sure you want to delete this job?')) return;

    try {
      const { error } = await supabase
        .from('jobs')
        .delete()
        .eq('id', jobId);

      if (error) throw error;
      await fetchJobs();
    } catch (error) {
      console.error('Error deleting job:', error);
    }
  };

  const handleFormClose = () => {
    setShowForm(false);
    setSelectedJob(undefined);
  };

  const handleFormSave = () => {
    fetchJobs();
  };

  return (
    <Layout>
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="sm:flex sm:items-center">
          <div className="sm:flex-auto">
            <h1 className="text-2xl font-semibold text-gray-900">Jobs</h1>
            <p className="mt-2 text-sm text-gray-700">
              A list of all job postings in your company
            </p>
          </div>
          <div className="mt-4 sm:mt-0 sm:ml-16 sm:flex-none">
            <button
              type="button"
              onClick={() => setShowForm(true)}
              className="inline-flex items-center justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 sm:w-auto"
            >
              <Plus className="h-4 w-4 mr-2" />
              Add job
            </button>
          </div>
        </div>

        {loading ? (
          <div className="mt-6 flex justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
          </div>
        ) : jobs.length === 0 ? (
          <div className="mt-6 text-center">
            <p className="text-sm text-gray-500">No jobs found</p>
          </div>
        ) : (
          <div className="mt-8 flex flex-col">
            <div className="-my-2 -mx-4 overflow-x-auto sm:-mx-6 lg:-mx-8">
              <div className="inline-block min-w-full py-2 align-middle md:px-6 lg:px-8">
                <div className="overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg">
                  <table className="min-w-full divide-y divide-gray-300">
                    <thead className="bg-gray-50">
                      <tr>
                        <th scope="col" className="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6">
                          Title
                        </th>
                        <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                          Location
                        </th>
                        <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                          Status
                        </th>
                        <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                          Salary Range
                        </th>
                        <th scope="col" className="relative py-3.5 pl-3 pr-4 sm:pr-6">
                          <span className="sr-only">Actions</span>
                        </th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200 bg-white">
                      {jobs.map((job) => (
                        <tr key={job.id}>
                          <td className="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-6">
                            {job.title}
                          </td>
                          <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                            {job.location || 'Remote'}
                          </td>
                          <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                            <span className={`inline-flex rounded-full px-2 text-xs font-semibold leading-5 ${
                              job.status === 'draft' 
                                ? 'bg-gray-100 text-gray-800'
                                : job.status === 'published'
                                ? 'bg-green-100 text-green-800'
                                : 'bg-red-100 text-red-800'
                            }`}>
                              {job.status}
                            </span>
                          </td>
                          <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                            {job.salary_range ? (
                              <>
                                {job.salary_range.currency} {job.salary_range.min} - {job.salary_range.max}
                              </>
                            ) : (
                              'Not specified'
                            )}
                          </td>
                          <td className="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6">
                            <button
                              onClick={() => handleEdit(job)}
                              className="text-indigo-600 hover:text-indigo-900 mr-4"
                            >
                              <Edit className="h-4 w-4" />
                              <span className="sr-only">Edit</span>
                            </button>
                            <button
                              onClick={() => handleDelete(job.id)}
                              className="text-red-600 hover:text-red-900"
                            >
                              <Trash2 className="h-4 w-4" />
                              <span className="sr-only">Delete</span>
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </div>
        )}

        {showForm && (
          <JobForm
            job={selectedJob}
            onClose={handleFormClose}
            onSave={handleFormSave}
          />
        )}
      </div>
    </Layout>
  );
}