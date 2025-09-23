import React, { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Box,
  Typography,
  Paper,
  Grid,
  Avatar,
  Chip,
  Button,
  Card,
  CardContent,
  CardHeader,
  Divider,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Switch,
  FormControlLabel,
  TextField,
  Alert,
  CircularProgress,
  Tabs,
  Tab,
  Badge,
  IconButton,
  Tooltip,
  LinearProgress,
  useTheme,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Timeline,
  TimelineItem,
  TimelineSeparator,
  TimelineConnector,
  TimelineContent,
  TimelineDot,
  TimelineOppositeContent
} from '@mui/material'
import {
  Person as PersonIcon,
  Email as EmailIcon,
  Phone as PhoneIcon,
  Language as LanguageIcon,
  Book as BookIcon,
  Payment as PaymentIcon,
  Edit as EditIcon,
  Save as SaveIcon,
  Cancel as CancelIcon,
  Block as BlockIcon,
  CheckCircle as VerifyIcon,
  AdminPanelSettings as AdminIcon,
  Security as SecurityIcon,
  Timeline as TimelineIcon,
  TrendingUp as TrendingUpIcon,
  Warning as WarningIcon,
  Info as InfoIcon,
  Refresh as RefreshIcon,
  Download as DownloadIcon,
  MoreVert as MoreVertIcon,
  Visibility as VisibilityIcon,
  Delete as DeleteIcon
} from '@mui/icons-material'
import { getUser, updateUserStatus, deleteUser } from '@/services/adminAPI'
import { useDispatch } from 'react-redux'
import { addNotification } from '@/store/slices/uiSlice'
import { format } from 'date-fns'

interface TabPanelProps {
  children?: React.ReactNode
  index: number
  value: number
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`user-tabpanel-${index}`}
      aria-labelledby={`user-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ p: 3 }}>{children}</Box>}
    </div>
  )
}

const UserDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const dispatch = useDispatch()
  const queryClient = useQueryClient()
  const theme = useTheme()
  
  const [tabValue, setTabValue] = useState(0)
  const [editMode, setEditMode] = useState(false)
  const [editData, setEditData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    languagePreference: 'en',
    themePreference: 'light',
  })
  const [statusDialogOpen, setStatusDialogOpen] = useState(false)
  const [newStatus, setNewStatus] = useState({ isActive: true, isVerified: true })
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [isActionLoading, setIsActionLoading] = useState(false)

  // Fetch user data
  const { data: userData, isLoading } = useQuery({
    queryKey: ['admin-user', id],
    queryFn: () => getUser(id!),
  })

  // Update user status mutation
  const updateUserStatusMutation = useMutation({
    mutationFn: (data: { id: string; status: { isActive?: boolean; isVerified?: boolean } }) =>
              updateUserStatus(data.id, data.status),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-user', id] })
      queryClient.invalidateQueries({ queryKey: ['admin-users'] })
      dispatch(addNotification({
        type: 'success',
        message: 'User status updated successfully',
      }))
      setStatusDialogOpen(false)
    },
    onError: (error: any) => {
      dispatch(addNotification({
        type: 'error',
        message: error.response?.data?.error || 'Failed to update user status',
      }))
    },
  })

  // Delete user mutation
  const deleteUserMutation = useMutation({
    mutationFn: (userId: string) => deleteUser(userId),
    onSuccess: () => {
      dispatch(addNotification({
        type: 'success',
        message: 'User deleted successfully',
      }))
      navigate('/admin/users')
    },
    onError: (error: any) => {
      dispatch(addNotification({
        type: 'error',
        message: error.response?.data?.error || 'Failed to delete user',
      }))
    },
  })

  // Initialize edit data when user data is loaded
  React.useEffect(() => {
    if (userData?.user) {
      setEditData({
        firstName: userData.user.first_name || '',
        lastName: userData.user.last_name || '',
        email: userData.user.email || '',
        languagePreference: userData.user.language_preference || 'en',
        themePreference: userData.user.theme_preference || 'light',
      })
    }
  }, [userData])

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue)
  }

  const handleEditToggle = () => {
    if (editMode) {
      // Reset to original data
      if (userData?.user) {
        setEditData({
          firstName: userData.user.first_name || '',
          lastName: userData.user.last_name || '',
          email: userData.user.email || '',
          languagePreference: userData.user.language_preference || 'en',
          themePreference: userData.user.theme_preference || 'light',
        })
      }
    }
    setEditMode(!editMode)
  }

  const handleInputChange = (field: string) => (event: React.ChangeEvent<HTMLInputElement>) => {
    setEditData(prev => ({
      ...prev,
      [field]: event.target.value,
    }))
  }

  const handleStatusUpdate = () => {
    if (id) {
      updateUserStatusMutation.mutate({
        id,
        status: newStatus,
      })
    }
  }

  const getSubscriptionColor = (plan: string) => {
    switch (plan) {
      case 'premium':
        return 'success'
      case 'lifetime':
        return 'warning'
      default:
        return 'default'
    }
  }

  const getStatusColor = (isActive: boolean) => {
    return isActive ? 'success' : 'error'
  }

  if (isLoading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    )
  }

  if (!userData?.user) {
    return (
      <Box>
        <Typography variant="h4" color="error">
          User not found
        </Typography>
      </Box>
    )
  }

  const user = userData.user

  return (
    <Box>
      {/* Header */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" fontWeight="bold">
          User Details
        </Typography>
        <Box display="flex" gap={2}>
          <Button
            variant="outlined"
            startIcon={editMode ? <CancelIcon /> : <EditIcon />}
            onClick={handleEditToggle}
          >
            {editMode ? 'Cancel' : 'Edit'}
          </Button>
          <Button
            variant="outlined"
            startIcon={<BlockIcon />}
            onClick={() => {
              setNewStatus({
                isActive: user.is_active,
                isVerified: user.is_verified,
              })
              setStatusDialogOpen(true)
            }}
          >
            Update Status
          </Button>
          <Button
            variant="outlined"
            color="error"
            startIcon={<DeleteIcon />}
            onClick={() => setDeleteDialogOpen(true)}
          >
            Delete User
          </Button>
        </Box>
      </Box>

      {/* Enhanced User Profile Card */}
      <Paper sx={{ 
        p: 3, 
        mb: 3,
        background: `linear-gradient(135deg, ${theme.palette.primary.main}05, ${theme.palette.primary.main}10)`,
        border: `1px solid ${theme.palette.primary.main}20`
      }}>
        <Grid container spacing={3} alignItems="center">
          <Grid item>
            <Badge
              overlap="circular"
              anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
              badgeContent={
                user.is_active ? (
                  <CheckCircleIcon sx={{ color: 'success.main', fontSize: 20 }} />
                ) : (
                  <BlockIcon sx={{ color: 'error.main', fontSize: 20 }} />
                )
              }
            >
              <Avatar
                src={user.avatar_url}
                sx={{ width: 100, height: 100, border: `3px solid ${theme.palette.primary.main}20` }}
              >
                {user.first_name?.charAt(0) || 'U'}
              </Avatar>
            </Badge>
          </Grid>
          <Grid item xs>
            <Box display="flex" alignItems="center" gap={2} mb={1}>
              <Typography variant="h4" fontWeight="bold">
                {user.first_name} {user.last_name}
              </Typography>
              {user.is_admin && (
                <Chip
                  icon={<AdminIcon />}
                  label="Admin"
                  color="warning"
                  variant="filled"
                  size="small"
                />
              )}
            </Box>
            <Box display="flex" alignItems="center" gap={1} mb={2}>
              <EmailIcon fontSize="small" color="action" />
              <Typography variant="body1" color="textSecondary">
                {user.email}
              </Typography>
            </Box>
            <Box display="flex" gap={1} flexWrap="wrap" mb={2}>
              <Chip
                label={user.is_active ? 'Active' : 'Inactive'}
                color={getStatusColor(user.is_active)}
                size="small"
                icon={user.is_active ? <CheckCircleIcon /> : <BlockIcon />}
              />
              <Chip
                label={user.is_verified ? 'Verified' : 'Unverified'}
                color={user.is_verified ? 'success' : 'warning'}
                size="small"
                icon={user.is_verified ? <VerifyIcon /> : <WarningIcon />}
              />
              <Chip
                label={user.subscription_plan}
                color={getSubscriptionColor(user.subscription_plan)}
                variant="outlined"
                size="small"
              />
            </Box>
            <Box display="flex" gap={3}>
              <Box display="flex" alignItems="center" gap={1}>
                <LanguageIcon fontSize="small" color="action" />
                <Typography variant="body2" color="textSecondary">
                  {user.language_preference || 'en'}
                </Typography>
              </Box>
              <Box display="flex" alignItems="center" gap={1}>
                <TimelineIcon fontSize="small" color="action" />
                <Typography variant="body2" color="textSecondary">
                  Member since {format(new Date(user.created_at), 'MMM dd, yyyy')}
                </Typography>
              </Box>
            </Box>
          </Grid>
          <Grid item>
            <Box display="flex" flexDirection="column" gap={1}>
              <Typography variant="body2" color="textSecondary" textAlign="right">
                Last login: {user.last_login_at ? format(new Date(user.last_login_at), 'MMM dd, yyyy') : 'Never'}
              </Typography>
              <Typography variant="caption" color="textSecondary" textAlign="right">
                ID: {user.id}
              </Typography>
            </Box>
          </Grid>
        </Grid>
      </Paper>

      {/* Tabs */}
      <Paper sx={{ width: '100%' }}>
        <Tabs value={tabValue} onChange={handleTabChange} aria-label="user tabs">
          <Tab label="Profile" />
          <Tab label="Library" />
          <Tab label="Subscriptions" />
          <Tab label="Activity" />
        </Tabs>

        {/* Profile Tab */}
        <TabPanel value={tabValue} index={0}>
          <Grid container spacing={3}>
            <Grid item xs={12} md={6}>
              <Card>
                <CardHeader title="Personal Information" />
                <CardContent>
                  <Box display="flex" flexDirection="column" gap={2}>
                    <TextField
                      label="First Name"
                      value={editData.firstName}
                      onChange={handleInputChange('firstName')}
                      disabled={!editMode}
                      fullWidth
                    />
                    <TextField
                      label="Last Name"
                      value={editData.lastName}
                      onChange={handleInputChange('lastName')}
                      disabled={!editMode}
                      fullWidth
                    />
                    <TextField
                      label="Email"
                      value={editData.email}
                      onChange={handleInputChange('email')}
                      disabled={!editMode}
                      fullWidth
                    />
                  </Box>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} md={6}>
              <Card>
                <CardHeader title="Preferences" />
                <CardContent>
                  <Box display="flex" flexDirection="column" gap={2}>
                    <TextField
                      select
                      label="Language Preference"
                      value={editData.languagePreference}
                      onChange={handleInputChange('languagePreference')}
                      disabled={!editMode}
                      fullWidth
                    >
                      <option value="en">English</option>
                      <option value="so">Somali</option>
                      <option value="ar">Arabic</option>
                    </TextField>
                    <TextField
                      select
                      label="Theme Preference"
                      value={editData.themePreference}
                      onChange={handleInputChange('themePreference')}
                      disabled={!editMode}
                      fullWidth
                    >
                      <option value="light">Light</option>
                      <option value="dark">Dark</option>
                      <option value="sepia">Sepia</option>
                      <option value="night">Night</option>
                    </TextField>
                  </Box>
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        </TabPanel>

        {/* Library Tab */}
        <TabPanel value={tabValue} index={1}>
          <Card>
            <CardHeader title="User Library" />
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Library Statistics
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={12} sm={6} md={3}>
                  <Box textAlign="center">
                    <Typography variant="h4" color="primary">
                      {userData.libraryStats?.total_books || 0}
                    </Typography>
                    <Typography variant="body2" color="textSecondary">
                      Total Books
                    </Typography>
                  </Box>
                </Grid>
                {/* Add more library stats as needed */}
              </Grid>
            </CardContent>
          </Card>
        </TabPanel>

        {/* Subscriptions Tab */}
        <TabPanel value={tabValue} index={2}>
          <Card>
            <CardHeader title="Subscription History" />
            <CardContent>
              <List>
                {userData.subscriptions?.map((subscription: any, index: number) => (
                  <React.Fragment key={subscription.id}>
                    <ListItem>
                      <ListItemIcon>
                        <PaymentIcon color="primary" />
                      </ListItemIcon>
                      <ListItemText
                        primary={`${subscription.plan_type} - $${subscription.amount}`}
                        secondary={`${subscription.status} • ${new Date(subscription.created_at).toLocaleDateString()}`}
                      />
                      <Chip
                        label={subscription.status}
                        color={subscription.status === 'active' ? 'success' : 'default'}
                        size="small"
                      />
                    </ListItem>
                    {index < userData.subscriptions.length - 1 && <Divider />}
                  </React.Fragment>
                ))}
              </List>
            </CardContent>
          </Card>
        </TabPanel>

        {/* Activity Tab */}
        <TabPanel value={tabValue} index={3}>
          <Card>
            <CardHeader title="Recent Activity" />
            <CardContent>
              <Typography variant="body2" color="textSecondary">
                Last login: {user.last_login_at ? new Date(user.last_login_at).toLocaleString() : 'Never'}
              </Typography>
              {/* Add more activity information as needed */}
            </CardContent>
          </Card>
        </TabPanel>
      </Paper>

      {/* Status Update Dialog */}
      <Dialog open={statusDialogOpen} onClose={() => setStatusDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Update User Status</DialogTitle>
        <DialogContent>
          <Box sx={{ mt: 2 }}>
            <FormControlLabel
              control={
                <Switch
                  checked={newStatus.isActive}
                  onChange={(e) => setNewStatus(prev => ({ ...prev, isActive: e.target.checked }))}
                />
              }
              label="User Active"
            />
            <FormControlLabel
              control={
                <Switch
                  checked={newStatus.isVerified}
                  onChange={(e) => setNewStatus(prev => ({ ...prev, isVerified: e.target.checked }))}
                />
              }
              label="Email Verified"
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setStatusDialogOpen(false)}>Cancel</Button>
          <Button
            onClick={handleStatusUpdate}
            variant="contained"
            disabled={updateUserStatusMutation.isPending}
          >
            Update Status
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete User Dialog */}
      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>
          <Box display="flex" alignItems="center" gap={1}>
            <WarningIcon color="error" />
            Delete User
          </Box>
        </DialogTitle>
        <DialogContent>
          <Alert severity="error" sx={{ mb: 2 }}>
            This action cannot be undone. All user data, including their library and preferences, will be permanently deleted.
          </Alert>
          <Typography variant="body1" gutterBottom>
            Are you sure you want to delete this user?
          </Typography>
          <Box display="flex" alignItems="center" gap={2} mt={2} p={2} sx={{ backgroundColor: 'grey.50', borderRadius: 1 }}>
            <Avatar src={user.avatar_url}>
              {user.first_name?.charAt(0) || 'U'}
            </Avatar>
            <Box>
              <Typography variant="body1" fontWeight="bold">
                {user.first_name} {user.last_name}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {user.email}
              </Typography>
            </Box>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)} disabled={deleteUserMutation.isPending}>
            Cancel
          </Button>
          <Button
            onClick={() => deleteUserMutation.mutate(user.id)}
            variant="contained"
            color="error"
            disabled={deleteUserMutation.isPending}
            startIcon={deleteUserMutation.isPending ? <CircularProgress size={16} /> : <DeleteIcon />}
          >
            {deleteUserMutation.isPending ? 'Deleting...' : 'Delete User'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  )
}

export default UserDetailPage
