import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '/laravel_api/providers/api_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize FCM
  Future<void> init() async {
    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted notification permission: ${settings.authorizationStatus}');

    // Configure local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
    
    // Set up token refresh listener
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      print('FCM Token refreshed: $token');
    });
  }

  // Show local notification when message is received in foreground
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null && !kIsWeb) {
      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'fcm_default_channel',
            'Default Channel',
            channelDescription: 'This channel is used for important notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  // Method to update token when user logs in
  Future<void> updateTokenForUser(String authToken) async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      try {
        const String apiUrl = 'http://localhost:8000/api/users/fcm-token';
        
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'fcm_token': token,
          }),
        );
        
        if (response.statusCode == 200) {
          print('FCM Token updated for authenticated user');
        } else {
          print('Failed to update FCM Token: ${response.statusCode}, ${response.body}');
        }
      } catch (e) {
        print('Error updating FCM token: $e');
      }
    }
  }
  
  // Method to update token using context and current API provider
  Future<void> updateToken(BuildContext context) async {
    final apiProvider = Provider.of<ApiProvider>(context, listen: false);
    String? token = await _firebaseMessaging.getToken();
    
    if (token != null && apiProvider.token != null) {
      try {
        final response = await http.post(
          Uri.parse('${apiProvider.baseUrl}/users/fcm-token'),
          headers: {
            'Authorization': 'Bearer ${apiProvider.token}',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'fcm_token': token,
          }),
        );
        
        if (response.statusCode == 200) {
          print('FCM Token updated for authenticated user');
        } else {
          print('Failed to update FCM Token: ${response.statusCode}, ${response.body}');
        }
      } catch (e) {
        print('Error updating FCM token: $e');
      }
    }
  }
  
  // Method to clear token when user logs out
  Future<void> clearToken() async {
    try {
      // No need to make an API call here, the token will be cleared in the logout process
      await _firebaseMessaging.deleteToken();
      print('FCM Token cleared locally');
    } catch (e) {
      print('Error clearing FCM token: $e');
    }
  }
} 