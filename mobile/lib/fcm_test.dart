import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:teekoob/firebase_options.dart';

// Background message handler - must be top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Request permissions
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  
  // Get FCM token
  String? token = await FirebaseMessaging.instance.getToken();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Test',
      home: FCMTestPage(),
    );
  }
}

class FCMTestPage extends StatefulWidget {
  @override
  _FCMTestPageState createState() => _FCMTestPageState();
}

class _FCMTestPageState extends State<FCMTestPage> {
  String? _token;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeFCM();
  }

  Future<void> _initializeFCM() async {
    try {
      // Get FCM token
      _token = await FirebaseMessaging.instance.getToken();
      
      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        setState(() {
          _status = 'Foreground message received: ${message.notification?.title}';
        });
      });
      
      // Listen for background messages when app is opened
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        setState(() {
          _status = 'Background message opened: ${message.notification?.title}';
        });
      });
      
      setState(() {
        _status = 'FCM initialized successfully!';
      });
      
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FCM Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(_status),
            SizedBox(height: 16),
            Text(
              'FCM Token:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _token ?? 'Loading...',
                style: TextStyle(fontSize: 12),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Instructions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('1. Copy the FCM token above'),
            Text('2. Send a test notification from Firebase Console'),
            Text('3. Close the app completely'),
            Text('4. Check if notification appears'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                _token = await FirebaseMessaging.instance.getToken();
                setState(() {});
              },
              child: Text('Refresh Token'),
            ),
          ],
        ),
      ),
    );
  }
}
