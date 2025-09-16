import React, { useState, useMemo, useEffect } from 'react';
import {
  Box,
  Typography,
  Button,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  CircularProgress,
  IconButton,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Alert,
  Snackbar,
  Card,
  CardContent,
  Grid,
  Avatar,
  Switch,
  FormControlLabel,
  Divider,
  Badge,
  Tabs,
  Tab
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Block as BlockIcon,
  CheckCircle as CheckIcon,
  Warning as WarningIcon,
  Download as DownloadIcon,
  FilterList as FilterIcon,
  Refresh as RefreshIcon,
  Search as SearchIcon,
  Person as PersonIcon,
  Group as GroupIcon,
  TrendingUp as TrendingIcon,
  Security as SecurityIcon
} from '@mui/icons-material';
import { DataGrid, GridColDef, GridActionsCellItem, GridToolbar } from '@mui/x-data-grid';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getUsers, updateUserStatus, getUserStats, bulkUpdateUsers, deleteUser, exportUsers } from '../../services/adminAPI';
import { useNavigate } from 'react-router-dom';
import { format } from 'date-fns';
import { useSelector } from 'react-redux';
import { RootState } from '../../store';

interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  displayName?: string;
  avatarUrl?: string;
  languagePreference: string;
  themePreference?: string;
  subscriptionPlan: string;
  subscriptionStatus?: string;
  subscriptionExpiresAt?: string;
  isVerified: boolean;
  isActive: boolean;
  isAdmin: boolean;
  lastLoginAt?: string;
  createdAt: string;
  updatedAt: string;
}

interface UserStats {
  totalUsers: number;
  activeUsers: number;
  verifiedUsers: number;
  adminUsers: number;
  newUsersToday: number;
  newUsersThisWeek: number;
  newUsersThisMonth: number;
}

const UsersPage: React.FC = () => {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const currentUser = useSelector((state: RootState) => state.auth.user);
  
     // Check if current user is admin
   const isAdmin = currentUser?.isAdmin;
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [planFilter, setPlanFilter] = useState<string>('all');
  const [selectedUsers, setSelectedUsers] = useState<string[]>([]);
  const [bulkAction, setBulkAction] = useState<string>('');
  const [showBulkDialog, setShowBulkDialog] = useState(false);
  const [showUserDialog, setShowUserDialog] = useState(false);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [activeTab, setActiveTab] = useState(0);

  // Fetch users with enhanced query
  const { data: usersData, isLoading, error } = useQuery({
    queryKey: ['users', { search: searchTerm, status: statusFilter, plan: planFilter }],
         queryFn: () => {
       return getUsers({ 
         search: searchTerm, 
         status: statusFilter === 'all' ? undefined : statusFilter,
         subscriptionPlan: planFilter === 'all' ? undefined : planFilter
       });
     },
     staleTime: 30000, // 30 seconds
     onError: (error) => {
       console.error('❌ Error fetching users:', error);
     }
  });

     // Fetch user statistics
   const { data: userStats } = useQuery({
     queryKey: ['userStats'],
     queryFn: () => getUserStats(),
     staleTime: 60000, // 1 minute
     onError: (error) => {
       console.error('❌ Error fetching user stats:', error);
     }
   });

  // Mutations
  const updateUserStatusMutation = useMutation({
    mutationFn: updateUserStatus,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      queryClient.invalidateQueries({ queryKey: ['userStats'] });
    },
  });

  const bulkUpdateUsersMutation = useMutation({
    mutationFn: bulkUpdateUsers,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      queryClient.invalidateQueries({ queryKey: ['userStats'] });
      setSelectedUsers([]);
      setShowBulkDialog(false);
    },
  });

  const deleteUserMutation = useMutation({
    mutationFn: deleteUser,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      queryClient.invalidateQueries({ queryKey: ['userStats'] });
    },
  });

     // Enhanced columns with responsive widths and mobile hiding
   const baseColumns: GridColDef[] = [
     {
       field: 'avatar',
       headerName: 'Avatar',
       width: 80,
       minWidth: 60,
       maxWidth: 100,
       hideable: false,
       renderCell: (params) => (
         <Avatar
           src={params.row.avatarUrl}
           alt={params.row.displayName || `${params.row.firstName} ${params.row.lastName}`}
           sx={{ width: 32, height: 32 }}
         >
           {params.row.firstName?.[0]}{params.row.lastName?.[0]}
         </Avatar>
       ),
     },
     {
       field: 'name',
       headerName: 'Name',
       width: 200,
       minWidth: 150,
       maxWidth: 300,
       flex: 1,
       hideable: false,
       valueGetter: (params) => 
         params.row.displayName || `${params.row.firstName} ${params.row.lastName}`,
     },
     {
       field: 'email',
       headerName: 'Email',
       width: 250,
       minWidth: 200,
       maxWidth: 350,
       flex: 1,
       hideable: false,
     },
     {
       field: 'subscription',
       headerName: 'Subscription',
       width: 150,
       minWidth: 120,
       maxWidth: 180,
       hideable: true,
       renderCell: (params) => (
         <Box>
           <Chip 
             label={params.row.subscriptionPlan} 
             color={params.row.subscriptionPlan === 'lifetime' ? 'success' : 'primary'}
             size="small"
           />
           <Typography variant="caption" display="block">
             {params.row.subscriptionStatus}
           </Typography>
         </Box>
       ),
     },
     {
       field: 'status',
       headerName: 'Status',
       width: 120,
       minWidth: 100,
       maxWidth: 150,
       hideable: true,
       renderCell: (params) => (
         <Box>
           <Chip 
             label={params.row.isActive ? 'Active' : 'Inactive'} 
             color={params.row.isActive ? 'success' : 'error'}
             size="small"
           />
           {params.row.isVerified && (
             <Chip 
               label="Verified" 
               color="info" 
               size="small" 
               sx={{ ml: 0.5 }}
             />
           )}
         </Box>
       ),
     },
     {
       field: 'language',
       headerName: 'Language',
       width: 100,
       minWidth: 80,
       maxWidth: 120,
       hideable: true,
       valueGetter: (params) => params.row.languagePreference,
     },
     {
       field: 'lastLogin',
       headerName: 'Last Login',
       width: 150,
       minWidth: 120,
       maxWidth: 180,
       hideable: true,
       valueGetter: (params) => {
         if (!params.row.lastLoginAt) return 'Never';
         try {
           return format(new Date(params.row.lastLoginAt), 'MMM dd, yyyy');
         } catch (error) {
           console.warn('Invalid lastLoginAt for user:', params.row.id, 'date:', params.row.lastLoginAt);
           return 'Invalid Date';
         }
       },
     },
     {
       field: 'createdAt',
       headerName: 'Joined',
       width: 150,
       minWidth: 120,
       maxWidth: 180,
       hideable: true,
       valueGetter: (params) => {
         if (!params.row.createdAt) return 'Unknown';
         try {
           return format(new Date(params.row.createdAt), 'MMM dd, yyyy');
         } catch (error) {
           console.warn('Invalid date for user:', params.row.id, 'date:', params.row.createdAt);
           return 'Invalid Date';
         }
       },
     },
     {
       field: 'actions',
       headerName: 'Actions',
       width: 200,
       minWidth: 150,
       maxWidth: 250,
       type: 'actions',
       hideable: false,
       getActions: (params) => [
         <GridActionsCellItem
           icon={<EditIcon />}
           label="Edit User"
           onClick={() => handleEditUser(params.row)}
         />,
         <GridActionsCellItem
           icon={params.row.isActive ? <BlockIcon /> : <CheckIcon />}
           label={params.row.isActive ? 'Deactivate' : 'Activate'}
           onClick={() => handleToggleUserStatus(params.row.id, !params.row.isActive)}
         />,
         <GridActionsCellItem
           icon={<DeleteIcon />}
           label="Delete User"
           onClick={() => handleDeleteUser(params.row.id)}
         />,
       ],
     },
   ];

   // Responsive columns based on screen size
   const [isMobile, setIsMobile] = useState(false);

   useEffect(() => {
     const checkMobile = () => {
       setIsMobile(window.innerWidth < 768);
     };

     checkMobile();
     window.addEventListener('resize', checkMobile);
     return () => window.removeEventListener('resize', checkMobile);
   }, []);

   const columns = useMemo(() => {
     if (isMobile) {
       // Show only essential columns on mobile
       return baseColumns.filter(col => 
         ['avatar', 'name', 'email', 'actions'].includes(col.field)
       );
     }
     return baseColumns;
   }, [isMobile]);

     // Enhanced user statistics cards
   const renderUserStats = () => (
     <Grid container spacing={2} sx={{ mb: 3 }}>
       <Grid item xs={6} sm={6} md={3}>
         <Card>
           <CardContent sx={{ p: { xs: 1.5, sm: 2 } }}>
             <Box display="flex" alignItems="center">
               <PersonIcon color="primary" sx={{ mr: 1, fontSize: { xs: 24, sm: 32, md: 40 } }} />
               <Box>
                 <Typography variant="h4" sx={{ fontSize: { xs: '1.5rem', sm: '2rem', md: '2.125rem' } }}>
                   {userStats?.totalUsers || 0}
                 </Typography>
                 <Typography variant="body2" color="textSecondary" sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
                   Total Users
                 </Typography>
               </Box>
             </Box>
           </CardContent>
         </Card>
       </Grid>
       <Grid item xs={6} sm={6} md={3}>
         <Card>
           <CardContent sx={{ p: { xs: 1.5, sm: 2 } }}>
             <Box display="flex" alignItems="center">
               <CheckIcon color="success" sx={{ mr: 1, fontSize: { xs: 24, sm: 32, md: 40 } }} />
               <Box>
                 <Typography variant="h4" sx={{ fontSize: { xs: '1.5rem', sm: '2rem', md: '2.125rem' } }}>
                   {userStats?.activeUsers || 0}
                 </Typography>
                 <Typography variant="body2" color="textSecondary" sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
                   Active Users
                 </Typography>
               </Box>
             </Box>
           </CardContent>
         </Card>
       </Grid>
       <Grid item xs={6} sm={6} md={3}>
         <Card>
           <CardContent sx={{ p: { xs: 1.5, sm: 2 } }}>
             <Box display="flex" alignItems="center">
               <SecurityIcon color="info" sx={{ mr: 1, fontSize: { xs: 24, sm: 32, md: 40 } }} />
               <Box>
                 <Typography variant="h4" sx={{ fontSize: { xs: '1.5rem', sm: '2rem', md: '2.125rem' } }}>
                   {userStats?.verifiedUsers || 0}
                 </Typography>
                 <Typography variant="body2" color="textSecondary" sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
                   Verified Users
                 </Typography>
               </Box>
             </Box>
           </CardContent>
         </Card>
       </Grid>
       <Grid item xs={6} sm={6} md={3}>
         <Card>
           <CardContent sx={{ p: { xs: 1.5, sm: 2 } }}>
             <Box display="flex" alignItems="center">
               <TrendingIcon color="warning" sx={{ mr: 1, fontSize: { xs: 24, sm: 32, md: 40 } }} />
               <Box>
                 <Typography variant="h4" sx={{ fontSize: { xs: '1.5rem', sm: '2rem', md: '2.125rem' } }}>
                   {userStats?.newUsersThisMonth || 0}
                 </Typography>
                 <Typography variant="body2" color="textSecondary" sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
                   New This Month
                 </Typography>
               </Box>
             </Box>
           </CardContent>
         </Card>
       </Grid>
     </Grid>
   );

  // Enhanced filters with mobile responsiveness
  const renderFilters = () => (
    <Card sx={{ mb: 3 }}>
      <CardContent>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} sm={6} md={4}>
            <TextField
              fullWidth
              placeholder="Search users..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              InputProps={{
                startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
              }}
              size="small"
            />
          </Grid>
          <Grid item xs={6} sm={6} md={2}>
            <FormControl fullWidth size="small">
              <InputLabel>Status</InputLabel>
              <Select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                label="Status"
              >
                <MenuItem value="all">All Status</MenuItem>
                <MenuItem value="active">Active</MenuItem>
                <MenuItem value="inactive">Inactive</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={6} sm={6} md={2}>
            <FormControl fullWidth size="small">
              <InputLabel>Plan</InputLabel>
              <Select
                value={planFilter}
                onChange={(e) => setPlanFilter(e.target.value)}
                label="Plan"
              >
                <MenuItem value="all">All Plans</MenuItem>
                <MenuItem value="free">Free</MenuItem>
                <MenuItem value="premium">Premium</MenuItem>
                <MenuItem value="lifetime">Lifetime</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} md={4}>
            <Box display="flex" gap={1} flexWrap="wrap">
              <Button
                variant="outlined"
                startIcon={<FilterIcon />}
                onClick={() => setShowBulkDialog(true)}
                disabled={selectedUsers.length === 0}
                size="small"
                sx={{ minWidth: 'fit-content' }}
              >
                Bulk ({selectedUsers.length})
              </Button>
              <Button
                variant="outlined"
                startIcon={<DownloadIcon />}
                onClick={() => handleExportUsers()}
                size="small"
                sx={{ minWidth: 'fit-content' }}
              >
                Export
              </Button>
              <Button
                variant="outlined"
                startIcon={<RefreshIcon />}
                onClick={() => queryClient.invalidateQueries({ queryKey: ['users'] })}
                size="small"
                sx={{ minWidth: 'fit-content' }}
              >
                Refresh
              </Button>
            </Box>
          </Grid>
        </Grid>
      </CardContent>
    </Card>
  );

  // Enhanced bulk actions dialog
  const renderBulkActionsDialog = () => (
    <Dialog open={showBulkDialog} onClose={() => setShowBulkDialog(false)} maxWidth="sm" fullWidth>
      <DialogTitle>Bulk Actions</DialogTitle>
      <DialogContent>
        <Typography variant="body2" sx={{ mb: 2 }}>
          Apply actions to {selectedUsers.length} selected users
        </Typography>
        <FormControl fullWidth sx={{ mb: 2 }}>
          <InputLabel>Action</InputLabel>
          <Select
            value={bulkAction}
            onChange={(e) => setBulkAction(e.target.value)}
            label="Action"
          >
            <MenuItem value="activate">Activate Users</MenuItem>
            <MenuItem value="deactivate">Deactivate Users</MenuItem>
            <MenuItem value="verify">Verify Users</MenuItem>
            <MenuItem value="unverify">Unverify Users</MenuItem>
            <MenuItem value="delete">Delete Users</MenuItem>
          </Select>
        </FormControl>
        {bulkAction === 'delete' && (
          <Alert severity="warning">
            This action cannot be undone. All selected users will be permanently deleted.
          </Alert>
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={() => setShowBulkDialog(false)}>Cancel</Button>
        <Button 
          variant="contained" 
          color={bulkAction === 'delete' ? 'error' : 'primary'}
          onClick={handleBulkAction}
          disabled={!bulkAction}
        >
          Apply Action
        </Button>
      </DialogActions>
    </Dialog>
  );

  // Enhanced user edit dialog
  const renderUserEditDialog = () => (
    <Dialog open={showUserDialog} onClose={() => setShowUserDialog(false)} maxWidth="md" fullWidth>
      <DialogTitle>Edit User: {selectedUser?.display_name || selectedUser?.email}</DialogTitle>
      <DialogContent>
        {selectedUser && (
          <Box sx={{ mt: 2 }}>
            <Tabs value={activeTab} onChange={(e, newValue) => setActiveTab(newValue)}>
              <Tab label="Profile" />
              <Tab label="Subscription" />
              <Tab label="Security" />
              <Tab label="Activity" />
            </Tabs>
            <Box sx={{ mt: 2 }}>
              {activeTab === 0 && (
                <Grid container spacing={2}>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="First Name"
                      defaultValue={selectedUser.first_name}
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="Last Name"
                      defaultValue={selectedUser.last_name}
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="Display Name"
                      defaultValue={selectedUser.display_name}
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="Email"
                      defaultValue={selectedUser.email}
                      disabled
                    />
                  </Grid>
                </Grid>
              )}
              {activeTab === 1 && (
                <Grid container spacing={2}>
                  <Grid item xs={12} sm={6}>
                    <FormControl fullWidth>
                      <InputLabel>Subscription Plan</InputLabel>
                      <Select defaultValue={selectedUser.subscription_plan} label="Subscription Plan">
                        <MenuItem value="free">Free</MenuItem>
                        <MenuItem value="premium">Premium</MenuItem>
                        <MenuItem value="lifetime">Lifetime</MenuItem>
                      </Select>
                    </FormControl>
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <FormControl fullWidth>
                      <InputLabel>Status</InputLabel>
                      <Select defaultValue={selectedUser.subscription_status} label="Status">
                        <MenuItem value="active">Active</MenuItem>
                        <MenuItem value="inactive">Inactive</MenuItem>
                        <MenuItem value="cancelled">Cancelled</MenuItem>
                      </Select>
                    </FormControl>
                  </Grid>
                </Grid>
              )}
              {activeTab === 2 && (
                <Grid container spacing={2}>
                  <Grid item xs={12}>
                    <FormControlLabel
                      control={
                        <Switch 
                          checked={selectedUser.is_active}
                          onChange={(e) => handleToggleUserStatus(selectedUser.id, e.target.checked)}
                        />
                      }
                      label="User Active"
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <FormControlLabel
                      control={
                        <Switch 
                          checked={selectedUser.is_verified}
                          onChange={(e) => handleToggleUserVerification(selectedUser.id, e.target.checked)}
                        />
                      }
                      label="Email Verified"
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <FormControlLabel
                      control={
                        <Switch 
                          checked={selectedUser.is_admin}
                          onChange={(e) => handleToggleAdminStatus(selectedUser.id, e.target.checked)}
                        />
                      }
                      label="Admin Access"
                    />
                  </Grid>
                </Grid>
              )}
              {activeTab === 3 && (
                <Box>
                  <Typography variant="body2" color="textSecondary">
                    Last Login: {selectedUser.last_login_at ? format(new Date(selectedUser.last_login_at), 'PPpp') : 'Never'}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Created: {format(new Date(selectedUser.created_at), 'PPpp')}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Updated: {format(new Date(selectedUser.updated_at), 'PPpp')}
                  </Typography>
                </Box>
              )}
            </Box>
          </Box>
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={() => setShowUserDialog(false)}>Cancel</Button>
        <Button variant="contained" onClick={() => handleSaveUser()}>
          Save Changes
        </Button>
      </DialogActions>
    </Dialog>
  );

  // Event handlers
  const handleEditUser = (user: User) => {
    setSelectedUser(user);
    setShowUserDialog(true);
    setActiveTab(0);
  };

  const handleToggleUserStatus = (userId: string, isActive: boolean) => {
    updateUserStatusMutation.mutate({ userId, isActive });
  };

  const handleToggleUserVerification = (userId: string, isVerified: boolean) => {
    updateUserStatusMutation.mutate({ userId, isVerified });
  };

  const handleToggleAdminStatus = (userId: string, isAdmin: boolean) => {
    updateUserStatusMutation.mutate({ userId, isAdmin });
  };

  const handleDeleteUser = (userId: string) => {
    if (window.confirm('Are you sure you want to delete this user? This action cannot be undone.')) {
      deleteUserMutation.mutate(userId);
    }
  };

  const handleBulkAction = () => {
    if (bulkAction && selectedUsers.length > 0) {
      bulkUpdateUsersMutation.mutate({
        userIds: selectedUsers,
        action: bulkAction,
      });
    }
  };

  const handleExportUsers = () => {
            exportUsers().then((blob) => {
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `teekoob-users-${format(new Date(), 'yyyy-MM-dd')}.csv`;
      a.click();
      window.URL.revokeObjectURL(url);
    });
  };

  const handleSaveUser = () => {
    // TODO: Implement user update
    setShowUserDialog(false);
  };

     // Check if user is admin
   if (!isAdmin) {
     return (
       <Alert severity="error" sx={{ m: 2 }}>
         Admin access required. Please log in with an admin account.
       </Alert>
     );
   }

  if (error) {
    return (
      <Alert severity="error" sx={{ m: 2 }}>
        Failed to load users: {error.message}
      </Alert>
    );
  }

  if (isLoading) {
    return (
      <Box sx={{ p: 3, display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '400px' }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ 
      p: { xs: 2, sm: 3 }, 
      height: '100vh', 
      overflow: 'auto',
      display: 'flex',
      flexDirection: 'column',
      boxSizing: 'border-box'
    }}>
      {/* Fixed Header Section */}
      <Box sx={{ flexShrink: 0 }}>
        <Box display="flex" justifyContent="space-between" alignItems="center" sx={{ mb: 3, flexWrap: 'wrap', gap: 2 }}>
          <Typography variant="h4" sx={{ fontSize: { xs: '1.5rem', sm: '2rem', md: '2.125rem' } }}>
            User Management
          </Typography>
          <Box display="flex" gap={1} flexWrap="wrap">
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
        {renderUserStats()}
        
        {/* Filters Section - Always Visible */}
        {renderFilters()}
      </Box>

      {/* Scrollable Data Section */}
      <Box sx={{ flexGrow: 1, minHeight: 0 }}>
        {!usersData?.users || usersData.users.length === 0 ? (
          <Card>
            <CardContent>
              <Box sx={{ textAlign: 'center', py: 4 }}>
                <Typography variant="h6" color="textSecondary" gutterBottom>
                  No users found
                </Typography>
                <Typography variant="body2" color="textSecondary" sx={{ mb: 3 }}>
                  {searchTerm || statusFilter !== 'all' || planFilter !== 'all' 
                    ? 'Try adjusting your filters or search terms.'
                    : 'There are no users in the system yet.'
                  }
                </Typography>
                {!searchTerm && statusFilter === 'all' && planFilter === 'all' && (
                  <Button
                    variant="contained"
                    color="primary"
                    onClick={() => navigate('/admin/users/new')}
                    startIcon={<AddIcon />}
                  >
                    Create First Admin User
                  </Button>
                )}
              </Box>
            </CardContent>
          </Card>
        ) : (
          <Card sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
            <Box sx={{ 
              height: '100%',
              minHeight: { xs: 300, sm: 400, md: 500, lg: 600 },
              width: '100%',
              display: 'flex',
              flexDirection: 'column'
            }}>
              <DataGrid
                rows={usersData.users}
                columns={columns}
                loading={isLoading}
                checkboxSelection
                onRowSelectionModelChange={(newSelection) => setSelectedUsers(newSelection as string[])}
                rowSelectionModel={selectedUsers}
                getRowId={(row) => row.id}
                pageSizeOptions={[5, 10, 25, 50]}
                initialState={{
                  pagination: {
                    paginationModel: { page: 0, pageSize: 10 },
                  },
                  columns: {
                    columnVisibilityModel: {
                      language: false,
                      lastLogin: false,
                      createdAt: false,
                    },
                  },
                }}
                slots={{ toolbar: GridToolbar }}
                slotProps={{
                  toolbar: {
                    showQuickFilter: false,
                    showColumnSelector: true,
                    showDensitySelector: true,
                  },
                }}
                onError={(error) => {
                  console.error('DataGrid error:', error);
                }}
                disableRowSelectionOnClick
                disableColumnMenu={false}
                disableColumnFilter={false}
                disableColumnSelector={false}
                disableDensitySelector={false}
                autoHeight={false}
                density="compact"
                sx={{
                  height: '100%',
                  width: '100%',
                  '& .MuiDataGrid-root': {
                    border: 'none',
                    height: '100%',
                  },
                  '& .MuiDataGrid-main': {
                    height: '100%',
                    overflow: 'hidden',
                  },
                  '& .MuiDataGrid-virtualScroller': {
                    height: '100% !important',
                    overflow: 'auto !important',
                  },
                  '& .MuiDataGrid-virtualScrollerContent': {
                    height: '100% !important',
                  },
                  '& .MuiDataGrid-footerContainer': {
                    borderTop: '1px solid #e0e0e0',
                    backgroundColor: '#fafafa',
                  },
                  '& .MuiDataGrid-columnHeaders': {
                    backgroundColor: '#f5f5f5',
                    borderBottom: '1px solid #e0e0e0',
                    position: 'sticky',
                    top: 0,
                    zIndex: 1,
                  },
                  '& .MuiDataGrid-cell': {
                    borderBottom: '1px solid #f0f0f0',
                  },
                  '& .MuiDataGrid-row:hover': {
                    backgroundColor: '#f8f9fa',
                  },
                  // Mobile responsive styles
                  '& .MuiDataGrid-columnHeader': {
                    '@media (max-width: 600px)': {
                      padding: '8px 4px',
                    },
                  },
                  '& .MuiDataGrid-cell': {
                    '@media (max-width: 600px)': {
                      padding: '8px 4px',
                    },
                  },
                  '& .MuiDataGrid-toolbarContainer': {
                    '@media (max-width: 600px)': {
                      flexDirection: 'column',
                      alignItems: 'stretch',
                      gap: 1,
                    },
                  },
                }}
              />
            </Box>
          </Card>
        )}
      </Box>

      {renderBulkActionsDialog()}
      {renderUserEditDialog()}

      <Snackbar
        open={updateUserStatusMutation.isSuccess || bulkUpdateUsersMutation.isSuccess}
        autoHideDuration={6000}
        onClose={() => {}}
      >
        <Alert severity="success">
          User(s) updated successfully!
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default UsersPage;
