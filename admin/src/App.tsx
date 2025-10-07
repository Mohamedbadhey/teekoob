import React, { useEffect } from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import { useSelector, useDispatch } from 'react-redux'
import { Box, CircularProgress } from '@mui/material'
import { RootState, AppDispatch } from './store'
import { getCurrentUser, validateToken, clearAuth } from './store/slices/authSlice'

// Components
import Layout from './components/Layout/Layout'
import LoginPage from './pages/Auth/LoginPage'
import DashboardPage from './pages/Dashboard/DashboardPage'
import BooksPage from './pages/Books/BooksPage'
import BookFormPage from './pages/Books/BookFormPage'
import PodcastsPage from './pages/Podcasts/PodcastsPage'
import PodcastEpisodesPage from './pages/Podcasts/PodcastEpisodesPage'
import UserManagementPage from './pages/Users/UserManagementPage'
import UserDetailPage from './pages/Users/UserDetailPage'
import CategoriesPage from './pages/Categories/CategoriesPage'
import AnalyticsPage from './pages/Analytics/AnalyticsPage'
import SettingsPage from './pages/Settings/SettingsPage'
import NotFoundPage from './pages/NotFound/NotFoundPage'
import ContentModerationPage from './pages/Moderation/ContentModerationPage'
import PlaceholderPage from './pages/PlaceholderPage'

// Protected Route Component
const ProtectedRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated, isLoading, user } = useSelector((state: RootState) => state.auth)
  
  // Debug logging
  console.log('ProtectedRoute state:', { isAuthenticated, isLoading, user: user?.isAdmin })
  
  // Show loading if we're checking authentication
  if (isLoading) {
    console.log('ProtectedRoute: showing loading')
    return (
      <Box
        display="flex"
        justifyContent="center"
        alignItems="center"
        minHeight="100vh"
      >
        <CircularProgress />
      </Box>
    )
  }
  
  // If not authenticated, redirect to login
  if (!isAuthenticated) {
    console.log('ProtectedRoute: not authenticated, redirecting to login')
    return <Navigate to="/login" replace />
  }
  
  // If authenticated but not admin, redirect to login with error message
  if (!user?.isAdmin) {
    console.log('ProtectedRoute: not admin, redirecting to login')
    // Clear auth state and redirect to login
    localStorage.removeItem('admin_token')
    return <Navigate to="/login" replace />
  }
  
  console.log('ProtectedRoute: authenticated and admin, rendering children')
  return <>{children}</>
}

function App() {
  const dispatch = useDispatch<AppDispatch>()
  const { isAuthenticated, token, isLoading, user } = useSelector((state: RootState) => state.auth)

  // Debug logging
  console.log('App render state:', { isAuthenticated, token, isLoading })

  // Check authentication state on startup
  useEffect(() => {
    console.log('App startup - Current auth state:', { isAuthenticated, token: !!token, user: !!user })
    
    // If we have a token but not authenticated, try to validate it
    if (token && !isAuthenticated) {
      console.log('App startup - Found token but not authenticated, validating...')
      // You could dispatch validateToken here if needed
    }
  }, [isAuthenticated, token, user]) // Include dependencies to track changes

  // Show loading while checking authentication
  if (isLoading) {
    return (
      <Box
        display="flex"
        justifyContent="center"
        alignItems="center"
        minHeight="100vh"
      >
        <CircularProgress />
      </Box>
    )
  }

  return (
    <Routes>
      {/* Public Routes */}
      <Route path="/login" element={<LoginPage />} />
      
      {/* Protected Admin Routes */}
      <Route
        path="/admin"
        element={
          <ProtectedRoute>
            <Layout />
          </ProtectedRoute>
        }
      >
        <Route index element={<DashboardPage />} />
        
        {/* Content Management */}
        <Route path="books" element={<BooksPage />} />
        <Route path="books/new" element={<BookFormPage />} />
        <Route path="books/:id/edit" element={<BookFormPage />} />
        <Route path="podcasts" element={<PodcastsPage />} />
        <Route path="podcasts/new" element={<PodcastsPage />} />
        <Route path="podcasts/:id/edit" element={<PodcastsPage />} />
        <Route path="podcasts/:podcastId/episodes" element={<PodcastEpisodesPage />} />
        <Route path="categories" element={<CategoriesPage />} />
        <Route path="moderation" element={<ContentModerationPage />} />
        
        {/* User Management */}
        <Route path="users" element={<UserManagementPage />} />
        <Route path="users/:id" element={<UserDetailPage />} />
        <Route path="users/analytics" element={<AnalyticsPage />} />
        <Route path="users/reports" element={<AnalyticsPage />} />
        
        {/* Analytics & Insights */}
        <Route path="analytics" element={<AnalyticsPage />} />
        <Route path="analytics/advanced" element={<AnalyticsPage />} />
        <Route path="analytics/revenue" element={<AnalyticsPage />} />
        <Route path="analytics/content" element={<AnalyticsPage />} />
        
        {/* Subscriptions & Payments */}
        <Route path="subscriptions" element={<AnalyticsPage />} />
        <Route path="payments" element={<AnalyticsPage />} />
        <Route path="revenue" element={<AnalyticsPage />} />
        
        {/* System Administration */}
        <Route path="settings" element={<SettingsPage />} />
        <Route path="security" element={<SettingsPage />} />
        <Route path="backup" element={<SettingsPage />} />
        <Route path="health" element={<SettingsPage />} />
        <Route path="notifications" element={<SettingsPage />} />
        <Route path="storage" element={<SettingsPage />} />
      </Route>
      
              {/* Redirect root based on authentication status */}
        <Route path="/" element={
          isAuthenticated ? <Navigate to="/admin" replace /> : <Navigate to="/login" replace />
        } />
      
      {/* Catch unauthorized admin access - redirect to login */}
      <Route path="/admin/*" element={
        isAuthenticated && user?.isAdmin ? (
          <Navigate to="/admin" replace />
        ) : (
          <Navigate to="/login" replace />
        )
      } />
      
      {/* 404 Route */}
      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  )
}

export default App
