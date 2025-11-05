import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  TextField,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
  Chip,
  CircularProgress,
  Grid,
  Divider,
  Checkbox,
  FormControlLabel,
  Autocomplete,
} from '@mui/material';
import {
  Send as SendIcon,
  People as PeopleIcon,
  Message as MessageIcon,
} from '@mui/icons-material';
import { useMutation, useQuery } from '@tanstack/react-query';
import { sendMessage, sendBroadcastMessage, getUsers } from '../../services/adminAPI';
import { useDispatch } from 'react-redux';
import { addNotification } from '../../store/slices/uiSlice';

interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  displayName?: string;
}

const SendMessagePage: React.FC = () => {
  const dispatch = useDispatch();
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [actionUrl, setActionUrl] = useState('');
  const [selectedUsers, setSelectedUsers] = useState<string[]>([]);
  const [sendToAll, setSendToAll] = useState(false);
  const [userSearch, setUserSearch] = useState('');

  // Fetch users for selection
  const { data: usersData, isLoading: isLoadingUsers } = useQuery({
    queryKey: ['users', userSearch],
    queryFn: () => getUsers({ search: userSearch, limit: 100 }),
    enabled: !sendToAll,
  });

  const users: User[] = usersData?.users || [];

  // Send message mutation
  const sendMessageMutation = useMutation({
    mutationFn: (data: any) => {
      if (sendToAll) {
        return sendBroadcastMessage({
          title: data.title,
          message: data.message,
          actionUrl: data.actionUrl || undefined,
        });
      } else {
        return sendMessage({
          userIds: data.userIds,
          title: data.title,
          message: data.message,
          actionUrl: data.actionUrl || undefined,
        });
      }
    },
    onSuccess: (data) => {
      dispatch(addNotification({
        type: 'success',
        message: `Message sent successfully to ${data.notificationsCreated || 0} user(s)`,
      }));
      // Reset form
      setTitle('');
      setMessage('');
      setActionUrl('');
      setSelectedUsers([]);
      setSendToAll(false);
    },
    onError: (error: any) => {
      dispatch(addNotification({
        type: 'error',
        message: error.response?.data?.error || 'Failed to send message',
      }));
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!title.trim() || !message.trim()) {
      dispatch(addNotification({
        type: 'error',
        message: 'Title and message are required',
      }));
      return;
    }

    if (!sendToAll && selectedUsers.length === 0) {
      dispatch(addNotification({
        type: 'error',
        message: 'Please select at least one user or choose "Send to All Users"',
      }));
      return;
    }

    sendMessageMutation.mutate({
      userIds: selectedUsers,
      title: title.trim(),
      message: message.trim(),
      actionUrl: actionUrl.trim() || undefined,
    });
  };

  const handleUserSelect = (userIds: string[]) => {
    setSelectedUsers(userIds);
  };

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom sx={{ mb: 3, display: 'flex', alignItems: 'center', gap: 1 }}>
        <MessageIcon /> Send Message to Users
      </Typography>

      <Card>
        <CardContent>
          <form onSubmit={handleSubmit}>
            <Grid container spacing={3}>
              {/* Send to All Toggle */}
              <Grid item xs={12}>
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={sendToAll}
                      onChange={(e) => setSendToAll(e.target.checked)}
                    />
                  }
                  label={
                    <Box>
                      <Typography variant="body1" fontWeight="bold">
                        Send to All Users
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        This will send the message to all registered users
                      </Typography>
                    </Box>
                  }
                />
              </Grid>

              <Grid item xs={12}>
                <Divider />
              </Grid>

              {/* User Selection (only if not sending to all) */}
              {!sendToAll && (
                <Grid item xs={12}>
                  <FormControl fullWidth>
                    <Autocomplete
                      multiple
                      options={users}
                      getOptionLabel={(option) => 
                        `${option.firstName} ${option.lastName} (${option.email})`
                      }
                      value={users.filter(u => selectedUsers.includes(u.id))}
                      onChange={(_, newValue) => {
                        handleUserSelect(newValue.map(u => u.id));
                      }}
                      loading={isLoadingUsers}
                      onInputChange={(_, newInputValue) => {
                        setUserSearch(newInputValue);
                      }}
                      renderInput={(params) => (
                        <TextField
                          {...params}
                          label="Select Users"
                          placeholder="Search and select users..."
                          InputProps={{
                            ...params.InputProps,
                            endAdornment: (
                              <>
                                {isLoadingUsers ? <CircularProgress size={20} /> : null}
                                {params.InputProps.endAdornment}
                              </>
                            ),
                          }}
                        />
                      )}
                      renderTags={(value, getTagProps) =>
                        value.map((option, index) => (
                          <Chip
                            {...getTagProps({ index })}
                            key={option.id}
                            label={`${option.firstName} ${option.lastName}`}
                            size="small"
                          />
                        ))
                      }
                    />
                  </FormControl>
                  {selectedUsers.length > 0 && (
                    <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                      {selectedUsers.length} user(s) selected
                    </Typography>
                  )}
                </Grid>
              )}

              {/* Title */}
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Message Title"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  required
                  helperText={`${title.length}/255 characters`}
                  inputProps={{ maxLength: 255 }}
                />
              </Grid>

              {/* Message */}
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Message Content"
                  value={message}
                  onChange={(e) => setMessage(e.target.value)}
                  required
                  multiline
                  rows={6}
                  helperText={`${message.length}/5000 characters`}
                  inputProps={{ maxLength: 5000 }}
                />
              </Grid>

              {/* Action URL (Optional) */}
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Action URL (Optional)"
                  value={actionUrl}
                  onChange={(e) => setActionUrl(e.target.value)}
                  placeholder="https://example.com"
                  helperText="Optional URL to navigate when user taps the notification"
                />
              </Grid>

              {/* Submit Button */}
              <Grid item xs={12}>
                <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 2 }}>
                  <Button
                    variant="outlined"
                    onClick={() => {
                      setTitle('');
                      setMessage('');
                      setActionUrl('');
                      setSelectedUsers([]);
                      setSendToAll(false);
                    }}
                  >
                    Clear
                  </Button>
                  <Button
                    type="submit"
                    variant="contained"
                    color="primary"
                    startIcon={
                      sendMessageMutation.isPending ? (
                        <CircularProgress size={20} color="inherit" />
                      ) : (
                        <SendIcon />
                      )
                    }
                    disabled={sendMessageMutation.isPending}
                  >
                    {sendToAll ? 'Send to All Users' : `Send to ${selectedUsers.length} User(s)`}
                  </Button>
                </Box>
              </Grid>
            </Grid>
          </form>
        </CardContent>
      </Card>

      {/* Info Card */}
      <Card sx={{ mt: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            <PeopleIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
            About Messages
          </Typography>
          <Typography variant="body2" color="text.secondary" paragraph>
            • Messages sent here will appear in the user's notification center in the mobile app
          </Typography>
          <Typography variant="body2" color="text.secondary" paragraph>
            • Users can view, mark as read, and delete notifications
          </Typography>
          <Typography variant="body2" color="text.secondary" paragraph>
            • Broadcast messages are sent to all registered users
          </Typography>
          <Typography variant="body2" color="text.secondary">
            • Action URLs allow users to navigate to a specific page when they tap the notification
          </Typography>
        </CardContent>
      </Card>
    </Box>
  );
};

export default SendMessagePage;

