import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teekoob/core/bloc/notification_bloc.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications and load pending notifications
    context.read<NotificationBloc>().add(const InitializeNotifications());
    context.read<NotificationBloc>().add(const LoadPendingNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: const Color(0xFF0466c8),
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state is NotificationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is NotificationPermissionGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notification permissions granted!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is NotificationPermissionDenied) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notification permissions denied. Please enable in device settings.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Permission Status Card
                _buildPermissionStatusCard(state),
                
                const SizedBox(height: 24),
                
                // Notification Settings
                _buildNotificationSettingsCard(),
                
                const SizedBox(height: 24),
                
                // Pending Notifications
                _buildPendingNotificationsCard(state),
                
                const SizedBox(height: 24),
                
                // Quick Actions
                _buildQuickActionsCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermissionStatusCard(NotificationState state) {
    bool hasPermission = false;
    if (state is NotificationInitialized) {
      hasPermission = state.hasPermission;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasPermission ? Icons.check_circle : Icons.warning,
                  color: hasPermission ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Notification Permission',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasPermission 
                  ? 'Notifications are enabled. You can receive book reminders.'
                  : 'Notifications are disabled. Enable to receive book reminders.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            if (!hasPermission)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<NotificationBloc>().add(
                      const RequestNotificationPermissions(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0466c8),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Enable Notifications'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Daily Reading Reminders
            SwitchListTile(
              title: const Text('Daily Reading Reminders'),
              subtitle: const Text('Get reminded to read at your preferred time'),
              value: true, // This would be managed by user preferences
              onChanged: (value) {
                // TODO: Implement user preference storage
              },
            ),
            
            // New Book Notifications
            SwitchListTile(
              title: const Text('New Book Notifications'),
              subtitle: const Text('Get notified about new book releases'),
              value: true, // This would be managed by user preferences
              onChanged: (value) {
                // TODO: Implement user preference storage
              },
            ),
            
            // Progress Reminders
            SwitchListTile(
              title: const Text('Reading Progress Reminders'),
              subtitle: const Text('Get reminded to check your reading progress'),
              value: false, // This would be managed by user preferences
              onChanged: (value) {
                // TODO: Implement user preference storage
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingNotificationsCard(NotificationState state) {
    List<dynamic> pendingNotifications = [];
    
    if (state is PendingNotificationsLoaded) {
      pendingNotifications = state.notifications;
    } else if (state is NotificationInitialized) {
      pendingNotifications = state.pendingNotifications;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Scheduled Reminders',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    context.read<NotificationBloc>().add(
                      const LoadPendingNotifications(),
                    );
                  },
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (pendingNotifications.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No scheduled reminders',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              ...pendingNotifications.map((notification) => ListTile(
                leading: const Icon(Icons.notifications_active),
                title: Text(notification.title ?? 'Book Reminder'),
                subtitle: Text(notification.body ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: () {
                    context.read<NotificationBloc>().add(
                      CancelNotification(notification.id),
                    );
                  },
                ),
              )),
              
            if (pendingNotifications.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear All Reminders'),
                          content: const Text(
                            'Are you sure you want to cancel all scheduled reminders?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                context.read<NotificationBloc>().add(
                                  const CancelAllNotifications(),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Clear All'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Clear All Reminders'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Notification History (placeholder)
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Notification History'),
              subtitle: const Text('View past notifications'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification history coming soon!'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
