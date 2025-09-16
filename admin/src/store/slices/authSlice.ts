import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit'
import { authAPI } from '@/services/authAPI'

export interface User {
  id: string
  email: string
  firstName: string
  lastName: string
  displayName?: string
  avatarUrl?: string
  languagePreference: 'en' | 'so' | 'ar'
  themePreference: 'light' | 'dark' | 'sepia' | 'night'
  subscriptionPlan: 'free' | 'premium' | 'lifetime'
  subscriptionStatus: 'active' | 'inactive' | 'cancelled' | 'expired'
  isVerified: boolean
  isActive: boolean
  isAdmin: boolean
  lastLoginAt?: string
  createdAt: string
  updatedAt: string
}

interface AuthState {
  user: User | null
  token: string | null
  isAuthenticated: boolean
  isLoading: boolean
  error: string | null
}

const initialState: AuthState = {
  user: null,
  token: localStorage.getItem('admin_token'), // Load token from localStorage
  isAuthenticated: false,
  isLoading: false,
  error: null,
}

// Async thunks
export const login = createAsyncThunk(
  'auth/login',
  async (credentials: { email: string; password: string }, { rejectWithValue }) => {
    try {
      const response = await authAPI.login(credentials)
      localStorage.setItem('admin_token', response.token)
      return response
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.error || 'Login failed')
    }
  }
)

export const logout = createAsyncThunk(
  'auth/logout',
  async (_, { rejectWithValue }) => {
    try {
      await authAPI.logout()
      localStorage.removeItem('admin_token')
      return null
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.error || 'Logout failed')
    }
  }
)

export const getCurrentUser = createAsyncThunk(
  'auth/getCurrentUser',
  async (_, { rejectWithValue }) => {
    try {
      console.log('🔍 Calling getCurrentUser API...')
      const response = await authAPI.getCurrentUser()
      console.log('🔍 getCurrentUser API response:', response)
      return response
    } catch (error: any) {
      // If it's a 401 error, try to refresh the token first
      if (error.response?.status === 401) {
        try {
          const refreshResponse = await authAPI.refreshToken()
          localStorage.setItem('admin_token', refreshResponse.token)
          // Try to get current user again with new token
          const userResponse = await authAPI.getCurrentUser()
          return userResponse
        } catch (refreshError: any) {
          // If refresh fails, clear auth and reject
          localStorage.removeItem('admin_token')
          return rejectWithValue('Token expired')
        }
      }
      return rejectWithValue(error.response?.data?.error || 'Failed to get user')
    }
  }
)

// Validate token on app startup
export const validateToken = createAsyncThunk(
  'auth/validateToken',
  async (_, { rejectWithValue, dispatch }) => {
    try {
      const token = localStorage.getItem('admin_token')
      console.log('🔍 validateToken - checking token:', token ? 'exists' : 'not found')
      
      if (!token) {
        console.log('🔍 validateToken - no token found, rejecting')
        return rejectWithValue('No token found')
      }
      
      console.log('🔍 validateToken - token found, calling getCurrentUser...')
      // Try to get current user to validate token
      const response = await authAPI.getCurrentUser()
      console.log('🔍 validateToken - getCurrentUser successful:', response)
      return response
    } catch (error: any) {
      console.log('🔍 validateToken - error occurred:', error)
      // Clear invalid token
      localStorage.removeItem('admin_token')
      return rejectWithValue('Invalid token')
    }
  }
)

const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null
    },
    setToken: (state, action: PayloadAction<string>) => {
      state.token = action.payload
      state.isAuthenticated = true
    },
    clearAuth: (state) => {
      state.user = null
      state.token = null
      state.isAuthenticated = false
      localStorage.removeItem('admin_token')
    },
  },
  extraReducers: (builder) => {
    builder
      // Login
      .addCase(login.pending, (state) => {
        state.isLoading = true
        state.error = null
      })
      .addCase(login.fulfilled, (state, action) => {
        console.log('🔍 Login fulfilled - Full action payload:', action.payload)
        console.log('🔍 Login fulfilled - User data:', action.payload.user)
        console.log('🔍 Login fulfilled - isAdmin flag:', action.payload.user?.isAdmin)
        console.log('🔍 Login fulfilled - User type:', typeof action.payload.user)
        console.log('🔍 Login fulfilled - isAdmin type:', typeof action.payload.user?.isAdmin)
        state.isLoading = false
        state.isAuthenticated = true
        state.user = action.payload.user
        state.token = action.payload.token
        state.error = null
        
        // Save token to localStorage
        localStorage.setItem('admin_token', action.payload.token)
      })
      .addCase(login.rejected, (state, action) => {
        state.isLoading = false
        state.error = action.payload as string
        
        // Clear any existing auth state on login failure
        state.user = null
        state.token = null
        state.isAuthenticated = false
      })
      // Logout
      .addCase(logout.fulfilled, (state) => {
        state.user = null
        state.token = null
        state.isAuthenticated = false
        localStorage.removeItem('admin_token') // Clear token from localStorage
      })
      // Get current user
      .addCase(getCurrentUser.pending, (state) => {
        state.isLoading = true
      })
      .addCase(getCurrentUser.fulfilled, (state, action) => {
        console.log('🔍 GetCurrentUser fulfilled - User data:', action.payload)
        console.log('🔍 GetCurrentUser fulfilled - isAdmin flag:', action.payload.isAdmin)
        state.isLoading = false
        state.user = action.payload
        state.isAuthenticated = true
      })
      .addCase(getCurrentUser.rejected, (state, action) => {
        state.isLoading = false
        state.error = action.payload as string
        // Only clear auth if it's a real authentication error, not a network error
        if (action.payload === 'Unauthorized' || action.payload === 'Token expired') {
          state.user = null
          state.token = null
          state.isAuthenticated = false
          localStorage.removeItem('admin_token')
        }
      })
      // Validate token
      .addCase(validateToken.pending, (state) => {
        state.isLoading = true
      })
      .addCase(validateToken.fulfilled, (state, action) => {
        state.isLoading = false
        state.isAuthenticated = true
        state.user = action.payload
        state.token = localStorage.getItem('admin_token')
      })
      .addCase(validateToken.rejected, (state) => {
        state.isLoading = false
        state.isAuthenticated = false
        state.user = null
        state.token = null
        localStorage.removeItem('admin_token')
      })
  },
})

export const { clearError, setToken, clearAuth } = authSlice.actions

// Helper function to clear auth manually (for testing)
export const clearAuthManually = () => {
  localStorage.removeItem('admin_token')
  return clearAuth()
}
export default authSlice.reducer
