import React, { useState, useEffect } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  Box,
  Typography,
  Paper,
  Grid,
  Card,
  CardContent,
  Chip,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
  CircularProgress,
  useTheme,
  Tabs,
  Tab
} from '@mui/material';
import {
  Timeline as TimelineIcon,
  TrendingUp as TrendingUpIcon,
  AccessTime as AccessTimeIcon,
  Psychology as BehaviorIcon,
  Analytics as AnalyticsIcon,
  Refresh as RefreshIcon,
  Group as GroupIcon
} from '@mui/icons-material';
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip as RechartsTooltip,
  Legend,
  ResponsiveContainer
} from 'recharts';
import { getUserActivity } from '../../services/adminAPI';

const UserActivityPage: React.FC = () => {
  const theme = useTheme();
  const [selectedPeriod, setSelectedPeriod] = useState('7');
  const [activeTab, setActiveTab] = useState(0);

  // Fetch activity data
  const { data: activityData, isLoading, error, refetch } = useQuery({
    queryKey: ['user-activity', selectedPeriod],
    queryFn: () => getUserActivity(selectedPeriod),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });

  // Debug logging
  useEffect(() => {
    console.log('🔍 UserActivityPage - Period:', selectedPeriod);
    console.log('🔍 UserActivityPage - Activity data received:', activityData);
    console.log('🔍 UserActivityPage - Error:', error);
  }, [activityData, error, selectedPeriod]);

  if (error) {
    console.error('❌ UserActivityPage Error:', error);
    return (
      <Alert severity="error" sx={{ mb: 3 }}>
        Error loading activity data. Please try again later.
      </Alert>
    );
  }

  return (
    <Box>
      {/* Header */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h5" fontWeight="bold">
          User Activity Monitoring
        </Typography>
        <Button
          variant="outlined"
          startIcon={<RefreshIcon />}
          onClick={() => refetch()}
          size="small"
        >
          Refresh
        </Button>
      </Box>

      {/* Period Selector */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <FormControl size="small" sx={{ minWidth: 200 }}>
          <InputLabel>Time Period</InputLabel>
          <Select
            value={selectedPeriod}
            onChange={(e) => setSelectedPeriod(e.target.value)}
            label="Time Period"
          >
            <MenuItem value="7">Last 7 Days</MenuItem>
            <MenuItem value="30">Last 30 Days</MenuItem>
            <MenuItem value="90">Last 3 Months</MenuItem>
          </Select>
        </FormControl>
      </Paper>

      {/* Tabs */}
      <Paper sx={{ mb: 3 }}>
        <Tabs value={activeTab} onChange={(e, newValue) => setActiveTab(newValue)}>
          <Tab label="Overview" icon={<AnalyticsIcon />} />
          <Tab label="Activity Feed" icon={<TimelineIcon />} />
          <Tab label="Charts" icon={<TrendingUpIcon />} />
        </Tabs>
      </Paper>

      {/* Loading State */}
      {isLoading && (
        <Box display="flex" justifyContent="center" py={4}>
          <CircularProgress />
        </Box>
      )}

      {/* Tab Content */}
      {!isLoading && (
        <>
          {activeTab === 0 && (
            <Box>
              {/* Key Metrics */}
              <Grid container spacing={3} mb={3}>
                <Grid item xs={6} sm={6} md={3}>
                  <Card>
                    <CardContent sx={{ textAlign: 'center', py: 2 }}>
                      <GroupIcon sx={{ fontSize: 40, color: 'primary.main', mb: 1 }} />
                      <Typography variant="h4" fontWeight="bold" color="primary">
                        {activityData?.summary?.total_users || 0}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        Total Users
                      </Typography>
                    </CardContent>
                  </Card>
                </Grid>
                <Grid item xs={6} sm={6} md={3}>
                  <Card>
                    <CardContent sx={{ textAlign: 'center', py: 2 }}>
                      <AccessTimeIcon sx={{ fontSize: 40, color: 'success.main', mb: 1 }} />
                      <Typography variant="h4" fontWeight="bold" color="success.main">
                        {activityData?.summary?.active_today || 0}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        Active Today
                      </Typography>
                    </CardContent>
                  </Card>
                </Grid>
                <Grid item xs={6} sm={6} md={3}>
                  <Card>
                    <CardContent sx={{ textAlign: 'center', py: 2 }}>
                      <TrendingUpIcon sx={{ fontSize: 40, color: 'warning.main', mb: 1 }} />
                      <Typography variant="h4" fontWeight="bold" color="warning.main">
                        {activityData?.summary?.active_this_week || 0}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        Active This Week
                      </Typography>
                    </CardContent>
                  </Card>
                </Grid>
                <Grid item xs={6} sm={6} md={3}>
                  <Card>
                    <CardContent sx={{ textAlign: 'center', py: 2 }}>
                      <BehaviorIcon sx={{ fontSize: 40, color: 'info.main', mb: 1 }} />
                      <Typography variant="h4" fontWeight="bold" color="info.main">
                        {activityData?.summary?.active_this_month || 0}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        Active This Month
                      </Typography>
                    </CardContent>
                  </Card>
                </Grid>
              </Grid>

              {/* Data Status */}
              <Paper sx={{ p: 3, mb: 3 }}>
                <Typography variant="h6" mb={2}>Data Status</Typography>
                <Grid container spacing={2}>
                  <Grid item xs={12} md={6}>
                    <Typography variant="body2">
                      <strong>Period:</strong> {activityData?.period || `${selectedPeriod} days`}
                    </Typography>
                    <Typography variant="body2">
                      <strong>Data Generated:</strong> {activityData?.generatedAt ? new Date(activityData.generatedAt).toLocaleString() : 'N/A'}
                    </Typography>
                  </Grid>
                  <Grid item xs={12} md={6}>
                    <Typography variant="body2">
                      <strong>Activity Data Points:</strong> {activityData?.activityData?.length || 0}
                    </Typography>
                    <Typography variant="body2">
                      <strong>Hourly Patterns:</strong> {activityData?.hourlyPatterns?.length || 0}
                    </Typography>
                  </Grid>
                </Grid>
              </Paper>
            </Box>
          )}

          {activeTab === 1 && (
            <Box>
              {/* Recent Activities */}
              <Paper sx={{ p: 3, mb: 3 }}>
                <Typography variant="h6" mb={2}>Recent Activities</Typography>
                {activityData?.recentActivities && activityData.recentActivities.length > 0 ? (
                  <Box maxHeight={400} overflow="auto">
                    {activityData.recentActivities.map((activity: any, index: number) => (
                      <Box key={index} sx={{ p: 2, borderBottom: '1px solid', borderColor: 'divider' }}>
                        <Box display="flex" justifyContent="space-between" alignItems="center">
                          <Box>
                            <Typography variant="body2" fontWeight="bold">
                              {activity.userName || 'Unknown User'}
                            </Typography>
                            <Typography variant="caption" color="text.secondary">
                              {activity.activityType} • {new Date(activity.timestamp).toLocaleString()}
                            </Typography>
                          </Box>
                          <Chip 
                            label={activity.activityType} 
                            size="small" 
                            color="primary" 
                            variant="outlined"
                          />
                        </Box>
                      </Box>
                    ))}
                  </Box>
                ) : (
                  <Box textAlign="center" py={4}>
                    <Typography color="text.secondary">
                      No recent activities available
                    </Typography>
                  </Box>
                )}
              </Paper>
            </Box>
          )}

          {activeTab === 2 && (
            <Box>
              {/* Activity Trends Chart */}
              {activityData?.activityData && activityData.activityData.length > 0 && (
                <Paper sx={{ p: 3, mb: 3 }}>
                  <Typography variant="h6" mb={2}>Activity Trends</Typography>
                  <ResponsiveContainer width="100%" height={400}>
                    <AreaChart data={activityData.activityData}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="date" />
                      <YAxis />
                      <RechartsTooltip />
                      <Legend />
                      <Area type="monotone" dataKey="sessions" stackId="1" stroke="#8884d8" fill="#8884d8" />
                      <Area type="monotone" dataKey="activeUsers" stackId="1" stroke="#82ca9d" fill="#82ca9d" />
                      <Area type="monotone" dataKey="pageViews" stackId="1" stroke="#ffc658" fill="#ffc658" />
                    </AreaChart>
                  </ResponsiveContainer>
                </Paper>
              )}

              {/* Hourly Activity Pattern */}
              {activityData?.hourlyPatterns && activityData.hourlyPatterns.length > 0 && (
                <Paper sx={{ p: 3, mb: 3 }}>
                  <Typography variant="h6" mb={2}>Hourly Activity Pattern</Typography>
                  <ResponsiveContainer width="100%" height={300}>
                    <BarChart data={activityData.hourlyPatterns}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="hour" />
                      <YAxis />
                      <RechartsTooltip />
                      <Legend />
                      <Bar dataKey="activity_count" fill="#8884d8" />
                    </BarChart>
                  </ResponsiveContainer>
                </Paper>
              )}

              {/* No Data Message */}
              {(!activityData?.activityData || activityData.activityData.length === 0) && 
               (!activityData?.hourlyPatterns || activityData.hourlyPatterns.length === 0) && (
                <Paper sx={{ p: 3, textAlign: 'center' }}>
                  <Typography color="text.secondary">
                    No chart data available for the selected period
                  </Typography>
                </Paper>
              )}
            </Box>
          )}
        </>
      )}

    </Box>
  );
};

export default UserActivityPage;
