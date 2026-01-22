# Admin Account Setup Guide

## How to Create an Admin Account

Admin accounts cannot be created through the app signup. You need to create them manually in Firebase:

### Step 1: Create Firebase Auth User

1. Go to Firebase Console: https://console.firebase.google.com
2. Select your project: `flutter-ccc75`
3. Go to **Authentication** → **Users**
4. Click **Add user**
5. Enter admin email and password
6. Click **Add user**

### Step 2: Get the User UID

After creating the user in Firebase Auth:
1. Find the newly created user in the Users list
2. Copy the **UID** (User ID)

### Step 3: Create Firestore Document

1. Go to **Firestore Database** in Firebase Console
2. Navigate to `users` collection
3. Click **Add document**
4. Set the **Document ID** to the UID you copied
5. Add the following fields:

```json
{
  "email": "admin@example.com",
  "name": "Admin Name",
  "role": "admin",
  "verified": true,
  "status": "verified",
  "verificationDocuments": [],
  "createdAt": [Current Timestamp],
  "updatedAt": [Current Timestamp]
}
```

**Important Fields:**
- `role`: Must be `"admin"` (lowercase)
- `verified`: `true`
- `status`: `"verified"`
- `createdAt` and `updatedAt`: Use Firestore Timestamp type

### Step 4: Login as Admin

1. Open the app
2. Click **Admin Portal** on the login screen
3. Enter the email and password you created
4. You will be redirected to the Admin Dashboard

## Example Admin Credentials Format

After setup, your admin account will look like:

- **Email**: admin@tourease.com (or your chosen email)
- **Password**: (the password you set in Firebase Auth)
- **Firestore Document**: `/users/{uid}` with `role: "admin"`

## Notes

- Only users with `role: "admin"` in Firestore can access admin features
- The admin login screen will reject non-admin accounts
- Make sure both Firebase Auth user and Firestore document exist

## Build and Locate APK

After setting up your admin account, you might want to build the app and locate the APK file:

1. Connect your device or start an emulator
2. Run the following command in your project directory:

```bash
flutter build apk --release
```

3. Once the build is complete, locate the APK at:

```
e:\Flutter-Architect\Flutter-Architect\build\app\outputs\flutter-apk\app-release.apk
```

4. Install the APK on your device/emulator
5. Open the app and log in with your admin credentials

## Troubleshooting Common Issues

- **Cannot login as admin**: Ensure the user is created in both Firebase Auth and Firestore with the correct `role` and `status`.
- **Firestore permissions error**: Check Firestore rules to ensure admins have access.
- **App crashes on startup**: Verify the APK is correctly installed and matches the app's Firebase project.

For further assistance, consult the Firebase documentation or seek help from a developer familiar with the project.

