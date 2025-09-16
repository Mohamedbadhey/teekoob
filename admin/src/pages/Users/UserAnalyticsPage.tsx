import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
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
  CircularProgress,
  Alert,
  Chip,
  useTheme
} from '@mui/material';
import {
  TrendingUp as TrendingIcon,
  People as PeopleIcon,
  Timeline as TimelineIcon,
  Assessment as AssessmentIcon,
  ShowChart as ShowChartIcon,
  Analytics as AnalyticsIcon
} from '@mui/icons-material';
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
  AreaChart,
  Area,
  PieChart,
  Pie,
  Cell
} from 'recharts';
import { getUserAnalytics, getUserStats } from '../../services/adminAPI';

const UserAnalyticsPage: React.FC = () => {
  const theme = useTheme();
  const [period, setPeriod] = useState('30');

  // Fetch analytics data
  const { data: analytics, isLoading: analyticsLoading, error: analyticsError } = useQuery({
    queryKey: ['user-analytics', period],
    queryFn: () => getUserAnalytics(period),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });

  const { data: stats, isLoading: statsLoading, error: statsError } = useQuery({
    queryKey: ['user-stats', period],
    queryFn: () => getUserStats(),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });

  const isLoading = analyticsLoading || statsLoading;
  const hasErrors = analyticsError || statsError;

  const chartColors = [
    theme.palette.primary.main,
    theme.palette.secondary.main,
    theme.palette.success.main,
    theme.palette.warning.main,
    theme.palette.error.main,
    theme.palette.info.main
  ];

  if (isLoading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress size={60} />
      </Box>
    );
  }

  if (hasErrors) {
    return (
      <Alert severity="error" sx={{ mb: 3 }}>
        Error loading analytics data. Please try again later.
      </Alert>
    );
  }

  return (
    <Box>
      {/* Header */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={4}>
        <Box>
          <Typography variant="h4" fontWeight="bold" gutterBottom>
            User Analytics & Insights
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Comprehensive analysis of user behavior, growth, and engagement patterns
          </Typography>
        </Box>
        
        <FormControl sx={{ minWidth: 120 }}>
          <InputLabel>Time Period</InputLabel>
          <Select
            value={period}
            label="Time Period"
            onChange={(e) => setPeriod(e.target.value)}
            size="small"
          >
            <MenuItem value="7">Last 7 days</MenuItem>
            <MenuItem value="30">Last 30 days</MenuItem>
            <MenuItem value="90">Last 3 months</MenuItem>
            <MenuItem value="365">Last year</MenuItem>
          </Select>
        </FormControl>
      </Box>

      {/* Key Metrics Cards */}
      <Grid container spacing={3} mb={4}>
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ height: '100%', background: `linear-gradient(135deg, ${theme.palette.primary.main}15, ${theme.palette.primary.main}25)` }}>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" gutterBottom variant="h6">
                    Total Users
                  </Typography>
                  <Typography variant="h4" component="div" fontWeight="bold" color="primary">
                    {stats?.totalUsers || 0}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Registered users
                  </Typography>
                </Box>
                <Box
                  sx={{
                    backgroundColor: theme.palette.primary.main,
                    borderRadius: '50%',
                    p: 1.5,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <PeopleIcon sx={{ color: 'white', fontSize: 28 }} />
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ height: '100%', background: `linear-gradient(135deg, ${theme.palette.success.main}15, ${theme.palette.success.main}25)` }}>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" gutterBottom variant="h6">
                    Active Users
                  </Typography>
                  <Typography variant="h4" component="div" fontWeight="bold" color="success.main">
                    {stats?.activeUsers || 0}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Currently active
                  </Typography>
                </Box>
                <Box
                  sx={{
                    backgroundColor: theme.palette.success.main,
                    borderRadius: '50%',
                    p: 1.5,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <TrendingIcon sx={{ color: 'white', fontSize: 28 }} />
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ height: '100%', background: `linear-gradient(135deg, ${theme.palette.warning.main}15, ${theme.palette.warning.main}25)` }}>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" gutterBottom variant="h6">
                    New Users
                  </Typography>
                  <Typography variant="h4" component="div" fontWeight="bold" color="warning.main">
                    {stats?.newUsers || 0}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    In last {period} days
                  </Typography>
                </Box>
                <Box
                  sx={{
                    backgroundColor: theme.palette.warning.main,
                    borderRadius: '50%',
                    p: 1.5,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <TimelineIcon sx={{ color: 'white', fontSize: 28 }} />
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ height: '100%', background: `linear-gradient(135deg, ${theme.palette.info.main}15, ${theme.palette.info.main}25)` }}>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" gutterBottom variant="h6">
                    Recent Logins
                  </Typography>
                  <Typography variant="h4" component="div" fontWeight="bold" color="info.main">
                    {stats?.recentLogins || 0}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Last 7 days
                  </Typography>
                </Box>
                <Box
                  sx={{
                    backgroundColor: theme.palette.info.main,
                    borderRadius: '50%',
                    p: 1.5,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <AssessmentIcon sx={{ color: 'white', fontSize: 28 }} />
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Charts Row 1 */}
      <Grid container spacing={3} mb={4}>
        {/* User Growth Chart */}
        <Grid item xs={12} lg={8}>
          <Paper sx={{ p: 3, height: 400 }}>
            <Box display="flex" alignItems="center" gap={1} mb={2}>
              <ShowChartIcon color="primary" />
              <Typography variant="h6" fontWeight="bold">
                User Growth Trend
              </Typography>
            </Box>
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={analytics?.userGrowth || []}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Area
                  type="monotone"
                  dataKey="new_users"
                  stroke={theme.palette.primary.main}
                  fill={theme.palette.primary.main}
                  fillOpacity={0.3}
                  name="New Users"
                />
                <Area
                  type="monotone"
                  dataKey="cumulative_users"
                  stroke={theme.palette.secondary.main}
                  fill={theme.palette.secondary.main}
                  fillOpacity={0.1}
                  name="Total Users"
                />
              </AreaChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>

        {/* User Activity Patterns */}
        <Grid item xs={12} lg={4}>
          <Paper sx={{ p: 3, height: 400 }}>
            <Box display="flex" alignItems="center" gap={1} mb={2}>
              <AnalyticsIcon color="secondary" />
              <Typography variant="h6" fontWeight="bold">
                Activity Patterns
              </Typography>
            </Box>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={analytics?.activityPatterns || []}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="hour" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="login_count" fill={theme.palette.secondary.main} name="Logins" />
              </BarChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>
      </Grid>

      {/* Charts Row 2 */}
      <Grid container spacing={3} mb={4}>
        {/* Engagement by Plan */}
        <Grid item xs={12} lg={6}>
          <Paper sx={{ p: 3, height: 400 }}>
            <Box display="flex" alignItems="center" gap={1} mb={2}>
              <AssessmentIcon color="success" />
              <Typography variant="h6" fontWeight="bold">
                Engagement by Subscription Plan
              </Typography>
            </Box>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={analytics?.engagementByPlan || []}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="subscription_plan" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="user_count" fill={theme.palette.success.main} name="Users" />
                <Bar dataKey="total_books" fill={theme.palette.info.main} name="Books" />
              </BarChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>

        {/* User Retention */}
        <Grid item xs={12} lg={6}>
          <Paper sx={{ p: 3, height: 400 }}>
            <Box display="flex" alignItems="center" gap={1} mb={2}>
              <TrendingIcon color="warning" />
              <Typography variant="h6" fontWeight="bold">
                User Retention Analysis
              </Typography>
            </Box>
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={analytics?.retentionData || []}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="week" />
                <YAxis />
                <Tooltip />
                <Line
                  type="monotone"
                  dataKey="new_users"
                  stroke={theme.palette.primary.main}
                  strokeWidth={2}
                  name="New Users"
                />
                <Line
                  type="monotone"
                  dataKey="retained_7d"
                  stroke={theme.palette.success.main}
                  strokeWidth={2}
                  name="7-Day Retention"
                />
                <Line
                  type="monotone"
                  dataKey="retained_30d"
                  stroke={theme.palette.warning.main}
                  strokeWidth={2}
                  name="30-Day Retention"
                />
              </LineChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>
      </Grid>

      {/* Breakdown Statistics */}
      <Grid container spacing={3}>
        {/* Users by Plan */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3, height: 300 }}>
            <Typography variant="h6" fontWeight="bold" gutterBottom>
              Users by Subscription Plan
            </Typography>
            <Box display="flex" flexDirection="column" gap={2}>
              {stats?.breakdown?.byPlan?.map((plan: any, index: number) => (
                <Box key={plan.subscription_plan} display="flex" justifyContent="space-between" alignItems="center">
                  <Box display="flex" alignItems="center" gap={1}>
                    <Chip 
                      label={plan.subscription_plan} 
                      size="small" 
                      color={index === 0 ? 'primary' : 'default'}
                      variant={index === 0 ? 'filled' : 'outlined'}
                    />
                  </Box>
                  <Typography variant="h6" fontWeight="bold">
                    {plan.count}
                  </Typography>
                </Box>
              ))}
            </Box>
          </Paper>
        </Grid>

        {/* Users by Language */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3, height: 300 }}>
            <Typography variant="h6" fontWeight="bold" gutterBottom>
              Users by Language Preference
            </Typography>
            <Box display="flex" flexDirection="column" gap={2}>
              {stats?.breakdown?.byLanguage?.map((lang: any, index: number) => (
                <Box key={lang.language_preference} display="flex" justifyContent="space-between" alignItems="center">
                  <Box display="flex" alignItems="center" gap={1}>
                    <Chip 
                      label={lang.language_preference} 
                      size="small" 
                      color={index === 0 ? 'success' : 'default'}
                      variant={index === 0 ? 'filled' : 'outlined'}
                    />
                  </Box>
                  <Typography variant="h6" fontWeight="bold">
                    {lang.count}
                  </Typography>
                </Box>
              ))}
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default UserAnalyticsPage;
