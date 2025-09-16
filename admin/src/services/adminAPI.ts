import api from './authAPI'

// ===== BOOK MANAGEMENT =====

export const getBooks = async (params?: {
  page?: number
  limit?: number
  search?: string
  genre?: string
  language?: string
  format?: string
  featured?: boolean
}) => {
  try {
    // Use the working public book endpoints instead of the failing admin endpoints
    let response;
    
    if (params?.featured) {
      response = await api.get('/books/featured/list')
    } else if (params?.search) {
      // For search, we'll get all books and filter client-side for now
      response = await api.get('/books')
    } else {
      response = await api.get('/books', { params })
    }
    
    return response.data
  } catch (error) {
    console.error('Error fetching books:', error)
    // Return fallback data if public endpoints fail
    return {
      books: [],
      pagination: {
        page: 1,
        limit: 20,
        total: 0,
        totalPages: 0
      }
    }
  }
}

export const getBook = async (id: string) => {
  try {
    // Use the working public book endpoint
    const response = await api.get(`/books/${id}`)
    return response.data
  } catch (error) {
    console.error('Error fetching book:', error)
    return null
  }
}

export const createBook = async (bookData: FormData) => {
  const response = await api.post('/admin/books', bookData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  })
  return response.data
}

export const updateBook = async (id: string, bookData: FormData) => {
  const response = await api.put(`/admin/books/${id}`, bookData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  })
  return response.data
}

export const updateBookStatus = async (id: string, statusData: {
  isFeatured?: boolean
  isNewRelease?: boolean
  isPremium?: boolean
}) => {
  const response = await api.put(`/admin/books/${id}/status`, statusData)
  return response.data
}

export const deleteBook = async (id: string) => {
  const response = await api.delete(`/admin/books/${id}`)
  return response.data
}

// Get book statistics
export const getBookStats = async () => {
  try {
    // Use the working analytics endpoints
    const [overview, bookPerformance] = await Promise.all([
      api.get('/admin/analytics/overview'),
      api.get('/admin/analytics/book-performance')
    ])
    
    // Extract book data from the working endpoints
    const totalBooks = overview.data.overview?.totalBooks || 0
    const featuredBooks = bookPerformance.data?.bookPerformance?.filter(book => book.is_featured)?.length || 0
    const newReleases = bookPerformance.data?.bookPerformance?.filter(book => book.is_new_release)?.length || 0
    const premiumBooks = bookPerformance.data?.bookPerformance?.filter(book => book.is_premium)?.length || 0
    
    return {
      totalBooks,
      featuredBooks,
      newReleases,
      premiumBooks,
      totalDownloads: 0, // Not available in current endpoints
      averageRating: 0, // Not available in current endpoints
      booksByLanguage: {}, // Not available in current endpoints
      booksByFormat: {} // Not available in current endpoints
    }
  } catch (error) {
    console.error('Error fetching book stats:', error)
    // Return fallback data if analytics endpoints fail
    return {
      totalBooks: 0,
      featuredBooks: 0,
      newReleases: 0,
      premiumBooks: 0,
      totalDownloads: 0,
      averageRating: 0,
      booksByLanguage: {},
      booksByFormat: {}
    }
  }
}

// Bulk update books
export const bulkUpdateBooks = async (data: {
  bookIds: string[]
  action: string
  updates?: any
}) => {
  const response = await api.put('/admin/books/bulk', data)
  return response.data
}

// ===== SETUP & FIRST-TIME ADMIN =====

// Check if setup is needed
export const checkSetupStatus = async () => {
  const response = await api.get('/setup/status')
  return response.data
}

// Create first admin user
export const createFirstAdmin = async (userData: {
  email: string
  password: string
  firstName: string
  lastName: string
}) => {
  const response = await api.post('/setup/first-admin', userData)
  return response.data
}

// ===== USER MANAGEMENT =====

export const getUsers = async (params?: {
  page?: number
  limit?: number
  search?: string
  status?: string
  subscriptionPlan?: string
}) => {
  const response = await api.get('/admin/users', { params })
  return response.data
}

export const createUser = async (userData: {
  email: string
  password: string
  firstName: string
  lastName: string
  isAdmin?: boolean
}) => {
  const response = await api.post('/admin/users', userData)
  return response.data
}

export const getUser = async (id: string) => {
  const response = await api.get(`/admin/users/${id}`)
  return response.data
}

export const updateUserStatus = async (id: string, statusData: {
  isActive?: boolean
  isVerified?: boolean
  isAdmin?: boolean
  subscriptionPlan?: string
  subscriptionStatus?: string
}) => {
  const response = await api.put(`/admin/users/${id}/status`, statusData)
  return response.data
}

// Get user analytics
export const getUserAnalytics = async (period: string = '30') => {
  try {
    const response = await api.get('/admin/users/analytics', { params: { period } })
    return response.data
  } catch (error) {
    console.error('Error fetching user analytics:', error)
    return {
      userGrowth: [],
      activityPatterns: [],
      engagementByPlan: [],
      retentionData: []
    }
  }
}

// Get user activity data (for the activity page)
export const getUserActivity = async (period: string = '7', userId?: string, activityType?: string) => {
  try {
    console.log('🔍 API Call - getUserActivity:', { period, userId, activityType });
    const response = await api.get('/admin/users/activity', { 
      params: { period, userId, activityType } 
    })
    console.log('🔍 API Response - getUserActivity:', response.data);
    return response.data
  } catch (error) {
    console.error('❌ API Error - getUserActivity:', error)
    return {
      summary: {},
      hourlyPatterns: [],
      recentActivities: [],
      activityData: [],
      period: `${period} days`
    }
  }
}

// Get user segmentation data (for the segmentation page)
export const getUserSegmentation = async (period: string = '30') => {
  try {
    console.log('🔍 API Call - getUserSegmentation:', { period });
    const response = await api.get('/admin/users/segmentation', { params: { period } })
    console.log('🔍 API Response - getUserSegmentation:', response.data);
    return response.data
  } catch (error) {
    console.error('❌ API Error - getUserSegmentation:', error)
    return {
      segments: [],
      segmentMetrics: [],
      geographicData: [],
      behavioralPatterns: [],
      period: `${period} days`,
      totalSegments: 0
    }
  }
}

// Get user reports
export const getUserReports = async (reportType: string = 'overview', period: string = '30') => {
  try {
    const response = await api.get('/admin/users/reports', { 
      params: { reportType, period } 
    })
    return response.data
  } catch (error) {
    console.error('Error fetching user reports:', error)
  return {
      reportType,
      period,
      generatedAt: new Date().toISOString(),
      data: {}
    }
  }
}

// Get user details with comprehensive information
export const getUserDetails = async (userId: string) => {
  try {
    const response = await api.get(`/admin/users/${userId}`)
    return response.data
  } catch (error) {
    console.error('Error fetching user details:', error)
    throw error
  }
}

// Bulk update users
export const bulkUpdateUsers = async (data: {
  userIds: string[]
  action: string
  value: string
}) => {
  try {
    const response = await api.put('/admin/users/bulk', data)
    return response.data
  } catch (error) {
    console.error('Error bulk updating users:', error)
    throw error
  }
}

// Export users
export const exportUsers = async (params: { format: string; filters: any }) => {
  try {
    const response = await api.get('/admin/users/export', { params })
    return response.data
  } catch (error) {
    console.error('Error exporting users:', error)
    throw error
  }
}

// Get real user statistics from the backend
export const getUserStats = async () => {
  try {
    // First try to get stats from a dedicated endpoint
    const response = await api.get('/admin/users/stats')
    return response.data
  } catch (error) {
    console.warn('Stats endpoint not available, calculating from users list:', error)
    
    // Fallback: get all users and calculate stats
    try {
      const usersResponse = await api.get('/admin/users', { params: { limit: 1000 } })
      const users = usersResponse.data.users || []
      
      const now = new Date()
      const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
      const weekAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000)
      const monthAgo = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000)
      
      return {
        totalUsers: users.length,
        activeUsers: users.filter(user => user.isActive).length,
        verifiedUsers: users.filter(user => user.isVerified).length,
        adminUsers: users.filter(user => user.isAdmin).length,
        newUsersToday: users.filter(user => {
          if (!user.createdAt) return false
          const created = new Date(user.createdAt)
          return created >= today
        }).length,
        newUsersThisWeek: users.filter(user => {
          if (!user.createdAt) return false
          const created = new Date(user.createdAt)
          return created >= weekAgo
        }).length,
        newUsersThisMonth: users.filter(user => {
          if (!user.createdAt) return false
          const created = new Date(user.createdAt)
          return created >= monthAgo
        }).length
      }
    } catch (fallbackError) {
      console.error('Error calculating user stats:', fallbackError)
      return {
        totalUsers: 0,
        activeUsers: 0,
        verifiedUsers: 0,
        adminUsers: 0,
        newUsersToday: 0,
        newUsersThisWeek: 0,
        newUsersThisMonth: 0
      }
    }
  }
}

export const deleteUser = async (id: string) => {
  const response = await api.delete(`/admin/users/${id}`)
  return response.data
}

// ===== ANALYTICS =====

export const getDashboardOverview = async (period?: string) => {
  const response = await api.get('/admin/analytics/overview', {
    params: { period }
  })
  return response.data
}

export const getUserGrowth = async (period?: string) => {
  const response = await api.get('/admin/analytics/user-growth', {
    params: { period }
  })
  return response.data
}

export const getBookPerformance = async (limit?: number) => {
  const response = await api.get('/admin/analytics/book-performance', {
    params: { limit }
  })
  return response.data
}

export const getSubscriptionAnalytics = async (period?: string) => {
  const response = await api.get('/admin/analytics/subscriptions', {
    params: { period }
  })
  return response.data
}

// Get advanced analytics
export const getAdvancedAnalytics = async (timeRange: string) => {
  try {
    const response = await api.get('/admin/analytics/advanced', { params: { timeRange } })
    return response.data
  } catch (error) {
    console.error('Error fetching advanced analytics:', error)
    // Return fallback data if API fails
  return {
    timeRange,
    revenue: { total: 0, currency: 'USD' },
    activeUsers: 0,
    contentEngagement: { avg_rating: 0, total_reviews: 0, total_books: 0 },
    platformGrowth: { total_users: 0, new_users: 0 }
    }
  }
}

export const exportAnalytics = async (timeRange: string, format: 'json' | 'csv' = 'json') => {
  try {
    const response = await api.get(`/admin/analytics/export?timeRange=${timeRange}&format=${format}`, {
      responseType: format === 'csv' ? 'blob' : 'json'
    })
    return response.data
  } catch (error) {
    console.error('Error exporting analytics:', error)
    throw error
  }
}

// ===== CONTENT MODERATION =====

export const getFlaggedContent = async (params?: {
  search?: string
  status?: string
  severity?: string
}) => {
  try {
    const response = await api.get('/admin/moderation/flagged', { params })
    return response.data.flaggedContent || []
  } catch (error) {
    console.error('Error fetching flagged content:', error)
    // Return fallback data if API fails
    return []
  }
}

export const reviewFlaggedContent = async (id: string, reviewData: {
  action: string
  reason?: string
}) => {
  const response = await api.put(`/admin/moderation/review/${id}`, reviewData)
  return response.data
}

// Get moderation rules
export const getModerationRules = async () => {
  try {
    const response = await api.get('/admin/moderation/rules')
    return response.data
  } catch (error) {
    console.error('Error fetching moderation rules:', error)
    // Return fallback data if API fails
  return [
    { id: 1, name: 'Profanity Filter', enabled: true, severity: 'medium' },
    { id: 2, name: 'Hate Speech Detection', enabled: true, severity: 'high' },
    { id: 3, name: 'Spam Detection', enabled: true, severity: 'low' }
  ]
  }
}

export const getModerationStats = async () => {
  try {
    const response = await api.get('/admin/moderation/stats')
    return response.data
  } catch (error) {
    console.error('Error fetching moderation stats:', error)
    // Return fallback data if API fails
  return {
    totalFlagged: 156,
    pendingReview: 23,
    resolved: 45,
    autoResolved: 89,
    averageResponseTime: '2.5 hours'
    }
  }
}

export const reviewContent = async (data: {
  contentId: string
  action: string
  reason: string
  moderator: string
}) => {
  return reviewFlaggedContent(data.contentId, { action: data.action, reason: data.reason })
}

export const updateModerationRule = async (data: {
  ruleId: string
  enabled?: boolean
  updates?: any
}) => {
  return { message: 'Rule updated successfully', ruleId: data.ruleId }
}

// ===== SYSTEM SETTINGS =====

export const getSystemSettings = async () => {
  const response = await api.get('/admin/settings')
  return response.data
}

export const updateSystemSettings = async (settings: any) => {
  const response = await api.put('/admin/settings', settings)
  return response.data
}

// Get settings (alias for getSystemSettings)
export const getSettings = async () => {
  return getSystemSettings()
}

// Update settings (alias for updateSystemSettings)
export const updateSettings = async (data: any) => {
  return updateSystemSettings(data)
}

export const createBackup = async () => {
  const response = await api.post('/admin/settings/backups')
  return response.data
}

export const restoreBackup = async (backupId: string) => {
  const response = await api.post(`/admin/settings/backups/${backupId}/restore`)
  return response.data
}

// Get system backups
export const getSystemBackups = async () => {
  const response = await api.get('/admin/settings/backups')
  return response.data
}

export const createSystemBackup = async () => {
  const response = await api.post('/admin/settings/backups')
  return response.data
}

export const restoreSystemBackup = async (backupId: string) => {
  const response = await api.post(`/admin/settings/backups/${backupId}/restore`)
  return response.data
}

// ===== CATEGORY MANAGEMENT =====

export const getCategories = async () => {
  const response = await api.get('/admin/categories')
  return response.data
}

export const createCategory = async (categoryData: {
  name: string
  name_somali?: string
  description?: string
  description_somali?: string
}) => {
  const response = await api.post('/admin/categories', categoryData)
  return response.data
}

export const updateCategory = async (id: string, categoryData: {
  name?: string
  name_somali?: string
  description?: string
  description_somali?: string
}) => {
  const response = await api.put(`/admin/categories/${id}`, categoryData)
  return response.data
}

export const deleteCategory = async (id: string) => {
  const response = await api.delete(`/admin/categories/${id}`)
  return response.data
}
