import React from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import type { Company } from '../types/database';

interface CompanySelectorProps {
  selectedCompanyId?: string;
  onCompanyChange?: (companyId: string) => void;
  className?: string;
}

export default function CompanySelector({ selectedCompanyId, onCompanyChange, className = '' }: CompanySelectorProps) {
  const [companies, setCompanies] = React.useState<Company[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();

  // Get the company ID from URL if not provided as prop
  const currentCompanyId = selectedCompanyId || searchParams.get('company') || '';

  React.useEffect(() => {
    async function fetchCompanies() {
      try {
        const userId = (await supabase.auth.getUser()).data.user?.id;
        if (!userId) throw new Error('No user found');

        // First check if user is admin in any company
        const { data: adminCheck, error: adminError } = await supabase
          .from('team_members')
          .select('role')
          .eq('user_id', userId)
          .eq('role', 'admin')
          .maybeSingle();

        if (adminError) throw adminError;

        // If admin, get all companies
        if (adminCheck?.role === 'admin') {
          const { data: allCompanies, error: allCompaniesError } = await supabase
            .from('companies')
            .select('*')
            .order('name');

          if (allCompaniesError) throw allCompaniesError;
          setCompanies(allCompanies || []);
        } else {
          // If not admin, get only companies where user is a member
          const { data: userCompanies, error: userCompaniesError } = await supabase
            .from('companies')
            .select('*')
            .in('id', (
              supabase
                .from('team_members')
                .select('company_id')
                .eq('user_id', userId)
            ))
            .order('name');

          if (userCompaniesError) throw userCompaniesError;
          setCompanies(userCompanies || []);
        }

        // If no company is selected and we have companies, select the first one
        if (!currentCompanyId && companies.length > 0) {
          const firstCompany = companies[0];
          if (onCompanyChange) {
            onCompanyChange(firstCompany.id);
          } else {
            navigate(`${window.location.pathname}?company=${firstCompany.id}`);
          }
        }
      } catch (error) {
        console.error('Error fetching companies:', error);
      } finally {
        setLoading(false);
      }
    }

    fetchCompanies();
  }, [currentCompanyId, onCompanyChange, navigate, companies.length]);

  const handleChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const companyId = e.target.value;
    if (onCompanyChange) {
      onCompanyChange(companyId);
    } else {
      // Keep the current path but update the company param
      navigate(`${window.location.pathname}?company=${companyId}`);
    }
  };

  if (loading) {
    return (
      <div className={`inline-flex items-center ${className}`}>
        <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  if (companies.length === 0) {
    return null;
  }

  return (
    <select
      value={currentCompanyId}
      onChange={handleChange}
      className={`block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md ${className}`}
    >
      <option value="">Select Company</option>
      {companies.map((company) => (
        <option key={company.id} value={company.id}>
          {company.name}
        </option>
      ))}
    </select>
  );
}