import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teekoob/core/bloc/notification_bloc.dart';
import 'package:teekoob/core/services/firebase_notification_service.dart';
import 'package:teekoob/core/services/localization_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _randomBookNotificationsEnabled = true;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  final FirebaseNotificationService _notificationService = FirebaseNotificationService();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _hasError = false;
        });
      }

      // Initialize notifications and load pending notifications
      context.read<NotificationBloc>().add(const InitializeNotifications());
      context.read<NotificationBloc>().add(const LoadPendingNotifications());
      await _loadRandomBookNotificationStatus();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadRandomBookNotificationStatus() async {
    // Check if random book notifications are currently enabled
    // This would typically be stored in user preferences
    if (mounted) {
      setState(() {
        _randomBookNotificationsEnabled = true; // Default to enabled
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: const Color(0xFF0466c8),
        foregroundColor: Colors.white,
        actions: [
          if (_hasError)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _initializeNotifications,
              tooltip: 'Retry',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading notification settings...'),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load notification settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeNotifications,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return BlocConsumer<NotificationBloc, NotificationState>(
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
            
            // Random Book Notifications
            SwitchListTile(
              title: Text(LocalizationService.getLocalizedText(
                englishText: 'Random Book Notifications',
                somaliText: 'Ogeysiisyo Buugag Kala Duwan',
              )),
              subtitle: Text(LocalizationService.getLocalizedText(
                englishText: 'Get random book recommendations every 10 minutes',
                somaliText: 'Hel talooyin buugag kala duwan 10 daqiiqo kasta',
              )),
              value: _randomBookNotificationsEnabled,
              onChanged: (value) async {
                if (mounted) {
                  setState(() {
                    _randomBookNotificationsEnabled = value;
                  });
                }
                
                try {
                  if (value) {
                    await _notificationService.enableRandomBookNotifications();
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(LocalizationService.getLocalizedText(
                            englishText: 'Random book notifications enabled!',
                            somaliText: 'Ogeysiisyooyinka buugag kala duwan ayaa la furay!',
                          )),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    await _notificationService.disableRandomBookNotifications();
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(LocalizationService.getLocalizedText(
                            englishText: 'Random book notifications disabled',
                            somaliText: 'Ogeysiisyooyinka buugag kala duwan ayaa la xidhay',
                          )),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  // Revert the switch state
                  if (mounted) {
                    setState(() {
                      _randomBookNotificationsEnabled = !value;
                    });
                  }
                }
              },
            ),
            
            // Test Random Book Notification
            ListTile(
              leading: const Icon(Icons.notifications_active),
              title: Text(LocalizationService.getLocalizedText(
                englishText: 'Test Random Book Notification',
                somaliText: 'Tijaabi Ogeysiiska Buug Kala Duwan',
              )),
              subtitle: Text(LocalizationService.getLocalizedText(
                englishText: 'Send a test notification with a random book',
                somaliText: 'Dir ogeysiis tijaabadeed oo buug kala duwan ah',
              )),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                try {
                  await _notificationService.sendTestNotification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(LocalizationService.getLocalizedText(
                        englishText: 'Test notification sent!',
                        somaliText: 'Ogeysiiska tijaabadeed ayaa la diray!',
                      )),
                      backgroundColor: Colors.blue,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error sending test notification: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            
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
