import React, { useState, useEffect, useMemo } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Typography,
  Paper,
  Grid,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Button,
  Card,
  CardContent,
  CircularProgress,
  Alert,
  Chip,
  IconButton,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  useTheme,
  useMediaQuery,
  Avatar,
  Menu,
  ListItemIcon,
  ListItemText,
  Divider,
  Badge,
  LinearProgress
} from '@mui/material';
import {
  Add as AddIcon,
  Refresh as RefreshIcon,
  Search as SearchIcon,
  FilterList as FilterIcon,
  MoreVert as MoreIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Visibility as ViewIcon,
  Download as DownloadIcon,
  People as PeopleIcon,
  AdminPanelSettings as AdminIcon,
  Verified as VerifiedIcon,
  Block as BlockIcon,
  Timeline as TimelineIcon,
  Email as EmailIcon,
  Phone as PhoneIcon,
  LocationOn as LocationIcon,
  Security as SecurityIcon,
  TrendingUp as TrendingUpIcon,
  Warning as WarningIcon,
  CheckCircle as CheckCircleIcon,
  Cancel as CancelIcon,
  Save as SaveIcon
} from '@mui/icons-material';
import { DataGrid, GridColDef, GridToolbar, GridActionsCellItem } from '@mui/x-data-grid';
import { format } from 'date-fns';
import { getUsers, getUserStats, updateUserStatus, bulkUpdateUsers, exportUsers, deleteUser } from '../../services/adminAPI';

interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  displayName?: string;
  avatarUrl?: string;
  languagePreference: string;
  themePreference: string;
  subscriptionPlan: string;
  subscriptionStatus: string;
  subscriptionExpiresAt?: string;
  isVerified: boolean;
  isActive: boolean;
  isAdmin: boolean;
  lastLoginAt?: string;
  createdAt: string;
  updatedAt: string;
}

const AllUsersPage: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  // State
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [subscriptionFilter, setSubscriptionFilter] = useState('all');
  const [languageFilter, setLanguageFilter] = useState('all');
  const [verificationFilter, setVerificationFilter] = useState('all');
  const [adminFilter, setAdminFilter] = useState('all');
  const [selectedUsers, setSelectedUsers] = useState<string[]>([]);
  const [showFilters, setShowFilters] = useState(false);
  const [bulkActionDialog, setBulkActionDialog] = useState(false);
  const [bulkAction, setBulkAction] = useState('');
  const [bulkValue, setBulkValue] = useState('');
  const [deleteDialog, setDeleteDialog] = useState(false);
  const [userToDelete, setUserToDelete] = useState<User | null>(null);
  const [actionMenuAnchor, setActionMenuAnchor] = useState<null | HTMLElement>(null);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [isActionLoading, setIsActionLoading] = useState(false);

  // Query parameters
  const queryParams = {
    search: searchTerm,
    status: statusFilter,
    subscriptionPlan: subscriptionFilter,
    language: languageFilter,
    isVerified: verificationFilter,
    isAdmin: adminFilter,
    page: 1,
    limit: 100
  };

  // Fetch data
  const { data: usersData, isLoading, error } = useQuery({
    queryKey: ['users', queryParams],
    queryFn: () => getUsers(queryParams),
    staleTime: 2 * 60 * 1000, // 2 minutes
  });

  const { data: userStats } = useQuery({
    queryKey: ['user-stats'],
    queryFn: () => getUserStats(),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });

  // Enhanced columns definition
  const baseColumns: GridColDef[] = [
    {
      field: 'avatar',
      headerName: 'User',
      width: 120,
      sortable: false,
      renderCell: (params) => (
        <Box display="flex" alignItems="center" gap={1}>
          <Badge
            overlap="circular"
            anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
            badgeContent={
              params.row.isActive ? (
                <CheckCircleIcon sx={{ color: 'success.main', fontSize: 16 }} />
              ) : (
                <BlockIcon sx={{ color: 'error.main', fontSize: 16 }} />
              )
            }
          >
            <Avatar
              src={params.row.avatarUrl}
              sx={{ width: 40, height: 40 }}
            >
              {params.row.firstName?.charAt(0) || 'U'}
            </Avatar>
          </Badge>
          <Box>
            <Typography variant="body2" fontWeight="bold" noWrap>
              {params.row.firstName} {params.row.lastName}
            </Typography>
            <Typography variant="caption" color="text.secondary" noWrap>
              {params.row.email}
            </Typography>
          </Box>
        </Box>
      ),
    },
    {
      field: 'subscriptionPlan',
      headerName: 'Subscription',
      width: 140,
      renderCell: (params) => (
        <Box display="flex" flexDirection="column" gap={0.5}>
          <Chip
            label={params.value}
            size="small"
            color={
              params.value === 'lifetime' ? 'success' :
              params.value === 'premium' ? 'primary' : 'default'
            }
            variant="outlined"
            sx={{ fontSize: '0.75rem' }}
          />
          {params.row.subscriptionStatus && (
            <Chip
              label={params.row.subscriptionStatus}
              size="small"
              color={params.row.subscriptionStatus === 'active' ? 'success' : 'warning'}
              variant="filled"
              sx={{ fontSize: '0.7rem', height: 16 }}
            />
          )}
        </Box>
      ),
    },
    {
      field: 'isVerified',
      headerName: 'Verification',
      width: 120,
      renderCell: (params) => (
        <Box display="flex" alignItems="center" gap={1}>
          {params.value ? (
            <VerifiedIcon color="success" fontSize="small" />
          ) : (
            <WarningIcon color="warning" fontSize="small" />
          )}
          <Typography variant="caption" color={params.value ? 'success.main' : 'warning.main'}>
            {params.value ? 'Verified' : 'Pending'}
          </Typography>
        </Box>
      ),
    },
    {
      field: 'isAdmin',
      headerName: 'Role',
      width: 100,
      renderCell: (params) => (
        <Chip
          icon={params.value ? <AdminIcon /> : <PeopleIcon />}
          label={params.value ? 'Admin' : 'User'}
          size="small"
          color={params.value ? 'warning' : 'default'}
          variant={params.value ? 'filled' : 'outlined'}
        />
      ),
    },
    {
      field: 'lastLoginAt',
      headerName: 'Last Activity',
      width: 160,
      renderCell: (params) => {
        if (!params.value) {
          return (
            <Box display="flex" alignItems="center" gap={1}>
              <BlockIcon color="disabled" fontSize="small" />
              <Typography variant="caption" color="text.secondary">
                Never
              </Typography>
            </Box>
          );
        }
        
        const lastLogin = new Date(params.value);
        const now = new Date();
        const diffInHours = Math.floor((now.getTime() - lastLogin.getTime()) / (1000 * 60 * 60));
        
        let statusColor = 'success';
        let statusText = 'Active';
        
        if (diffInHours > 24 * 7) {
          statusColor = 'error';
          statusText = 'Inactive';
        } else if (diffInHours > 24) {
          statusColor = 'warning';
          statusText = 'Recent';
        }
        
        return (
          <Box>
            <Typography variant="body2" fontWeight="medium">
              {format(lastLogin, 'MMM dd, yyyy')}
            </Typography>
            <Typography variant="caption" color={`${statusColor}.main`}>
              {statusText} • {diffInHours < 24 ? `${diffInHours}h ago` : `${Math.floor(diffInHours / 24)}d ago`}
            </Typography>
          </Box>
        );
      },
    },
    {
      field: 'createdAt',
      headerName: 'Member Since',
      width: 140,
      renderCell: (params) => {
        const created = new Date(params.value);
        const now = new Date();
        const diffInDays = Math.floor((now.getTime() - created.getTime()) / (1000 * 60 * 60 * 24));
        
        return (
          <Box>
            <Typography variant="body2" fontWeight="medium">
              {format(created, 'MMM dd, yyyy')}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {diffInDays < 30 ? `${diffInDays}d ago` : `${Math.floor(diffInDays / 30)}mo ago`}
            </Typography>
          </Box>
        );
      },
    },
    {
      field: 'actions',
      headerName: 'Actions',
      type: 'actions',
      width: 120,
      getActions: (params) => [
        <GridActionsCellItem
          icon={<ViewIcon />}
          label="View Details"
          onClick={() => navigate(`/admin/users/${params.row.id}`)}
        />,
        <GridActionsCellItem
          icon={<EditIcon />}
          label="Edit User"
          onClick={() => navigate(`/admin/users/${params.row.id}/edit`)}
        />,
        <GridActionsCellItem
          icon={<DeleteIcon />}
          label="Delete User"
          onClick={() => {
            setUserToDelete(params.row);
            setDeleteDialog(true);
          }}
          showInMenu
        />,
      ],
    },
  ];

  // Mobile columns
  const columns = useMemo(() => {
    if (isMobile) {
      return baseColumns.filter(col => 
        ['avatar', 'name', 'email', 'actions'].includes(col.field)
      );
    }
    return baseColumns;
  }, [isMobile]);

  // Handle bulk actions
  const handleBulkAction = async () => {
    if (!selectedUsers.length || !bulkAction) return;

    setIsActionLoading(true);
    try {
      await bulkUpdateUsers({
        userIds: selectedUsers,
        action: bulkAction,
        value: bulkValue
      });

      // Refresh data
      queryClient.invalidateQueries({ queryKey: ['users'] });
      queryClient.invalidateQueries({ queryKey: ['user-stats'] });
      setSelectedUsers([]);
      setBulkActionDialog(false);
    } catch (error) {
      console.error('Bulk action failed:', error);
    } finally {
      setIsActionLoading(false);
    }
  };

  // Handle user deletion
  const handleDeleteUser = async () => {
    if (!userToDelete) return;

    setIsActionLoading(true);
    try {
      await deleteUser(userToDelete.id);
      queryClient.invalidateQueries({ queryKey: ['users'] });
      queryClient.invalidateQueries({ queryKey: ['user-stats'] });
      setDeleteDialog(false);
      setUserToDelete(null);
    } catch (error) {
      console.error('Delete user failed:', error);
    } finally {
      setIsActionLoading(false);
    }
  };

  // Handle export
  const handleExport = async () => {
    try {
      const filters = {
        status: statusFilter !== 'all' ? statusFilter : undefined,
        subscriptionPlan: subscriptionFilter !== 'all' ? subscriptionFilter : undefined,
        language: languageFilter !== 'all' ? languageFilter : undefined,
      };
      
      await exportUsers({ format: 'csv', filters });
    } catch (error) {
      console.error('Export failed:', error);
    }
  };

  if (error) {
    return (
      <Alert severity="error" sx={{ mb: 3 }}>
        Error loading users. Please try again later.
      </Alert>
    );
  }

  return (
    <Box>
      {/* Header */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h5" fontWeight="bold">
          All Users
        </Typography>
        <Box display="flex" gap={1}>
          <Button
            variant="outlined"
            startIcon={<RefreshIcon />}
            onClick={() => queryClient.invalidateQueries({ queryKey: ['users'] })}
            size="small"
          >
            Refresh
          </Button>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => navigate('/admin/users/new')}
            size="small"
          >
            Add New User
          </Button>
        </Box>
      </Box>

      {/* Enhanced Statistics Cards */}
      <Grid container spacing={3} mb={3}>
        <Grid item xs={6} sm={6} md={3}>
          <Card sx={{ 
            background: `linear-gradient(135deg, ${theme.palette.primary.main}15, ${theme.palette.primary.main}25)`,
            border: `1px solid ${theme.palette.primary.main}20`
          }}>
            <CardContent sx={{ textAlign: 'center', py: 2 }}>
              <Box
                sx={{
                  backgroundColor: theme.palette.primary.main,
                  borderRadius: '50%',
                  p: 1.5,
                  display: 'inline-flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  mb: 2
                }}
              >
                <PeopleIcon sx={{ color: 'white', fontSize: 28 }} />
              </Box>
              <Typography variant="h4" fontWeight="bold" color="primary">
                {userStats?.totalUsers || 0}
              </Typography>
              <Typography variant="body2" color="text.secondary" mb={1}>
                Total Users
              </Typography>
              <Typography variant="caption" color="success.main">
                +{userStats?.newUsersThisMonth || 0} this month
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={6} sm={6} md={3}>
          <Card sx={{ 
            background: `linear-gradient(135deg, ${theme.palette.success.main}15, ${theme.palette.success.main}25)`,
            border: `1px solid ${theme.palette.success.main}20`
          }}>
            <CardContent sx={{ textAlign: 'center', py: 2 }}>
              <Box
                sx={{
                  backgroundColor: theme.palette.success.main,
                  borderRadius: '50%',
                  p: 1.5,
                  display: 'inline-flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  mb: 2
                }}
              >
                <CheckCircleIcon sx={{ color: 'white', fontSize: 28 }} />
              </Box>
              <Typography variant="h4" fontWeight="bold" color="success.main">
                {userStats?.activeUsers || 0}
              </Typography>
              <Typography variant="body2" color="text.secondary" mb={1}>
                Active Users
              </Typography>
              <Typography variant="caption" color="success.main">
                {userStats?.totalUsers ? Math.round((userStats.activeUsers / userStats.totalUsers) * 100) : 0}% of total
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={6} sm={6} md={3}>
          <Card sx={{ 
            background: `linear-gradient(135deg, ${theme.palette.warning.main}15, ${theme.palette.warning.main}25)`,
            border: `1px solid ${theme.palette.warning.main}20`
          }}>
            <CardContent sx={{ textAlign: 'center', py: 2 }}>
              <Box
                sx={{
                  backgroundColor: theme.palette.warning.main,
                  borderRadius: '50%',
                  p: 1.5,
                  display: 'inline-flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  mb: 2
                }}
              >
                <AdminIcon sx={{ color: 'white', fontSize: 28 }} />
              </Box>
              <Typography variant="h4" fontWeight="bold" color="warning.main">
                {userStats?.adminUsers || 0}
              </Typography>
              <Typography variant="body2" color="text.secondary" mb={1}>
                Admin Users
              </Typography>
              <Typography variant="caption" color="warning.main">
                {userStats?.verifiedUsers || 0} verified
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={6} sm={6} md={3}>
          <Card sx={{ 
            background: `linear-gradient(135deg, ${theme.palette.info.main}15, ${theme.palette.info.main}25)`,
            border: `1px solid ${theme.palette.info.main}20`
          }}>
            <CardContent sx={{ textAlign: 'center', py: 2 }}>
              <Box
                sx={{
                  backgroundColor: theme.palette.info.main,
                  borderRadius: '50%',
                  p: 1.5,
                  display: 'inline-flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  mb: 2
                }}
              >
                <TrendingUpIcon sx={{ color: 'white', fontSize: 28 }} />
              </Box>
              <Typography variant="h4" fontWeight="bold" color="info.main">
                {userStats?.newUsersThisWeek || 0}
              </Typography>
              <Typography variant="body2" color="text.secondary" mb={1}>
                New This Week
              </Typography>
              <Typography variant="caption" color="info.main">
                {userStats?.recentLogins || 0} recent logins
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Search and Filters */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} sm={6} md={4}>
            <TextField
              fullWidth
              size="small"
              placeholder="Search users..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              InputProps={{
                startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
              }}
            />
          </Grid>
          
          <Grid item xs={12} sm={6} md={2}>
            <FormControl fullWidth size="small">
              <InputLabel>Status</InputLabel>
              <Select
                value={statusFilter}
                label="Status"
                onChange={(e) => setStatusFilter(e.target.value)}
              >
                <MenuItem value="all">All</MenuItem>
                <MenuItem value="active">Active</MenuItem>
                <MenuItem value="inactive">Inactive</MenuItem>
              </Select>
            </FormControl>
          </Grid>

          <Grid item xs={12} sm={6} md={2}>
            <FormControl fullWidth size="small">
              <InputLabel>Plan</InputLabel>
              <Select
                value={subscriptionFilter}
                label="Plan"
                onChange={(e) => setSubscriptionFilter(e.target.value)}
              >
                <MenuItem value="all">All</MenuItem>
                <MenuItem value="free">Free</MenuItem>
                <MenuItem value="premium">Premium</MenuItem>
                <MenuItem value="lifetime">Lifetime</MenuItem>
              </Select>
            </FormControl>
          </Grid>

          <Grid item xs={12} sm={6} md={2}>
            <FormControl fullWidth size="small">
              <InputLabel>Language</InputLabel>
              <Select
                value={languageFilter}
                label="Language"
                onChange={(e) => setLanguageFilter(e.target.value)}
              >
                <MenuItem value="all">All</MenuItem>
                <MenuItem value="en">English</MenuItem>
                <MenuItem value="so">Somali</MenuItem>
                <MenuItem value="ar">Arabic</MenuItem>
              </Select>
            </FormControl>
          </Grid>

          <Grid item xs={12} sm={6} md={2}>
            <Button
              variant="outlined"
              startIcon={<FilterIcon />}
              onClick={() => setShowFilters(!showFilters)}
              size="small"
              fullWidth
            >
              More Filters
            </Button>
          </Grid>
        </Grid>

        {/* Additional Filters */}
        {showFilters && (
          <Box mt={2} pt={2} borderTop={1} borderColor="divider">
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6} md={3}>
                <FormControl fullWidth size="small">
                  <InputLabel>Verification</InputLabel>
                  <Select
                    value={verificationFilter}
                    label="Verification"
                    onChange={(e) => setVerificationFilter(e.target.value)}
                  >
                    <MenuItem value="all">All</MenuItem>
                    <MenuItem value="true">Verified</MenuItem>
                    <MenuItem value="false">Unverified</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <FormControl fullWidth size="small">
                  <InputLabel>Role</InputLabel>
                  <Select
                    value={adminFilter}
                    label="Role"
                    onChange={(e) => setAdminFilter(e.target.value)}
                  >
                    <MenuItem value="all">All</MenuItem>
                    <MenuItem value="true">Admin</MenuItem>
                    <MenuItem value="false">User</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
            </Grid>
          </Box>
        )}
      </Paper>

      {/* Bulk Actions */}
      {selectedUsers.length > 0 && (
        <Paper sx={{ p: 2, mb: 3, backgroundColor: 'primary.light', color: 'white' }}>
          <Box display="flex" justifyContent="space-between" alignItems="center">
            <Typography variant="body1">
              {selectedUsers.length} user(s) selected
            </Typography>
            <Box display="flex" gap={1}>
              <Button
                variant="contained"
                color="secondary"
                onClick={() => setBulkActionDialog(true)}
                size="small"
              >
                Bulk Actions
              </Button>
              <Button
                variant="outlined"
                color="inherit"
                onClick={() => setSelectedUsers([])}
                size="small"
              >
                Clear Selection
              </Button>
            </Box>
          </Box>
        </Paper>
      )}

      {/* Users DataGrid */}
      <Paper sx={{ height: 600, width: '100%' }}>
        <DataGrid
          rows={usersData?.users || []}
          columns={columns}
          loading={isLoading}
          checkboxSelection
          onRowSelectionModelChange={(newSelection) => setSelectedUsers(newSelection as string[])}
          rowSelectionModel={selectedUsers}
          getRowId={(row) => row.id}
          pageSizeOptions={[10, 25, 50, 100]}
          initialState={{
            pagination: {
              paginationModel: { page: 0, pageSize: 25 },
            },
          }}
          slots={{ toolbar: GridToolbar }}
          slotProps={{
            toolbar: {
              showQuickFilter: false,
            },
          }}
          disableRowSelectionOnClick
          density="compact"
        />
      </Paper>

      {/* Bulk Action Dialog */}
      <Dialog open={bulkActionDialog} onClose={() => setBulkActionDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Bulk Update Users</DialogTitle>
        <DialogContent>
          <Box display="flex" flexDirection="column" gap={2} mt={1}>
            <Alert severity="info" sx={{ mb: 2 }}>
              This action will be applied to {selectedUsers.length} selected user(s).
            </Alert>
            <FormControl fullWidth>
              <InputLabel>Action</InputLabel>
              <Select
                value={bulkAction}
                label="Action"
                onChange={(e) => setBulkAction(e.target.value)}
              >
                <MenuItem value="activate">Activate Users</MenuItem>
                <MenuItem value="deactivate">Deactivate Users</MenuItem>
                <MenuItem value="verify">Verify Users</MenuItem>
                <MenuItem value="unverify">Unverify Users</MenuItem>
                <MenuItem value="make_admin">Make Admin</MenuItem>
                <MenuItem value="remove_admin">Remove Admin</MenuItem>
                <MenuItem value="change_plan">Change Plan</MenuItem>
              </Select>
            </FormControl>
            
            {bulkAction === 'change_plan' && (
              <FormControl fullWidth>
                <InputLabel>New Plan</InputLabel>
                <Select
                  value={bulkValue}
                  label="New Plan"
                  onChange={(e) => setBulkValue(e.target.value)}
                >
                  <MenuItem value="free">Free</MenuItem>
                  <MenuItem value="premium">Premium</MenuItem>
                  <MenuItem value="lifetime">Lifetime</MenuItem>
                </Select>
              </FormControl>
            )}
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setBulkActionDialog(false)} disabled={isLoading}>
            Cancel
          </Button>
          <Button 
            onClick={handleBulkAction} 
            variant="contained"
            disabled={isActionLoading || !bulkAction}
            startIcon={isActionLoading ? <CircularProgress size={16} /> : <SaveIcon />}
          >
            {isActionLoading ? 'Applying...' : 'Apply Changes'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete User Dialog */}
      <Dialog open={deleteDialog} onClose={() => setDeleteDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>
          <Box display="flex" alignItems="center" gap={1}>
            <WarningIcon color="error" />
            Delete User
          </Box>
        </DialogTitle>
        <DialogContent>
          <Alert severity="warning" sx={{ mb: 2 }}>
            This action cannot be undone. All user data, including their library and preferences, will be permanently deleted.
          </Alert>
          {userToDelete && (
            <Box>
              <Typography variant="body1" gutterBottom>
                Are you sure you want to delete this user?
              </Typography>
              <Box display="flex" alignItems="center" gap={2} mt={2} p={2} sx={{ backgroundColor: 'grey.50', borderRadius: 1 }}>
                <Avatar src={userToDelete.avatarUrl}>
                  {userToDelete.firstName?.charAt(0) || 'U'}
                </Avatar>
                <Box>
                  <Typography variant="body1" fontWeight="bold">
                    {userToDelete.firstName} {userToDelete.lastName}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {userToDelete.email}
                  </Typography>
                </Box>
              </Box>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialog(false)} disabled={isLoading}>
            Cancel
          </Button>
          <Button 
            onClick={handleDeleteUser} 
            variant="contained"
            color="error"
            disabled={isActionLoading}
            startIcon={isActionLoading ? <CircularProgress size={16} /> : <DeleteIcon />}
          >
            {isActionLoading ? 'Deleting...' : 'Delete User'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default AllUsersPage;
