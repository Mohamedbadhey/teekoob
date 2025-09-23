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
  Group as GroupIcon,
  Analytics as AnalyticsIcon,
  Campaign as CampaignIcon,
  Add as AddIcon,
  Refresh as RefreshIcon
} from '@mui/icons-material';
import {
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
import { getUserSegmentation } from '../../services/adminAPI';

const UserSegmentationPage: React.FC = () => {
  const theme = useTheme();
  const [activeTab, setActiveTab] = useState(0);
  const [selectedPeriod, setSelectedPeriod] = useState('30');

  // Fetch segmentation data
  const { data: segmentationData, isLoading, error, refetch } = useQuery({
    queryKey: ['user-segmentation', selectedPeriod],
    queryFn: () => getUserSegmentation(selectedPeriod),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });

  // Debug logging
  useEffect(() => {
    console.log('🔍 UserSegmentationPage - Period:', selectedPeriod);
    console.log('🔍 UserSegmentationPage - Segmentation data received:', segmentationData);
    console.log('🔍 UserSegmentationPage - Error:', error);
  }, [segmentationData, error, selectedPeriod]);

  if (error) {
    console.error('❌ UserSegmentationPage Error:', error);
    return (
      <Alert severity="error" sx={{ mb: 3 }}>
        Error loading segmentation data. Please try again later.
      </Alert>
    );
  }

  return (
    <Box>
      {/* Header */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h5" fontWeight="bold">
          User Segmentation & Targeting
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
          <Tab label="Segments" icon={<GroupIcon />} />
          <Tab label="Analytics" icon={<AnalyticsIcon />} />
          <Tab label="Campaigns" icon={<CampaignIcon />} />
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
              {/* User Segments */}
              <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
                <Typography variant="h6">User Segments</Typography>
                <Button variant="contained" startIcon={<AddIcon />}>
                  Create Segment
                </Button>
              </Box>

              {segmentationData?.segments && segmentationData.segments.length > 0 ? (
                <Grid container spacing={3}>
                  {segmentationData.segments.map((segment: any, index: number) => (
                    <Grid item xs={12} md={4} key={index}>
                      <Card>
                        <CardContent>
                          <Typography variant="h6" color="primary">
                            {segment.segment_name || 'Unknown Segment'}
                          </Typography>
                          <Typography variant="body2" color="text.secondary" mb={2}>
                            {segment.description || 'No description available'}
                          </Typography>
                          <Chip 
                            label={`${segment.user_count || 0} users`} 
                            color={index % 3 === 0 ? 'success' : index % 3 === 1 ? 'warning' : 'info'} 
                            size="small" 
                          />
                        </CardContent>
                      </Card>
                    </Grid>
                  ))}
                </Grid>
              ) : (
                <Alert severity="info">No segmentation data available for the selected period</Alert>
              )}

              {/* Data Status */}
              {segmentationData && (
                <Paper sx={{ p: 3, mt: 3 }}>
                  <Typography variant="h6" mb={2}>Data Status</Typography>
                  <Grid container spacing={2}>
                    <Grid item xs={12} md={6}>
                      <Typography variant="body2">
                        <strong>Period:</strong> {segmentationData.period || `${selectedPeriod} days`}
                      </Typography>
                      <Typography variant="body2">
                        <strong>Total Segments:</strong> {segmentationData.totalSegments || 0}
                      </Typography>
                    </Grid>
                    <Grid item xs={12} md={6}>
                      <Typography variant="body2">
                        <strong>Data Generated:</strong> {segmentationData.generatedAt ? new Date(segmentationData.generatedAt).toLocaleString() : 'N/A'}
                      </Typography>
                      <Typography variant="body2">
                        <strong>Segment Metrics:</strong> {segmentationData.segmentMetrics?.length || 0}
                      </Typography>
                    </Grid>
                  </Grid>
                </Paper>
              )}
            </Box>
          )}

          {activeTab === 1 && (
            <Box>
              {/* Behavioral Analytics */}
              <Typography variant="h6" mb={3}>Behavioral Analytics</Typography>
              
              {segmentationData?.segmentMetrics && segmentationData.segmentMetrics.length > 0 ? (
                <Grid container spacing={3}>
                  <Grid item xs={12} md={6}>
                    <Paper sx={{ p: 3 }}>
                      <Typography variant="h6" mb={2}>Subscription Plan Distribution</Typography>
                      <ResponsiveContainer width="100%" height={300}>
                        <BarChart data={segmentationData.segmentMetrics}>
                          <CartesianGrid strokeDasharray="3 3" />
                          <XAxis dataKey="subscription_plan" />
                          <YAxis />
                          <RechartsTooltip />
                          <Legend />
                          <Bar dataKey="total_users" fill="#8884d8" name="Total Users" />
                          <Bar dataKey="active_users" fill="#82ca9d" name="Active Users" />
                        </BarChart>
                      </ResponsiveContainer>
                    </Paper>
                  </Grid>
                  <Grid item xs={12} md={6}>
                    <Paper sx={{ p: 3 }}>
                      <Typography variant="h6" mb={2}>Engagement Rates</Typography>
                      <ResponsiveContainer width="100%" height={300}>
                        <BarChart data={segmentationData.segmentMetrics}>
                          <CartesianGrid strokeDasharray="3 3" />
                          <XAxis dataKey="subscription_plan" />
                          <YAxis />
                          <RechartsTooltip />
                          <Legend />
                          <Bar dataKey="engagement_rate" fill="#ffc658" name="Engagement %" />
                        </BarChart>
                      </ResponsiveContainer>
                    </Paper>
                  </Grid>
                </Grid>
              ) : (
                <Alert severity="info">No analytics data available</Alert>
              )}
            </Box>
          )}

          {activeTab === 2 && (
            <Box>
              {/* Marketing Campaigns */}
              <Typography variant="h6" mb={3}>Marketing Campaigns</Typography>
              <Grid container spacing={3}>
                <Grid item xs={12} md={6}>
                  <Card>
                    <CardContent>
                      <Typography variant="h6">Welcome Series</Typography>
                      <Typography variant="body2" color="text.secondary" mb={2}>
                        Onboarding emails for new users
                      </Typography>
                      <Chip label="Active" color="success" size="small" />
                    </CardContent>
                  </Card>
                </Grid>
                <Grid item xs={12} md={6}>
                  <Card>
                    <CardContent>
                      <Typography variant="h6">Premium Upsell</Typography>
                      <Typography variant="body2" color="text.secondary" mb={2}>
                        Target free users for premium upgrade
                      </Typography>
                      <Chip label="Scheduled" color="warning" size="small" />
                    </CardContent>
                  </Card>
                </Grid>
              </Grid>
            </Box>
          )}
        </>
      )}

    </Box>
  );
};

export default UserSegmentationPage;
