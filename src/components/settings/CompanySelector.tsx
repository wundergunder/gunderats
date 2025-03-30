import React from 'react';
import type { Company } from '../../types/database';

interface CompanySelectorProps {
  companies: Company[];
  selectedCompanyId: string;
  onCompanyChange: (companyId: string) => void;
}

export default function CompanySelector({ companies, selectedCompanyId, onCompanyChange }: CompanySelectorProps) {
  return (
    <div className="bg-white shadow sm:rounded-lg">
      <div className="px-4 py-5 sm:p-6">
        <h3 className="text-lg leading-6 font-medium text-gray-900">
          Select Company
        </h3>
        <div className="mt-2">
          <select
            value={selectedCompanyId}
            onChange={(e) => onCompanyChange(e.target.value)}
            className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
          >
            {companies.map((company) => (
              <option key={company.id} value={company.id}>
                {company.name}
              </option>
            ))}
          </select>
        </div>
      </div>
    </div>
  );
}