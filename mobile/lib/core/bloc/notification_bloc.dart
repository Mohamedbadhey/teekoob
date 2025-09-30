import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/services/notification_service.dart';

// Events
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class InitializeNotifications extends NotificationEvent {
  const InitializeNotifications();
}

class RequestNotificationPermissions extends NotificationEvent {
  const RequestNotificationPermissions();
}

class ScheduleBookReminder extends NotificationEvent {
  final Book book;
  final DateTime scheduledTime;
  final String? customMessage;

  const ScheduleBookReminder({
    required this.book,
    required this.scheduledTime,
    this.customMessage,
  });

  @override
  List<Object?> get props => [book, scheduledTime, customMessage];
}

class ScheduleDailyReadingReminder extends NotificationEvent {
  final Book book;
  final TimeOfDay time;

  const ScheduleDailyReadingReminder({
    required this.book,
    required this.time,
  });

  @override
  List<Object?> get props => [book, time];
}

class ScheduleNewBookNotification extends NotificationEvent {
  final Book book;
  final DateTime releaseTime;

  const ScheduleNewBookNotification({
    required this.book,
    required this.releaseTime,
  });

  @override
  List<Object?> get props => [book, releaseTime];
}

class ShowInstantBookReminder extends NotificationEvent {
  final Book book;
  final String? customMessage;

  const ShowInstantBookReminder({
    required this.book,
    this.customMessage,
  });

  @override
  List<Object?> get props => [book, customMessage];
}

class ScheduleReadingProgressReminder extends NotificationEvent {
  final Book book;
  final Duration interval;

  const ScheduleReadingProgressReminder({
    required this.book,
    required this.interval,
  });

  @override
  List<Object?> get props => [book, interval];
}

class CancelNotification extends NotificationEvent {
  final int notificationId;

  const CancelNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class CancelAllNotifications extends NotificationEvent {
  const CancelAllNotifications();
}

class LoadPendingNotifications extends NotificationEvent {
  const LoadPendingNotifications();
}

// States
abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationInitialized extends NotificationState {
  final bool hasPermission;
  final List<PendingNotificationRequest> pendingNotifications;

  const NotificationInitialized({
    required this.hasPermission,
    required this.pendingNotifications,
  });

  @override
  List<Object?> get props => [hasPermission, pendingNotifications];
}

class NotificationPermissionGranted extends NotificationState {
  const NotificationPermissionGranted();
}

class NotificationPermissionDenied extends NotificationState {
  const NotificationPermissionDenied();
}

class BookReminderScheduled extends NotificationState {
  final Book book;
  final DateTime scheduledTime;

  const BookReminderScheduled({
    required this.book,
    required this.scheduledTime,
  });

  @override
  List<Object?> get props => [book, scheduledTime];
}

class DailyReadingReminderScheduled extends NotificationState {
  final Book book;
  final TimeOfDay time;

  const DailyReadingReminderScheduled({
    required this.book,
    required this.time,
  });

  @override
  List<Object?> get props => [book, time];
}

class NewBookNotificationScheduled extends NotificationState {
  final Book book;
  final DateTime releaseTime;

  const NewBookNotificationScheduled({
    required this.book,
    required this.releaseTime,
  });

  @override
  List<Object?> get props => [book, releaseTime];
}

class InstantReminderShown extends NotificationState {
  final Book book;

  const InstantReminderShown(this.book);

  @override
  List<Object?> get props => [book];
}

class ReadingProgressReminderScheduled extends NotificationState {
  final Book book;
  final Duration interval;

  const ReadingProgressReminderScheduled({
    required this.book,
    required this.interval,
  });

  @override
  List<Object?> get props => [book, interval];
}

class NotificationCancelled extends NotificationState {
  final int notificationId;

  const NotificationCancelled(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class AllNotificationsCancelled extends NotificationState {
  const AllNotificationsCancelled();
}

class PendingNotificationsLoaded extends NotificationState {
  final List<PendingNotificationRequest> notifications;

  const PendingNotificationsLoaded(this.notifications);

  @override
  List<Object?> get props => [notifications];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationService _notificationService;

  NotificationBloc({required NotificationService notificationService})
      : _notificationService = notificationService,
        super(const NotificationInitial()) {
    
    on<InitializeNotifications>(_onInitializeNotifications);
    on<RequestNotificationPermissions>(_onRequestNotificationPermissions);
    on<ScheduleBookReminder>(_onScheduleBookReminder);
    on<ScheduleDailyReadingReminder>(_onScheduleDailyReadingReminder);
    on<ScheduleNewBookNotification>(_onScheduleNewBookNotification);
    on<ShowInstantBookReminder>(_onShowInstantBookReminder);
    on<ScheduleReadingProgressReminder>(_onScheduleReadingProgressReminder);
    on<CancelNotification>(_onCancelNotification);
    on<CancelAllNotifications>(_onCancelAllNotifications);
    on<LoadPendingNotifications>(_onLoadPendingNotifications);
  }

  Future<void> _onInitializeNotifications(
    InitializeNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(const NotificationLoading());
      
      await _notificationService.initialize();
      final bool hasPermission = await _notificationService.areNotificationsEnabled();
      final List<PendingNotificationRequest> pendingNotifications = 
          await _notificationService.getPendingNotifications();
      
      emit(NotificationInitialized(
        hasPermission: hasPermission,
        pendingNotifications: pendingNotifications,
      ));
    } catch (e) {
      emit(NotificationError('Failed to initialize notifications: $e'));
    }
  }

  Future<void> _onRequestNotificationPermissions(
    RequestNotificationPermissions event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(const NotificationLoading());
      
      final bool granted = await _notificationService.requestPermissions();
      
      if (granted) {
        emit(const NotificationPermissionGranted());
      } else {
        emit(const NotificationPermissionDenied());
      }
    } catch (e) {
      emit(NotificationError('Failed to request permissions: $e'));
    }
  }

  Future<void> _onScheduleBookReminder(
    ScheduleBookReminder event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(const NotificationLoading());
      
      await _notificationService.scheduleBookReminder(
        book: event.book,
        scheduledTime: event.scheduledTime,
        customMessage: event.customMessage,
      );
      
      emit(BookReminderScheduled(
        book: event.book,
        scheduledTime: event.scheduledTime,
      ));
    } catch (e) {
      emit(NotificationError('Failed to schedule book reminder: $e'));
    }
  }

  Future<void> _onScheduleDailyReadingReminder(
    ScheduleDailyReadingReminder event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(const NotificationLoading());
      
      await _notificationService.scheduleDailyReadingReminder(
        book: event.book,
        time: event.time,
      );
      
      emit(DailyReadingReminderScheduled(
        book: event.book,
        time: event.time,
      ));
    } catch (e) {
      emit(NotificationError('Failed to schedule daily reading reminder: $e'));
    }
  }

  Future<void> _onScheduleNewBookNotification(
    ScheduleNewBookNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(const NotificationLoading());
      
      await _notificationService.scheduleNewBookNotification(
        book: event.book,
        releaseTime: event.releaseTime,
      );
      
      emit(NewBookNotificationScheduled(
        book: event.book,
        releaseTime: event.releaseTime,
      ));
    } catch (e) {
      emit(NotificationError('Failed to schedule new book notification: $e'));
    }
  }

  Future<void> _onShowInstantBookReminder(
    ShowInstantBookReminder event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(const NotificationLoading());
      
      await _notificationService.showInstantBookReminder(
        book: event.book,
        customMessage: event.customMessage,
      );
      
      emit(InstantReminderShown(event.book));
    } catch (e) {
      emit(NotificationError('Failed to show instant reminder: $e'));
    }
  }

  Future<void> _onScheduleReadingProgressReminder(
    ScheduleReadingProgressReminder event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(const NotificationLoading());
      
      await _notificationService.scheduleReadingProgressReminder(
        book: event.book,
        interval: event.interval,
      );
      
      emit(ReadingProgressReminderScheduled(
        book: event.book,
        interval: event.interval,
      ));
    } catch (e) {
      emit(NotificationError('Failed to schedule reading progress reminder: $e'));
    }
  }

  Future<void> _onCancelNotification(
    CancelNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(const NotificationLoading());
      
      await _notificationService.cancelNotification(event.notificationId);
      
      emit(NotificationCancelled(event.notificationId));
    } catch (e) {
      emit(NotificationError('Failed to cancel notification: $e'));
    }
  }

  Future<void> _onCancelAllNotifications(
    CancelAllNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(const NotificationLoading());
      
      await _notificationService.cancelAllNotifications();
      
      emit(const AllNotificationsCancelled());
    } catch (e) {
      emit(NotificationError('Failed to cancel all notifications: $e'));
    }
  }

  Future<void> _onLoadPendingNotifications(
    LoadPendingNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(const NotificationLoading());
      
      final List<PendingNotificationRequest> notifications = 
          await _notificationService.getPendingNotifications();
      
      emit(PendingNotificationsLoaded(notifications));
    } catch (e) {
      emit(NotificationError('Failed to load pending notifications: $e'));
    }
  }
}
