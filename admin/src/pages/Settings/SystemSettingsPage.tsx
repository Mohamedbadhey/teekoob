import React, { useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  Switch,
  FormControlLabel,
  TextField,
  Button,
  Alert,
  Snackbar,
  Divider,
  Chip,
  IconButton,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Slider,
  InputAdornment,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  ListItemSecondaryAction,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  LinearProgress
} from '@mui/material';
import {
  Settings as SettingsIcon,
  Security as SecurityIcon,
  Backup as BackupIcon,
  Notifications as NotificationsIcon,
  Storage as StorageIcon,
  Speed as SpeedIcon,
  Language as LanguageIcon,
  Payment as PaymentIcon,
  Analytics as AnalyticsIcon,
  ExpandMore as ExpandMoreIcon,
  Refresh as RefreshIcon,
  Save as SaveIcon,
  Restore as RestoreIcon,
  Download as DownloadIcon,
  Upload as UploadIcon,
  Delete as DeleteIcon,
  CheckCircle as CheckIcon,
  Warning as WarningIcon,
  Error as ErrorIcon,
  Info as InfoIcon
} from '@mui/icons-material';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { 
  getSystemSettings, 
  updateSystemSettings,
  createBackup,
  restoreBackup
} from '../../services/adminAPI';

interface SystemSettings {
  features: {
    userRegistration: boolean;
    socialLogin: boolean;
    offlineMode: boolean;
    multiLanguage: boolean;
    pushNotifications: boolean;
    advancedSearch: boolean;
    recommendationEngine: boolean;
    analytics: boolean;
    contentModeration: boolean;
    paymentProcessing: boolean;
  };
  limits: {
    maxFileSize: number;
    maxBooksPerUser: number;
    maxOfflineDownloads: number;
    maxConcurrentUsers: number;
    maxUploadsPerDay: number;
    sessionTimeout: number;
  };
  security: {
    emailVerification: boolean;
    twoFactorAuth: boolean;
    passwordMinLength: number;
    passwordComplexity: 'low' | 'medium' | 'high';
    sessionTimeout: number;
    maxLoginAttempts: number;
    ipWhitelist: string[];
    rateLimiting: boolean;
  };
  notifications: {
    emailNotifications: boolean;
    pushNotifications: boolean;
    smsNotifications: boolean;
    adminAlerts: boolean;
    userReports: boolean;
    systemUpdates: boolean;
  };
  performance: {
    cacheEnabled: boolean;
    compressionEnabled: boolean;
    cdnEnabled: boolean;
    databaseOptimization: boolean;
    imageOptimization: boolean;
    backgroundJobs: boolean;
  };
  backup: {
    autoBackup: boolean;
    backupFrequency: 'daily' | 'weekly' | 'monthly';
    retentionDays: number;
    cloudStorage: boolean;
    encryption: boolean;
  };
}

interface BackupInfo {
  id: string;
  name: string;
  size: string;
  createdAt: string;
  status: 'completed' | 'in_progress' | 'failed';
  type: 'full' | 'incremental';
}

const SystemSettingsPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [activeSection, setActiveSection] = useState('features');
  const [showBackupDialog, setShowBackupDialog] = useState(false);
  const [showRestoreDialog, setShowRestoreDialog] = useState(false);
  const [backupName, setBackupName] = useState('');
  const [selectedBackup, setSelectedBackup] = useState<BackupInfo | null>(null);
  const [isCreatingBackup, setIsCreatingBackup] = useState(false);

  // Fetch system settings
  const { data: settings, isLoading } = useQuery({
    queryKey: ['systemSettings'],
    queryFn: () => getSystemSettings(),
    staleTime: 300000, // 5 minutes
  });

  // Fetch backup information
  const { data: backups } = useQuery({
    queryKey: ['systemBackups'],
    queryFn: () => getSystemBackups(),
    staleTime: 60000, // 1 minute
  });

  // Mutations
  const updateSettingsMutation = useMutation({
    mutationFn: updateSystemSettings,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['systemSettings'] });
    },
  });

  const createBackupMutation = useMutation({
    mutationFn: createSystemBackup,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['systemBackups'] });
      setShowBackupDialog(false);
      setIsCreatingBackup(false);
    },
  });

  const restoreBackupMutation = useMutation({
    mutationFn: restoreSystemBackup,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['systemBackups'] });
      setShowRestoreDialog(false);
    },
  });

  // Mock data for demonstration
  const mockSettings: SystemSettings = {
    features: {
      userRegistration: true,
      socialLogin: true,
      offlineMode: true,
      multiLanguage: true,
      pushNotifications: true,
      advancedSearch: true,
      recommendationEngine: false,
      analytics: true,
      contentModeration: true,
      paymentProcessing: true,
    },
    limits: {
      maxFileSize: 100,
      maxBooksPerUser: 1000,
      maxOfflineDownloads: 100,
      maxConcurrentUsers: 5000,
      maxUploadsPerDay: 50,
      sessionTimeout: 30,
    },
    security: {
      emailVerification: true,
      twoFactorAuth: false,
      passwordMinLength: 8,
      passwordComplexity: 'medium',
      sessionTimeout: 30,
      maxLoginAttempts: 5,
      ipWhitelist: ['192.168.1.1', '10.0.0.1'],
      rateLimiting: true,
    },
    notifications: {
      emailNotifications: true,
      pushNotifications: true,
      smsNotifications: false,
      adminAlerts: true,
      userReports: true,
      systemUpdates: true,
    },
    performance: {
      cacheEnabled: true,
      compressionEnabled: true,
      cdnEnabled: false,
      databaseOptimization: true,
      imageOptimization: true,
      backgroundJobs: true,
    },
    backup: {
      autoBackup: true,
      backupFrequency: 'daily',
      retentionDays: 30,
      cloudStorage: false,
      encryption: true,
    },
  };

  const mockBackups: BackupInfo[] = [
    {
      id: '1',
      name: 'Full Backup - 2024-01-15',
      size: '2.5 GB',
      createdAt: '2024-01-15T10:00:00Z',
      status: 'completed',
      type: 'full',
    },
    {
      id: '2',
      name: 'Incremental Backup - 2024-01-16',
      size: '150 MB',
      createdAt: '2024-01-16T10:00:00Z',
      status: 'completed',
      type: 'incremental',
    },
    {
      id: '3',
      name: 'Full Backup - 2024-01-17',
      size: '2.6 GB',
      createdAt: '2024-01-17T10:00:00Z',
      status: 'in_progress',
      type: 'full',
    },
  ];

  const data = settings || mockSettings;
  const backupData = backups || mockBackups;

  // Handle settings updates
  const handleFeatureToggle = (feature: keyof SystemSettings['features'], value: boolean) => {
    updateSettingsMutation.mutate({
      path: `features.${feature}`,
      value,
    });
  };

  const handleLimitChange = (limit: keyof SystemSettings['limits'], value: number) => {
    updateSettingsMutation.mutate({
      path: `limits.${limit}`,
      value,
    });
  };

  const handleSecurityToggle = (setting: keyof SystemSettings['security'], value: boolean | number | string) => {
    updateSettingsMutation.mutate({
      path: `security.${setting}`,
      value,
    });
  };

  // Handle backup creation
  const handleCreateBackup = () => {
    if (backupName.trim()) {
      setIsCreatingBackup(true);
      createBackupMutation.mutate({
        name: backupName,
        type: 'full',
      });
    }
  };

  // Handle backup restoration
  const handleRestoreBackup = () => {
    if (selectedBackup) {
      restoreBackupMutation.mutate(selectedBackup.id);
    }
  };

  // Render feature flags section
  const renderFeatureFlags = () => (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          <SettingsIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
          Feature Flags
        </Typography>
        <Typography variant="body2" color="textSecondary" sx={{ mb: 3 }}>
          Enable or disable platform features to control user experience and system capabilities.
        </Typography>
        
        <Grid container spacing={3}>
          <Grid item xs={12} sm={6} md={4}>
            <FormControlLabel
              control={
                <Switch
                  checked={data.features.userRegistration}
                  onChange={(e) => handleFeatureToggle('userRegistration', e.target.checked)}
                />
              }
              label="User Registration"
            />
            <Typography variant="caption" color="textSecondary" display="block">
              Allow new users to create accounts
            </Typography>
          </Grid>
          
          <Grid item xs={12} sm={6} md={4}>
            <FormControlLabel
              control={
                <Switch
                  checked={data.features.socialLogin}
                  onChange={(e) => handleFeatureToggle('socialLogin', e.target.checked)}
                />
              }
              label="Social Login"
            />
            <Typography variant="caption" color="textSecondary" display="block">
              Enable Google, Facebook login options
            </Typography>
          </Grid>
          
          <Grid item xs={12} sm={6} md={4}>
            <FormControlLabel
              control={
                <Switch
                  checked={data.features.offlineMode}
                  onChange={(e) => handleFeatureToggle('offlineMode', e.target.checked)}
                />
              }
              label="Offline Mode"
            />
            <Typography variant="caption" color="textSecondary" display="block">
              Allow users to download content for offline use
            </Typography>
          </Grid>
          
          <Grid item xs={12} sm={6} md={4}>
            <FormControlLabel
              control={
                <Switch
                  checked={data.features.multiLanguage}
                  onChange={(e) => handleFeatureToggle('multiLanguage', e.target.checked)}
                />
              }
              label="Multi-Language Support"
            />
            <Typography variant="caption" color="textSecondary" display="block">
              Enable multiple language interfaces
            </Typography>
          </Grid>
          
          <Grid item xs={12} sm={6} md={4}>
            <FormControlLabel
              control={
                <Switch
                  checked={data.features.pushNotifications}
                  onChange={(e) => handleFeatureToggle('pushNotifications', e.target.checked)}
                />
              }
              label="Push Notifications"
            />
            <Typography variant="caption" color="textSecondary" display="block">
              Send real-time notifications to users
            </Typography>
          </Grid>
          
          <Grid item xs={12} sm={6} md={4}>
            <FormControlLabel
              control={
                <Switch
                  checked={data.features.advancedSearch}
                  onChange={(e) => handleFeatureToggle('advancedSearch', e.target.checked)}
                />
              }
              label="Advanced Search"
            />
            <Typography variant="caption" color="textSecondary" display="block">
              Enable advanced search filters and options
            </Typography>
          </Grid>
          
          <Grid item xs={12} sm={6} md={4}>
            <FormControlLabel
              control={
                <Switch
                  checked={data.features.recommendationEngine}
                  onChange={(e) => handleFeatureToggle('recommendationEngine', e.target.checked)}
                />
              }
              label="Recommendation Engine"
            />
            <Typography variant="caption" color="textSecondary" display="block">
              AI-powered book recommendations
            </Typography>
          </Grid>
          
          <Grid item xs={12} sm={6} md={4}>
            <FormControlLabel
              control={
                <Switch
                  checked={data.features.analytics}
                  onChange={(e) => handleFeatureToggle('analytics', e.target.checked)}
                />
              }
              label="Analytics Dashboard"
            />
            <Typography variant="caption" color="textSecondary" display="block">
              Enable detailed analytics and reporting
            </Typography>
          </Grid>
          
          <Grid item xs={12} sm={6} md={4}>
            <FormControlLabel
              control={
                <Switch
                  checked={data.features.contentModeration}
                  onChange={(e) => handleFeatureToggle('contentModeration', e.target.checked)}
                />
              }
              label="Content Moderation"
            />
            <Typography variant="caption" color="textSecondary" display="block">
              Automated content filtering and moderation
            </Typography>
          </Grid>
          
          <Grid item xs={12} sm={6} md={4}>
            <FormControlLabel
              control={
                <Switch
                  checked={data.features.paymentProcessing}
                  onChange={(e) => handleFeatureToggle('paymentProcessing', e.target.checked)}
                />
              }
              label="Payment Processing"
            />
            <Typography variant="caption" color="textSecondary" display="block">
              Enable subscription and payment features
            </Typography>
          </Grid>
        </Grid>
      </CardContent>
    </Card>
  );

  // Render system limits section
  const renderSystemLimits = () => (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          <SpeedIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
          System Limits & Performance
        </Typography>
        <Typography variant="body2" color="textSecondary" sx={{ mb: 3 }}>
          Configure system performance limits and resource constraints.
        </Typography>
        
        <Grid container spacing={3}>
          <Grid item xs={12} sm={6} md={4}>
            <Typography variant="body2" gutterBottom>
              Max File Size (MB)
            </Typography>
            <TextField
              type="number"
              value={data.limits.maxFileSize}
              onChange={(e) => handleLimitChange('maxFileSize', parseInt(e.target.value))}
              fullWidth
              size="small"
              InputProps={{
                endAdornment: <InputAdornment position="end">MB</InputAdornment>,
              }}
            />
          </Grid>
          
          <Grid item xs={12} sm={6} md={4}>
            <Typography variant="body2" gutterBottom>
              Max Books Per User
            </Typography>
            <TextField
              type="number"
              value={data.limits.maxBooksPerUser}
              onChange={(e) => handleLimitChange('maxBooksPerUser', parseInt(e.target.value))}
              fullWidth
              size="small"
            />
          </Grid>
          
          <Grid item xs={12} sm={6} md={4}>
            <Typography variant="body2" gutterBottom>
              Max Offline Downloads
            </Typography>
            <TextField
              type="number"
              value={data.limits.maxOfflineDownloads}
              onChange={(e) => handleLimitChange('maxOfflineDownloads', parseInt(e.target.value))}
              fullWidth
              size="small"
            />
          </Grid>
          
          <Grid item xs={12} sm={6} md={4}>
            <Typography variant="body2" gutterBottom>
              Max Concurrent Users
            </Typography>
            <TextField
              type="number"
              value={data.limits.maxConcurrentUsers}
              onChange={(e) => handleLimitChange('maxConcurrentUsers', parseInt(e.target.value))}
              fullWidth
              size="small"
            />
          </Grid>
          
          <Grid item xs={12} sm={6} md={4}>
            <Typography variant="body2" gutterBottom>
              Max Uploads Per Day
            </Typography>
            <TextField
              type="number"
              value={data.limits.maxUploadsPerDay}
              onChange={(e) => handleLimitChange('maxUploadsPerDay', parseInt(e.target.value))}
              fullWidth
              size="small"
            />
          </Grid>
          
          <Grid item xs={12} sm={6} md={4}>
            <Typography variant="body2" gutterBottom>
              Session Timeout (minutes)
            </Typography>
            <TextField
              type="number"
              value={data.limits.sessionTimeout}
              onChange={(e) => handleLimitChange('sessionTimeout', parseInt(e.target.value))}
              fullWidth
              size="small"
              InputProps={{
                endAdornment: <InputAdornment position="end">min</InputAdornment>,
              }}
            />
          </Grid>
        </Grid>
      </CardContent>
    </Card>
  );

  // Render security settings section
  const renderSecuritySettings = () => (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          <SecurityIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
          Security & Authentication
        </Typography>
        <Typography variant="body2" color="textSecondary" sx={{ mb: 3 }}>
          Configure security settings and authentication requirements.
        </Typography>
        
        <Grid container spacing={3}>
          <Grid item xs={12} sm={6} md={4}>
            <FormControlLabel
              control={
                <Switch
                  checked={data.security.emailVerification}
                  onChange={(e) => handleSecurityToggle('emailVerification', e.target.checked)}
                />
              }
              label="Email Verification Required"
            />
          </Grid>
          
          <Grid item xs={12} sm={6} md={4}>
            <FormControlLabel
              control={
                <Switch
                  checked={data.security.twoFactorAuth}
                  onChange={(e) => handleSecurityToggle('twoFactorAuth', e.target.checked)}
                />
              }
              label="Two-Factor Authentication"
            />
          </Grid>
          
          <Grid item xs={12} sm={6} md={4}>
            <FormControlLabel
              control={
                <Switch
                  checked={data.security.rateLimiting}
                  onChange={(e) => handleSecurityToggle('rateLimiting', e.target.checked)}
                />
              }
              label="Rate Limiting"
            />
          </Grid>
          
          <Grid item xs={12} sm={6} md={4}>
            <Typography variant="body2" gutterBottom>
              Password Min Length
            </Typography>
            <TextField
              type="number"
              value={data.security.passwordMinLength}
              onChange={(e) => handleSecurityToggle('passwordMinLength', parseInt(e.target.value))}
              fullWidth
              size="small"
            />
          </Grid>
          
          <Grid item xs={12} sm={6} md={4}>
            <Typography variant="body2" gutterBottom>
              Password Complexity
            </Typography>
            <FormControl fullWidth size="small">
              <Select
                value={data.security.passwordComplexity}
                onChange={(e) => handleSecurityToggle('passwordComplexity', e.target.value)}
              >
                <MenuItem value="low">Low (Letters only)</MenuItem>
                <MenuItem value="medium">Medium (Letters + Numbers)</MenuItem>
                <MenuItem value="high">High (Letters + Numbers + Symbols)</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          
          <Grid item xs={12} sm={6} md={4}>
            <Typography variant="body2" gutterBottom>
              Max Login Attempts
            </Typography>
            <TextField
              type="number"
              value={data.security.maxLoginAttempts}
              onChange={(e) => handleSecurityToggle('maxLoginAttempts', parseInt(e.target.value))}
              fullWidth
              size="small"
            />
          </Grid>
        </Grid>
      </CardContent>
    </Card>
  );

  // Render backup and restore section
  const renderBackupRestore = () => (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          <BackupIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
          Backup & Restore
        </Typography>
        <Typography variant="body2" color="textSecondary" sx={{ mb: 3 }}>
          Manage system backups and restore points for disaster recovery.
        </Typography>
        
        <Grid container spacing={3} sx={{ mb: 3 }}>
          <Grid item xs={12} sm={6} md={4}>
            <FormControlLabel
              control={
                <Switch
                  checked={data.backup.autoBackup}
                  onChange={(e) => updateSettingsMutation.mutate({
                    path: 'backup.autoBackup',
                    value: e.target.checked,
                  })}
                />
              }
              label="Automatic Backups"
            />
          </Grid>
          
          <Grid item xs={12} sm={6} md={4}>
            <Typography variant="body2" gutterBottom>
              Backup Frequency
            </Typography>
            <FormControl fullWidth size="small">
              <Select
                value={data.backup.backupFrequency}
                onChange={(e) => updateSettingsMutation.mutate({
                  path: 'backup.backupFrequency',
                  value: e.target.value,
                })}
              >
                <MenuItem value="daily">Daily</MenuItem>
                <MenuItem value="weekly">Weekly</MenuItem>
                <MenuItem value="monthly">Monthly</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          
          <Grid item xs={12} sm={6} md={4}>
            <Typography variant="body2" gutterBottom>
              Retention Period (days)
            </Typography>
            <TextField
              type="number"
              value={data.backup.retentionDays}
              onChange={(e) => updateSettingsMutation.mutate({
                path: 'backup.retentionDays',
                value: parseInt(e.target.value),
              })}
              fullWidth
              size="small"
            />
          </Grid>
        </Grid>
        
        <Box display="flex" gap={2} sx={{ mb: 3 }}>
          <Button
            variant="contained"
            startIcon={<DownloadIcon />}
            onClick={() => setShowBackupDialog(true)}
          >
            Create Backup
          </Button>
          <Button
            variant="outlined"
            startIcon={<UploadIcon />}
            onClick={() => setShowRestoreDialog(true)}
          >
            Restore Backup
          </Button>
        </Box>
        
        <Typography variant="h6" gutterBottom>
          Available Backups
        </Typography>
        <List>
          {backupData.map((backup) => (
            <ListItem key={backup.id}>
              <ListItemIcon>
                {backup.status === 'completed' && <CheckIcon color="success" />}
                {backup.status === 'in_progress' && <LinearProgress sx={{ width: 20 }} />}
                {backup.status === 'failed' && <ErrorIcon color="error" />}
              </ListItemIcon>
              <ListItemText
                primary={backup.name}
                secondary={`${backup.size} • ${new Date(backup.createdAt).toLocaleDateString()} • ${backup.type}`}
              />
              <ListItemSecondaryAction>
                <Tooltip title="Download Backup">
                  <IconButton edge="end" size="small">
                    <DownloadIcon />
                  </IconButton>
                </Tooltip>
                <Tooltip title="Delete Backup">
                  <IconButton edge="end" size="small" color="error">
                    <DeleteIcon />
                  </IconButton>
                </Tooltip>
              </ListItemSecondaryAction>
            </ListItem>
          ))}
        </List>
      </CardContent>
    </Card>
  );

  // Render backup creation dialog
  const renderBackupDialog = () => (
    <Dialog open={showBackupDialog} onClose={() => setShowBackupDialog(false)} maxWidth="sm" fullWidth>
      <DialogTitle>Create System Backup</DialogTitle>
      <DialogContent>
        <TextField
          fullWidth
          label="Backup Name"
          value={backupName}
          onChange={(e) => setBackupName(e.target.value)}
          placeholder="e.g., Full Backup - 2024-01-20"
          sx={{ mt: 2 }}
        />
        <Typography variant="body2" color="textSecondary" sx={{ mt: 2 }}>
          This will create a complete backup of your system including:
        </Typography>
        <List dense>
          <ListItem>
            <ListItemIcon>
              <CheckIcon color="success" fontSize="small" />
            </ListItemIcon>
            <ListItemText primary="Database content and structure" />
          </ListItem>
          <ListItem>
            <ListItemIcon>
              <CheckIcon color="success" fontSize="small" />
            </ListItemIcon>
            <ListItemText primary="User files and uploads" />
          </ListItem>
          <ListItem>
            <ListItemIcon>
              <CheckIcon color="success" fontSize="small" />
            </ListItemIcon>
            <ListItemText primary="System configuration" />
          </ListItem>
        </List>
        {isCreatingBackup && (
          <Box sx={{ mt: 2 }}>
            <LinearProgress />
            <Typography variant="body2" sx={{ mt: 1 }}>
              Creating backup... This may take several minutes.
            </Typography>
          </Box>
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={() => setShowBackupDialog(false)} disabled={isCreatingBackup}>
          Cancel
        </Button>
        <Button
          variant="contained"
          onClick={handleCreateBackup}
          disabled={!backupName.trim() || isCreatingBackup}
          startIcon={<SaveIcon />}
        >
          Create Backup
        </Button>
      </DialogActions>
    </Dialog>
  );

  // Render restore dialog
  const renderRestoreDialog = () => (
    <Dialog open={showRestoreDialog} onClose={() => setShowRestoreDialog(false)} maxWidth="sm" fullWidth>
      <DialogTitle>Restore System from Backup</DialogTitle>
      <DialogContent>
        <Alert severity="warning" sx={{ mb: 2 }}>
          <strong>Warning:</strong> Restoring a backup will overwrite all current data. 
          This action cannot be undone. Make sure to create a backup before proceeding.
        </Alert>
        
        <Typography variant="body2" gutterBottom>
          Select a backup to restore from:
        </Typography>
        
        <FormControl fullWidth sx={{ mt: 2 }}>
          <InputLabel>Backup</InputLabel>
          <Select
            value={selectedBackup?.id || ''}
            onChange={(e) => {
              const backup = backupData.find(b => b.id === e.target.value);
              setSelectedBackup(backup || null);
            }}
            label="Backup"
          >
            {backupData
              .filter(backup => backup.status === 'completed')
              .map((backup) => (
                <MenuItem key={backup.id} value={backup.id}>
                  {backup.name} ({backup.size})
                </MenuItem>
              ))}
          </Select>
        </FormControl>
        
        {selectedBackup && (
          <Alert severity="info" sx={{ mt: 2 }}>
            <strong>Selected:</strong> {selectedBackup.name}
            <br />
            Size: {selectedBackup.size} • Created: {new Date(selectedBackup.createdAt).toLocaleDateString()}
          </Alert>
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={() => setShowRestoreDialog(false)}>
          Cancel
        </Button>
        <Button
          variant="contained"
          color="warning"
          onClick={handleRestoreBackup}
          disabled={!selectedBackup}
          startIcon={<RestoreIcon />}
        >
          Restore System
        </Button>
      </DialogActions>
    </Dialog>
  );

  if (isLoading) {
    return (
      <Box sx={{ p: 3 }}>
        <LinearProgress />
        <Typography variant="h6" sx={{ mt: 2 }}>
          Loading system settings...
        </Typography>
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box display="flex" justifyContent="space-between" alignItems="center" sx={{ mb: 3 }}>
        <Typography variant="h4">System Settings</Typography>
        <Box display="flex" gap={1}>
          <Button
            variant="outlined"
            startIcon={<RefreshIcon />}
            onClick={() => queryClient.invalidateQueries({ queryKey: ['systemSettings'] })}
          >
            Refresh
          </Button>
          <Button
            variant="contained"
            startIcon={<SaveIcon />}
            onClick={() => updateSettingsMutation.mutate(data)}
          >
            Save All Changes
          </Button>
        </Box>
      </Box>

      <Grid container spacing={3}>
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>Settings Categories</Typography>
              <List dense>
                <ListItem button onClick={() => setActiveSection('features')}>
                  <ListItemIcon>
                    <SettingsIcon color={activeSection === 'features' ? 'primary' : 'action'} />
                  </ListItemIcon>
                  <ListItemText primary="Feature Flags" />
                </ListItem>
                <ListItem button onClick={() => setActiveSection('limits')}>
                  <ListItemIcon>
                    <SpeedIcon color={activeSection === 'limits' ? 'primary' : 'action'} />
                  </ListItemIcon>
                  <ListItemText primary="System Limits" />
                </ListItem>
                <ListItem button onClick={() => setActiveSection('security')}>
                  <ListItemIcon>
                    <SecurityIcon color={activeSection === 'security' ? 'primary' : 'action'} />
                  </ListItemIcon>
                  <ListItemText primary="Security" />
                </ListItem>
                <ListItem button onClick={() => setActiveSection('backup')}>
                  <ListItemIcon>
                    <BackupIcon color={activeSection === 'backup' ? 'primary' : 'action'} />
                  </ListItemIcon>
                  <ListItemText primary="Backup & Restore" />
                </ListItem>
              </List>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} md={9}>
          {activeSection === 'features' && renderFeatureFlags()}
          {activeSection === 'limits' && renderSystemLimits()}
          {activeSection === 'security' && renderSecuritySettings()}
          {activeSection === 'backup' && renderBackupRestore()}
        </Grid>
      </Grid>

      {renderBackupDialog()}
      {renderRestoreDialog()}

      <Snackbar
        open={updateSettingsMutation.isSuccess}
        autoHideDuration={6000}
        onClose={() => {}}
      >
        <Alert severity="success">
          System settings updated successfully!
        </Alert>
      </Snackbar>

      <Snackbar
        open={createBackupMutation.isSuccess}
        autoHideDuration={6000}
        onClose={() => {}}
      >
        <Alert severity="success">
          System backup created successfully!
        </Alert>
      </Snackbar>

      <Snackbar
        open={restoreBackupMutation.isSuccess}
        autoHideDuration={6000}
        onClose={() => {}}
      >
        <Alert severity="success">
          System restored from backup successfully!
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default SystemSettingsPage;
