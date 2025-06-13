# Testing FCM Notifications with Postman

This guide provides step-by-step instructions for testing Firebase Cloud Messaging (FCM) notifications using Postman for the Daily Checklist Student application.

## Prerequisites

1. [Postman](https://www.postman.com/downloads/) installed
2. Laravel API running locally
3. Migration has been run to add the FCM token field to users (`php artisan migrate`)
4. Service account JSON file placed in `storage/credentials/daily-checklist-student-69cf10d6f307.json`

## Setting Up Postman Collections

### 1. Import the Collection

1. Download [FCM Testing Collection](https://www.postman.com/collections/fcm-testing-collection) (or create a new collection)
2. In Postman, click "Import" and select the downloaded file or create a new collection named "FCM Testing"

### 2. Configure Environment Variables

Create a new environment in Postman and add the following variables:

- `base_url`: http://localhost:8000/api (adjust if your API runs on a different port)
- `token`: (leave empty for now, we'll set it after login)

## Testing Workflow

### Step 1: Register a FCM Token

#### Test User Login

1. Create a new request in your collection: `POST {{base_url}}/auth/login`
2. In the "Body" tab, select "raw" and "JSON", then add:
   ```json
   {
     "email": "teacher@example.com",
     "password": "password123"
   }
   ```
3. Send the request and copy the returned token

4. Set the token variable in your environment:
   - In the environment quick-look view (eye icon in the top right), edit the value for `token`
   - Paste the token you received from the login response

#### Register FCM Token

1. Create a new request: `POST {{base_url}}/users/fcm-token`
2. Add header: `Authorization: Bearer {{token}}`
3. In the "Body" tab, select "raw" and "JSON", then add:
   ```json
   {
     "fcm_token": "YOUR_DEVICE_FCM_TOKEN"
   }
   ```
   Replace `YOUR_DEVICE_FCM_TOKEN` with an actual FCM token from your device
   (You can get this token from the app's console logs when running the Flutter app)
4. Send the request. You should receive a success response.

### Step 2: Test Plan Creation Notification

In this step, we'll create a new plan which should trigger FCM notifications to parents.

1. Create a new request: `POST {{base_url}}/plans`
2. Add header: `Authorization: Bearer {{token}}`
3. In the "Body" tab, select "raw" and "JSON", then add:
   ```json
   {
     "type": "daily",
     "start_date": "2023-06-14",
     "child_ids": [1, 2],
     "activities": [
       {
         "activity_id": 1,
         "scheduled_date": "2023-06-14",
         "scheduled_time": "09:00",
         "reminder": true
       },
       {
         "activity_id": 2,
         "scheduled_date": "2023-06-14",
         "scheduled_time": "14:00",
         "reminder": true
       }
     ]
   }
   ```
   Adjust the child_ids and activity_ids based on your database
4. Send the request

5. Check your device for notifications
   - If the FCM token you registered belongs to a parent of the children specified in the request, you should receive a notification
   - If you're testing with an emulator, check the logcat for FCM messages

### Step 3: Test Activity Completion Notification

1. First, get the ID of a planned activity:
   - Create a GET request to `{{base_url}}/plans` to list all plans
   - Find a plan and note a planned_activity ID

2. Create a new request: `PUT {{base_url}}/planned-activities/{id}/status`
   Replace `{id}` with the actual planned activity ID
3. Add header: `Authorization: Bearer {{token}}`
4. In the "Body" tab, select "raw" and "JSON", then add:
   ```json
   {
     "completed": true
   }
   ```
5. Send the request
6. Check for notifications on the appropriate device

## Troubleshooting

### No Notifications Received

1. **Check Laravel Logs**:
   - Look at `storage/logs/laravel.log` for FCM-related errors
   - Common errors include access token issues or malformed messages

2. **Verify FCM Token Registration**:
   - Create a GET request to `{{base_url}}/auth/user` with the Authorization header
   - Check that the user has a valid fcm_token value

3. **Firebase Console**:
   - Check the Firebase Console > Messaging section for delivery reports
   - Make sure your app is properly set up to receive messages when in the background

## HTTP v1 API Direct Testing

You can also test the HTTP v1 API directly using Postman:

1. Create a new OAuth 2.0 token:
   - Click on the "Authorization" tab
   - Select "OAuth 2.0"
   - Click "Get New Access Token"
   - Type: "Service Account - JWT"
   - Upload your service account JSON

2. Create a new request:
   POST https://fcm.googleapis.com/v1/projects/daily-checklist-student/messages:send

3. Set the Authorization to use your OAuth 2.0 token

4. Set the body to:
   ```json
   {
     "message": {
       "token": "YOUR_DEVICE_FCM_TOKEN",
       "notification": {
         "title": "Test Notification",
         "body": "This is a test notification from Postman"
       },
       "data": {
         "type": "test",
         "id": "123"
       }
     }
   }
   ```

5. Send the request and check your device for the notification 