import React from 'react';
import { Plus, Trash2 } from 'lucide-react';
import type { TeamMember } from '../../types/database';

interface TeamMembersProps {
  teamMembers: TeamMember[];
  onMemberAdd: (email: string) => Promise<void>;
  onMemberRemove: (id: string) => Promise<void>;
  saving: boolean;
  error: string;
}

export default function TeamMembers({ 
  teamMembers, 
  onMemberAdd, 
  onMemberRemove, 
  saving,
  error 
}: TeamMembersProps) {
  const [newTeamMemberEmail, setNewTeamMemberEmail] = React.useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTeamMemberEmail.trim()) return;
    await onMemberAdd(newTeamMemberEmail);
    setNewTeamMemberEmail('');
  };

  return (
    <div className="shadow sm:rounded-md sm:overflow-hidden">
      <div className="bg-white py-6 px-4 space-y-6 sm:p-6">
        <div>
          <h3 className="text-lg leading-6 font-medium text-gray-900">Team Members</h3>
          <p className="mt-1 text-sm text-gray-500">
            Manage your team and their permissions
          </p>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-md text-sm">
            {error}
          </div>
        )}

        <div className="space-y-4">
          {teamMembers.map((member) => (
            <div key={member.id} className="flex items-center justify-between bg-gray-50 rounded-md p-3">
              <div>
                <p className="text-sm font-medium text-gray-900">
                  {(member as any).user?.email}
                </p>
                <p className="text-sm text-gray-500 capitalize">
                  {member.role}
                </p>
              </div>
              <button
                type="button"
                onClick={() => onMemberRemove(member.id)}
                className="text-red-600 hover:text-red-900"
              >
                <Trash2 className="h-4 w-4" />
              </button>
            </div>
          ))}

          <form onSubmit={handleSubmit} className="mt-4">
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
  );
}