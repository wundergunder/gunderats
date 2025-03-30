import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { 
  FileSpreadsheet,
  CheckCircle2,
  Zap,
  Users,
  Clock,
  Shield,
  Workflow,
  Globe,
  MessageSquare,
  BarChart3
} from 'lucide-react';
import { supabase } from '../lib/supabase';

const benefits = [
  {
    icon: Zap,
    title: "AI-Powered Candidate Matching",
    description: "Smart algorithms match candidates to roles based on skills, experience, and cultural fit."
  },
  {
    icon: Users,
    title: "Collaborative Hiring",
    description: "Team feedback, shared notes, and structured interview scorecards all in one place."
  },
  {
    icon: Clock,
    title: "Automated Workflows",
    description: "Automate repetitive tasks, from scheduling interviews to sending offer letters."
  },
  {
    icon: Shield,
    title: "Enterprise Security",
    description: "Bank-level encryption, GDPR compliance, and role-based access control."
  },
  {
    icon: Workflow,
    title: "Custom Hiring Pipelines",
    description: "Create unique workflows for different positions and departments."
  },
  {
    icon: Globe,
    title: "Multi-Channel Sourcing",
    description: "Post to multiple job boards and track applicant sources automatically."
  },
  {
    icon: MessageSquare,
    title: "Integrated Communication",
    description: "Email templates, automated notifications, and candidate messaging."
  },
  {
    icon: BarChart3,
    title: "Advanced Analytics",
    description: "Track key metrics like time-to-hire, source effectiveness, and pipeline velocity."
  }
];

export default function Register() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [companyName, setCompanyName] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    // Validate inputs
    if (!companyName.trim()) {
      setError('Company name is required');
      setLoading(false);
      return;
    }

    if (!email.trim()) {
      setError('Email is required');
      setLoading(false);
      return;
    }

    if (!password || password.length < 6) {
      setError('Password must be at least 6 characters');
      setLoading(false);
      return;
    }

    try {
      // Create the user account with company metadata
      const { data, error: signUpError } = await supabase.auth.signUp({
        email: email.trim(),
        password,
        options: {
          data: {
            company_name: companyName.trim()
          }
        }
      });

      if (signUpError) {
        // Handle specific error codes
        if (signUpError.message.includes('CMPNY')) {
          throw new Error('Company name already exists');
        } else if (signUpError.message.includes('EMAIL')) {
          throw new Error('Email is already registered');
        } else {
          throw signUpError;
        }
      }

      // Check if the user was created successfully
      if (!data?.user?.id) {
        throw new Error('Failed to create user account');
      }

      // Success - navigate to dashboard
      navigate('/dashboard');
    } catch (err: any) {
      console.error('Registration error:', err);
      setError(err.message || 'An error occurred during registration');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="grid grid-cols-1 lg:grid-cols-2">
        {/* Registration Form */}
        <div className="flex flex-col justify-center py-12 px-4 sm:px-6 lg:px-8">
          <div className="mx-auto w-full max-w-md">
            <div className="flex justify-center">
              <FileSpreadsheet className="h-12 w-12 text-indigo-600" />
            </div>
            <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
              Start hiring better today
            </h2>
            <p className="mt-2 text-center text-sm text-gray-600">
              Join thousands of companies using Gunder ATS to streamline their hiring
            </p>

            <form className="mt-8 space-y-6" onSubmit={handleRegister}>
              {error && (
                <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-md text-sm">
                  {error}
                </div>
              )}

              <div>
                <label htmlFor="company" className="block text-sm font-medium text-gray-700">
                  Company name
                </label>
                <div className="mt-1">
                  <input
                    id="company"
                    name="company"
                    type="text"
                    required
                    value={companyName}
                    onChange={(e) => setCompanyName(e.target.value)}
                    className="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    placeholder="Enter your company name"
                  />
                </div>
              </div>

              <div>
                <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                  Work email
                </label>
                <div className="mt-1">
                  <input
                    id="email"
                    name="email"
                    type="email"
                    autoComplete="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    placeholder="you@company.com"
                  />
                </div>
              </div>

              <div>
                <label htmlFor="password" className="block text-sm font-medium text-gray-700">
                  Password
                </label>
                <div className="mt-1">
                  <input
                    id="password"
                    name="password"
                    type="password"
                    autoComplete="new-password"
                    required
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    placeholder="Create a secure password"
                    minLength={6}
                  />
                </div>
              </div>

              <div>
                <button
                  type="submit"
                  disabled={loading}
                  className="w-full flex justify-center py-3 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 transition-colors duration-200"
                >
                  {loading ? 'Creating your account...' : 'Create your free account'}
                </button>
              </div>

              <div className="text-center text-xs text-gray-500">
                By signing up, you agree to our Terms of Service and Privacy Policy
              </div>
            </form>

            <div className="mt-6 text-center">
              <p className="text-sm text-gray-600">
                Already have an account?{' '}
                <Link to="/login" className="font-medium text-indigo-600 hover:text-indigo-500">
                  Sign in
                </Link>
              </p>
            </div>
          </div>
        </div>

        {/* Benefits Section */}
        <div className="hidden lg:block bg-indigo-600">
          <div className="flex flex-col justify-center min-h-screen px-8 lg:px-12 py-12">
            <div className="w-full max-w-lg mx-auto">
              <h2 className="text-3xl font-extrabold text-white sm:text-4xl mb-4">
                The modern way to hire
              </h2>
              <p className="text-xl text-indigo-200 mb-8">
                Everything you need to attract, evaluate, and hire the best talent.
              </p>
              
              <div className="grid grid-cols-1 gap-6">
                {benefits.map((benefit, index) => {
                  const Icon = benefit.icon;
                  return (
                    <div key={index} className="flex items-start space-x-4 bg-indigo-500/20 rounded-lg p-4">
                      <div className="flex-shrink-0">
                        <Icon className="h-6 w-6 text-indigo-300" />
                      </div>
                      <div>
                        <h3 className="text-lg font-semibold text-white">
                          {benefit.title}
                        </h3>
                        <p className="mt-1 text-indigo-200">
                          {benefit.description}
                        </p>
                      </div>
                    </div>
                  );
                })}
              </div>

              <div className="mt-8 pt-8 border-t border-indigo-500">
                <div className="flex items-center justify-between text-indigo-200">
                  <div className="flex items-center space-x-2">
                    <CheckCircle2 className="h-5 w-5" />
                    <span>Free 14-day trial</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <CheckCircle2 className="h-5 w-5" />
                    <span>No credit card required</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}