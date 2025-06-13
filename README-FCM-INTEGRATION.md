# Firebase Cloud Messaging (FCM) Integration

This README documents the integration of Firebase Cloud Messaging (FCM) into the Daily Checklist Student application to enable push notifications.

## Overview

FCM has been integrated to send push notifications when:
1. A teacher creates a new plan in the application
2. A teacher marks an activity as completed
3. A parent marks an activity as completed (notifies the teacher)

## Important Update: HTTP v1 API Migration

As of June 2023, Firebase has deprecated the legacy HTTP API, requiring migration to the HTTP v1 API by June 20, 2024. This implementation uses the HTTP v1 API which requires:

1. Service account authentication instead of server key
2. A different endpoint format (`https://fcm.googleapis.com/v1/projects/{project-id}/messages:send`)
3. A different message payload structure

## Implementation Steps

### 1. Flutter Project Setup

1. **Enabled Firebase Configuration**
   - Uncommented and updated the `firebase_options.dart` file
   - Updated `main.dart` to initialize Firebase and configure FCM

2. **Created FCM Service**
   - Implemented `fcm_service.dart` to handle FCM token management
   - Added methods to register, update, and clear FCM tokens
   - Added handlers for foreground and background messages

3. **Integrated FCM in App Lifecycle**
   - Initialized FCM in the `SplashScreen`
   - Configured token registration when user logs in
   - Setup token clearing when user logs out

### 2. Laravel API Backend Updates

1. **Database Changes**
   - Created migration to add `fcm_token` column to users table
   - Updated the User model to include the FCM token in fillable fields

2. **Created HTTP v1 FCM Service**
   - Implemented `FCMService.php` using Google API Client for authentication
   - Used service account JSON file for authentication
   - Added methods for sending to individual devices and multiple devices

3. **Updated Controllers**
   - Added endpoints in `UserController.php` to update and clear FCM tokens
   - Updated `PlanController.php` to send notifications via FCM when:
     - Plans are created
     - Activities are marked as completed

4. **Routes**
   - Added API routes for FCM token management:
     - `POST /api/users/fcm-token` - Update FCM token
     - `POST /api/users/fcm-token/clear` - Clear FCM token

## How to Test

### Prerequisites
1. Make sure you have the Laravel API project running locally
2. Ensure the Flutter app is connected to the API
3. Place the service account JSON file at:
   ```
   storage/credentials/daily-checklist-student-69cf10d6f307.json
   ```
4. Set the project ID in the `.env` file:
   ```
   FCM_PROJECT_ID=daily-checklist-student
   ```

### Testing Procedure
1. **Run the migration on Laravel:**
   ```
   php artisan migrate
   ```

2. **Install required Google API Client library:**
   ```
   composer require google/apiclient:^2.15.0
   ```

3. **Test FCM with Postman:**
   - See `POSTMAN-FCM-TESTING.md` for detailed instructions
   - Create a new plan as a teacher
   - Verify push notifications are received on parent devices
   - Mark activities as completed and verify notifications

4. **Testing through Flutter App:**
   - Login as a teacher and create a new plan
   - Login as a parent and verify notification received
   - Mark activities as completed and verify notifications

## Troubleshooting

If notifications are not working:

1. Check the Laravel logs for any FCM-related errors
2. Verify that service account file is in the correct location and has proper permissions
3. Ensure that FCM token is being correctly saved to the database
4. Verify that the app has notification permissions on the device
5. Check the Firebase Console > Cloud Messaging section for delivery reports

## Future Improvements

- Implement topic-based subscriptions for different notification types
- Add notification customization settings in the app
- Enable silent notifications for data synchronization
- Add notification analytics tracking
- Implement notification grouping for multiple updates 