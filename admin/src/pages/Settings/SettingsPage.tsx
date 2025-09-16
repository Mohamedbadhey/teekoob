import React, { useState, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Box,
  Typography,
  Paper,
  Grid,
  Switch,
  FormControlLabel,
  TextField,
  Button,
  Divider,
  Alert,
  CircularProgress,
  Card,
  CardContent,
  CardHeader,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
} from '@mui/material'
import {
  Save as SaveIcon,
  Refresh as RefreshIcon,
  Backup as BackupIcon,
  Restore as RestoreIcon,
  Security as SecurityIcon,
  Storage as StorageIcon,
  Notifications as NotificationsIcon,
  Language as LanguageIcon,
} from '@mui/icons-material'
import { getSystemSettings, updateSystemSettings } from '@/services/adminAPI'
import { useDispatch } from 'react-redux'
import { addNotification } from '@/store/slices/uiSlice'

const SettingsPage: React.FC = () => {
  const dispatch = useDispatch()
  const queryClient = useQueryClient()
  
  const [settings, setSettings] = useState({
    features: {
      userRegistration: true,
      socialLogin: true,
      offlineMode: true,
      multiLanguage: true,
      pushNotifications: true,
      analytics: true,
    },
    limits: {
      maxFileSize: '100',
      maxBooksPerUser: '1000',
      maxOfflineDownloads: '100',
      maxUploadsPerDay: '10',
    },
    security: {
      requireEmailVerification: true,
      requirePhoneVerification: false,
      twoFactorAuth: false,
      sessionTimeout: '24',
      maxLoginAttempts: '5',
    },
    notifications: {
      emailNotifications: true,
      pushNotifications: true,
      smsNotifications: false,
      adminAlerts: true,
    },
  })

  const [backupDialogOpen, setBackupDialogOpen] = useState(false)
  const [restoreDialogOpen, setRestoreDialogOpen] = useState(false)
  const [selectedFile, setSelectedFile] = useState<File | null>(null)

  // Fetch current settings
  const { data: currentSettings, isLoading } = useQuery({
    queryKey: ['admin-settings'],
    queryFn: () => getSettings(),
  })

  // Update settings mutation
  const updateSettingsMutation = useMutation({
    mutationFn: (data: any) => updateSettings(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-settings'] })
      dispatch(addNotification({
        type: 'success',
        message: 'Settings updated successfully',
      }))
    },
    onError: (error: any) => {
      dispatch(addNotification({
        type: 'error',
        message: error.response?.data?.error || 'Failed to update settings',
      }))
    },
  })

  // Create backup mutation
  const createBackupMutation = useMutation({
    mutationFn: () => createBackup(),
    onSuccess: () => {
      dispatch(addNotification({
        type: 'success',
        message: 'Backup created successfully',
      }))
      setBackupDialogOpen(false)
    },
    onError: (error: any) => {
      dispatch(addNotification({
        type: 'error',
        message: error.response?.data?.error || 'Failed to create backup',
      }))
    },
  })

  // Restore backup mutation
  const restoreBackupMutation = useMutation({
    mutationFn: (backupId: string) => restoreBackup(backupId),
    onSuccess: () => {
      dispatch(addNotification({
        type: 'success',
        message: 'Backup restored successfully',
      }))
      setRestoreDialogOpen(false)
    },
    onError: (error: any) => {
      dispatch(addNotification({
        type: 'error',
        message: error.response?.data?.error || 'Failed to restore backup',
      }))
    },
  })

  // Update settings when fetched
  useEffect(() => {
    if (currentSettings) {
      setSettings(currentSettings)
    }
  }, [currentSettings])

  const handleFeatureToggle = (feature: string) => (event: React.ChangeEvent<HTMLInputElement>) => {
    setSettings(prev => ({
      ...prev,
      features: {
        ...prev.features,
        [feature]: event.target.checked,
      },
    }))
  }

  const handleLimitChange = (limit: string) => (event: React.ChangeEvent<HTMLInputElement>) => {
    setSettings(prev => ({
      ...prev,
      limits: {
        ...prev.limits,
        [limit]: event.target.value,
      },
    }))
  }

  const handleSecurityToggle = (setting: string) => (event: React.ChangeEvent<HTMLInputElement>) => {
    setSettings(prev => ({
      ...prev,
      security: {
        ...prev.security,
        [setting]: event.target.checked,
      },
    }))
  }

  const handleSecurityChange = (setting: string) => (event: React.ChangeEvent<HTMLInputElement>) => {
    setSettings(prev => ({
      ...prev,
      security: {
        ...prev.security,
        [setting]: event.target.value,
      },
    }))
  }

  const handleNotificationToggle = (setting: string) => (event: React.ChangeEvent<HTMLInputElement>) => {
    setSettings(prev => ({
      ...prev,
      notifications: {
        ...prev.notifications,
        [setting]: event.target.checked,
      },
    }))
  }

  const handleSaveSettings = () => {
    updateSettingsMutation.mutate(settings)
  }

  const handleCreateBackup = () => {
    createBackupMutation.mutate()
  }

  const handleRestoreBackup = () => {
    if (selectedFile) {
      // In a real implementation, you'd upload the file and get a backup ID
      restoreBackupMutation.mutate('backup-id')
    }
  }

  if (isLoading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    )
  }

  return (
    <Box>
      {/* Header */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" fontWeight="bold">
          System Settings
        </Typography>
        <Button
          variant="contained"
          startIcon={<SaveIcon />}
          onClick={handleSaveSettings}
          disabled={updateSettingsMutation.isPending}
        >
          Save Settings
        </Button>
      </Box>

      <Grid container spacing={3}>
        {/* Features Settings */}
        <Grid item xs={12} lg={6}>
          <Card>
            <CardHeader
              title="Feature Flags"
              avatar={<LanguageIcon />}
            />
            <CardContent>
              <Box display="flex" flexDirection="column" gap={2}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.features.userRegistration}
                      onChange={handleFeatureToggle('userRegistration')}
                    />
                  }
                  label="User Registration"
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.features.socialLogin}
                      onChange={handleFeatureToggle('socialLogin')}
                    />
                  }
                  label="Social Login"
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.features.offlineMode}
                      onChange={handleFeatureToggle('offlineMode')}
                    />
                  }
                  label="Offline Mode"
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.features.multiLanguage}
                      onChange={handleFeatureToggle('multiLanguage')}
                    />
                  }
                  label="Multi-language Support"
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.features.pushNotifications}
                      onChange={handleFeatureToggle('pushNotifications')}
                    />
                  }
                  label="Push Notifications"
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.features.analytics}
                      onChange={handleFeatureToggle('analytics')}
                    />
                  }
                  label="Analytics & Tracking"
                />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* System Limits */}
        <Grid item xs={12} lg={6}>
          <Card>
            <CardHeader
              title="System Limits"
              avatar={<StorageIcon />}
            />
            <CardContent>
              <Box display="flex" flexDirection="column" gap={2}>
                <TextField
                  label="Max File Size (MB)"
                  type="number"
                  value={settings.limits.maxFileSize}
                  onChange={handleLimitChange('maxFileSize')}
                  inputProps={{ min: 1, max: 1000 }}
                />
                <TextField
                  label="Max Books Per User"
                  type="number"
                  value={settings.limits.maxBooksPerUser}
                  onChange={handleLimitChange('maxBooksPerUser')}
                  inputProps={{ min: 1, max: 10000 }}
                />
                <TextField
                  label="Max Offline Downloads"
                  type="number"
                  value={settings.limits.maxOfflineDownloads}
                  onChange={handleLimitChange('maxOfflineDownloads')}
                  inputProps={{ min: 1, max: 1000 }}
                />
                <TextField
                  label="Max Uploads Per Day"
                  type="number"
                  value={settings.limits.maxUploadsPerDay}
                  onChange={handleLimitChange('maxUploadsPerDay')}
                  inputProps={{ min: 1, max: 100 }}
                />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Security Settings */}
        <Grid item xs={12} lg={6}>
          <Card>
            <CardHeader
              title="Security Settings"
              avatar={<SecurityIcon />}
            />
            <CardContent>
              <Box display="flex" flexDirection="column" gap={2}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.security.requireEmailVerification}
                      onChange={handleSecurityToggle('requireEmailVerification')}
                    />
                  }
                  label="Require Email Verification"
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.security.requirePhoneVerification}
                      onChange={handleSecurityToggle('requirePhoneVerification')}
                    />
                  }
                  label="Require Phone Verification"
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.security.twoFactorAuth}
                      onChange={handleSecurityToggle('twoFactorAuth')}
                    />
                  }
                  label="Two-Factor Authentication"
                />
                <TextField
                  label="Session Timeout (hours)"
                  type="number"
                  value={settings.security.sessionTimeout}
                  onChange={handleSecurityChange('sessionTimeout')}
                  inputProps={{ min: 1, max: 168 }}
                />
                <TextField
                  label="Max Login Attempts"
                  type="number"
                  value={settings.security.maxLoginAttempts}
                  onChange={handleSecurityChange('maxLoginAttempts')}
                  inputProps={{ min: 1, max: 10 }}
                />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Notification Settings */}
        <Grid item xs={12} lg={6}>
          <Card>
            <CardHeader
              title="Notification Settings"
              avatar={<NotificationsIcon />}
            />
            <CardContent>
              <Box display="flex" flexDirection="column" gap={2}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.notifications.emailNotifications}
                      onChange={handleNotificationToggle('emailNotifications')}
                    />
                  }
                  label="Email Notifications"
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.notifications.pushNotifications}
                      onChange={handleNotificationToggle('pushNotifications')}
                    />
                  }
                  label="Push Notifications"
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.notifications.smsNotifications}
                      onChange={handleNotificationToggle('smsNotifications')}
                    />
                  }
                  label="SMS Notifications"
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.notifications.adminAlerts}
                      onChange={handleNotificationToggle('adminAlerts')}
                    />
                  }
                  label="Admin Alerts"
                />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Backup & Restore */}
        <Grid item xs={12}>
          <Card>
            <CardHeader
              title="Backup & Restore"
              avatar={<BackupIcon />}
            />
            <CardContent>
              <Box display="flex" gap={2}>
                <Button
                  variant="outlined"
                  startIcon={<BackupIcon />}
                  onClick={() => setBackupDialogOpen(true)}
                >
                  Create Backup
                </Button>
                <Button
                  variant="outlined"
                  startIcon={<RestoreIcon />}
                  onClick={() => setRestoreDialogOpen(true)}
                >
                  Restore Backup
                </Button>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Create Backup Dialog */}
      <Dialog open={backupDialogOpen} onClose={() => setBackupDialogOpen(false)}>
        <DialogTitle>Create System Backup</DialogTitle>
        <DialogContent>
          <Typography>
            This will create a complete backup of the system including:
          </Typography>
          <Box component="ul" sx={{ mt: 1 }}>
            <li>Database</li>
            <li>User files</li>
            <li>System configuration</li>
            <li>Analytics data</li>
          </Box>
          <Alert severity="info" sx={{ mt: 2 }}>
            The backup process may take several minutes depending on the data size.
          </Alert>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setBackupDialogOpen(false)}>Cancel</Button>
          <Button
            onClick={handleCreateBackup}
            variant="contained"
            disabled={createBackupMutation.isPending}
          >
            Create Backup
          </Button>
        </DialogActions>
      </Dialog>

      {/* Restore Backup Dialog */}
      <Dialog open={restoreDialogOpen} onClose={() => setRestoreDialogOpen(false)}>
        <DialogTitle>Restore System Backup</DialogTitle>
        <DialogContent>
          <Typography>
            Warning: This will overwrite the current system with backup data.
          </Typography>
          <Alert severity="warning" sx={{ mt: 2 }}>
            This action cannot be undone. Please ensure you have a current backup before proceeding.
          </Alert>
          <input
            type="file"
            accept=".zip,.tar.gz"
            onChange={(e) => setSelectedFile(e.target.files?.[0] || null)}
            style={{ marginTop: '16px' }}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setRestoreDialogOpen(false)}>Cancel</Button>
          <Button
            onClick={handleRestoreBackup}
            variant="contained"
            color="error"
            disabled={restoreBackupMutation.isPending || !selectedFile}
          >
            Restore Backup
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  )
}

export default SettingsPage
