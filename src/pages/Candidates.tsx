import React from 'react';
import Layout from '../components/Layout';
import CandidateForm from '../components/CandidateForm';
import CandidateDetails from '../components/CandidateDetails';
import { useAuth } from '../lib/auth';
import { supabase } from '../lib/supabase';
import type { Candidate } from '../types/database';
import { Plus, Eye, Trash2 } from 'lucide-react';

export default function Candidates() {
  const { user } = useAuth();
  const [candidates, setCandidates] = React.useState<Candidate[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [showForm, setShowForm] = React.useState(false);
  const [selectedCandidate, setSelectedCandidate] = React.useState<Candidate | null>(null);
  const [showDetails, setShowDetails] = React.useState(false);

  const fetchCandidates = React.useCallback(async () => {
    try {
      const { data, error } = await supabase
        .from('candidates')
        .select(`
          *,
          jobs (
            title
          ),
          pipeline_stages (
            name
          )
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setCandidates(data || []);
    } catch (error) {
      console.error('Error fetching candidates:', error);
    } finally {
      setLoading(false);
    }
  }, []);

  React.useEffect(() => {
    fetchCandidates();
  }, [fetchCandidates]);

  const handleDelete = async (candidateId: string) => {
    if (!confirm('Are you sure you want to delete this candidate?')) return;

    try {
      const { error } = await supabase
        .from('candidates')
        .delete()
        .eq('id', candidateId);

      if (error) throw error;
      await fetchCandidates();
    } catch (error) {
      console.error('Error deleting candidate:', error);
    }
  };

  const handleFormClose = () => {
    setShowForm(false);
    setSelectedCandidate(null);
  };

  const handleFormSave = () => {
    fetchCandidates();
  };

  const handleViewDetails = (candidate: Candidate) => {
    setSelectedCandidate(candidate);
    setShowDetails(true);
  };

  const handleDetailsClose = () => {
    setShowDetails(false);
    setSelectedCandidate(null);
  };

  return (
    <Layout>
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="sm:flex sm:items-center">
          <div className="sm:flex-auto">
            <h1 className="text-2xl font-semibold text-gray-900">Candidates</h1>
            <p className="mt-2 text-sm text-gray-700">
              A list of all candidates in your hiring pipeline
            </p>
          </div>
          <div className="mt-4 sm:mt-0 sm:ml-16 sm:flex-none">
            <button
              type="button"
              onClick={() => setShowForm(true)}
              className="inline-flex items-center justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 sm:w-auto"
            >
              <Plus className="h-4 w-4 mr-2" />
              Add candidate
            </button>
          </div>
        </div>

        {loading ? (
          <div className="mt-6 flex justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
          </div>
        ) : candidates.length === 0 ? (
          <div className="mt-6 text-center">
            <p className="text-sm text-gray-500">No candidates found</p>
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
                          Name
                        </th>
                        <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                          Job
                        </th>
                        <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                          Stage
                        </th>
                        <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                          Status
                        </th>
                        <th scope="col" className="relative py-3.5 pl-3 pr-4 sm:pr-6">
                          <span className="sr-only">Actions</span>
                        </th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200 bg-white">
                      {candidates.map((candidate) => (
                        <tr key={candidate.id}>
                          <td className="whitespace-nowrap py-4 pl-4 pr-3 text-sm sm:pl-6">
                            <div className="font-medium text-gray-900">
                              {candidate.first_name} {candidate.last_name}
                            </div>
                            <div className="text-gray-500">{candidate.email}</div>
                          </td>
                          <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                            {(candidate as any).jobs?.title}
                          </td>
                          <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                            {(candidate as any).pipeline_stages?.name}
                          </td>
                          <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                            <span className={`inline-flex rounded-full px-2 text-xs font-semibold leading-5 ${
                              candidate.status === 'active' 
                                ? 'bg-green-100 text-green-800'
                                : 'bg-gray-100 text-gray-800'
                            }`}>
                              {candidate.status}
                            </span>
                          </td>
                          <td className="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6">
                            <button
                              onClick={() => handleViewDetails(candidate)}
                              className="text-indigo-600 hover:text-indigo-900 mr-4"
                            >
                              <Eye className="h-4 w-4" />
                              <span className="sr-only">View</span>
                            </button>
                            <button
                              onClick={() => handleDelete(candidate.id)}
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
          <CandidateForm
            onClose={handleFormClose}
            onSave={handleFormSave}
          />
        )}

        {showDetails && selectedCandidate && (
          <CandidateDetails
            candidate={selectedCandidate}
            onClose={handleDetailsClose}
            onUpdate={fetchCandidates}
          />
        )}
      </div>
    </Layout>
  );
}