# Book Notification System

This document describes the implementation of a comprehensive notification system for the Teekoob mobile app that allows users to set reminders for books with detailed information including book name, author, and category.

## Features

### 📚 Book Reminders
- **Scheduled Reminders**: Set specific date and time for book reading reminders
- **Daily Reading Reminders**: Set recurring daily reminders at preferred times
- **Instant Reminders**: Send immediate notifications for book reminders
- **Progress Reminders**: Get reminded to check reading progress at intervals

### 🔔 Notification Types
- **Book Reminders**: Personalized notifications with book title, author, and category
- **New Book Notifications**: Alerts for new book releases
- **Reading Progress**: Periodic reminders to check reading progress
- **Daily Reading**: Recurring daily reading time reminders

### ⚙️ Settings & Management
- **Permission Management**: Request and check notification permissions
- **Scheduled Notifications**: View and manage all scheduled reminders
- **Quick Actions**: Easy access to common notification functions
- **Settings Integration**: Dedicated notification settings page

## Implementation Details

### Core Components

#### 1. NotificationService (`lib/core/services/notification_service.dart`)
The main service handling all notification operations:

```dart
// Initialize the service
await NotificationService().initialize();

// Schedule a book reminder
await NotificationService().scheduleBookReminder(
  book: book,
  scheduledTime: DateTime.now().add(Duration(hours: 2)),
  customMessage: "Don't forget to read this amazing book!",
);

// Schedule daily reading reminder
await NotificationService().scheduleDailyReadingReminder(
  book: book,
  time: TimeOfDay(hour: 19, minute: 0), // 7 PM
);
```

#### 2. NotificationBloc (`lib/core/bloc/notification_bloc.dart`)
State management for notification operations:

```dart
// Schedule a reminder
context.read<NotificationBloc>().add(
  ScheduleBookReminder(
    book: book,
    scheduledTime: scheduledDateTime,
    customMessage: customMessage,
  ),
);

// Request permissions
context.read<NotificationBloc>().add(
  const RequestNotificationPermissions(),
);
```

#### 3. BookReminderWidget (`lib/core/presentation/widgets/book_reminder_widget.dart`)
UI component for setting book reminders:

- Date and time picker
- Custom message input
- Quick action buttons
- Daily reading setup
- Progress reminder options

#### 4. NotificationSettingsPage (`lib/features/settings/presentation/pages/notification_settings_page.dart`)
Comprehensive settings management:

- Permission status display
- Notification preferences
- Pending notifications list
- Quick actions and test notifications

### Notification Content

Each notification includes:
- **Title**: "📚 Book Reminder" or "📖 Daily Reading Time"
- **Body**: Book title, author, and category information
- **Payload**: Book ID for navigation handling
- **Custom Message**: User-defined reminder text (optional)

Example notification:
```
📚 Book Reminder
Time to read "The Great Adventure" by John Smith
Category: Fiction, Adventure
```

### Platform Support

#### Android
- Requires `POST_NOTIFICATIONS` permission (Android 13+)
- Uses notification channels for organization
- Supports notification categories
- Large icon support for book covers

#### iOS
- Requests alert, badge, and sound permissions
- Supports notification categories
- Handles notification responses

### Integration Points

#### 1. Book Detail Page
The `BookReminderWidget` is integrated into the book detail page, allowing users to:
- Set reminders while viewing book details
- Access quick actions for common reminder types
- View book information in the reminder interface

#### 2. Settings Page
The notification settings are accessible through:
- Main settings page → "Manage notification settings"
- Direct navigation to `NotificationSettingsPage`
- Integration with existing settings structure

#### 3. App Initialization
The notification service is initialized in `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Localization
  await LocalizationService.initialize();
  
  // Initialize Notification Service
  await NotificationService().initialize();
  
  runApp(TeekoobApp());
}
```

## Usage Examples

### Setting a Book Reminder
```dart
// In BookDetailPage or any book-related screen
BookReminderWidget(book: selectedBook)
```

### Programmatic Reminder Scheduling
```dart
// Schedule a reminder for tomorrow at 7 PM
final tomorrow = DateTime.now().add(Duration(days: 1));
final scheduledTime = DateTime(
  tomorrow.year,
  tomorrow.month,
  tomorrow.day,
  19, // 7 PM
  0,
);

context.read<NotificationBloc>().add(
  ScheduleBookReminder(
    book: book,
    scheduledTime: scheduledTime,
    customMessage: "Your daily reading time!",
  ),
);
```

### Daily Reading Reminder
```dart
// Set daily reminder at 8 PM
context.read<NotificationBloc>().add(
  ScheduleDailyReadingReminder(
    book: book,
    time: TimeOfDay(hour: 20, minute: 0),
  ),
);
```

### Progress Reminder
```dart
// Remind every 3 days to check progress
context.read<NotificationBloc>().add(
  ScheduleReadingProgressReminder(
    book: book,
    interval: Duration(days: 3),
  ),
);
```

## Dependencies

The notification system uses these Flutter packages:

```yaml
dependencies:
  flutter_local_notifications: ^16.3.2
  timezone: ^0.9.2
  permission_handler: ^11.0.1  # Already included
```

## Permissions

### Android Permissions (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### iOS Permissions
Automatically requested through the Flutter Local Notifications plugin.

## Testing

### Test Notifications
Use the "Test Notification" button in the Notification Settings page to verify:
- Permission status
- Notification display
- Sound and vibration
- Notification handling

### Debug Information
The service includes comprehensive logging:
```dart
debugPrint('🔔 NotificationService: Scheduled reminder for "${book.displayTitle}"');
debugPrint('🔔 NotificationService: Permission status: $hasPermission');
```

## Future Enhancements

### Planned Features
1. **Smart Reminders**: AI-powered optimal reminder timing
2. **Reading Streaks**: Gamification with streak notifications
3. **Social Notifications**: Reminders from friends about shared books
4. **Location-based**: Reminders based on reading locations
5. **Voice Reminders**: Audio notifications with book information

### Integration Opportunities
1. **Reading Analytics**: Connect with reading progress tracking
2. **Social Features**: Share reminders with reading groups
3. **Offline Support**: Queue notifications when offline
4. **Custom Sounds**: Book-specific notification sounds

## Troubleshooting

### Common Issues

#### Notifications Not Appearing
1. Check permission status in Notification Settings
2. Verify device notification settings
3. Ensure app is not in battery optimization mode
4. Check notification channels are enabled

#### Permission Denied
1. Guide user to device settings
2. Provide clear instructions for enabling notifications
3. Show permission status in the app

#### Scheduled Notifications Not Working
1. Verify timezone settings
2. Check device time and date
3. Ensure app is not force-closed
4. Test with immediate notifications first

## Conclusion

The notification system provides a comprehensive solution for book reminders with:
- ✅ Rich notification content (title, author, category)
- ✅ Multiple reminder types (scheduled, daily, progress)
- ✅ User-friendly interface
- ✅ Proper permission handling
- ✅ Cross-platform support
- ✅ Integration with existing app architecture

Users can now easily set reminders for their favorite books and never miss their reading time!
