import React, { useState, useEffect } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useSelector } from 'react-redux'
import { RootState } from '../../store'
import { useNavigate } from 'react-router-dom'
import {
  Box,
  Typography,
  Paper,
  Grid,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Card,
  CardContent,
  Chip,
  CircularProgress,
  Button,
} from '@mui/material'
import {
  TrendingUp as TrendingIcon,
  People as PeopleIcon,
  Book as BookIcon,
  AttachMoney as MoneyIcon,
  Timeline as TimelineIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material'
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  AreaChart,
  Area,
} from 'recharts'
import { 
  getDashboardOverview, 
  getUserGrowth, 
  getBookPerformance, 
  getSubscriptionAnalytics 
} from '../../services/adminAPI'

const AnalyticsPage: React.FC = () => {
  const navigate = useNavigate()
  const currentUser = useSelector((state: RootState) => state.auth.user)
  const isAuthenticated = useSelector((state: RootState) => state.auth.isAuthenticated)
  const [timeRange, setTimeRange] = useState('30')
  const [chartType, setChartType] = useState('line')

  // Check authentication
  useEffect(() => {
    if (!isAuthenticated || !currentUser?.isAdmin) {
      console.log('User not authenticated or not admin, redirecting to login')
      navigate('/login')
    }
  }, [isAuthenticated, currentUser, navigate])

  // Don't render if not authenticated
  if (!isAuthenticated || !currentUser?.isAdmin) {
    return null
  }

  // Fetch analytics data
  const { data: overview, isLoading: overviewLoading, error: overviewError } = useQuery({
    queryKey: ['dashboard-overview', timeRange],
    queryFn: () => getDashboardOverview(timeRange),
    onError: (error) => console.error('Error fetching dashboard overview:', error),
  })

  const { data: userGrowth, isLoading: userGrowthLoading, error: userGrowthError } = useQuery({
    queryKey: ['user-growth', timeRange],
    queryFn: () => getUserGrowth(timeRange),
    onError: (error) => console.error('Error fetching user growth:', error),
  })

  const { data: bookPerformance, isLoading: bookPerformanceLoading, error: bookPerformanceError } = useQuery({
    queryKey: ['book-performance'],
    queryFn: () => getBookPerformance(20),
    onError: (error) => console.error('Error fetching book performance:', error),
  })

  const { data: subscriptionData, isLoading: subscriptionLoading, error: subscriptionError } = useQuery({
    queryKey: ['subscription-analytics', timeRange],
    queryFn: () => getSubscriptionAnalytics(timeRange),
    onError: (error) => console.error('Error fetching subscription analytics:', error),
  })

  const isLoading = overviewLoading || userGrowthLoading || bookPerformanceLoading || subscriptionLoading
  const hasErrors = overviewError || userGrowthError || bookPerformanceError || subscriptionError

  // Debug logging
  console.log('Analytics Page State:', {
    isAuthenticated,
    currentUser,
    overview,
    userGrowth,
    bookPerformance,
    subscriptionData,
    errors: { overviewError, userGrowthError, bookPerformanceError, subscriptionError }
  })

  const chartColors = [
    '#8884d8', '#82ca9d', '#ffc658', '#ff7300', '#00C49F',
    '#FFBB28', '#FF8042', '#0088FE', '#00C49F', '#FFBB28'
  ]

  const StatCard: React.FC<{
    title: string
    value: string | number
    icon: React.ReactNode
    color: string
    subtitle?: string
    trend?: { value: number; isPositive: boolean }
  }> = ({ title, value, icon, color, subtitle, trend }) => (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Box display="flex" alignItems="center" justifyContent="space-between">
          <Box>
            <Typography color="textSecondary" gutterBottom variant="h6">
              {title}
            </Typography>
            <Typography variant="h4" component="div" fontWeight="bold">
              {value}
            </Typography>
            {subtitle && (
              <Typography variant="body2" color="textSecondary">
                {subtitle}
              </Typography>
            )}
            {trend && (
              <Box display="flex" alignItems="center" mt={1}>
                <TrendingIcon
                  sx={{
                    color: trend.isPositive ? 'success.main' : 'error.main',
                    transform: trend.isPositive ? 'rotate(0deg)' : 'rotate(180deg)',
                    mr: 0.5,
                  }}
                />
                <Typography
                  variant="body2"
                  color={trend.isPositive ? 'success.main' : 'error.main'}
                >
                  {trend.isPositive ? '+' : ''}{trend.value}%
                </Typography>
              </Box>
            )}
          </Box>
          <Box
            sx={{
              backgroundColor: color,
              borderRadius: '50%',
              p: 1.5,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            {icon}
          </Box>
        </Box>
      </CardContent>
    </Card>
  )

  if (isLoading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    )
  }

  if (hasErrors) {
    return (
      <Box display="flex" flexDirection="column" justifyContent="center" alignItems="center" minHeight="400px" gap={2}>
        <Typography variant="h6" color="error">
          Error loading analytics data
        </Typography>
        <Typography variant="body2" color="textSecondary" textAlign="center">
          Please check your connection and try again. If the problem persists, contact support.
        </Typography>
        <Button 
          variant="outlined" 
          onClick={() => window.location.reload()}
          startIcon={<RefreshIcon />}
        >
          Retry
        </Button>
      </Box>
    )
  }

  return (
    <Box>
      {/* Header */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" fontWeight="bold">
          Analytics & Insights
        </Typography>
        
        <Box display="flex" gap={2}>
          <FormControl sx={{ minWidth: 120 }}>
            <InputLabel>Time Range</InputLabel>
            <Select
              value={timeRange}
              label="Time Range"
              onChange={(e) => setTimeRange(e.target.value)}
            >
              <MenuItem value="7">Last 7 days</MenuItem>
              <MenuItem value="30">Last 30 days</MenuItem>
              <MenuItem value="90">Last 3 months</MenuItem>
              <MenuItem value="365">Last year</MenuItem>
            </Select>
          </FormControl>
        </Box>
      </Box>

      {/* Key Metrics */}
      <Grid container spacing={3} mb={4}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Users"
            value={overview?.overview?.totalUsers || overview?.totalUsers || 0}
            icon={<PeopleIcon sx={{ color: 'white', fontSize: 28 }} />}
            color="#1976d2"
            subtitle="Registered users"
            trend={{ value: 12, isPositive: true }}
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Books"
            value={overview?.overview?.totalBooks || overview?.totalBooks || 0}
            icon={<BookIcon sx={{ color: 'white', fontSize: 28 }} />}
            color="#2e7d32"
            subtitle="Published content"
            trend={{ value: 8, isPositive: true }}
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Active Subscriptions"
            value={overview?.overview?.activeSubscriptions || overview?.activeSubscriptions || 0}
            icon={<TimelineIcon sx={{ color: 'white', fontSize: 28 }} />}
            color="#ed6c02"
            subtitle="Premium users"
            trend={{ value: 15, isPositive: true }}
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Monthly Revenue"
            value={`$${overview?.overview.revenue || 0}`}
            icon={<MoneyIcon sx={{ color: 'white', fontSize: 28 }} />}
            color="#9c27b0"
            subtitle="This month"
            trend={{ value: 22, isPositive: true }}
          />
        </Grid>
      </Grid>

      {/* Charts Row 1 */}
      <Grid container spacing={3} mb={4}>
        {/* User Growth Chart */}
        <Grid item xs={12} lg={8}>
          <Paper sx={{ p: 3, height: 400 }}>
            <Typography variant="h6" gutterBottom>
              User Growth Trend
            </Typography>
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={userGrowth?.userGrowth || []}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Area
                  type="monotone"
                  dataKey="new_users"
                  stroke="#1976d2"
                  fill="#1976d2"
                  fillOpacity={0.3}
                />
              </AreaChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>

        {/* Subscription Distribution */}
        <Grid item xs={12} lg={4}>
          <Paper sx={{ p: 3, height: 400 }}>
            <Typography variant="h6" gutterBottom>
              Subscription Plans Distribution
            </Typography>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={subscriptionData?.planDistribution || []}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="count"
                >
                  {subscriptionData?.planDistribution?.map((entry: any, index: number) => (
                    <Cell key={`cell-${index}`} fill={chartColors[index % chartColors.length]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>
      </Grid>

      {/* Charts Row 2 */}
      <Grid container spacing={3} mb={4}>
        {/* Book Performance */}
        <Grid item xs={12} lg={6}>
          <Paper sx={{ p: 3, height: 400 }}>
            <Typography variant="h6" gutterBottom>
              Top Performing Books (by Rating)
            </Typography>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={bookPerformance?.bookPerformance || []}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="title" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="rating" fill="#82ca9d" />
              </BarChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>

        {/* Revenue Metrics */}
        <Grid item xs={12} lg={6}>
          <Paper sx={{ p: 3, height: 400 }}>
            <Typography variant="h6" gutterBottom>
              Revenue Metrics
            </Typography>
            <Box display="flex" flexDirection="column" gap={3} height="100%">
              <Box>
                <Typography variant="body2" color="textSecondary">
                  Monthly Recurring Revenue (MRR)
                </Typography>
                <Typography variant="h3" fontWeight="bold" color="primary">
                  ${subscriptionData?.mrr || 0}
                </Typography>
              </Box>
              
              <Box>
                <Typography variant="body2" color="textSecondary">
                  Churn Rate
                </Typography>
                <Typography variant="h4" fontWeight="bold" color="error">
                  {subscriptionData?.churnRate || 0}%
                </Typography>
              </Box>
              
              <Box>
                <Typography variant="body2" color="textSecondary">
                  Average Revenue Per User (ARPU)
                </Typography>
                <Typography variant="h4" fontWeight="bold" color="success.main">
                  ${overview?.overview.revenue && overview.overview.activeSubscriptions 
                    ? (overview.overview.revenue / overview.overview.activeSubscriptions).toFixed(2)
                    : 0}
                </Typography>
              </Box>
            </Box>
          </Paper>
        </Grid>
      </Grid>

      {/* Charts Row 3 */}
      <Grid container spacing={3}>
        {/* Language Distribution */}
        <Grid item xs={12} lg={6}>
          <Paper sx={{ p: 3, height: 400 }}>
            <Typography variant="h6" gutterBottom>
              Content by Language
            </Typography>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={[
                    { name: 'English', value: 45 },
                    { name: 'Somali', value: 35 },
                    { name: 'Arabic', value: 20 },
                  ]}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {[
                    { name: 'English', value: 45 },
                    { name: 'Somali', value: 35 },
                    { name: 'Arabic', value: 20 },
                  ].map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={chartColors[index % chartColors.length]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>

        {/* Format Distribution */}
        <Grid item xs={12} lg={6}>
          <Paper sx={{ p: 3, height: 400 }}>
            <Typography variant="h6" gutterBottom>
              Content by Format
            </Typography>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={[
                { format: 'eBook', count: 60 },
                { format: 'Audiobook', count: 25 },
                { format: 'Both', count: 15 },
              ]}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="format" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="count" fill="#ffc658" />
              </BarChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  )
}

export default AnalyticsPage
