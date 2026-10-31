import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:dhartti/firebase_options.dart';
import 'package:dhartti/service/notification_service.dart';
import 'package:dhartti/UserScreen/NotificationScreen.dart';
import 'package:dhartti/constants.dart';

// Top-level background message handler (when app is killed / terminated)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}

  // If system didn't show notification automatically, show via local notifications with sound
  final FlutterLocalNotificationsPlugin localNotifs = FlutterLocalNotificationsPlugin();
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'dhartti_high_importance_channel',
    'Dhartti Notifications',
    channelDescription: 'Real-time updates regarding properties, loan schemes, inquiries, and bids.',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    icon: '@drawable/ic_notification',
  );

  final title = message.notification?.title ?? message.data['title'] ?? 'Dhartti Alert';
  final body = message.notification?.body ?? message.data['body'] ?? message.data['message'] ?? '';

  if (title.isNotEmpty || body.isNotEmpty) {
    localNotifs.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }
}

class FirebaseNotificationService {
  static final FirebaseNotificationService instance = FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => instance;
  FirebaseNotificationService._internal();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? navigatorKey;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'dhartti_high_importance_channel',
    'Dhartti Notifications',
    description: 'Real-time updates regarding properties, loan schemes, inquiries, and bids.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  bool _isInitialized = false;

  Future<void> initialize({GlobalKey<NavigatorState>? navKey}) async {
    if (_isInitialized) return;
    if (navKey != null) navigatorKey = navKey;

    try {
      // 1. Initialize Firebase Core
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
          .timeout(const Duration(seconds: 6));

      // 2. Set Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Request Notification Permission (Android 13+ & iOS)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );
      debugPrint('User notification permission status: ${settings.authorizationStatus}');

      // 4. Create High-Priority Notification Channel with Sound for Android
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // 5. Initialize Local Notifications Plugin with Dhartti App Icon
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@drawable/ic_notification');
      const InitializationSettings initSettings = InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _navigateToNotifications();
        },
      );

      // 6. Foreground FCM Message Listener (Shows Heads-up Banner when app is open)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground FCM message received: ${message.notification?.title}');
        
        RemoteNotification? notification = message.notification;
        final title = notification?.title ?? message.data['title'] ?? 'Dhartti Alert';
        final body = notification?.body ?? message.data['body'] ?? message.data['message'] ?? '';

        if (!kIsWeb && (title.isNotEmpty || body.isNotEmpty)) {
          _localNotifications.show(
            id: notification?.hashCode ?? message.hashCode,
            title: title,
            body: body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                icon: '@drawable/ic_notification',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
              ),
            ),
          );
        }

        // Real-time update of in-app unread count badge & trigger live list rebuild
        NotificationService.liveUpdateTrigger.value++;
        NotificationService().refreshUnreadCount();
      });

      // 7. Message Opened App (User clicked on notification from system tray)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('App opened from notification: ${message.messageId}');
        _navigateToNotifications();
      });

      // 8. Check if app was opened from terminated state via notification
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          _navigateToNotifications();
        });
      }

      // 9. Fetch and Sync FCM Token
      await syncCurrentFcmToken();

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _syncTokenWithServer(newToken);
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing Firebase Notifications: $e');
    }
  }

  void _navigateToNotifications() {
    if (navigatorKey?.currentState != null) {
      navigatorKey!.currentState!.push(
        MaterialPageRoute(builder: (_) => const NotificationScreen()),
      );
    }
  }

  /// Explicitly sync FCM token with current authenticated user
  Future<void> syncCurrentFcmToken() async {
    try {
      final token = await _fcm.getToken().timeout(const Duration(seconds: 5));
      if (token != null) {
        debugPrint('FCM Registration Token: $token');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
        await _syncTokenWithServer(token);
      }
    } catch (e) {
      debugPrint('Error fetching FCM token: $e');
    }
  }

  Future<void> _syncTokenWithServer(String fcmToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get safe userId
      dynamic rawId = prefs.get('userId') ?? prefs.get('user_id');
      String? userId = rawId?.toString();
      final authToken = prefs.getString('auth_token') ?? prefs.getString('token');

      final url = Uri.parse('${AppConstants.baseUrl}/notifications/fcm-token');
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (authToken != null && authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
          if (userId != null && userId.isNotEmpty) 'X-User-Id': userId,
        },
        body: jsonEncode({
          'fcm_token': fcmToken,
          if (userId != null && userId.isNotEmpty) 'user_id': userId,
        }),
      );
    } catch (e) {
      debugPrint('Error syncing FCM token with backend: $e');
    }
  }
}
