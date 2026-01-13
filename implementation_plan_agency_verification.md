# Implementation Plan - Agency Profile & Verification System

This plan outlines the steps to implement a comprehensive Agency Profile and Verification system for the TourEase Flutter application.

## 1. Model Updates
- [ ] **UserModel (lib/models/user_model.dart)**:
    - Add fields: `ownerName`, `cnicFrontUrl`, `cnicBackUrl`, `businessLicenseUrl`, `accreditationId`.
    - Map `name` as `agencyName` and `photoUrl` as `logoUrl` for internal consistency if needed, or simply clarify usage.
    - Update `fromFirestore`, `toFirestore`, and `copyWith`.

## 2. Agency Profile Editing (Agency Side)
- [ ] **EditAgencyProfileScreen (lib/screens/agency/edit_profile_screen.dart)**:
    - Add FormFields for:
        - Basic: Agency Name, Owner Name, Description, City, Country.
        - Contact: Phone (required), WhatsApp, Office Address.
        - Verification (Docs): CNIC Front, CNIC Back, Business License.
        - Trust: Years of Experience (int), Accreditation ID, Specialized Destinations (Multi-select/Chips).
    - Implement Cloudinary upload for multiple documents.
    - Add validation and loading states.

## 3. Admin Verification Flow (Admin Side)
- [ ] **Agency Management Screen (lib/screens/admin/agency_management_screen.dart)**:
    - Update list to show status badges (Pending, Verified, Rejected).
    - Create a detailed view for agency approval:
        - View all profile info.
        - Preview uploaded documents.
        - Implement "Approve" and "Reject" actions.
        - Add "Rejection Reason" dialog.

## 4. Traveler Visibility & Trust
- [ ] **Filtering Queries**:
    - Update `TourService.getTours()` and other relevant fetch methods to filter for `verified == true` and `status == "verified"`.
    - Update `AuthService` or relevant service for fetching agencies.
- [ ] **Verified Badge**:
    - Add a "Verified" badge widget to be used in tour lists and agency profiles.

## 5. Verification & Cleanup
- [ ] Run `flutter analyze` to ensure no lint/type errors.
- [ ] Manual verification of the entire flow.

---
**Status**: Initializing models...
