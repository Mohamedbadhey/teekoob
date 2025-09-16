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
  useMediaQuery
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
  Timeline as TimelineIcon
} from '@mui/icons-material';
import { DataGrid, GridColDef, GridToolbar } from '@mui/x-data-grid';
import { format } from 'date-fns';
import { getUsers, getUserStats, updateUserStatus, bulkUpdateUsers, exportUsers } from '../../services/adminAPI';

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

  // Columns definition
  const baseColumns: GridColDef[] = [
    {
      field: 'avatar',
      headerName: 'Avatar',
      width: 80,
      sortable: false,
      renderCell: (params) => (
        <Box
          sx={{
            width: 40,
            height: 40,
            borderRadius: '50%',
            backgroundColor: theme.palette.primary.main,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: 'white',
            fontWeight: 'bold',
            fontSize: '1rem'
          }}
        >
          {params.row.firstName?.charAt(0) || 'U'}
        </Box>
      ),
    },
    {
      field: 'name',
      headerName: 'Name',
      width: 200,
      valueGetter: (params) => `${params.row.firstName} ${params.row.lastName}`,
      renderCell: (params) => (
        <Box>
          <Typography variant="body2" fontWeight="bold">
            {params.row.firstName} {params.row.lastName}
          </Typography>
          {params.row.displayName && (
            <Typography variant="caption" color="text.secondary">
              @{params.row.displayName}
            </Typography>
          )}
        </Box>
      ),
    },
    {
      field: 'email',
      headerName: 'Email',
      width: 250,
      renderCell: (params) => (
        <Typography variant="body2" noWrap>
          {params.value}
        </Typography>
      ),
    },
    {
      field: 'subscriptionPlan',
      headerName: 'Plan',
      width: 120,
      renderCell: (params) => (
        <Chip
          label={params.value}
          size="small"
          color={
            params.value === 'lifetime' ? 'success' :
            params.value === 'premium' ? 'primary' : 'default'
          }
          variant="outlined"
        />
      ),
    },
    {
      field: 'isVerified',
      headerName: 'Verified',
      width: 100,
      renderCell: (params) => (
        <Chip
          icon={params.value ? <VerifiedIcon /> : <BlockIcon />}
          label={params.value ? 'Yes' : 'No'}
          size="small"
          color={params.value ? 'success' : 'default'}
        />
      ),
    },
    {
      field: 'isActive',
      headerName: 'Status',
      width: 100,
      renderCell: (params) => (
        <Chip
          label={params.value ? 'Active' : 'Inactive'}
          size="small"
          color={params.value ? 'success' : 'error'}
        />
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
        />
      ),
    },
    {
      field: 'lastLoginAt',
      headerName: 'Last Login',
      width: 150,
      valueGetter: (params) => {
        if (!params.value) return 'Never';
        try {
          return format(new Date(params.value), 'MMM dd, yyyy');
        } catch {
          return 'Invalid Date';
        }
      },
    },
    {
      field: 'createdAt',
      headerName: 'Joined',
      width: 150,
      valueGetter: (params) => {
        try {
          return format(new Date(params.value), 'MMM dd, yyyy');
        } catch {
          return 'Invalid Date';
        }
      },
    },
    {
      field: 'actions',
      headerName: 'Actions',
      width: 120,
      sortable: false,
      renderCell: (params) => (
        <Box display="flex" gap={0.5}>
          <Tooltip title="View Details">
            <IconButton
              size="small"
              onClick={() => navigate(`/admin/users/${params.row.id}`)}
            >
              <ViewIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title="Edit User">
            <IconButton
              size="small"
              onClick={() => navigate(`/admin/users/${params.row.id}/edit`)}
            >
              <EditIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Box>
      ),
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

    try {
      await bulkUpdateUsers({
        userIds: selectedUsers,
        action: bulkAction,
        value: bulkValue
      });

      // Refresh data
      queryClient.invalidateQueries({ queryKey: ['users'] });
      setSelectedUsers([]);
      setBulkActionDialog(false);
    } catch (error) {
      console.error('Bulk action failed:', error);
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

      {/* Statistics Cards */}
      <Grid container spacing={3} mb={3}>
        <Grid item xs={6} sm={6} md={3}>
          <Card>
            <CardContent sx={{ textAlign: 'center', py: 2 }}>
              <PeopleIcon sx={{ fontSize: 40, color: 'primary.main', mb: 1 }} />
              <Typography variant="h4" fontWeight="bold" color="primary">
                {userStats?.totalUsers || 0}
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
              <VerifiedIcon sx={{ fontSize: 40, color: 'success.main', mb: 1 }} />
              <Typography variant="h4" fontWeight="bold" color="success.main">
                {userStats?.activeUsers || 0}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Active Users
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={6} sm={6} md={3}>
          <Card>
            <CardContent sx={{ textAlign: 'center', py: 2 }}>
              <AdminIcon sx={{ fontSize: 40, color: 'warning.main', mb: 1 }} />
              <Typography variant="h4" fontWeight="bold" color="warning.main">
                {userStats?.adminUsers || 0}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Admin Users
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={6} sm={6} md={3}>
          <Card>
            <CardContent sx={{ textAlign: 'center', py: 2 }}>
              <TimelineIcon sx={{ fontSize: 40, color: 'info.main', mb: 1 }} />
              <Typography variant="h4" fontWeight="bold" color="info.main">
                {userStats?.newUsers || 0}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                New Users
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
      <Dialog open={bulkActionDialog} onClose={() => setBulkActionDialog(false)}>
        <DialogTitle>Bulk Update Users</DialogTitle>
        <DialogContent>
          <Box display="flex" flexDirection="column" gap={2} mt={1}>
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
          <Button onClick={() => setBulkActionDialog(false)}>Cancel</Button>
          <Button onClick={handleBulkAction} variant="contained">
            Apply
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default AllUsersPage;
