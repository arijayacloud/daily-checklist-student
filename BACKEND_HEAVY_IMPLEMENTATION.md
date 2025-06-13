# Backend-Heavy Implementation in the Flutter App

This document summarizes the changes made to implement a backend-heavy approach in the Daily Checklist Student Flutter app.

## What is Backend-Heavy Architecture?

The backend-heavy architecture shifts most of the business logic from the client to the server. This approach:
- Simplifies client-side code
- Enables consistent behavior across platforms
- Centralizes logic in one place
- Reduces duplicate code

## Key Changes Implemented

### 1. Enhanced NotificationProvider

The NotificationProvider has been updated to support the backend-heavy approach:
- Added `fetchUnreadCount()` method to get unread notifications count from server
- Added `registerFirebaseToken()` method to register device FCM tokens
- Improved notification state management with backend-driven counts

```dart
// New methods in NotificationProvider
Future<void> fetchUnreadCount() async {
  final data = await _apiProvider.get('notifications/unread-count');
  _unreadCount = data['unread_count'];
  notifyListeners();
}

Future<bool> registerFirebaseToken(String token, {String? deviceInfo}) async {
  final data = await _apiProvider.post('notifications/register-token', {
    'token': token,
    'device_info': deviceInfo,
  });
  return data != null;
}
```

### 2. FCM Service

Added a new FCMService to handle Firebase Cloud Messaging:
- Registers FCM tokens with the backend
- Handles foreground and background notifications
- Manages notification permissions
- Provides device information for better tracking

```dart
// Usage in main.dart
Provider<FCMService>(
  create: (_) => FCMService(
    onNotificationTap: (data) {
      // Handle notification taps
    },
  ),
),
```

### 3. Main App Initialization

Updated main.dart to properly initialize Firebase and FCM:
- Initializes Firebase at app startup
- Sets up FCM background message handling
- Initializes FCM service when user authenticates
- Configures notification tap handling

### 4. Notification Screen

Updated NotificationScreen to work with the backend-heavy approach:
- Fetches notifications from the backend
- Gets unread count for badge display
- Uses the markAllAsRead endpoint to update notification status

## API Endpoints Being Used

- `GET /notifications` - Fetch user notifications
- `GET /notifications/unread-count` - Get count of unread notifications
- `PUT /notifications/read-all` - Mark all notifications as read
- `PUT /notifications/{id}` - Update notification (mark as read/unread)
- `DELETE /notifications/{id}` - Delete a notification
- `POST /notifications/register-token` - Register a device FCM token

## Benefits

1. **Simplified Client Code**: The Flutter app no longer needs to handle complex notification logic
2. **Reduced Network Traffic**: Fewer API calls by getting just what's needed
3. **Consistent Behavior**: Notifications behave the same across all platforms
4. **Better Security**: Sensitive operations are handled server-side

## Troubleshooting

If notifications aren't working properly:

1. Check that Firebase initialization is successful
2. Verify that the FCM token is being registered with the backend
3. Ensure the backend has the correct Firebase server key in the `.env` file
4. Check that notification permissions are granted on the device 