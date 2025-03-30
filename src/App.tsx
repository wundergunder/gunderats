import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './lib/auth';
import Login from './pages/Login';
import Register from './pages/Register';
import Dashboard from './pages/Dashboard';
import Jobs from './pages/Jobs';
import Candidates from './pages/Candidates';
import Settings from './pages/Settings';
import { RequireAuth } from './lib/auth';

function App() {
  return (
    <Router>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          
          {/* Protected routes */}
          <Route path="/dashboard" element={
            <RequireAuth>
              <Dashboard />
            </RequireAuth>
          } />
          <Route path="/jobs" element={
            <RequireAuth>
              <Jobs />
            </RequireAuth>
          } />
          <Route path="/candidates" element={
            <RequireAuth>
              <Candidates />
            </RequireAuth>
          } />
          <Route path="/settings" element={
            <RequireAuth>
              <Settings />
            </RequireAuth>
          } />
          
          <Route path="/" element={<Navigate to="/login" replace />} />
        </Routes>
      </AuthProvider>
    </Router>
  );
}

export default App;