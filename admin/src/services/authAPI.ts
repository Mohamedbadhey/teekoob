import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://teekoob-production.up.railway.app/api/v1'

// Create axios instance
const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('admin_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor to handle auth errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    // Only handle 401 errors for auth endpoints, not admin endpoints
    if (error.response?.status === 401 && error.config?.url?.includes('/auth/')) {
      // Clear token and redirect to login only for auth endpoints
      localStorage.removeItem('admin_token')
      window.location.href = '/login'
    } else if (error.response?.status === 401) {
      // For other 401 errors, just reject the promise and let components handle it
      console.warn('Unauthorized request:', error.config?.url)
    } else if (error.response?.status === 403) {
      // Handle admin access denied
      console.error('Admin access denied:', error.response.data)
    }
    return Promise.reject(error)
  }
)

export interface LoginCredentials {
  email: string
  password: string
}

export interface LoginResponse {
  user: {
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
  token: string
}

export const authAPI = {
  login: async (credentials: LoginCredentials): Promise<LoginResponse> => {
    const response = await api.post('/auth/login', credentials)
    console.log('🔍 authAPI.login - Raw response:', response)
    console.log('🔍 authAPI.login - Response data:', response.data)
    console.log('🔍 authAPI.login - User object:', response.data.user)
    console.log('🔍 authAPI.login - isAdmin value:', response.data.user?.isAdmin)
    return response.data
  },

  logout: async (): Promise<void> => {
    await api.post('/auth/logout')
  },

  getCurrentUser: async (): Promise<LoginResponse['user']> => {
    const response = await api.get('/auth/me')
    console.log('🔍 getCurrentUser raw response:', response.data)
    return response.data.user // Extract user from { user: ... } response
  },

  refreshToken: async (): Promise<{ token: string }> => {
    const response = await api.post('/auth/refresh')
    return response.data
  },

  forgotPassword: async (email: string): Promise<{ message: string }> => {
    const response = await api.post('/auth/forgot-password', { email })
    return response.data
  },

  resetPassword: async (token: string, password: string): Promise<{ message: string }> => {
    const response = await api.post('/auth/reset-password', { token, password })
    return response.data
  },
}

export default api
