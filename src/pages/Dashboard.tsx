import React from 'react';
import Layout from '../components/Layout';
import { useAuth } from '../lib/auth';
import { supabase } from '../lib/supabase';
import { formatDistanceToNow } from 'date-fns';
import {
  Users,
  Briefcase,
  CheckCircle,
  Clock,
  ArrowRight,
  UserPlus,
  Building2
} from 'lucide-react';

interface DashboardStats {
  totalCandidates: number;
  activeJobs: number;
  totalHires: number;
  openPositions: number;
}

interface ActivityItem {
  id: string;
  type: 'new_candidate' | 'stage_change' | 'new_job' | 'candidate_hired';
  candidateName?: string;
  jobTitle?: string;
  stageName?: string;
  timestamp: string;
}

export default function Dashboard() {
  const { user } = useAuth();
  const [stats, setStats] = React.useState<DashboardStats>({
    totalCandidates: 0,
    activeJobs: 0,
    totalHires: 0,
    openPositions: 0,
  });
  const [activity, setActivity] = React.useState<ActivityItem[]>([]);
  const [loading, setLoading] = React.useState(true);

  React.useEffect(() => {
    async function fetchDashboardData() {
      try {
        // Fetch total candidates
        const { count: candidatesCount } = await supabase
          .from('candidates')
          .select('*', { count: 'exact', head: true });

        // Fetch active jobs
        const { count: activeJobsCount } = await supabase
          .from('jobs')
          .select('*', { count: 'exact', head: true })
          .eq('status', 'published');

        // Fetch hired candidates
        const { count: hiresCount } = await supabase
          .from('candidates')
          .select('*', { count: 'exact', head: true })
          .eq('status', 'hired');

        // Fetch open positions
        const { count: openPositionsCount } = await supabase
          .from('jobs')
          .select('*', { count: 'exact', head: true })
          .eq('status', 'published');

        setStats({
          totalCandidates: candidatesCount || 0,
          activeJobs: activeJobsCount || 0,
          totalHires: hiresCount || 0,
          openPositions: openPositionsCount || 0,
        });

        // Fetch recent activity
        const { data: recentCandidates } = await supabase
          .from('candidates')
          .select(`
            id,
            first_name,
            last_name,
            created_at,
            jobs (
              title
            )
          `)
          .order('created_at', { ascending: false })
          .limit(5);

        const { data: recentStageChanges } = await supabase
          .from('candidate_stages')
          .select(`
            id,
            created_at,
            candidates (
              first_name,
              last_name
            ),
            pipeline_stages (
              name
            )
          `)
          .order('created_at', { ascending: false })
          .limit(5);

        // Combine and sort activity
        const combinedActivity: ActivityItem[] = [
          ...(recentCandidates?.map(candidate => ({
            id: candidate.id,
            type: 'new_candidate' as const,
            candidateName: `${candidate.first_name} ${candidate.last_name}`,
            jobTitle: (candidate as any).jobs?.title,
            timestamp: candidate.created_at,
          })) || []),
          ...(recentStageChanges?.map(change => ({
            id: change.id,
            type: 'stage_change' as const,
            candidateName: `${(change as any).candidates.first_name} ${(change as any).candidates.last_name}`,
            stageName: (change as any).pipeline_stages.name,
            timestamp: change.created_at,
          })) || []),
        ].sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());

        setActivity(combinedActivity.slice(0, 10));
      } catch (error) {
        console.error('Error fetching dashboard data:', error);
      } finally {
        setLoading(false);
      }
    }

    fetchDashboardData();
  }, []);

  const getActivityIcon = (type: ActivityItem['type']) => {
    switch (type) {
      case 'new_candidate':
        return <UserPlus className="h-5 w-5 text-blue-500" />;
      case 'stage_change':
        return <ArrowRight className="h-5 w-5 text-green-500" />;
      case 'new_job':
        return <Briefcase className="h-5 w-5 text-purple-500" />;
      case 'candidate_hired':
        return <CheckCircle className="h-5 w-5 text-green-500" />;
      default:
        return null;
    }
  };

  const getActivityMessage = (item: ActivityItem) => {
    switch (item.type) {
      case 'new_candidate':
        return `${item.candidateName} applied for ${item.jobTitle}`;
      case 'stage_change':
        return `${item.candidateName} moved to ${item.stageName}`;
      case 'new_job':
        return `New position opened: ${item.jobTitle}`;
      case 'candidate_hired':
        return `${item.candidateName} was hired`;
      default:
        return '';
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
        <h1 className="text-2xl font-semibold text-gray-900">Dashboard</h1>
        
        <div className="mt-6 grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <Users className="h-6 w-6 text-gray-400" />
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">
                      Total Candidates
                    </dt>
                    <dd className="text-lg font-semibold text-gray-900">
                      {stats.totalCandidates}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <Briefcase className="h-6 w-6 text-gray-400" />
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">
                      Active Jobs
                    </dt>
                    <dd className="text-lg font-semibold text-gray-900">
                      {stats.activeJobs}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <CheckCircle className="h-6 w-6 text-gray-400" />
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">
                      Total Hires
                    </dt>
                    <dd className="text-lg font-semibold text-gray-900">
                      {stats.totalHires}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <Building2 className="h-6 w-6 text-gray-400" />
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">
                      Open Positions
                    </dt>
                    <dd className="text-lg font-semibold text-gray-900">
                      {stats.openPositions}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className="mt-8">
          <h2 className="text-lg font-medium text-gray-900">Recent Activity</h2>
          <div className="mt-4 bg-white shadow rounded-lg">
            <ul role="list" className="divide-y divide-gray-200">
              {activity.map((item) => (
                <li key={item.id} className="px-4 py-4">
                  <div className="flex items-center space-x-4">
                    <div className="flex-shrink-0">
                      {getActivityIcon(item.type)}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-gray-900 truncate">
                        {getActivityMessage(item)}
                      </p>
                      <p className="text-sm text-gray-500">
                        {formatDistanceToNow(new Date(item.timestamp), { addSuffix: true })}
                      </p>
                    </div>
                  </div>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </div>
    </Layout>
  );
}