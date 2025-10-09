import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:teekoob/firebase_options.dart';
import 'package:teekoob/core/services/notification_service_interface.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/features/books/services/books_service.dart';
import 'package:teekoob/core/services/localization_service.dart';

// Conditional import for Firebase Messaging (disabled on web)
import 'firebase_notification_service_stub.dart'
    if (dart.library.io) 'firebase_notification_service_io.dart';

// Export the appropriate implementation
export 'firebase_notification_service_stub.dart'
    if (dart.library.io) 'firebase_notification_service_io.dart';
