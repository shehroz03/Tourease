# Firebase Authentication Setup - Troubleshooting Guide

## Console Error: `identitytoolkit.goog... 400 Bad Request`

Yeh error Firebase Authentication API call fail hone par aata hai. Iska matlab Firebase setup mein problem hai.

## Quick Fix Checklist

### 1. Enable Email/Password Authentication in Firebase Console

1. Firebase Console kholo: https://console.firebase.google.com
2. Apna project select karo: `flutter-ccc75`
3. Left sidebar se **Authentication** click karo
4. **Sign-in method** tab kholo
5. **Email/Password** provider ko enable karo:
   - Email/Password par click karo
   - Toggle ko **Enable** par switch karo
   - **Save** click karo

### 2. Create Admin User in Firebase Authentication

1. **Authentication** → **Users** tab
2. **Add user** button click karo
3. Enter:
   - **Email:** `admin@tourease.com`
   - **Password:** `admin123`
   - "Set email as verified" checkbox tick karo (recommended)
4. **Add user** click karo
5. **UID copy karo** - yeh Firestore document ID ke liye chahiye

### 3. Create Firestore Document

1. **Firestore Database** → **users** collection
2. **Add document** click karo
3. **Document ID** = Firebase Authentication ka UID (step 2 se)
4. Fields add karo:

```
email: "admin@tourease.com" (string)
name: "Admin" (string)
role: "admin" (string) - IMPORTANT: lowercase!
verified: true (boolean)
status: "verified" (string) - lowercase!
verificationDocuments: [] (array)
createdAt: [current timestamp]
updatedAt: [current timestamp]
```

### 4. Verify Firebase Project Settings

1. **Project Settings** (gear icon)
2. **General** tab mein check karo:
   - Project ID: `flutter-ccc75`
   - Web API Key should match `firebase_options.dart` file
3. **Service accounts** tab mein API enabled hona chahiye

## Common Errors & Solutions

### Error: "400 Bad Request" from identitytoolkit.goog
**Solution:** Email/Password authentication enable karo (Step 1)

### Error: "user-not-found"
**Solution:** Admin user Firebase Authentication mein create karo (Step 2)

### Error: "wrong-password"
**Solution:** Password sahi check karo ya naya user create karo

### Error: "User profile not found in Firestore"
**Solution:** Firestore document create karo (Step 3) - UID match karna chahiye

### Login ke baad phir login page khulta hai
**Solution:** Firestore document mein `role: "admin"` (lowercase) hona chahiye

## Testing Steps

1. Firebase Console mein Email/Password enable karo
2. Admin user create karo
3. Firestore document create karo
4. App run karo
5. Admin Portal login karo
6. Console logs check karo - ab detailed messages dikhengi

## Debug Logs

App mein ab detailed debug logs hain. Console mein yeh messages dikhengi:
- `AuthService.signIn: Attempting to sign in...`
- `AuthService.signIn: Firebase Auth successful...`
- `AuthService.signIn: Fetching user data from Firestore...`
- `Admin login - User role: ...`

Agar koi error ho to exact message console mein dikhega.






