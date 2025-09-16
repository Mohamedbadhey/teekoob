import React, { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useSelector, useDispatch } from 'react-redux'
import {
  Box,
  Paper,
  TextField,
  Button,
  Typography,
  Alert,
  CircularProgress,
  Container,
} from '@mui/material'
import { Book as BookIcon } from '@mui/icons-material'
import { RootState, AppDispatch } from '@/store'
import { login, clearError, clearAuth } from '@/store/slices/authSlice'

const LoginPage: React.FC = () => {
  const navigate = useNavigate()
  const dispatch = useDispatch<AppDispatch>()
  const { isLoading, error, isAuthenticated, user } = useSelector(
    (state: RootState) => state.auth
  )

  const [formData, setFormData] = useState({
    email: '',
    password: '',
  })

  useEffect(() => {
    if (isAuthenticated && user?.isAdmin) {
      console.log('🔍 LoginPage - User authenticated and is admin, navigating to /admin')
      navigate('/admin')
    }
  }, [isAuthenticated, user?.isAdmin, navigate])

  useEffect(() => {
    // Only clear errors, don't clear auth state
    dispatch(clearError())
    
    // Don't clear localStorage token or auth state on mount
    // This was causing the login to fail
    
    console.log('🔍 LoginPage mounted - auth state preserved')
  }, [dispatch])

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!formData.email || !formData.password) {
      return
    }

          try {
        const result = await dispatch(login(formData)).unwrap()
        console.log('🔍 Login successful, user:', result.user)
        if (result.user?.isAdmin) {
          navigate('/admin')
        } else {
          console.error('🔍 User is not admin')
          // Clear the login and show error
          dispatch(clearAuth())
          // Set a custom error message
          setFormData({ email: '', password: '' })
        }
      } catch (error: any) {
        console.error('Login failed:', error)
        // Handle specific admin access error
        if (error?.response?.data?.code === 'ADMIN_ACCESS_REQUIRED') {
          // This error is already handled by the Redux slice
          // The error message will be displayed in the UI
        }
      }
  }

  return (
    <Container component="main" maxWidth="xs">
      <Box
        sx={{
          marginTop: 8,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
        }}
      >
        {/* Logo and Title */}
        <Box
          sx={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            mb: 3,
          }}
        >
          <BookIcon sx={{ fontSize: 60, color: 'primary.main', mb: 2 }} />
          <Typography component="h1" variant="h4" fontWeight="bold">
            Teekoob Admin
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
            Multilingual eBook & Audiobook Platform
          </Typography>
        </Box>

        {/* Login Form */}
        <Paper
          elevation={3}
          sx={{
            padding: 4,
            width: '100%',
            borderRadius: 2,
          }}
        >
          <Typography component="h2" variant="h5" align="center" gutterBottom>
            Sign In
          </Typography>

          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
              {error.includes('admin') && (
                <Typography variant="body2" sx={{ mt: 1 }}>
                  Only users with admin privileges can access the admin panel.
                </Typography>
              )}
            </Alert>
          )}

          <Box component="form" onSubmit={handleSubmit} sx={{ mt: 1 }}>
            <TextField
              margin="normal"
              required
              fullWidth
              id="email"
              label="Email Address"
              name="email"
              autoComplete="email"
              autoFocus
              value={formData.email}
              onChange={handleInputChange}
              disabled={isLoading}
            />
            <TextField
              margin="normal"
              required
              fullWidth
              name="password"
              label="Password"
              type="password"
              id="password"
              autoComplete="current-password"
              value={formData.password}
              onChange={handleInputChange}
              disabled={isLoading}
            />
            <Button
              type="submit"
              fullWidth
              variant="contained"
              sx={{ mt: 3, mb: 2, py: 1.5 }}
              disabled={isLoading || !formData.email || !formData.password}
            >
              {isLoading ? (
                <CircularProgress size={24} color="inherit" />
              ) : (
                'Sign In'
              )}
            </Button>
            
            {/* Clear State Button */}
            <Button
              type="button"
              fullWidth
              variant="outlined"
              sx={{ mb: 2, py: 1.5 }}
              onClick={() => {
                dispatch(clearAuth())
                setFormData({ email: '', password: '' })
              }}
              disabled={isLoading}
            >
              Clear State & Refresh
            </Button>
          </Box>
        </Paper>

        {/* Footer */}
        <Box sx={{ mt: 3, textAlign: 'center' }}>
          <Typography variant="body2" color="text.secondary">
            © 2024 Teekoob. All rights reserved.
          </Typography>
        </Box>
      </Box>
    </Container>
  )
}

export default LoginPage
