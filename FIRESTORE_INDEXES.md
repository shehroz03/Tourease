# Firestore Indexes Setup Guide

## How to Create Required Indexes

### Step 1: Open Each URL
Copy each URL below and open it in your browser. The Firebase Console will open with the index configuration.

### Step 2: Create the Index
1. Click "Create index" or "Save" button in Firebase Console
2. Wait for the index status to become "Enabled" (usually takes 1-3 minutes)

### Step 3: Verify
Once all indexes are enabled, restart your app and the errors will be gone.

---

## Required Indexes

### 1. Tours - Active Tours (status + startDate)
**Collection:** `tours`  
**Fields:** `status` (Ascending), `startDate` (Ascending)

URL: https://console.firebase.google.com/v1/r/project/flutter-ccc75/firestore/indexes?create_composite=Cktwcm9qZWN0cy9mbHV0dGVyLWNjYzc1L2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy90b3Vycy9pbmRleGVzL18QARoKCgZzdGF0dXMQARoNCglzdGFydERhdGUQARoMCghfX25hbWVfXxAB

**Used in:** Traveler home screen (`streamActiveTours()`)

---

### 2. Tours - Agency Tours (agencyId + createdAt)
**Collection:** `tours`  
**Fields:** `agencyId` (Ascending), `createdAt` (Descending)

URL: https://console.firebase.google.com/v1/r/project/flutter-ccc75/firestore/indexes?create_composite=Cktwcm9qZWN0cy9mbHV0dGVyLWNjYzc1L2RhdGFiYXNIcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy90b3Vycy9pbmRleGVzL18QARoMCghhZ2VuY3lJZBABGg0KCWNyZWF0ZWRBdBABE4wKCF9fbmFtZV9fEAE

**Used in:** Agency tours screen (`streamAgencyTours()`)

---

### 3. Bookings - Traveler Bookings (travelerId + createdAt)
**Collection:** `bookings`  
**Fields:** `travelerId` (Ascending), `createdAt` (Descending)

URL: https://console.firebase.google.com/v1/r/project/flutter-ccc75/firestore/indexes?create_composite=Cktwcm9qZWN0cy9mbHV0dGVyLWNjYzc1L2RhdGFiYXNIcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9ib29raW5ncy9pbmRleGVzL18QARoOCgx0cmF2ZWxlcklkEAEaDQoJY3JlYXRlZEF0EAETjAoIX19uYW1lX18QAQ

**Used in:** Traveler bookings screen (`streamTravelerBookings()`)

---

### 4. Bookings - Agency Bookings (agencyId + createdAt)
**Collection:** `bookings`  
**Fields:** `agencyId` (Ascending), `createdAt` (Descending)

URL: https://console.firebase.google.com/v1/r/project/flutter-ccc75/firestore/indexes?create_composite=Cktwcm9qZWN0cy9mbHV0dGVyLWNjYzc1L2RhdGFiYXNIcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9ib29raW5ncy9pbmRleGVzL18QARoMCghhZ2VuY3lJZBABGg0KCWNyZWF0ZWRBdBABE4wKCF9fbmFtZV9fEAE

**Used in:** Agency bookings screen (`streamAgencyBookings()`)

---

### 5. Chats - Get/Create Chat (travelerId + agencyId + tourId)
**Collection:** `chats`  
**Fields:** `travelerId` (Ascending), `agencyId` (Ascending), `tourId` (Ascending)

URL: https://console.firebase.google.com/v1/r/project/flutter-ccc75/firestore/indexes?create_composite=Cktwcm9qZWN0cy9mbHV0dGVyLWNjYzc1L2RhdGFiYXNIcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9jaGF0cy9pbmRleGVzL18QARoOCgx0cmF2ZWxlcklkEAEaDAoIYWdlbmN5SWQQARoNCgl0b3VySWQQAROMCghfX25hbWVfXxAB

**Used in:** Chat creation (`getOrCreateChat()`)

---

### 6. Chats - Traveler Chats (travelerId + updatedAt)
**Collection:** `chats`  
**Fields:** `travelerId` (Ascending), `updatedAt` (Descending)

URL: https://console.firebase.google.com/v1/r/project/flutter-ccc75/firestore/indexes?create_composite=Cktwcm9qZWN0cy9mbHV0dGVyLWNjYzc1L2RhdGFiYXNIcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9jaGF0cy9pbmRleGVzL18QARoOCgx0cmF2ZWxlcklkEAEaDQoJdXBkYXRlZEF0EAETjAoIX19uYW1lX18QAQ

**Used in:** Traveler chats list (`streamUserChats()` for travelers)

---

### 7. Chats - Agency Chats (agencyId + updatedAt)
**Collection:** `chats`  
**Fields:** `agencyId` (Ascending), `updatedAt` (Descending)

URL: https://console.firebase.google.com/v1/r/project/flutter-ccc75/firestore/indexes?create_composite=Cktwcm9qZWN0cy9mbHV0dGVyLWNjYzc1L2RhdGFiYXNIcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9jaGF0cy9pbmRleGVzL18QARoMCghhZ2VuY3lJZBABGg0KCXVwZGF0ZWRBdBABE4wKCF9fbmFtZV9fEAE

**Used in:** Agency chats list (`streamUserChats()` for agencies)

---

## Quick Steps:

1. **Open each URL above in your browser** (7 URLs total)
2. **Click "Create index"** for each one
3. **Wait for status to become "Enabled"** (check Firebase Console → Firestore → Indexes)
4. **Restart your app**

Once all indexes are enabled, all Firestore index errors will be resolved!

