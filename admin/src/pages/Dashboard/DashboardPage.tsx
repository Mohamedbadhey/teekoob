import React from 'react'
import {
  Grid,
  Card,
  CardContent,
  Typography,
  Box,
  Paper,
  IconButton,
  Tooltip,
} from '@mui/material'
import {
  People as PeopleIcon,
  Book as BookIcon,
  AttachMoney as MoneyIcon,
  TrendingUp as TrendingIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material'
import { useQuery } from '@tanstack/react-query'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip as RechartsTooltip, ResponsiveContainer, BarChart, Bar, PieChart, Pie, Cell } from 'recharts'
import { 
  getDashboardOverview, 
  getUserGrowth, 
  getBookPerformance, 
  getSubscriptionAnalytics 
} from '@/services/adminAPI'

const DashboardPage: React.FC = () => {
  const { data: overview, isLoading, refetch } = useQuery({
    queryKey: ['dashboard-overview'],
    queryFn: () => getDashboardOverview(),
  })

  const { data: userGrowth } = useQuery({
    queryKey: ['user-growth'],
    queryFn: () => getUserGrowth(),
  })

  const { data: bookPerformance } = useQuery({
    queryKey: ['book-performance'],
    queryFn: () => getBookPerformance(),
  })

  const { data: subscriptionData } = useQuery({
    queryKey: ['subscription-analytics'],
    queryFn: () => getSubscriptionAnalytics(),
  })

  const handleRefresh = () => {
    refetch()
  }

  const StatCard: React.FC<{
    title: string
    value: string | number
    icon: React.ReactNode
    color: string
    subtitle?: string
  }> = ({ title, value, icon, color, subtitle }) => (
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
          </Box>
          <Box
            sx={{
              backgroundColor: color,
              borderRadius: '50%',
              p: 1,
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

  const chartColors = ['#8884d8', '#82ca9d', '#ffc658', '#ff7300', '#00C49F']

  return (
    <Box>
      {/* Header */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" fontWeight="bold">
          Dashboard Overview
        </Typography>
        <Tooltip title="Refresh Data">
          <IconButton onClick={handleRefresh} disabled={isLoading}>
            <RefreshIcon />
          </IconButton>
        </Tooltip>
      </Box>

      {/* Stats Cards */}
      <Grid container spacing={3} mb={4}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Users"
            value={overview?.overview.totalUsers || 0}
            icon={<PeopleIcon sx={{ color: 'white' }} />}
            color="#1976d2"
            subtitle="Active accounts"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Books"
            value={overview?.overview.totalBooks || 0}
            icon={<BookIcon sx={{ color: 'white' }} />}
            color="#2e7d32"
            subtitle="Published content"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Active Subscriptions"
            value={overview?.overview.activeSubscriptions || 0}
            icon={<TrendingIcon sx={{ color: 'white' }} />}
            color="#ed6c02"
            subtitle="Premium users"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Monthly Revenue"
            value={`$${overview?.overview.revenue || 0}`}
            icon={<MoneyIcon sx={{ color: 'white' }} />}
            color="#9c27b0"
            subtitle="This month"
          />
        </Grid>
      </Grid>

      {/* Charts Row 1 */}
      <Grid container spacing={3} mb={4}>
        {/* User Growth Chart */}
        <Grid item xs={12} lg={8}>
          <Paper sx={{ p: 3, height: 400 }}>
            <Typography variant="h6" gutterBottom>
              User Growth (Last 30 Days)
            </Typography>
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={userGrowth?.userGrowth || []}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <RechartsTooltip />
                <Line
                  type="monotone"
                  dataKey="new_users"
                  stroke="#1976d2"
                  strokeWidth={2}
                  dot={{ fill: '#1976d2' }}
                />
              </LineChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>

        {/* Subscription Distribution */}
        <Grid item xs={12} lg={4}>
          <Paper sx={{ p: 3, height: 400 }}>
            <Typography variant="h6" gutterBottom>
              Subscription Plans
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
                <RechartsTooltip />
              </PieChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>
      </Grid>

      {/* Charts Row 2 */}
      <Grid container spacing={3}>
        {/* Book Performance */}
        <Grid item xs={12} lg={6}>
          <Paper sx={{ p: 3, height: 400 }}>
            <Typography variant="h6" gutterBottom>
              Top Performing Books
            </Typography>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={bookPerformance?.bookPerformance || []}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="title" />
                <YAxis />
                <RechartsTooltip />
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
            <Box display="flex" flexDirection="column" gap={2}>
              <Box>
                <Typography variant="body2" color="textSecondary">
                  Monthly Recurring Revenue (MRR)
                </Typography>
                <Typography variant="h4" fontWeight="bold" color="primary">
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
    </Box>
  )
}

export default DashboardPage
