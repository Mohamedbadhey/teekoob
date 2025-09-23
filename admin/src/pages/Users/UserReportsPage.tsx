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
  Assessment as AssessmentIcon,
  Download as DownloadIcon,
  Refresh as RefreshIcon
} from '@mui/icons-material';
import { Button } from '@mui/material';
import { getUserReports } from '../../services/adminAPI';

const UserReportsPage: React.FC = () => {
  const theme = useTheme();
  const [reportType, setReportType] = useState('overview');
  const [period, setPeriod] = useState('30');

  const { data: reportData, isLoading, error, refetch } = useQuery({
    queryKey: ['user-reports', reportType, period],
    queryFn: () => getUserReports(reportType, period),
    staleTime: 10 * 60 * 1000,
  });

  if (isLoading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress size={60} />
      </Box>
    );
  }

  if (error) {
    return (
      <Alert severity="error" sx={{ mb: 3 }}>
        Error loading report data. Please try again later.
      </Alert>
    );
  }

  return (
    <Box>
      {/* Header */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={4}>
        <Box>
          <Typography variant="h4" fontWeight="bold" gutterBottom>
            User Reports & Insights
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Comprehensive user reports and analytics
          </Typography>
        </Box>
        
        <Box display="flex" gap={2}>
          <FormControl sx={{ minWidth: 120 }}>
            <InputLabel>Report Type</InputLabel>
            <Select
              value={reportType}
              label="Report Type"
              onChange={(e) => setReportType(e.target.value)}
              size="small"
            >
              <MenuItem value="overview">Overview</MenuItem>
              <MenuItem value="subscription">Subscription</MenuItem>
              <MenuItem value="engagement">Engagement</MenuItem>
              <MenuItem value="geographic">Geographic</MenuItem>
              <MenuItem value="behavioral">Behavioral</MenuItem>
            </Select>
          </FormControl>
          
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
      </Box>

      {/* Report Content */}
      <Paper sx={{ p: 3 }}>
        <Box display="flex" alignItems="center" gap={2} mb={3}>
          <AssessmentIcon color="primary" />
          <Typography variant="h6" fontWeight="bold">
            {reportType.charAt(0).toUpperCase() + reportType.slice(1)} Report
          </Typography>
          <Box sx={{ ml: 'auto', display: 'flex', gap: 1 }}>
            <Button
              variant="outlined"
              startIcon={<RefreshIcon />}
              onClick={() => refetch()}
              size="small"
            >
              Refresh
            </Button>
            <Button
              variant="outlined"
              startIcon={<DownloadIcon />}
              size="small"
            >
              Export
            </Button>
          </Box>
        </Box>

        {reportData?.data && (
          <Box>
            <Typography variant="body1" color="text.secondary" gutterBottom>
              Generated on {new Date(reportData.generatedAt).toLocaleString()}
            </Typography>
            
            <Grid container spacing={3}>
              <Grid item xs={12}>
                <Paper sx={{ p: 2, backgroundColor: 'grey.50' }}>
                  <Typography variant="h6" gutterBottom>
                    Report Summary
                  </Typography>
                  <Box component="pre" sx={{ 
                    backgroundColor: 'white', 
                    p: 2, 
                    borderRadius: 1,
                    overflow: 'auto',
                    fontSize: '0.875rem',
                    border: '1px solid',
                    borderColor: 'divider'
                  }}>
                    {JSON.stringify(reportData.data, null, 2)}
                  </Box>
                </Paper>
              </Grid>
            </Grid>
          </Box>
        )}
      </Paper>
    </Box>
  );
};

export default UserReportsPage;
