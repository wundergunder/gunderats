import React from 'react';
import { supabase } from '../lib/supabase';
import type { Job } from '../types/database';

interface JobFormProps {
  job?: Job;
  onClose: () => void;
  onSave: () => void;
}

export default function JobForm({ job, onClose, onSave }: JobFormProps) {
  const [title, setTitle] = React.useState(job?.title || '');
  const [description, setDescription] = React.useState(job?.description || '');
  const [requirements, setRequirements] = React.useState(job?.requirements || '');
  const [location, setLocation] = React.useState(job?.location || '');
  const [status, setStatus] = React.useState(job?.status || 'draft');
  const [salaryRange, setSalaryRange] = React.useState(job?.salary_range || { min: '', max: '', currency: 'USD' });
  const [loading, setLoading] = React.useState(false);
  const [error, setError] = React.useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      if (job) {
        // Update existing job
        const { error } = await supabase
          .from('jobs')
          .update({
            title,
            description,
            requirements,
            location,
            status,
            salary_range: salaryRange,
            updated_at: new Date().toISOString(),
          })
          .eq('id', job.id);

        if (error) throw error;
      } else {
        // Create new job
        const { error } = await supabase
          .from('jobs')
          .insert([{
            title,
            description,
            requirements,
            location,
            status,
            salary_range: salaryRange,
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
              {job ? 'Edit Job' : 'Create New Job'}
            </h3>

            {error && (
              <div className="mt-4 bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-md text-sm">
                {error}
              </div>
            )}

            <div className="mt-6 grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6">
              <div className="sm:col-span-4">
                <label htmlFor="title" className="block text-sm font-medium text-gray-700">
                  Job Title
                </label>
                <div className="mt-1">
                  <input
                    type="text"
                    name="title"
                    id="title"
                    required
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    className="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  />
                </div>
              </div>

              <div className="sm:col-span-6">
                <label htmlFor="description" className="block text-sm font-medium text-gray-700">
                  Description
                </label>
                <div className="mt-1">
                  <textarea
                    id="description"
                    name="description"
                    rows={4}
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    className="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  />
                </div>
              </div>

              <div className="sm:col-span-6">
                <label htmlFor="requirements" className="block text-sm font-medium text-gray-700">
                  Requirements
                </label>
                <div className="mt-1">
                  <textarea
                    id="requirements"
                    name="requirements"
                    rows={4}
                    value={requirements}
                    onChange={(e) => setRequirements(e.target.value)}
                    className="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  />
                </div>
              </div>

              <div className="sm:col-span-3">
                <label htmlFor="location" className="block text-sm font-medium text-gray-700">
                  Location
                </label>
                <div className="mt-1">
                  <input
                    type="text"
                    name="location"
                    id="location"
                    value={location}
                    onChange={(e) => setLocation(e.target.value)}
                    className="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  />
                </div>
              </div>

              <div className="sm:col-span-3">
                <label htmlFor="status" className="block text-sm font-medium text-gray-700">
                  Status
                </label>
                <div className="mt-1">
                  <select
                    id="status"
                    name="status"
                    value={status}
                    onChange={(e) => setStatus(e.target.value)}
                    className="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  >
                    <option value="draft">Draft</option>
                    <option value="published">Published</option>
                    <option value="closed">Closed</option>
                  </select>
                </div>
              </div>

              <div className="sm:col-span-6">
                <label className="block text-sm font-medium text-gray-700">
                  Salary Range
                </label>
                <div className="mt-1 grid grid-cols-3 gap-4">
                  <div>
                    <label htmlFor="salary-min" className="sr-only">
                      Minimum Salary
                    </label>
                    <input
                      type="number"
                      name="salary-min"
                      id="salary-min"
                      placeholder="Min"
                      value={salaryRange.min}
                      onChange={(e) => setSalaryRange({ ...salaryRange, min: e.target.value })}
                      className="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                    />
                  </div>
                  <div>
                    <label htmlFor="salary-max" className="sr-only">
                      Maximum Salary
                    </label>
                    <input
                      type="number"
                      name="salary-max"
                      id="salary-max"
                      placeholder="Max"
                      value={salaryRange.max}
                      onChange={(e) => setSalaryRange({ ...salaryRange, max: e.target.value })}
                      className="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                    />
                  </div>
                  <div>
                    <label htmlFor="salary-currency" className="sr-only">
                      Currency
                    </label>
                    <select
                      id="salary-currency"
                      name="salary-currency"
                      value={salaryRange.currency}
                      onChange={(e) => setSalaryRange({ ...salaryRange, currency: e.target.value })}
                      className="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                    >
                      <option value="USD">USD</option>
                      <option value="EUR">EUR</option>
                      <option value="GBP">GBP</option>
                    </select>
                  </div>
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