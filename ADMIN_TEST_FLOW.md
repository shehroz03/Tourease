# Admin Authentication Test Flow

## Prerequisites

Before testing, ensure you have:
1. Created an admin user in Firebase Authentication with:
   - Email: `admin@tourease.com`
   - Password: (your chosen password)
   - UID: `Mh8dvEqxZAY78nBrx7KWFlpWIso1`

2. Created a Firestore document at `/users/Mh8dvEqxZAY78nBrx7KWFlpWIso1` with:
   ```json
   {
     "email": "admin@tourease.com",
     "name": "Admin",
     "role": "admin",
     "verified": true,
     "status": "verified",
     "createdAt": [Timestamp],
     "updatedAt": [Timestamp]
   }
   ```

## Test Sequence

### Test 1: Non-Admin User Cannot Access Admin Portal

**Steps:**
1. **Log out** (if logged in)
2. **Sign up** as a new traveler or agency user
3. **Log in** with the traveler/agency credentials
4. Try to navigate to `/admin/login` or `/admin/dashboard`

**Expected Result:**
- If trying to access `/admin/login`: Should be able to open login screen
- If trying to login as admin with non-admin credentials: Should see error "This account is not an admin."
- If trying to access `/admin/dashboard` directly: Should be redirected to their home route (traveler home or agency dashboard)
- Should see SnackBar: "Access denied. Admin only."

**Status:** ✅ Pass / ❌ Fail

---

### Test 2: Admin Login with Correct Credentials

**Steps:**
1. **Log out** (if logged in)
2. Click **"Admin Portal"** button on login screen
3. Enter admin credentials:
   - Email: `admin@tourease.com`
   - Password: (your admin password)
4. Click **"Login as Admin"**

**Expected Result:**
- Should successfully authenticate
- Should redirect to `/admin/dashboard`
- Should see admin dashboard with navigation tabs (Dashboard, Agencies, Tours, Settings)
- No error messages

**Status:** ✅ Pass / ❌ Fail

---

### Test 3: Admin Login with Wrong Password

**Steps:**
1. **Log out** (if logged in)
2. Click **"Admin Portal"** button
3. Enter:
   - Email: `admin@tourease.com`
   - Password: `wrongpassword`
4. Click **"Login as Admin"**

**Expected Result:**
- Should show Firebase Auth error (e.g., "Wrong password")
- Should NOT redirect to admin dashboard
- Should remain on admin login screen

**Status:** ✅ Pass / ❌ Fail

---

### Test 4: Admin Login with Non-Admin Email

**Steps:**
1. **Log out** (if logged in)
2. Click **"Admin Portal"** button
3. Enter credentials of a traveler or agency user
4. Click **"Login as Admin"**

**Expected Result:**
- Should authenticate successfully (Firebase Auth works)
- Should immediately sign out the user
- Should show SnackBar: "This account is not an admin."
- Should remain on admin login screen
- Should NOT access admin dashboard

**Status:** ✅ Pass / ❌ Fail

---

### Test 5: Admin Account Not Verified

**Steps:**
1. In Firestore, update admin document:
   - Set `verified: false` OR
   - Set `status: "pending"`
2. **Log out** (if logged in)
3. Try to login as admin with correct credentials

**Expected Result:**
- Should authenticate successfully
- Should immediately sign out
- Should show SnackBar: "Your admin account is not verified yet."
- Should NOT access admin dashboard

**Status:** ✅ Pass / ❌ Fail

**Note:** After testing, restore admin document to:
- `verified: true`
- `status: "verified"`

---

### Test 6: Direct Navigation to Admin Routes (Non-Admin)

**Steps:**
1. **Log in** as a traveler or agency user
2. Try to navigate directly to:
   - `/admin/dashboard`
   - `/admin/agencies`
   - `/admin/tours`
   - `/admin/settings`

**Expected Result:**
- Should be redirected to their appropriate home route
- Should see SnackBar: "Access denied. Admin only."
- Should NOT see admin screens

**Status:** ✅ Pass / ❌ Fail

---

### Test 7: Admin Route Guards

**Steps:**
1. **Log in** as admin successfully
2. Navigate through all admin routes:
   - Dashboard
   - Agencies
   - Tours
   - Settings
3. All should load without errors

**Expected Result:**
- All admin routes should be accessible
- No redirects or error messages
- Navigation should work smoothly

**Status:** ✅ Pass / ❌ Fail

---

## Security Checklist

- [ ] No hard-coded admin credentials in code
- [ ] Admin login uses Firebase Auth only
- [ ] Admin routes check `role == 'admin'`
- [ ] Admin routes check `verified == true`
- [ ] Admin routes check `status == 'verified'`
- [ ] Non-admin users are redirected with error message
- [ ] Unverified admin accounts are blocked
- [ ] All admin screens have proper guards

---

## Notes

- All admin authentication is handled through Firebase Authentication
- Admin role is determined by Firestore document field `role: "admin"`
- Admin must have `verified: true` and `status: "verified"` to access admin features
- No bypass mechanisms or debug shortcuts exist
- All error messages are user-friendly and informative

