# Admin Login Credentials - Quick Setup Guide

## Pre-filled Credentials in Code

The admin login screen has these credentials pre-filled:

- **Email:** `admin@tourease.com`
- **Password:** `admin123`

## Firebase Setup (REQUIRED - Do This First!)

You MUST create this user in Firebase before testing. Follow these exact steps:

### Step 1: Create User in Firebase Authentication

1. Go to: https://console.firebase.google.com
2. Select your project
3. Click **Authentication** → **Users** tab
4. Click **Add user** button (top left)
5. Enter:
   - **Email:** `admin@tourease.com`
   - **Password:** `admin123`
   - Check "Set email as verified" (optional but recommended)
6. Click **Add user**
7. **IMPORTANT:** Copy the **UID** (User ID) - you'll need it for Step 2

### Step 2: Create Firestore Document

1. In Firebase Console, go to **Firestore Database**
2. Click **users** collection (or create it if it doesn't exist)
3. Click **Add document**
4. Set **Document ID** = the UID you copied from Step 1
5. Add these fields (click "Add field" for each):

   | Field Name | Type | Value |
   |------------|------|-------|
   | `email` | string | `admin@tourease.com` |
   | `name` | string | `Admin` |
   | `role` | string | `admin` (MUST be lowercase!) |
   | `verified` | boolean | `true` (check the checkbox) |
   | `status` | string | `verified` (lowercase) |
   | `verificationDocuments` | array | `[]` (empty array) |
   | `createdAt` | timestamp | Click "Set" and choose "Current time" |
   | `updatedAt` | timestamp | Click "Set" and choose "Current time" |

6. Click **Save**

### Step 3: Verify Setup

Your Firestore document should look like this:
```json
{
  "email": "admin@tourease.com",
  "name": "Admin",
  "role": "admin",
  "verified": true,
  "status": "verified",
  "verificationDocuments": [],
  "createdAt": [timestamp],
  "updatedAt": [timestamp]
}
```

## Testing

1. Run your Flutter app
2. Click **Admin Portal** button on login screen
3. Email and password fields will be **pre-filled automatically**
4. Click **Login as Admin** button
5. You should be redirected to **Admin Dashboard**

## Troubleshooting

### Error: "Wrong password"
- Make sure password in Firebase Auth is exactly `admin123`
- Check for any extra spaces

### Error: "This account is not an admin"
- Check Firestore document has `role: "admin"` (lowercase)
- Make sure UID matches between Auth and Firestore

### Error: "Your admin account is not verified yet"
- Check `verified: true` in Firestore
- Check `status: "verified"` in Firestore

### Still redirecting to traveler dashboard?
- Check console logs for debug messages
- Verify role is exactly `"admin"` (not `"Admin"` or `"ADMIN"`)
- Make sure you're using the admin login screen, not regular login

## Security Note

⚠️ **IMPORTANT:** These credentials are for development/testing only. 
- Remove or change the pre-filled password before production
- Use strong passwords in production
- Never commit real credentials to version control

