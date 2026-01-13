# Dummy Data Guide / ڈیمو ڈیٹا گائیڈ

## کیسے استعمال کریں / How to Use

### Step 1: App کو Debug Mode میں چلائیں
```bash
flutter run
```

### Step 2: Profile Screen پر جائیں
- Bottom navigation میں "Profile" پر tap کریں
- یا Account section میں جائیں

### Step 3: Debug Tools تلاش کریں
- Profile screen میں نیچے scroll کریں
- "Debug Tools" section نظر آئے گا (صرف debug mode میں)
- "Seed Dummy Data" button پر tap کریں

### Step 4: Confirm کریں
- Dialog box میں "Seed Data" button پر tap کریں
- کچھ seconds انتظار کریں

### Step 5: Results دیکھیں
**Completed Tours دیکھنے کے لیے:**
1. Bottom navigation میں "Bookings" پر tap کریں
2. "History" tab select کریں
3. آپ کو 5 completed tours نظر آئیں گے

**Reviews دیکھنے کے لیے:**
1. کسی بھی completed tour پر tap کریں
2. "Write a Review" یا "Edit Review" button نظر آئے گا
3. Tour detail pages پر بھی reviews نظر آئیں گے

## کیا Add ہوگا / What Gets Added

### ✅ 5 Completed Bookings
- مختلف dates کے ساتھ (پچھلے 2 مہینوں میں)
- مختلف prices: $100, $175, $250, $325, $400
- مختلف seats: 1-3 seats
- Payment methods: Credit Card اور PayPal

### ✅ 5 Detailed Reviews
- Ratings: زیادہ تر 4-5 stars
- تفصیلی comments (realistic tour reviews)
- Approved status (فوری طور پر visible)

### ✅ Additional Tour Reviews
- ہر tour کے لیے 2-4 sample reviews
- مختلف traveler names
- Varied ratings (3-5 stars)

## Important Notes / اہم نوٹس

⚠️ **یہ feature صرف Debug Mode میں کام کرتا ہے**
- Production build میں یہ button نظر نہیں آئے گا
- یہ صرف development اور demo کے لیے ہے

✅ **Duplicate Prevention**
- اگر پہلے سے dummy data موجود ہے تو دوبارہ add نہیں ہوگا
- آپ safely multiple times button press کر سکتے ہیں

🎯 **Perfect for University Project Demo**
- Completed tours section populated ہو جائے گا
- Reviews section realistic data کے ساتھ بھر جائے گا
- Professional presentation کے لیے بہترین

## Troubleshooting

### اگر data نظر نہیں آ رہا:
1. App کو restart کریں
2. Bookings screen پر pull-to-refresh کریں
3. Check کریں کہ tours database میں موجود ہیں

### اگر button نظر نہیں آ رہا:
1. Confirm کریں کہ debug mode میں چل رہا ہے
2. Profile screen میں نیچے تک scroll کریں
3. "Support" section کے بعد "Debug Tools" ہونا چاہیے

## Demo Presentation Tips

### اپنے Project کو Present کرتے وقت:

1. **پہلے Seed Data کریں** (presentation سے پہلے)
2. **Bookings History دکھائیں** - 5 completed tours
3. **Individual Reviews دکھائیں** - detailed feedback
4. **Tour Detail Pages دکھائیں** - multiple reviews per tour
5. **Write Review Feature دکھائیں** - fully functional

### Key Features to Highlight:
- ✅ Booking history with completed tours
- ✅ Review system with ratings
- ✅ Detailed user feedback
- ✅ Professional UI/UX
- ✅ Complete booking lifecycle

---

## Quick Commands

### Seed Data:
Profile → Debug Tools → Seed Dummy Data → Confirm

### View Completed Tours:
Bookings → History Tab

### View Reviews:
Tour Details → Reviews Section

---

**یہ feature آپ کے university project کو professional اور complete بنانے میں مدد کرے گا!** 🎓✨
