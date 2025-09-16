import React, { useState } from 'react';
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
  TextField,
  Alert,
  CircularProgress,
  useTheme,
  Tabs,
  Tab,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Divider,
  LinearProgress
} from '@mui/material';
import {
  Lightbulb as InsightIcon,
  TrendingUp as TrendingIcon,
  Psychology as PsychologyIcon,
  Analytics as AnalyticsIcon,
  Refresh as RefreshIcon,
  Download as DownloadIcon,
  Warning as WarningIcon,
  CheckCircle as CheckIcon,
  Info as InfoIcon,
  Timeline as TimelineIcon,
  Assessment as AssessmentIcon,
  AutoGraph as AutoGraphIcon
} from '@mui/icons-material';

const UserInsightsPage: React.FC = () => {
  const theme = useTheme();
  const [activeTab, setActiveTab] = useState(0);

  // Mock insights data
  const insights = [
    {
      id: 1,
      type: 'opportunity',
      title: 'High Churn Risk Users',
      description: '150 users show signs of potential churn based on declining engagement',
      impact: 'high',
      confidence: 87,
      action: 'Send retention campaign',
      value: '$2,500 potential revenue loss'
    },
    {
      id: 2,
      type: 'trend',
      title: 'Mobile Usage Surge',
      description: 'Mobile app usage increased by 35% in the last 7 days',
      impact: 'medium',
      confidence: 92,
      action: 'Optimize mobile experience',
      value: '15% engagement improvement'
    },
    {
      id: 3,
      type: 'anomaly',
      title: 'Unusual Reading Patterns',
      description: 'Detected unusual reading behavior in 23 users',
      impact: 'low',
      confidence: 78,
      action: 'Investigate further',
      value: 'Security review needed'
    }
  ];

  const predictions = [
    {
      metric: 'User Growth',
      current: '2,450',
      predicted: '3,200',
      change: '+30.6%',
      confidence: 89,
      timeframe: 'Next 30 days'
    },
    {
      metric: 'Revenue',
      current: '$12,450',
      predicted: '$18,200',
      change: '+46.2%',
      confidence: 85,
      timeframe: 'Next 30 days'
    },
    {
      metric: 'Churn Rate',
      current: '8.5%',
      predicted: '6.2%',
      change: '-27.1%',
      confidence: 82,
      timeframe: 'Next 30 days'
    }
  ];

  const recommendations = [
    {
      category: 'User Retention',
      title: 'Implement Gamification',
      description: 'Add reading challenges and achievements to increase user engagement',
      impact: 'High',
      effort: 'Medium',
      priority: 'P1',
      estimatedROI: '25%'
    },
    {
      category: 'Revenue Optimization',
      title: 'Dynamic Pricing',
      description: 'Implement time-based pricing for premium features',
      impact: 'High',
      effort: 'High',
      priority: 'P2',
      estimatedROI: '18%'
    },
    {
      category: 'User Experience',
      title: 'Personalized Recommendations',
      description: 'Use AI to suggest books based on reading history',
      impact: 'Medium',
      effort: 'Low',
      priority: 'P3',
      estimatedROI: '12%'
    }
  ];

  return (
    <Box>
      <Typography variant="h5" fontWeight="bold" mb={3}>
        User Insights & Predictive Analytics
      </Typography>

      <Tabs value={activeTab} onChange={(e, newValue) => setActiveTab(newValue)} sx={{ mb: 3 }}>
        <Tab label="AI Insights" icon={<InsightIcon />} />
        <Tab label="Predictions" icon={<TrendingIcon />} />
        <Tab label="Recommendations" icon={<PsychologyIcon />} />
        <Tab label="Behavioral Patterns" icon={<AnalyticsIcon />} />
      </Tabs>

      {activeTab === 0 && (
        <Box>
          <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
            <Typography variant="h6">AI-Powered Insights</Typography>
            <Button variant="outlined" startIcon={<RefreshIcon />}>
              Refresh Insights
            </Button>
          </Box>

          <Grid container spacing={3}>
            {insights.map((insight) => (
              <Grid item xs={12} md={6} lg={4} key={insight.id}>
                <Card>
                  <CardContent>
                    <Box display="flex" justifyContent="space-between" alignItems="flex-start" mb={2}>
                      <Chip 
                        label={insight.type.toUpperCase()} 
                        color={
                          insight.type === 'opportunity' ? 'success' :
                          insight.type === 'trend' ? 'info' : 'warning'
                        }
                        size="small"
                      />
                      <Chip 
                        label={`${insight.confidence}%`} 
                        color="primary" 
                        size="small"
                        variant="outlined"
                      />
                    </Box>
                    
                    <Typography variant="h6" mb={1}>
                      {insight.title}
                    </Typography>
                    
                    <Typography variant="body2" color="text.secondary" mb={2}>
                      {insight.description}
                    </Typography>
                    
                    <Box mb={2}>
                      <Typography variant="caption" color="text.secondary">
                        Impact: {insight.impact}
                      </Typography>
                      <LinearProgress 
                        variant="determinate" 
                        value={insight.impact === 'high' ? 100 : insight.impact === 'medium' ? 66 : 33}
                        sx={{ mt: 1 }}
                      />
                    </Box>
                    
                    <Typography variant="body2" mb={1}>
                      <strong>Action:</strong> {insight.action}
                    </Typography>
                    
                    <Typography variant="body2" color="primary" fontWeight="bold">
                      {insight.value}
                    </Typography>
                    
                    <Box display="flex" gap={1} mt={2}>
                      <Button size="small" variant="contained">
                        Take Action
                      </Button>
                      <Button size="small" variant="outlined">
                        Dismiss
                      </Button>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Box>
      )}

      {activeTab === 1 && (
        <Box>
          <Typography variant="h6" mb={3}>Predictive Analytics</Typography>
          
          <Grid container spacing={3} mb={3}>
            {predictions.map((prediction, index) => (
              <Grid item xs={12} md={4} key={index}>
                <Card>
                  <CardContent sx={{ textAlign: 'center' }}>
                    <Typography variant="h6" color="primary" mb={1}>
                      {prediction.metric}
                    </Typography>
                    
                    <Typography variant="h4" fontWeight="bold" mb={1}>
                      {prediction.current}
                    </Typography>
                    
                    <Typography variant="h6" color="success.main" mb={1}>
                      {prediction.predicted}
                    </Typography>
                    
                    <Chip 
                      label={prediction.change} 
                      color={prediction.change.startsWith('+') ? 'success' : 'error'}
                      size="small"
                      sx={{ mb: 1 }}
                    />
                    
                    <Typography variant="body2" color="text.secondary" mb={1}>
                      Confidence: {prediction.confidence}%
                    </Typography>
                    
                    <Typography variant="caption" color="text.secondary">
                      {prediction.timeframe}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>

          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" mb={2}>Forecasting Model Performance</Typography>
            <Grid container spacing={2}>
              <Grid item xs={12} md={6}>
                <Typography variant="body2" mb={1}>
                  Model Accuracy: <strong>87.3%</strong>
                </Typography>
                <LinearProgress variant="determinate" value={87.3} sx={{ mb: 2 }} />
                
                <Typography variant="body2" mb={1}>
                  Data Quality Score: <strong>94.1%</strong>
                </Typography>
                <LinearProgress variant="determinate" value={94.1} sx={{ mb: 2 }} />
              </Grid>
              <Grid item xs={12} md={6}>
                <Typography variant="body2" mb={1}>
                  Prediction Horizon: <strong>30 days</strong>
                </Typography>
                <Typography variant="body2" mb={1}>
                  Last Updated: <strong>2 hours ago</strong>
                </Typography>
                <Typography variant="body2" mb={1}>
                  Training Data: <strong>12 months</strong>
                </Typography>
              </Grid>
            </Grid>
          </Paper>
        </Box>
      )}

      {activeTab === 2 && (
        <Box>
          <Typography variant="h6" mb={3}>Strategic Recommendations</Typography>
          
          <Grid container spacing={3}>
            {recommendations.map((rec, index) => (
              <Grid item xs={12} md={6} lg={4} key={index}>
                <Card>
                  <CardContent>
                    <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                      <Chip 
                        label={rec.category} 
                        color="primary" 
                        size="small"
                        variant="outlined"
                      />
                      <Chip 
                        label={rec.priority} 
                        color={
                          rec.priority === 'P1' ? 'error' :
                          rec.priority === 'P2' ? 'warning' : 'success'
                        }
                        size="small"
                      />
                    </Box>
                    
                    <Typography variant="h6" mb={1}>
                      {rec.title}
                    </Typography>
                    
                    <Typography variant="body2" color="text.secondary" mb={2}>
                      {rec.description}
                    </Typography>
                    
                    <Grid container spacing={2} mb={2}>
                      <Grid item xs={6}>
                        <Typography variant="caption" color="text.secondary">
                          Impact
                        </Typography>
                        <Typography variant="body2" fontWeight="bold">
                          {rec.impact}
                        </Typography>
                      </Grid>
                      <Grid item xs={6}>
                        <Typography variant="caption" color="text.secondary">
                          Effort
                        </Typography>
                        <Typography variant="body2" fontWeight="bold">
                          {rec.effort}
                        </Typography>
                      </Grid>
                    </Grid>
                    
                    <Typography variant="body2" color="success.main" fontWeight="bold" mb={2}>
                      Estimated ROI: {rec.estimatedROI}
                    </Typography>
                    
                    <Box display="flex" gap={1}>
                      <Button size="small" variant="contained">
                        Implement
                      </Button>
                      <Button size="small" variant="outlined">
                        Learn More
                      </Button>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Box>
      )}

      {activeTab === 3 && (
        <Box>
          <Typography variant="h6" mb={3}>Behavioral Pattern Analysis</Typography>
          
          <Grid container spacing={3}>
            <Grid item xs={12} md={6}>
              <Paper sx={{ p: 3 }}>
                <Typography variant="h6" mb={2}>Reading Behavior Patterns</Typography>
                <List>
                  <ListItem>
                    <ListItemIcon>
                      <CheckIcon color="success" />
                    </ListItemIcon>
                    <ListItemText 
                      primary="Peak reading hours: 7-9 PM and 9-11 PM"
                      secondary="Based on 2,450 user sessions"
                    />
                  </ListItem>
                  <ListItem>
                    <ListItemIcon>
                      <CheckIcon color="success" />
                    </ListItemIcon>
                    <ListItemText 
                      primary="Average session duration: 23 minutes"
                      secondary="Increased by 15% from last month"
                    />
                  </ListItem>
                  <ListItem>
                    <ListItemIcon>
                      <WarningIcon color="warning" />
                    </ListItemIcon>
                    <ListItemText 
                      primary="Drop-off rate at 15 minutes"
                      secondary="Consider implementing engagement hooks"
                    />
                  </ListItem>
                </List>
              </Paper>
            </Grid>
            
            <Grid item xs={12} md={6}>
              <Paper sx={{ p: 3 }}>
                <Typography variant="h6" mb={2}>User Journey Insights</Typography>
                <List>
                  <ListItem>
                    <ListItemIcon>
                      <InfoIcon color="info" />
                    </ListItemIcon>
                    <ListItemText 
                      primary="Onboarding completion: 78%"
                      secondary="22% drop-off at step 3"
                    />
                  </ListItem>
                  <ListItem>
                    <ListItemIcon>
                      <InfoIcon color="info" />
                    </ListItemIcon>
                    <ListItemText 
                      primary="First book completion: 45%"
                      secondary="55% users don't finish their first book"
                    />
                  </ListItem>
                  <ListItem>
                    <ListItemIcon>
                      <InfoIcon color="info" />
                    </ListItemIcon>
                    <ListItemText 
                      primary="Premium conversion: 12%"
                      secondary="Peaks at 3rd book completion"
                    />
                  </ListItem>
                </List>
              </Paper>
            </Grid>
          </Grid>
        </Box>
      )}
    </Box>
  );
};

export default UserInsightsPage;
