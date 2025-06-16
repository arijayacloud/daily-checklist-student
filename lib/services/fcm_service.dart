import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '/laravel_api/providers/api_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '/laravel_api/providers/notification_provider.dart';
import '/laravel_api/providers/auth_provider.dart';

class FCMService {
  late final FirebaseMessaging _messaging;
  late final FlutterLocalNotificationsPlugin _localNotifications;
  final deviceInfo = DeviceInfoPlugin();
  
  // Function to be called when a notification is tapped
  late final Function(Map<String, dynamic>)? onNotificationTap;
  
  // If set to true, will show local notification for foreground messages
  final bool handleForegroundMessages;

  FCMService({
    this.onNotificationTap,
    this.handleForegroundMessages = true,
  }) {
    _messaging = FirebaseMessaging.instance;
    _localNotifications = FlutterLocalNotificationsPlugin();
  }

  Future<void> initialize(BuildContext context) async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    debugPrint('FCM Authorization status: ${settings.authorizationStatus}');

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Configure messaging handlers
    _configureMessageHandling();

    // Get and register the FCM token
    await _getAndRegisterToken(context);

    // Listen for token refreshes
    _messaging.onTokenRefresh.listen((token) {
      _registerTokenWithBackend(context, token);
    });
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const DarwinInitializationSettings initializationSettingsIOS = 
        DarwinInitializationSettings();
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    // Create notification channel for Android
    await _createAndroidNotificationChannel();
  }

  Future<void> _createAndroidNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.', // description
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _configureMessageHandling() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.notification?.title}');
      
      if (handleForegroundMessages) {
        _showLocalNotification(message);
      }
    });

    // Handle when app is opened from a background notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened from background message: ${message.notification?.title}');
      _processNotificationTap(message);
    });
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        _processNotificationTap(RemoteMessage(data: data));
      } catch (e) {
        debugPrint('Error processing notification tap: $e');
      }
    }
  }

  void _processNotificationTap(RemoteMessage message) {
    if (onNotificationTap != null && message.data.isNotEmpty) {
      onNotificationTap!(message.data);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'New Notification',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is used for important notifications.',
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          priority: Priority.high,
          importance: Importance.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: json.encode(message.data),
    );
  }

  Future<void> _getAndRegisterToken(BuildContext context) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _registerTokenWithBackend(context, token);
    } else {
      debugPrint('Failed to get FCM token');
    }
  }

  Future<void> _registerTokenWithBackend(BuildContext context, String token) async {
    try {
      // Get auth state
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      
      if (authProvider.isAuthenticated) {
        // Get device info
        String deviceInfoStr = await _getDeviceInfo();
        
        // Register with backend
        final success = await notificationProvider.registerFirebaseToken(token, deviceInfo: deviceInfoStr);
        
        if (success) {
          debugPrint('Successfully registered FCM token with backend');
        } else {
          debugPrint('Failed to register FCM token with backend');
        }
      } else {
        debugPrint('Not authenticated, skipping FCM token registration');
      }
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  Future<String> _getDeviceInfo() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.model} (Android ${androidInfo.version.release})';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.model} (iOS ${iosInfo.systemVersion})';
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }
    return 'Unknown Device';
  }

  // Call this when you need to handle the initial notification that launched the app
  Future<void> handleInitialMessage() async {
    final RemoteMessage? initialMessage = 
        await FirebaseMessaging.instance.getInitialMessage();
        
    if (initialMessage != null) {
      _processNotificationTap(initialMessage);
    }
  }

  // Method to update token when user logs in with authentication token
  Future<bool> updateTokenForUser(String authToken) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('Failed to get FCM token');
        return false;
      }
      
      String deviceInfoStr = await _getDeviceInfo();
      
      // Make a direct API call with the auth token
      final uri = Uri.parse('http://192.168.1.10:8000/api/notifications/register-token');
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'token': token,
          'device_info': deviceInfoStr,
        }),
      );
      
      if (response.statusCode == 200) {
        debugPrint('Successfully registered FCM token with backend after login');
        return true;
      } else {
        debugPrint('Failed to register FCM token: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
      return false;
    }
  }

  // Method to clear token when user logs out
  Future<bool> clearToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('No FCM token to clear');
        return true;
      }
      
      // Make a direct API call to clear the token
      final uri = Uri.parse('http://192.168.1.10:8000/api/notifications/unregister-token');
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'token': token,
        }),
      );
      
      // Attempt to delete the token from Firebase
      try {
        await _messaging.deleteToken();
        debugPrint('Deleted FCM token from Firebase');
      } catch (e) {
        debugPrint('Failed to delete FCM token from Firebase: $e');
      }
      
      if (response.statusCode == 200) {
        debugPrint('Successfully unregistered FCM token from backend');
        return true;
      } else {
        debugPrint('Failed to unregister FCM token: ${response.body}');
        // Return true anyway since we deleted the token from Firebase
        return true;
      }
    } catch (e) {
      debugPrint('Error clearing FCM token: $e');
      return false;
    }
  }
}

// Top-level background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No need to initialize Firebase here as it should already be initialized in main.dart
  debugPrint('Handling background message: ${message.messageId}');
  // Background message handling if needed
} 