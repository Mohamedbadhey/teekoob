import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teekoob/core/bloc/notification_bloc.dart';
import 'package:teekoob/core/models/book_model.dart';

/// Widget to demonstrate and test system notifications
class NotificationDemoWidget extends StatelessWidget {
  final Book? sampleBook;

  const NotificationDemoWidget({
    Key? key,
    this.sampleBook,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state is TestNotificationShown) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Test notification sent! Check your phone\'s notification panel.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else if (state is BookReminderScheduled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📚 Reminder scheduled for "${state.book.displayTitle}"!'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is NotificationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: ${state.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      builder: (context, state) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'System Notifications Demo',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Text(
                  'These notifications will appear in your phone\'s notification panel (system tray) just like other app notifications.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Test notification button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: state is! NotificationLoading
                        ? () {
                            context.read<NotificationBloc>().add(
                              const ShowTestNotification(),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.notifications),
                    label: const Text('Send Test Notification'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Sample book reminder button
                if (sampleBook != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: state is! NotificationLoading
                          ? () {
                              final scheduledTime = DateTime.now().add(
                                const Duration(minutes: 1),
                              );
                              
                              context.read<NotificationBloc>().add(
                                ScheduleBookReminder(
                                  book: sampleBook!,
                                  scheduledTime: scheduledTime,
                                  customMessage: 'Demo reminder for testing!',
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.schedule),
                      label: Text('Schedule "${sampleBook!.displayTitle}" Reminder'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'This will schedule a reminder for 1 minute from now',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Information about system notifications
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'System Notifications',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Appear in phone\'s notification panel\n'
                        '• Show on lock screen\n'
                        '• Play sound and vibrate\n'
                        '• Include book title, author, and category\n'
                        '• Can be tapped to open the app',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Loading indicator
                if (state is NotificationLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
