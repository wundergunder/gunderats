import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '../lib/auth';
import {
  LayoutDashboard,
  Briefcase,
  Users,
  Settings,
  LogOut,
  Menu,
  X,
  FileSpreadsheet
} from 'lucide-react';

const navigation = [
  { name: 'Dashboard', href: '/dashboard', icon: LayoutDashboard },
  { name: 'Jobs', href: '/jobs', icon: Briefcase },
  { name: 'Candidates', href: '/candidates', icon: Users },
  { name: 'Settings', href: '/settings', icon: Settings },
];

export default function Layout({ children }: { children: React.ReactNode }) {
  const [sidebarOpen, setSidebarOpen] = React.useState(false);
  const location = useLocation();
  const { signOut } = useAuth();

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Mobile sidebar */}
      <div className={`fixed inset-0 z-40 lg:hidden ${sidebarOpen ? '' : 'hidden'}`}>
        <div className="fixed inset-0 bg-gray-600 bg-opacity-75" onClick={() => setSidebarOpen(false)} />
        
        <div className="fixed inset-y-0 left-0 flex w-64 flex-col bg-indigo-700">
          <div className="flex h-16 items-center justify-between px-4">
            <div className="flex items-center">
              <FileSpreadsheet className="h-8 w-8 text-white" />
              <span className="ml-2 text-xl font-bold text-white">Gunder ATS</span>
            </div>
            <button onClick={() => setSidebarOpen(false)}>
              <X className="h-6 w-6 text-white" />
            </button>
          </div>
          
          <nav className="flex-1 space-y-1 px-2 py-4">
            {navigation.map((item) => {
              const Icon = item.icon;
              const isActive = location.pathname === item.href;
              return (
                <Link
                  key={item.name}
                  to={item.href}
                  className={`group flex items-center px-2 py-2 text-sm font-medium rounded-md ${
                    isActive
                      ? 'bg-indigo-800 text-white'
                      : 'text-indigo-100 hover:bg-indigo-600'
                  }`}
                >
                  <Icon className="mr-3 h-6 w-6 flex-shrink-0" />
                  {item.name}
                </Link>
              );
            })}
          </nav>

          <div className="border-t border-indigo-800 p-4">
            <button
              onClick={() => signOut()}
              className="group flex w-full items-center px-2 py-2 text-sm font-medium rounded-md text-indigo-100 hover:bg-indigo-600"
            >
              <LogOut className="mr-3 h-6 w-6" />
              Sign out
            </button>
          </div>
        </div>
      </div>

      {/* Desktop sidebar */}
      <div className="hidden lg:fixed lg:inset-y-0 lg:flex lg:w-64 lg:flex-col">
        <div className="flex flex-col flex-grow bg-indigo-700 pt-5 pb-4">
          <div className="flex items-center flex-shrink-0 px-4">
            <FileSpreadsheet className="h-8 w-8 text-white" />
            <span className="ml-2 text-xl font-bold text-white">Gunder ATS</span>
          </div>
          
          <nav className="mt-5 flex-1 space-y-1 px-2">
            {navigation.map((item) => {
              const Icon = item.icon;
              const isActive = location.pathname === item.href;
              return (
                <Link
                  key={item.name}
                  to={item.href}
                  className={`group flex items-center px-2 py-2 text-sm font-medium rounded-md ${
                    isActive
                      ? 'bg-indigo-800 text-white'
                      : 'text-indigo-100 hover:bg-indigo-600'
                  }`}
                >
                  <Icon className="mr-3 h-6 w-6 flex-shrink-0" />
                  {item.name}
                </Link>
              );
            })}
          </nav>

          <div className="border-t border-indigo-800 p-4">
            <button
              onClick={() => signOut()}
              className="group flex w-full items-center px-2 py-2 text-sm font-medium rounded-md text-indigo-100 hover:bg-indigo-600"
            >
              <LogOut className="mr-3 h-6 w-6" />
              Sign out
            </button>
          </div>
        </div>
      </div>

      {/* Main content */}
      <div className="lg:pl-64 flex flex-col flex-1">
        <div className="sticky top-0 z-10 bg-white pl-1 pt-1 sm:pl-3 sm:pt-3 lg:hidden">
          <button
            type="button"
            className="-ml-0.5 -mt-0.5 inline-flex h-12 w-12 items-center justify-center rounded-md text-gray-500 hover:text-gray-900 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-indigo-500"
            onClick={() => setSidebarOpen(true)}
          >
            <span className="sr-only">Open sidebar</span>
            <Menu className="h-6 w-6" />
          </button>
        </div>

        <main className="flex-1">
          <div className="py-6">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}