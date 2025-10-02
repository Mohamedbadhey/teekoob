import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/bloc/notification_bloc.dart';
import 'package:teekoob/core/services/notification_service_interface.dart';

class BookReminderWidget extends StatefulWidget {
  final Book book;

  const BookReminderWidget({
    Key? key,
    required this.book,
  }) : super(key: key);

  @override
  State<BookReminderWidget> createState() => _BookReminderWidgetState();
}

class _BookReminderWidgetState extends State<BookReminderWidget> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _customMessage;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state is BookReminderScheduled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reminder scheduled for "${state.book.displayTitle}"'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is NotificationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is NotificationPermissionDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Notification permission denied. Please enable in settings.'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () {
                  // Open app settings
                },
              ),
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
                      'Set Book Reminder',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Book info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.book.displayTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (widget.book.displayAuthors.isNotEmpty)
                        Text(
                          'by ${widget.book.displayAuthors}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      if (widget.book.displayCategories.isNotEmpty)
                        Text(
                          'Category: ${widget.book.displayCategories}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Date picker
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(_selectedDate == null 
                      ? 'Select Date' 
                      : 'Date: ${_formatDate(_selectedDate!)}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _selectDate,
                ),
                
                // Time picker
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(_selectedTime == null 
                      ? 'Select Time' 
                      : 'Time: ${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _selectTime,
                ),
                
                // Custom message
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Custom Message (Optional)',
                    hintText: 'Add a personal message to your reminder...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onChanged: (value) {
                    setState(() {
                      _customMessage = value.isEmpty ? null : value;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _canScheduleReminder() && state is! NotificationLoading
                            ? _scheduleReminder
                            : null,
                        icon: const Icon(Icons.schedule),
                        label: const Text('Schedule Reminder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: state is! NotificationLoading
                            ? _showInstantReminder
                            : null,
                        icon: const Icon(Icons.notifications),
                        label: const Text('Remind Now'),
                      ),
                    ),
                  ],
                ),
                
                // Quick actions
                const SizedBox(height: 16),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Daily Reading'),
                      onPressed: state is! NotificationLoading
                          ? _scheduleDailyReminder
                          : null,
                      avatar: const Icon(Icons.repeat, size: 16),
                    ),
                    ActionChip(
                      label: const Text('Progress Check'),
                      onPressed: state is! NotificationLoading
                          ? _scheduleProgressReminder
                          : null,
                      avatar: const Icon(Icons.trending_up, size: 16),
                    ),
                  ],
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

  bool _canScheduleReminder() {
    return _selectedDate != null && _selectedTime != null;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _scheduleReminder() {
    if (_selectedDate == null || _selectedTime == null) return;
    
    final DateTime scheduledDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    
    context.read<NotificationBloc>().add(
      ScheduleBookReminder(
        book: widget.book,
        scheduledTime: scheduledDateTime,
        customMessage: _customMessage,
      ),
    );
  }

  void _showInstantReminder() {
    context.read<NotificationBloc>().add(
      ShowInstantBookReminder(
        book: widget.book,
        customMessage: _customMessage,
      ),
    );
  }

  void _scheduleDailyReminder() {
    final TimeOfDay defaultTime = TimeOfDay(hour: 19, minute: 0); // 7 PM
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Daily Reading Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Set a daily reminder to read "${widget.book.displayTitle}"'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text('Time: ${defaultTime.hour.toString().padLeft(2, '0')}:${defaultTime.minute.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: defaultTime,
                );
                if (picked != null) {
                  Navigator.pop(context);
                  context.read<NotificationBloc>().add(
                    ScheduleDailyReadingReminder(
                      book: widget.book,
                      time: picked,
                    ),
                  );
                }
              },
            ),
          ],
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
                ScheduleDailyReadingReminder(
                  book: widget.book,
                  time: defaultTime,
                ),
              );
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  void _scheduleProgressReminder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Progress Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Get reminded to check your progress with "${widget.book.displayTitle}"'),
            const SizedBox(height: 16),
            const Text('How often would you like to be reminded?'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Daily'),
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<NotificationBloc>().add(
                      ScheduleReadingProgressReminder(
                        book: widget.book,
                        interval: const Duration(days: 1),
                      ),
                    );
                  },
                ),
                ActionChip(
                  label: const Text('Weekly'),
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<NotificationBloc>().add(
                      ScheduleReadingProgressReminder(
                        book: widget.book,
                        interval: const Duration(days: 7),
                      ),
                    );
                  },
                ),
                ActionChip(
                  label: const Text('Bi-weekly'),
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<NotificationBloc>().add(
                      ScheduleReadingProgressReminder(
                        book: widget.book,
                        interval: const Duration(days: 14),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
