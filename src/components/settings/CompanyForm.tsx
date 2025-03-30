import React from 'react';
import type { Company } from '../../types/database';

interface CompanyFormProps {
  company: Company | null;
  onSave: (company: Company) => Promise<void>;
  saving: boolean;
  saved: boolean;
  error: string;
}

export default function CompanyForm({ company, onSave, saving, saved, error }: CompanyFormProps) {
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!company) return;
    await onSave(company);
  };

  return (
    <form onSubmit={handleSubmit}>
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
                onChange={(e) => company && onSave({ ...company, name: e.target.value })}
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
  );
}