import React, { useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  Button,
  Alert,
  Snackbar,
  Chip,
  IconButton,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  ListItemSecondaryAction,
  Avatar,
  Rating,
  Divider,
  Tabs,
  Tab,
  Badge,
  Switch,
  FormControlLabel,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  LinearProgress
} from '@mui/material';
import {
  Shield as ShieldIcon,
  Flag as FlagIcon,
  CheckCircle as ApproveIcon,
  Block as RejectIcon,
  Warning as WarningIcon,
  Delete as DeleteIcon,
  Visibility as ViewIcon,
  Settings as SettingsIcon,
  AutoFixHigh as AutoIcon,
  History as HistoryIcon,
  ExpandMore as ExpandMoreIcon,
  Refresh as RefreshIcon,
  FilterList as FilterIcon,
  Search as SearchIcon
} from '@mui/icons-material';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getFlaggedContent, reviewFlaggedContent } from '../../services/adminAPI';
import { format } from 'date-fns';

interface FlaggedContent {
  id: string;
  type: 'book' | 'review' | 'comment' | 'user';
  title: string;
  description: string;
  reportedBy: string;
  reportedAt: string;
  reason: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  status: 'pending' | 'reviewed' | 'resolved';
  content: any;
  reportCount: number;
}

interface ModerationRule {
  id: string;
  name: string;
  type: 'keyword' | 'pattern' | 'ai' | 'manual';
  enabled: boolean;
  action: 'flag' | 'auto-reject' | 'auto-approve' | 'require-review';
  conditions: string[];
  priority: number;
}

interface ModerationStats {
  totalReports: number;
  pendingReview: number;
  resolvedToday: number;
  autoFlagged: number;
  averageResponseTime: number;
  topReportReasons: Array<{
    reason: string;
    count: number;
  }>;
}

const ContentModerationPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState(0);
  const [selectedContent, setSelectedContent] = useState<FlaggedContent | null>(null);
  const [showContentDialog, setShowContentDialog] = useState(false);
  const [showRuleDialog, setShowRuleDialog] = useState(false);
  const [selectedRule, setSelectedRule] = useState<ModerationRule | null>(null);
  const [moderationAction, setModerationAction] = useState<string>('');
  const [actionReason, setActionReason] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [severityFilter, setSeverityFilter] = useState<string>('all');

  // Fetch flagged content
  const { data: flaggedContent, isLoading: contentLoading } = useQuery({
    queryKey: ['flaggedContent', { search: searchTerm, status: statusFilter, severity: severityFilter }],
    queryFn: () => getFlaggedContent({ 
      search: searchTerm, 
      status: statusFilter === 'all' ? undefined : statusFilter,
      severity: severityFilter === 'all' ? undefined : severityFilter
    }),
    staleTime: 30000, // 30 seconds
  });

  // Fetch moderation rules
  const { data: moderationRules, isLoading: rulesLoading } = useQuery({
    queryKey: ['moderationRules'],
    queryFn: () => getModerationRules(),
    staleTime: 60000, // 1 minute
  });

  // Fetch moderation statistics
  const { data: moderationStats } = useQuery({
    queryKey: ['moderationStats'],
    queryFn: () => getModerationStats(),
    staleTime: 60000, // 1 minute
  });

  // Mutations
  const reviewContentMutation = useMutation({
    mutationFn: reviewContent,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['flaggedContent'] });
      queryClient.invalidateQueries({ queryKey: ['moderationStats'] });
      setShowContentDialog(false);
    },
  });

  const updateModerationRuleMutation = useMutation({
    mutationFn: updateModerationRule,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['moderationRules'] });
      setShowRuleDialog(false);
    },
  });

  // Mock data for demonstration
  const mockFlaggedContent: FlaggedContent[] = [
    {
      id: '1',
      type: 'book',
      title: 'The Great Adventure',
      description: 'Book reported for inappropriate content',
      reportedBy: 'user@example.com',
      reportedAt: '2024-01-20T10:30:00Z',
      reason: 'Inappropriate content',
      severity: 'high',
      status: 'pending',
      content: { title: 'The Great Adventure', author: 'John Doe' },
      reportCount: 3
    },
    {
      id: '2',
      type: 'review',
      title: 'User Review',
      description: 'Review reported for spam',
      reportedBy: 'admin@teekoob.com',
      reportedAt: '2024-01-20T09:15:00Z',
      reason: 'Spam',
      severity: 'medium',
      status: 'pending',
      content: { text: 'This is a great book!', rating: 5 },
      reportCount: 1
    },
    {
      id: '3',
      type: 'comment',
      title: 'User Comment',
      description: 'Comment reported for harassment',
      reportedBy: 'moderator@teekoob.com',
      reportedAt: '2024-01-20T08:45:00Z',
      reason: 'Harassment',
      severity: 'critical',
      status: 'pending',
      content: { text: 'Inappropriate comment text' },
      reportCount: 5
    }
  ];

  const mockModerationRules: ModerationRule[] = [
    {
      id: '1',
      name: 'Profanity Filter',
      type: 'keyword',
      enabled: true,
      action: 'flag',
      conditions: ['profanity', 'curse words'],
      priority: 1
    },
    {
      id: '2',
      name: 'Spam Detection',
      type: 'pattern',
      enabled: true,
      action: 'auto-reject',
      conditions: ['repeated content', 'excessive links'],
      priority: 2
    },
    {
      id: '3',
      name: 'AI Content Analysis',
      type: 'ai',
      enabled: true,
      action: 'require-review',
      conditions: ['suspicious patterns', 'low quality'],
      priority: 3
    }
  ];

  const mockModerationStats: ModerationStats = {
    totalReports: 156,
    pendingReview: 23,
    resolvedToday: 45,
    autoFlagged: 89,
    averageResponseTime: 2.5,
    topReportReasons: [
      { reason: 'Inappropriate content', count: 45 },
      { reason: 'Spam', count: 32 },
      { reason: 'Harassment', count: 28 },
      { reason: 'Copyright violation', count: 15 }
    ]
  };

  const data = flaggedContent || mockFlaggedContent;
  const rules = moderationRules || mockModerationRules;
  const stats = moderationStats || mockModerationStats;

  // Handle content review
  const handleReviewContent = () => {
    if (selectedContent && moderationAction && actionReason) {
      reviewContentMutation.mutate({
        contentId: selectedContent.id,
        action: moderationAction,
        reason: actionReason,
        moderator: 'admin@teekoob.com'
      });
    }
  };

  // Handle rule toggle
  const handleRuleToggle = (ruleId: string, enabled: boolean) => {
    updateModerationRuleMutation.mutate({
      ruleId,
      enabled
    });
  };

  // Render moderation statistics
  const renderModerationStats = () => (
    <Grid container spacing={3} sx={{ mb: 4 }}>
      <Grid item xs={12} sm={6} md={3}>
        <Card>
          <CardContent>
            <Box display="flex" alignItems="center">
              <FlagIcon color="primary" sx={{ mr: 2, fontSize: 40 }} />
              <Box>
                <Typography variant="h4">{stats.totalReports}</Typography>
                <Typography variant="body2" color="textSecondary">Total Reports</Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={12} sm={6} md={3}>
        <Card>
          <CardContent>
            <Box display="flex" alignItems="center">
              <WarningIcon color="warning" sx={{ mr: 2, fontSize: 40 }} />
              <Box>
                <Typography variant="h4">{stats.pendingReview}</Typography>
                <Typography variant="body2" color="textSecondary">Pending Review</Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={12} sm={6} md={3}>
        <Card>
          <CardContent>
            <Box display="flex" alignItems="center">
              <CheckCircle as ApproveIcon color="success" sx={{ mr: 2, fontSize: 40 }} />
              <Box>
                <Typography variant="h4">{stats.resolvedToday}</Typography>
                <Typography variant="body2" color="textSecondary">Resolved Today</Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={12} sm={6} md={3}>
        <Card>
          <CardContent>
            <Box display="flex" alignItems="center">
              <AutoIcon color="info" sx={{ mr: 2, fontSize: 40 }} />
              <Box>
                <Typography variant="h4">{stats.autoFlagged}</Typography>
                <Typography variant="body2" color="textSecondary">Auto-Flagged</Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  );

  // Render flagged content list
  const renderFlaggedContent = () => (
    <Card>
      <CardContent>
        <Box display="flex" justifyContent="space-between" alignItems="center" sx={{ mb: 2 }}>
          <Typography variant="h6">Flagged Content</Typography>
          <Box display="flex" gap={1}>
            <TextField
              size="small"
              placeholder="Search content..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              InputProps={{
                startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
              }}
            />
            <FormControl size="small" sx={{ minWidth: 120 }}>
              <InputLabel>Status</InputLabel>
              <Select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                label="Status"
              >
                <MenuItem value="all">All Status</MenuItem>
                <MenuItem value="pending">Pending</MenuItem>
                <MenuItem value="reviewed">Reviewed</MenuItem>
                <MenuItem value="resolved">Resolved</MenuItem>
              </Select>
            </FormControl>
            <FormControl size="small" sx={{ minWidth: 120 }}>
              <InputLabel>Severity</InputLabel>
              <Select
                value={severityFilter}
                onChange={(e) => setSeverityFilter(e.target.value)}
                label="Severity"
              >
                <MenuItem value="all">All Severity</MenuItem>
                <MenuItem value="low">Low</MenuItem>
                <MenuItem value="medium">Medium</MenuItem>
                <MenuItem value="high">High</MenuItem>
                <MenuItem value="critical">Critical</MenuItem>
              </Select>
            </FormControl>
          </Box>
        </Box>

        <List>
          {data.map((content) => (
            <React.Fragment key={content.id}>
              <ListItem>
                <ListItemIcon>
                  <Avatar sx={{ bgcolor: getSeverityColor(content.severity) }}>
                    {content.type === 'book' && '📚'}
                    {content.type === 'review' && '⭐'}
                    {content.type === 'comment' && '💬'}
                    {content.type === 'user' && '👤'}
                  </Avatar>
                </ListItemIcon>
                <ListItemText
                  primary={
                    <Box display="flex" alignItems="center" gap={1}>
                      <Typography variant="body1" fontWeight="medium">
                        {content.title}
                      </Typography>
                      <Chip 
                        label={content.severity} 
                        size="small" 
                        color={getSeverityColor(content.severity) as any}
                      />
                      <Chip 
                        label={content.status} 
                        size="small" 
                        variant="outlined"
                      />
                    </Box>
                  }
                  secondary={
                    <Box>
                      <Typography variant="body2" color="textSecondary">
                        {content.description}
                      </Typography>
                      <Typography variant="caption" display="block">
                        Reported by {content.reportedBy} • {format(new Date(content.reportedAt), 'PPpp')} • {content.reportCount} reports
                      </Typography>
                    </Box>
                  }
                />
                <ListItemSecondaryAction>
                  <Box display="flex" gap={1}>
                    <Tooltip title="View Content">
                      <IconButton 
                        edge="end" 
                        size="small"
                        onClick={() => {
                          setSelectedContent(content);
                          setShowContentDialog(true);
                        }}
                      >
                        <ViewIcon />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Approve">
                      <IconButton 
                        edge="end" 
                        size="small" 
                        color="success"
                        onClick={() => handleQuickAction(content.id, 'approve')}
                      >
                        <ApproveIcon />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Reject">
                      <IconButton 
                        edge="end" 
                        size="small" 
                        color="error"
                        onClick={() => handleQuickAction(content.id, 'reject')}
                      >
                        <RejectIcon />
                      </IconButton>
                    </Tooltip>
                  </Box>
                </ListItemSecondaryAction>
              </ListItem>
              <Divider />
            </React.Fragment>
          ))}
        </List>
      </CardContent>
    </Card>
  );

  // Render moderation rules
  const renderModerationRules = () => (
    <Card>
      <CardContent>
        <Box display="flex" justifyContent="space-between" alignItems="center" sx={{ mb: 2 }}>
          <Typography variant="h6">Moderation Rules</Typography>
          <Button
            variant="contained"
            startIcon={<SettingsIcon />}
            onClick={() => {
              setSelectedRule(null);
              setShowRuleDialog(true);
            }}
          >
            Add Rule
          </Button>
        </Box>

        <List>
          {rules.map((rule) => (
            <ListItem key={rule.id}>
              <ListItemIcon>
                <Avatar sx={{ bgcolor: rule.enabled ? 'success.main' : 'grey.500' }}>
                  {rule.type === 'keyword' && '🔤'}
                  {rule.type === 'pattern' && '🔍'}
                  {rule.type === 'ai' && '🤖'}
                  {rule.type === 'manual' && '👤'}
                </Avatar>
              </ListItemIcon>
              <ListItemText
                primary={
                  <Box display="flex" alignItems="center" gap={1}>
                    <Typography variant="body1" fontWeight="medium">
                      {rule.name}
                    </Typography>
                    <Chip 
                      label={rule.action} 
                      size="small" 
                      color="primary"
                      variant="outlined"
                    />
                    <Chip 
                      label={`Priority ${rule.priority}`} 
                      size="small" 
                      variant="outlined"
                    />
                  </Box>
                }
                secondary={
                  <Box>
                    <Typography variant="body2" color="textSecondary">
                      Type: {rule.type.toUpperCase()} • Conditions: {rule.conditions.join(', ')}
                    </Typography>
                  </Box>
                }
              />
              <ListItemSecondaryAction>
                <Box display="flex" gap={1}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={rule.enabled}
                        onChange={(e) => handleRuleToggle(rule.id, e.target.checked)}
                      />
                    }
                    label=""
                  />
                  <Tooltip title="Edit Rule">
                    <IconButton 
                      edge="end" 
                      size="small"
                      onClick={() => {
                        setSelectedRule(rule);
                        setShowRuleDialog(true);
                      }}
                    >
                      <ViewIcon />
                    </IconButton>
                    </Tooltip>
                </Box>
              </ListItemSecondaryAction>
            </ListItem>
          ))}
        </List>
      </CardContent>
    </Card>
  );

  // Render content review dialog
  const renderContentDialog = () => (
    <Dialog open={showContentDialog} onClose={() => setShowContentDialog(false)} maxWidth="md" fullWidth>
      <DialogTitle>Review Flagged Content</DialogTitle>
      <DialogContent>
        {selectedContent && (
          <Box sx={{ mt: 2 }}>
            <Grid container spacing={3}>
              <Grid item xs={12} md={8}>
                <Typography variant="h6" gutterBottom>
                  Content Details
                </Typography>
                <Card variant="outlined" sx={{ p: 2 }}>
                  <Typography variant="body1" fontWeight="medium">
                    {selectedContent.title}
                  </Typography>
                  <Typography variant="body2" color="textSecondary" sx={{ mt: 1 }}>
                    {selectedContent.description}
                  </Typography>
                  <Box sx={{ mt: 2 }}>
                    <Typography variant="caption" color="textSecondary">
                      Type: {selectedContent.type} • Severity: {selectedContent.severity} • Status: {selectedContent.status}
                    </Typography>
                  </Box>
                </Card>
              </Grid>
              <Grid item xs={12} md={4}>
                <Typography variant="h6" gutterBottom>
                  Report Information
                </Typography>
                <Box>
                  <Typography variant="body2" color="textSecondary">
                    Reported by: {selectedContent.reportedBy}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Reported at: {format(new Date(selectedContent.reportedAt), 'PPpp')}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Reason: {selectedContent.reason}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Report count: {selectedContent.reportCount}
                  </Typography>
                </Box>
              </Grid>
            </Grid>
            
            <Divider sx={{ my: 3 }} />
            
            <Typography variant="h6" gutterBottom>
              Moderation Action
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>Action</InputLabel>
                  <Select
                    value={moderationAction}
                    onChange={(e) => setModerationAction(e.target.value)}
                    label="Action"
                  >
                    <MenuItem value="approve">Approve Content</MenuItem>
                    <MenuItem value="reject">Reject Content</MenuItem>
                    <MenuItem value="flag">Flag for Review</MenuItem>
                    <MenuItem value="delete">Delete Content</MenuItem>
                    <MenuItem value="warn">Warn User</MenuItem>
                    <MenuItem value="ban">Ban User</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Reason for Action"
                  value={actionReason}
                  onChange={(e) => setActionReason(e.target.value)}
                  placeholder="Explain your decision..."
                />
              </Grid>
            </Grid>
          </Box>
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={() => setShowContentDialog(false)}>Cancel</Button>
        <Button
          variant="contained"
          onClick={handleReviewContent}
          disabled={!moderationAction || !actionReason}
        >
          Submit Decision
        </Button>
      </DialogActions>
    </Dialog>
  );

  // Helper functions
  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'low': return 'success.main';
      case 'medium': return 'warning.main';
      case 'high': return 'error.main';
      case 'critical': return 'error.dark';
      default: return 'grey.500';
    }
  };

  const handleQuickAction = (contentId: string, action: string) => {
    reviewContentMutation.mutate({
      contentId,
      action,
      reason: `Quick ${action} action`,
      moderator: 'admin@teekoob.com'
    });
  };

  return (
    <Box sx={{ p: 3 }}>
      <Box display="flex" justifyContent="space-between" alignItems="center" sx={{ mb: 3 }}>
        <Typography variant="h4">Content Moderation</Typography>
        <Box display="flex" gap={1}>
          <Button
            variant="outlined"
            startIcon={<RefreshIcon />}
            onClick={() => queryClient.invalidateQueries({ queryKey: ['flaggedContent'] })}
          >
            Refresh
          </Button>
          <Button
            variant="outlined"
            startIcon={<FilterIcon />}
          >
            Advanced Filters
          </Button>
        </Box>
      </Box>

      {renderModerationStats()}

      <Tabs value={activeTab} onChange={(e, newValue) => setActiveTab(newValue)} sx={{ mb: 3 }}>
        <Tab label="Flagged Content" />
        <Tab label="Moderation Rules" />
        <Tab label="Reports History" />
        <Tab label="Settings" />
      </Tabs>

      {activeTab === 0 && renderFlaggedContent()}
      {activeTab === 1 && renderModerationRules()}
      {activeTab === 2 && (
        <Card>
          <CardContent>
            <Typography variant="h6">Reports History</Typography>
            <Typography variant="body2" color="textSecondary">
              View historical moderation actions and decisions.
            </Typography>
            {/* TODO: Implement reports history */}
          </CardContent>
        </Card>
      )}
      {activeTab === 3 && (
        <Card>
          <CardContent>
            <Typography variant="h6">Moderation Settings</Typography>
            <Typography variant="body2" color="textSecondary">
              Configure moderation preferences and automation settings.
            </Typography>
            {/* TODO: Implement moderation settings */}
          </CardContent>
        </Card>
      )}

      {renderContentDialog()}

      <Snackbar
        open={reviewContentMutation.isSuccess}
        autoHideDuration={6000}
        onClose={() => {}}
      >
        <Alert severity="success">
          Content review submitted successfully!
        </Alert>
      </Snackbar>

      <Snackbar
        open={updateModerationRuleMutation.isSuccess}
        autoHideDuration={6000}
        onClose={() => {}}
      >
        <Alert severity="success">
          Moderation rule updated successfully!
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default ContentModerationPage;
