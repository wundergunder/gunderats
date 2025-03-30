import React from 'react';
import Layout from '../components/Layout';
import { useAuth } from '../lib/auth';
import { supabase } from '../lib/supabase';
import type { Company, TeamMember, PipelineStage } from '../types/database';
import { Plus, Trash2 } from 'lucide-react';

export default function Settings() {
  const { user } = useAuth();
  const [loading, setLoading] = React.useState(true);
  const [saving, setSaving] = React.useState(false);
  const [saved, setSaved] = React.useState(false);
  const [error, setError] = React.useState('');
  const [company, setCompany] = React.useState<Company | null>(null);
  const [stages, setStages] = React.useState<PipelineStage[]>([]);
  const [teamMembers, setTeamMembers] = React.useState<TeamMember[]>([]);
  const [newTeamMemberEmail, setNewTeamMemberEmail] = React.useState('');
  const [newStageName, setNewStageName] = React.useState('');

  React.useEffect(() => {
    async function fetchData() {
      try {
        // Fetch company data
        const { data: companyData, error: companyError } = await supabase
          .from('companies')
          .select('*')
          .single();

        if (companyError) throw companyError;
        setCompany(companyData);

        // Fetch pipeline stages
        const { data: stagesData, error: stagesError } = await supabase
          .from('pipeline_stages')
          .select('*')
          .order('order_index', { ascending: true });

        if (stagesError) throw stagesError;
        setStages(stagesData || []);

        // Fetch team members with user emails from view
        const { data: teamData, error: teamError } = await supabase
          .from('team_members_with_profiles')
          .select('*');

        if (teamError) throw teamError;
        setTeamMembers(teamData || []);
      } catch (error) {
        console.error('Error fetching settings data:', error);
        setError('Failed to load settings');
      } finally {
        setLoading(false);
      }
    }

    fetchData();
  }, []);

  const handleCompanyUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!company) return;

    setSaving(true);
    setSaved(false);
    setError('');

    try {
      const { error } = await supabase
        .from('companies')
        .update({
          name: company.name,
          settings: company.settings,
          updated_at: new Date().toISOString(),
        })
        .eq('id', company.id);

      if (error) throw error;
      setSaved(true);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleAddStage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newStageName.trim() || !company) return;

    setSaving(true);
    setError('');

    try {
      const { data, error } = await supabase
        .from('pipeline_stages')
        .insert([{
          name: newStageName.trim(),
          order_index: stages.length,
          company_id: company.id
        }])
        .select()
        .single();

      if (error) throw error;
      setStages([...stages, data]);
      setNewStageName('');
    } catch (err: any) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleDeleteStage = async (stageId: string) => {
    if (!confirm('Are you sure you want to delete this stage? This action cannot be undone.')) return;

    try {
      const { error } = await supabase
        .from('pipeline_stages')
        .delete()
        .eq('id', stageId);

      if (error) throw error;
      setStages(stages.filter(stage => stage.id !== stageId));
    } catch (err: any) {
      setError(err.message);
    }
  };

  const handleAddTeamMember = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTeamMemberEmail.trim() || !company) return;

    setSaving(true);
    setError('');

    try {
      // First get the user ID from auth.users
      const { data: userData, error: userError } = await supabase
        .from('profiles')
        .select('id')
        .eq('email', newTeamMemberEmail.trim())
        .single();

      if (userError) {
        throw new Error('User not found. Please ensure they have registered first.');
      }

      const { error: teamError } = await supabase
        .from('team_members')
        .insert([{
          user_id: userData.id,
          company_id: company.id,
          role: 'member',
        }]);

      if (teamError) throw teamError;

      // Refresh team members list
      const { data: teamData, error: refreshError } = await supabase
        .from('team_members_with_profiles')
        .select('*');

      if (refreshError) throw refreshError;
      setTeamMembers(teamData || []);
      setNewTeamMemberEmail('');
    } catch (err: any) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleRemoveTeamMember = async (memberId: string) => {
    if (!confirm('Are you sure you want to remove this team member?')) return;

    try {
      const { error } = await supabase
        .from('team_members')
        .delete()
        .eq('id', memberId);

      if (error) throw error;
      setTeamMembers(teamMembers.filter(member => member.id !== memberId));
    } catch (err: any) {
      setError(err.message);
    }
  };

  if (loading) {
    return (
      <Layout>
        <div className="flex justify-center items-center h-64">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
        </div>
      </Layout>
    );
  }

  return (
    <Layout>
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="space-y-6 sm:px-6 lg:px-0 lg:col-span-9">
          <form onSubmit={handleCompanyUpdate}>
            <div className="shadow sm:rounded-md sm:overflow-hidden">
              <div className="bg-white py-6 px-4 space-y-6 sm:p-6">
                <div>
                  <h3 className="text-lg leading-6 font-medium text-gray-900">Company Settings</h3>
                  <p className="mt-1 text-sm text-gray-500">
                    Manage your company profile and preferences
                  </p>
                </div>

                {error && (
                  <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-md text-sm">
                    {error}
                  </div>
                )}

                <div className="grid grid-cols-6 gap-6">
                  <div className="col-span-6 sm:col-span-3">
                    <label htmlFor="company-name" className="block text-sm font-medium text-gray-700">
                      Company name
                    </label>
                    <input
                      type="text"
                      name="company-name"
                      id="company-name"
                      value={company?.name || ''}
                      onChange={(e) => setCompany(prev => prev ? { ...prev, name: e.target.value } : null)}
                      className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    />
                  </div>
                </div>
              </div>
              <div className="px-4 py-3 bg-gray-50 text-right sm:px-6">
                {saved && (
                  <span className="mr-3 text-sm text-green-600">
                    Settings saved successfully
                  </span>
                )}
                <button
                  type="submit"
                  disabled={saving}
                  className="bg-indigo-600 border border-transparent rounded-md shadow-sm py-2 px-4 inline-flex justify-center text-sm font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  {saving ? 'Saving...' : 'Save'}
                </button>
              </div>
            </div>
          </form>

          <div className="shadow sm:rounded-md sm:overflow-hidden">
            <div className="bg-white py-6 px-4 space-y-6 sm:p-6">
              <div>
                <h3 className="text-lg leading-6 font-medium text-gray-900">Pipeline Stages</h3>
                <p className="mt-1 text-sm text-gray-500">
                  Customize your hiring pipeline stages
                </p>
              </div>

              <div className="space-y-4">
                {stages.map((stage) => (
                  <div key={stage.id} className="flex items-center justify-between bg-gray-50 rounded-md p-3">
                    <span className="text-sm font-medium text-gray-900">{stage.name}</span>
                    <button
                      type="button"
                      onClick={() => handleDeleteStage(stage.id)}
                      className="text-red-600 hover:text-red-900"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                ))}

                <form onSubmit={handleAddStage} className="mt-4">
                  <div className="flex space-x-3">
                    <input
                      type="text"
                      value={newStageName}
                      onChange={(e) => setNewStageName(e.target.value)}
                      placeholder="New stage name"
                      className="flex-1 shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                    />
                    <button
                      type="submit"
                      disabled={!newStageName.trim() || saving}
                      className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
                    >
                      <Plus className="h-4 w-4 mr-2" />
                      Add Stage
                    </button>
                  </div>
                </form>
              </div>
            </div>
          </div>

          <div className="shadow sm:rounded-md sm:overflow-hidden">
            <div className="bg-white py-6 px-4 space-y-6 sm:p-6">
              <div>
                <h3 className="text-lg leading-6 font-medium text-gray-900">Team Members</h3>
                <p className="mt-1 text-sm text-gray-500">
                  Manage your team and their permissions
                </p>
              </div>

              <div className="space-y-4">
                {teamMembers.map((member) => (
                  <div key={member.id} className="flex items-center justify-between bg-gray-50 rounded-md p-3">
                    <div>
                      <p className="text-sm font-medium text-gray-900">
                        {(member as any).user_email}
                      </p>
                      <p className="text-sm text-gray-500 capitalize">
                        {member.role}
                      </p>
                    </div>
                    <button
                      type="button"
                      onClick={() => handleRemoveTeamMember(member.id)}
                      className="text-red-600 hover:text-red-900"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                ))}

                <form onSubmit={handleAddTeamMember} className="mt-4">
                  <div className="flex space-x-3">
                    <input
                      type="email"
                      value={newTeamMemberEmail}
                      onChange={(e) => setNewTeamMemberEmail(e.target.value)}
                      placeholder="team@company.com"
                      className="flex-1 shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                    />
                    <button
                      type="submit"
                      disabled={!newTeamMemberEmail.trim() || saving}
                      className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
                    >
                      <Plus className="h-4 w-4 mr-2" />
                      Add Member
                    </button>
                  </div>
                </form>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
}