import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Tabs,
  Tab,
  Paper,
  Container,
  useTheme,
  useMediaQuery
} from '@mui/material';
import { useNavigate, useLocation } from 'react-router-dom';
import { useSelector } from 'react-redux';
import { RootState } from '../../store';

// Import the individual components
import AllUsersPage from './AllUsersPage';
import UserAnalyticsPage from './UserAnalyticsPage';
import UserReportsPage from './UserReportsPage';
import UserActivityPage from './UserActivityPage';
import UserSegmentationPage from './UserSegmentationPage';
import UserInsightsPage from './UserInsightsPage';

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`user-management-tabpanel-${index}`}
      aria-labelledby={`user-management-tab-${index}`}
      {...other}
    >
      {value === index && (
        <Box sx={{ py: 3 }}>
          {children}
        </Box>
      )}
    </div>
  );
}

function a11yProps(index: number) {
  return {
    id: `user-management-tab-${index}`,
    'aria-controls': `user-management-tabpanel-${index}`,
  };
}

const UserManagementPage: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const navigate = useNavigate();
  const location = useLocation();
  const currentUser = useSelector((state: RootState) => state.auth.user);
  const isAuthenticated = useSelector((state: RootState) => state.auth.isAuthenticated);

  // Check authentication
  useEffect(() => {
    if (!isAuthenticated || !currentUser?.isAdmin) {
      console.log('User not authenticated or not admin, redirecting to login');
      navigate('/login');
    }
  }, [isAuthenticated, currentUser, navigate]);

  // Don't render if not authenticated
  if (!isAuthenticated || !currentUser?.isAdmin) {
    return null;
  }

  // Determine active tab based on URL or default to 0
  const getInitialTab = () => {
    const path = location.pathname;
    if (path.includes('/analytics')) return 1;
    if (path.includes('/reports')) return 2;
    if (path.includes('/activity')) return 3;
    if (path.includes('/segmentation')) return 4;
    if (path.includes('/insights')) return 5;
    return 0;
  };

  const [value, setValue] = useState(getInitialTab());

  const handleChange = (event: React.SyntheticEvent, newValue: number) => {
    setValue(newValue);
    
    // Update URL based on selected tab
    switch (newValue) {
      case 0:
        navigate('/admin/users');
        break;
      case 1:
        navigate('/admin/users/analytics');
        break;
      case 2:
        navigate('/admin/users/reports');
        break;
      case 3:
        navigate('/admin/users/activity');
        break;
      case 4:
        navigate('/admin/users/segmentation');
        break;
      case 5:
        navigate('/admin/users/insights');
        break;
      default:
        navigate('/admin/users');
    }
  };

  return (
    <Container maxWidth="xl" sx={{ py: 3 }}>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Typography 
          variant="h3" 
          component="h1" 
          gutterBottom
          sx={{ 
            fontWeight: 'bold',
            color: theme.palette.primary.main,
            fontSize: { xs: '1.75rem', sm: '2.125rem', md: '2.5rem' }
          }}
        >
          User Management
        </Typography>
        <Typography 
          variant="body1" 
          color="text.secondary"
          sx={{ fontSize: { xs: '0.875rem', sm: '1rem' } }}
        >
          Comprehensive user management, analytics, insights, segmentation, and AI-powered predictive analytics
        </Typography>
      </Box>

      {/* Navigation Tabs */}
      <Paper 
        elevation={2} 
        sx={{ 
          mb: 3,
          borderRadius: 2,
          overflow: 'hidden'
        }}
      >
        <Tabs
          value={value}
          onChange={handleChange}
          aria-label="User management tabs"
          variant={isMobile ? "scrollable" : "fullWidth"}
          scrollButtons={isMobile ? "auto" : false}
          sx={{
            backgroundColor: theme.palette.background.paper,
            borderBottom: `1px solid ${theme.palette.divider}`,
            '& .MuiTab-root': {
              minHeight: 64,
              fontSize: { xs: '0.875rem', sm: '1rem' },
              fontWeight: 500,
              textTransform: 'none',
              '&.Mui-selected': {
                color: theme.palette.primary.main,
                fontWeight: 600,
              },
            },
            '& .MuiTabs-indicator': {
              height: 3,
              borderRadius: '3px 3px 0 0',
            },
          }}
        >
          <Tab 
            label={
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <span>👥</span>
                <span>All Users</span>
              </Box>
            }
            {...a11yProps(0)}
          />
          <Tab 
            label={
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <span>📊</span>
                <span>User Analytics</span>
              </Box>
            }
            {...a11yProps(1)}
          />
          <Tab 
            label={
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <span>📋</span>
                <span>User Reports</span>
              </Box>
            }
            {...a11yProps(2)}
          />
          <Tab 
            label={
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <span>📈</span>
                <span>Activity</span>
              </Box>
            }
            {...a11yProps(3)}
          />
          <Tab 
            label={
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <span>🎯</span>
                <span>Segmentation</span>
              </Box>
            }
            {...a11yProps(4)}
          />
          <Tab 
            label={
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <span>💡</span>
                <span>AI Insights</span>
              </Box>
            }
            {...a11yProps(5)}
          />
        </Tabs>
      </Paper>

      {/* Tab Content */}
      <TabPanel value={value} index={0}>
        <AllUsersPage />
      </TabPanel>
      
      <TabPanel value={value} index={1}>
        <UserAnalyticsPage />
      </TabPanel>
      
      <TabPanel value={value} index={2}>
        <UserReportsPage />
      </TabPanel>
      
      <TabPanel value={value} index={3}>
        <UserActivityPage />
      </TabPanel>
      
      <TabPanel value={value} index={4}>
        <UserSegmentationPage />
      </TabPanel>
      
      <TabPanel value={value} index={5}>
        <UserInsightsPage />
      </TabPanel>
    </Container>
  );
};

export default UserManagementPage;
