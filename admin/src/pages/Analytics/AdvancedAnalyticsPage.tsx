import React, { useState, useMemo } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Tabs,
  Tab,
  Chip,
  LinearProgress,
  Alert,
  IconButton,
  Tooltip,
  Button
} from '@mui/material';
import {
  TrendingUp as TrendingIcon,
  People as PeopleIcon,
  Book as BookIcon,
  MonetizationOn as MoneyIcon,
  Download as DownloadIcon,
  Star as StarIcon,
  Language as LanguageIcon,
  Category as CategoryIcon,
  Refresh as RefreshIcon,
  Download as ExportIcon
} from '@mui/icons-material';
import {
  LineChart,
  Line,
  AreaChart,
  Area,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip as RechartsTooltip,
  Legend,
  ResponsiveContainer
} from 'recharts';
import { useQuery } from '@tanstack/react-query';
import { 
  getDashboardOverview, 
  getUserGrowth, 
  getBookPerformance, 
  getSubscriptionAnalytics 
} from '../../services/adminAPI';
import { format, subDays, startOfDay, endOfDay } from 'date-fns';

interface AnalyticsData {
  overview: {
    totalUsers: number;
    newUsers: number;
    totalBooks: number;
    activeSubscriptions: number;
    revenue: number;
    totalDownloads: number;
    averageRating: number;
  };
  userGrowth: Array<{
    date: string;
    new_users: number;
    active_users: number;
  }>;
  bookPerformance: Array<{
    id: string;
    title: string;
    authors: string;
    rating: number;
    review_count: number;
    downloads: number;
    is_featured: boolean;
  }>;
  subscriptionAnalytics: {
    planDistribution: Array<{
      plan_type: string;
      count: number;
    }>;
    mrr: number;
    churnRate: number;
    revenueGrowth: Array<{
      month: string;
      revenue: number;
    }>;
  };
  contentAnalytics: {
    booksByLanguage: Array<{
      language: string;
      count: number;
    }>;
    booksByFormat: Array<{
      format: string;
      count: number;
    }>;
    booksByGenre: Array<{
      genre: string;
      count: number;
    }>;
    topGenres: Array<{
      genre: string;
      downloads: number;
      rating: number;
    }>;
  };
  systemMetrics: {
    serverHealth: 'healthy' | 'warning' | 'critical';
    databasePerformance: number;
    apiResponseTime: number;
    activeConnections: number;
    storageUsage: number;
  };
}

const AdvancedAnalyticsPage: React.FC = () => {
  const [timeRange, setTimeRange] = useState('30');
  const [activeTab, setActiveTab] = useState(0);

  // Fetch comprehensive analytics data
  const { data: analyticsData, isLoading, error } = useQuery({
    queryKey: ['advancedAnalytics', timeRange],
    queryFn: () => getAdvancedAnalytics(timeRange),
    staleTime: 300000, // 5 minutes
  });

  // Mock data for demonstration
  const mockData: AnalyticsData = {
    overview: {
      totalUsers: 1250,
      newUsers: 45,
      totalBooks: 320,
      activeSubscriptions: 890,
      revenue: 12500,
      totalDownloads: 45600,
      averageRating: 4.2
    },
    userGrowth: Array.from({ length: 30 }, (_, i) => ({
      date: format(subDays(new Date(), 29 - i), 'MMM dd'),
      new_users: Math.floor(Math.random() * 20) + 5,
      active_users: Math.floor(Math.random() * 100) + 200
    })),
    bookPerformance: [
      { id: '1', title: 'The Great Adventure', authors: 'John Doe', rating: 4.8, review_count: 156, downloads: 1200, is_featured: true },
      { id: '2', title: 'Learning Somali', authors: 'Amina Hassan', rating: 4.6, review_count: 89, downloads: 890, is_featured: true },
      { id: '3', title: 'Science Today', authors: 'Dr. Smith', rating: 4.4, review_count: 234, downloads: 756, is_featured: false },
      { id: '4', title: 'Children Stories', authors: 'Maria Garcia', rating: 4.7, review_count: 67, downloads: 1100, is_featured: true },
      { id: '5', title: 'Business Guide', authors: 'Robert Chen', rating: 4.3, review_count: 123, downloads: 543, is_featured: false }
    ],
    subscriptionAnalytics: {
      planDistribution: [
        { plan_type: 'Free', count: 450 },
        { plan_type: 'Premium', count: 320 },
        { plan_type: 'Lifetime', count: 120 }
      ],
      mrr: 12500,
      churnRate: 2.3,
      revenueGrowth: Array.from({ length: 12 }, (_, i) => ({
        month: format(new Date(2024, i, 1), 'MMM'),
        revenue: Math.floor(Math.random() * 5000) + 8000
      }))
    },
    contentAnalytics: {
      booksByLanguage: [
        { language: 'English', count: 180 },
        { language: 'Somali', count: 95 },
        { language: 'Arabic', count: 45 }
      ],
      booksByFormat: [
        { format: 'E-Book', count: 200 },
        { format: 'Audio', count: 80 },
        { format: 'Both', count: 40 }
      ],
      booksByGenre: [
        { genre: 'Fiction', count: 120 },
        { genre: 'Educational', count: 100 },
        { genre: 'Children', count: 60 },
        { genre: 'Non-Fiction', count: 40 }
      ],
      topGenres: [
        { genre: 'Fiction', downloads: 18000, rating: 4.5 },
        { genre: 'Educational', downloads: 15000, rating: 4.3 },
        { genre: 'Children', downloads: 12000, rating: 4.7 },
        { genre: 'Non-Fiction', downloads: 6000, rating: 4.1 }
      ]
    },
    systemMetrics: {
      serverHealth: 'healthy',
      databasePerformance: 95,
      apiResponseTime: 120,
      activeConnections: 45,
      storageUsage: 78
    }
  };

  const data = analyticsData || mockData;

  // Color schemes for charts
  const colors = ['#8884d8', '#82ca9d', '#ffc658', '#ff7300', '#8dd1e1'];
  const statusColors = {
    healthy: 'success',
    warning: 'warning',
    critical: 'error'
  };

  // Render overview metrics
  const renderOverviewMetrics = () => (
    <Grid container spacing={3} sx={{ mb: 4 }}>
      <Grid item xs={12} sm={6} md={3}>
        <Card>
          <CardContent>
            <Box display="flex" alignItems="center">
              <PeopleIcon color="primary" sx={{ mr: 2, fontSize: 40 }} />
              <Box>
                <Typography variant="h4">{data.overview.totalUsers.toLocaleString()}</Typography>
                <Typography variant="body2" color="textSecondary">Total Users</Typography>
                <Typography variant="caption" color="success.main">
                  +{data.overview.newUsers} this period
                </Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={12} sm={6} md={3}>
        <Card>
          <CardContent>
            <Box display="flex" alignItems="center">
              <BookIcon color="secondary" sx={{ mr: 2, fontSize: 40 }} />
              <Box>
                <Typography variant="h4">{data.overview.totalBooks}</Typography>
                <Typography variant="body2" color="textSecondary">Total Books</Typography>
                <Typography variant="caption" color="info.main">
                  {data.overview.totalDownloads.toLocaleString()} downloads
                </Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={12} sm={6} md={3}>
        <Card>
          <CardContent>
            <Box display="flex" alignItems="center">
              <MoneyIcon color="success" sx={{ mr: 2, fontSize: 40 }} />
              <Box>
                <Typography variant="h4">${data.overview.revenue.toLocaleString()}</Typography>
                <Typography variant="body2" color="textSecondary">Monthly Revenue</Typography>
                <Typography variant="caption" color="success.main">
                  {data.overview.activeSubscriptions} active subs
                </Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={12} sm={6} md={3}>
        <Card>
          <CardContent>
            <Box display="flex" alignItems="center">
              <StarIcon color="warning" sx={{ mr: 2, fontSize: 40 }} />
              <Box>
                <Typography variant="h4">{data.overview.averageRating}</Typography>
                <Typography variant="body2" color="textSecondary">Avg Rating</Typography>
                <Typography variant="caption" color="warning.main">
                  Across all books
                </Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  );

  // Render user growth chart
  const renderUserGrowthChart = () => (
    <Card sx={{ mb: 4 }}>
      <CardContent>
        <Box display="flex" justifyContent="space-between" alignItems="center" sx={{ mb: 2 }}>
          <Typography variant="h6">User Growth & Activity</Typography>
          <Box display="flex" gap={1}>
            <Chip label="New Users" color="primary" size="small" />
            <Chip label="Active Users" color="success" size="small" />
          </Box>
        </Box>
        <ResponsiveContainer width="100%" height={300}>
          <AreaChart data={data.userGrowth}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="date" />
            <YAxis />
            <RechartsTooltip />
            <Legend />
            <Area type="monotone" dataKey="new_users" stackId="1" stroke="#8884d8" fill="#8884d8" />
            <Area type="monotone" dataKey="active_users" stackId="2" stroke="#82ca9d" fill="#82ca9d" />
          </AreaChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );

  // Render book performance chart
  const renderBookPerformanceChart = () => (
    <Card sx={{ mb: 4 }}>
      <CardContent>
        <Typography variant="h6" sx={{ mb: 2 }}>Top Performing Books</Typography>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={data.bookPerformance}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="title" />
            <YAxis />
            <RechartsTooltip />
            <Legend />
            <Bar dataKey="downloads" fill="#8884d8" />
            <Bar dataKey="rating" fill="#82ca9d" />
          </BarChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );

  // Render subscription analytics
  const renderSubscriptionAnalytics = () => (
    <Grid container spacing={3} sx={{ mb: 4 }}>
      <Grid item xs={12} md={6}>
        <Card>
          <CardContent>
            <Typography variant="h6" sx={{ mb: 2 }}>Subscription Plan Distribution</Typography>
            <ResponsiveContainer width="100%" height={250}>
              <PieChart>
                <Pie
                  data={data.subscriptionAnalytics.planDistribution}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ plan_type, percent }) => `${plan_type} ${(percent * 100).toFixed(0)}%`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="count"
                >
                  {data.subscriptionAnalytics.planDistribution.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={colors[index % colors.length]} />
                  ))}
                </Pie>
                <RechartsTooltip />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={12} md={6}>
        <Card>
          <CardContent>
            <Typography variant="h6" sx={{ mb: 2 }}>Revenue Growth</Typography>
            <ResponsiveContainer width="100%" height={250}>
              <LineChart data={data.subscriptionAnalytics.revenueGrowth}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month" />
                <YAxis />
                <RechartsTooltip />
                <Line type="monotone" dataKey="revenue" stroke="#8884d8" strokeWidth={2} />
              </LineChart>
            </ResponsiveContainer>
            <Box display="flex" justifyContent="space-around" sx={{ mt: 2 }}>
              <Box textAlign="center">
                <Typography variant="h6" color="success.main">
                  ${data.subscriptionAnalytics.mrr.toLocaleString()}
                </Typography>
                <Typography variant="caption">Monthly Recurring Revenue</Typography>
              </Box>
              <Box textAlign="center">
                <Typography variant="h6" color="error.main">
                  {data.subscriptionAnalytics.churnRate}%
                </Typography>
                <Typography variant="caption">Churn Rate</Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  );

  // Render content analytics
  const renderContentAnalytics = () => (
    <Grid container spacing={3} sx={{ mb: 4 }}>
      <Grid item xs={12} md={4}>
        <Card>
          <CardContent>
            <Typography variant="h6" sx={{ mb: 2 }}>Books by Language</Typography>
            <ResponsiveContainer width="100%" height={200}>
              <PieChart>
                <Pie
                  data={data.contentAnalytics.booksByLanguage}
                  cx="50%"
                  cy="50%"
                  outerRadius={60}
                  fill="#8884d8"
                  dataKey="count"
                  label={({ language, count }) => `${language}: ${count}`}
                >
                  {data.contentAnalytics.booksByLanguage.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={colors[index % colors.length]} />
                  ))}
                </Pie>
                <RechartsTooltip />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={12} md={4}>
        <Card>
          <CardContent>
            <Typography variant="h6" sx={{ mb: 2 }}>Books by Format</Typography>
            <ResponsiveContainer width="100%" height={200}>
              <PieChart>
                <Pie
                  data={data.contentAnalytics.booksByFormat}
                  cx="50%"
                  cy="50%"
                  outerRadius={60}
                  fill="#82ca9d"
                  dataKey="count"
                  label={({ format, count }) => `${format}: ${count}`}
                >
                  {data.contentAnalytics.booksByFormat.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={colors[index % colors.length]} />
                  ))}
                </Pie>
                <RechartsTooltip />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={12} md={4}>
        <Card>
          <CardContent>
            <Typography variant="h6" sx={{ mb: 2 }}>Top Genres Performance</Typography>
            <Box>
              {data.contentAnalytics.topGenres.map((genre, index) => (
                <Box key={genre.genre} sx={{ mb: 2 }}>
                  <Box display="flex" justifyContent="space-between" alignItems="center">
                    <Typography variant="body2">{genre.genre}</Typography>
                    <Typography variant="body2" color="textSecondary">
                      {genre.downloads.toLocaleString()} downloads
                    </Typography>
                  </Box>
                  <Box display="flex" alignItems="center" gap={1}>
                    <Rating value={genre.rating} readOnly size="small" />
                    <Typography variant="caption">{genre.rating}</Typography>
                  </Box>
                </Box>
              ))}
            </Box>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  );

  // Render system metrics
  const renderSystemMetrics = () => (
    <Card sx={{ mb: 4 }}>
      <CardContent>
        <Typography variant="h6" sx={{ mb: 2 }}>System Health & Performance</Typography>
        <Grid container spacing={3}>
          <Grid item xs={12} sm={6} md={3}>
            <Box textAlign="center">
              <Chip 
                label={data.systemMetrics.serverHealth} 
                color={statusColors[data.systemMetrics.serverHealth]}
                sx={{ mb: 1 }}
              />
              <Typography variant="body2">Server Status</Typography>
            </Box>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Box textAlign="center">
              <Typography variant="h6" color="success.main">
                {data.systemMetrics.databasePerformance}%
              </Typography>
              <Typography variant="body2">Database Performance</Typography>
              <LinearProgress 
                variant="determinate" 
                value={data.systemMetrics.databasePerformance} 
                sx={{ mt: 1 }}
              />
            </Box>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Box textAlign="center">
              <Typography variant="h6" color="info.main">
                {data.systemMetrics.apiResponseTime}ms
              </Typography>
              <Typography variant="body2">API Response Time</Typography>
            </Box>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Box textAlign="center">
              <Typography variant="h6" color="warning.main">
                {data.systemMetrics.storageUsage}%
              </Typography>
              <Typography variant="body2">Storage Usage</Typography>
              <LinearProgress 
                variant="determinate" 
                value={data.systemMetrics.storageUsage} 
                sx={{ mt: 1 }}
              />
            </Box>
          </Grid>
        </Grid>
      </CardContent>
    </Card>
  );

  if (error) {
    return (
      <Alert severity="error" sx={{ m: 2 }}>
        Failed to load analytics: {error.message}
      </Alert>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box display="flex" justifyContent="space-between" alignItems="center" sx={{ mb: 3 }}>
        <Typography variant="h4">Advanced Analytics Dashboard</Typography>
        <Box display="flex" gap={1}>
          <FormControl size="small" sx={{ minWidth: 120 }}>
            <InputLabel>Time Range</InputLabel>
            <Select
              value={timeRange}
              onChange={(e) => setTimeRange(e.target.value)}
              label="Time Range"
            >
              <MenuItem value="7">Last 7 days</MenuItem>
              <MenuItem value="30">Last 30 days</MenuItem>
              <MenuItem value="90">Last 90 days</MenuItem>
              <MenuItem value="365">Last year</MenuItem>
            </Select>
          </FormControl>
          <Button
            variant="outlined"
            startIcon={<RefreshIcon />}
            onClick={() => window.location.reload()}
          >
            Refresh
          </Button>
          <Button
            variant="outlined"
            startIcon={<ExportIcon />}
            onClick={() => exportAnalytics(timeRange)}
          >
            Export
          </Button>
        </Box>
      </Box>

      <Tabs value={activeTab} onChange={(e, newValue) => setActiveTab(newValue)} sx={{ mb: 3 }}>
        <Tab label="Overview" />
        <Tab label="Users" />
        <Tab label="Content" />
        <Tab label="Revenue" />
        <Tab label="System" />
      </Tabs>

      {activeTab === 0 && (
        <Box>
          {renderOverviewMetrics()}
          {renderUserGrowthChart()}
          {renderBookPerformanceChart()}
        </Box>
      )}

      {activeTab === 1 && (
        <Box>
          {renderUserGrowthChart()}
          <Card sx={{ mb: 4 }}>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 2 }}>User Demographics</Typography>
              <Grid container spacing={3}>
                <Grid item xs={12} md={6}>
                  <Typography variant="body2" color="textSecondary">Language Preferences</Typography>
                  <Box sx={{ mt: 1 }}>
                    <Box display="flex" justifyContent="space-between" sx={{ mb: 1 }}>
                      <Typography variant="body2">English</Typography>
                      <Typography variant="body2">65%</Typography>
                    </Box>
                    <LinearProgress variant="determinate" value={65} sx={{ mb: 2 }} />
                    
                    <Box display="flex" justifyContent="space-between" sx={{ mb: 1 }}>
                      <Typography variant="body2">Somali</Typography>
                      <Typography variant="body2">25%</Typography>
                    </Box>
                    <LinearProgress variant="determinate" value={25} sx={{ mb: 2 }} />
                    
                    <Box display="flex" justifyContent="space-between" sx={{ mb: 1 }}>
                      <Typography variant="body2">Arabic</Typography>
                      <Typography variant="body2">10%</Typography>
                    </Box>
                    <LinearProgress variant="determinate" value={10} />
                  </Box>
                </Grid>
                <Grid item xs={12} md={6}>
                  <Typography variant="body2" color="textSecondary">Subscription Distribution</Typography>
                  <Box sx={{ mt: 1 }}>
                    <Box display="flex" justifyContent="space-between" sx={{ mb: 1 }}>
                      <Typography variant="body2">Free Users</Typography>
                      <Typography variant="body2">36%</Typography>
                    </Box>
                    <LinearProgress variant="determinate" value={36} sx={{ mb: 2 }} />
                    
                    <Box display="flex" justifyContent="space-between" sx={{ mb: 1 }}>
                      <Typography variant="body2">Premium Users</Typography>
                      <Typography variant="body2">29%</Typography>
                    </Box>
                    <LinearProgress variant="determinate" value={29} sx={{ mb: 2 }} />
                    
                    <Box display="flex" justifyContent="space-between" sx={{ mb: 1 }}>
                      <Typography variant="body2">Lifetime Users</Typography>
                      <Typography variant="body2">35%</Typography>
                    </Box>
                    <LinearProgress variant="determinate" value={35} />
                  </Box>
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Box>
      )}

      {activeTab === 2 && (
        <Box>
          {renderBookPerformanceChart()}
          {renderContentAnalytics()}
        </Box>
      )}

      {activeTab === 3 && (
        <Box>
          {renderSubscriptionAnalytics()}
          <Card sx={{ mb: 4 }}>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 2 }}>Revenue Breakdown</Typography>
              <Grid container spacing={3}>
                <Grid item xs={12} md={6}>
                  <Typography variant="body2" color="textSecondary">Revenue by Plan</Typography>
                  <Box sx={{ mt: 1 }}>
                    <Box display="flex" justifyContent="space-between" sx={{ mb: 1 }}>
                      <Typography variant="body2">Premium Subscriptions</Typography>
                      <Typography variant="body2">$8,400</Typography>
                    </Box>
                    <LinearProgress variant="determinate" value={67} sx={{ mb: 2 }} />
                    
                    <Box display="flex" justifyContent="space-between" sx={{ mb: 1 }}>
                      <Typography variant="body2">Lifetime Sales</Typography>
                      <Typography variant="body2">$4,100</Typography>
                    </Box>
                    <LinearProgress variant="determinate" value={33} />
                  </Box>
                </Grid>
                <Grid item xs={12} md={6}>
                  <Typography variant="body2" color="textSecondary">Growth Metrics</Typography>
                  <Box sx={{ mt: 1 }}>
                    <Box display="flex" justifyContent="space-between" sx={{ mb: 1 }}>
                      <Typography variant="body2">Monthly Growth</Typography>
                      <Typography variant="body2" color="success.main">+12.5%</Typography>
                    </Box>
                    <Box display="flex" justifyContent="space-between" sx={{ mb: 1 }}>
                      <Typography variant="body2">Churn Rate</Typography>
                      <Typography variant="body2" color="error.main">2.3%</Typography>
                    </Box>
                    <Box display="flex" justifyContent="space-between" sx={{ mb: 1 }}>
                      <Typography variant="body2">LTV</Typography>
                      <Typography variant="body2" color="info.main">$156</Typography>
                    </Box>
                  </Box>
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Box>
      )}

      {activeTab === 4 && (
        <Box>
          {renderSystemMetrics()}
          <Card sx={{ mb: 4 }}>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 2 }}>Performance Trends</Typography>
              <ResponsiveContainer width="100%" height={200}>
                <LineChart data={Array.from({ length: 24 }, (_, i) => ({
                  hour: i,
                  responseTime: Math.floor(Math.random() * 100) + 50,
                  connections: Math.floor(Math.random() * 50) + 20
                }))}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="hour" />
                  <YAxis />
                  <RechartsTooltip />
                  <Legend />
                  <Line type="monotone" dataKey="responseTime" stroke="#8884d8" name="Response Time (ms)" />
                  <Line type="monotone" dataKey="connections" stroke="#82ca9d" name="Active Connections" />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </Box>
      )}
    </Box>
  );
};

export default AdvancedAnalyticsPage;
