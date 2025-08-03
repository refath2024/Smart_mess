# Firebase Functions Deployment Guide

## Overview
The Firebase Cloud Functions have been set up to automatically handle Firebase Auth user deletion when staff members are deleted from the admin panel, with **PMC protection** to prevent accidental deletion of super admin accounts.

## What the Functions Do

### 1. `onStaffDeleted` (Automatic Trigger)
- **Trigger**: Automatically runs when a document is deleted from the `staff_state` collection
- **Purpose**: Cleans up Firebase Auth accounts and user documents
- **PMC Protection**: Logs critical alerts if PMC account is somehow deleted
- **Actions**:
  - Deletes the Firebase Auth user account associated with the deleted staff member's email
  - Removes any documents from the `users` collection with the same email
  - Logs all operations for debugging

### 2. `deleteUserByEmail` (Manual Callable Function)
- **Trigger**: Can be called manually from the app (requires cloud_functions package)
- **Purpose**: Allows admins to manually delete Firebase Auth users
- **Security**: Only admins with roles PMC, G2 (Mess), or Mess Secretary can call this function
- **PMC Protection**: Prevents deletion of PMC accounts with specific error message

## PMC Protection Features

### Frontend Protection (Flutter App):
1. **Delete Button**: PMC accounts show disabled (grey) delete button with explanatory tooltip
2. **Safety Check**: `_deleteStaff()` function has early return for PMC roles
3. **User Feedback**: Clear error message if PMC deletion is attempted

### Backend Protection (Cloud Functions):
1. **Manual Function**: `deleteUserByEmail` checks target user role before deletion
2. **Automatic Trigger**: Logs critical alerts if PMC somehow gets deleted
3. **Error Handling**: Returns specific error messages for PMC deletion attempts

## Deployment Steps

1. **Install Firebase CLI** (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Navigate to functions directory**:
   ```bash
   cd "d:\App Dev\S-M\Smart_mess\functions"
   ```

4. **Deploy the functions**:
   ```bash
   firebase deploy --only functions
   ```

## How It Works in the App

### For Regular Staff Members:
1. ✅ **Flutter App**: Delete button is enabled and functional
2. ✅ **Firestore**: Document deleted from `staff_state` collection  
3. ✅ **Cloud Function**: Automatically triggered and deletes Firebase Auth account
4. ✅ **Result**: Complete cleanup, no email conflicts

### For PMC Accounts:
1. 🔒 **Flutter App**: Delete button is disabled (grey) with protective tooltip
2. 🔒 **Safety Check**: If somehow triggered, shows error message and stops
3. 🔒 **Cloud Function**: Additional backend check prevents PMC deletion
4. 🔒 **Result**: PMC account is fully protected from accidental deletion

## Testing

After deployment, test by:
1. **Regular Staff**: Create and delete a test non-PMC staff member ✅
2. **PMC Protection**: Try to delete PMC account - should be blocked 🔒
3. **Email Reuse**: Create new staff with previously deleted email ✅

## Logs and Monitoring

You can view function logs in the Firebase Console:
1. Go to Firebase Console > Functions
2. Click on the function name
3. View logs to see execution details
4. Look for 🚨 CRITICAL alerts if PMC deletion is attempted

## Security Benefits

- **System Access**: Ensures at least one super admin always exists
- **Multi-layer Protection**: Both frontend and backend safeguards
- **Clear Feedback**: Users understand why PMC can't be deleted
- **Audit Trail**: All deletion attempts are logged for security monitoring

## Notes

- Requires Firebase Blaze plan for Cloud Functions
- The automatic trigger (`onStaffDeleted`) works immediately after deployment
- No additional code changes needed in the Flutter app
- Functions handle error cases gracefully (e.g., user already deleted)
- All operations are logged for debugging and security monitoring
