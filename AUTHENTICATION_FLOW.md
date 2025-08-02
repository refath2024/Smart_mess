# Smart Mess Authentication Flow

## Overview
The Smart Mess system uses a two-stage authentication process where users register first, then admin approval creates their Firebase Auth credentials.

## Complete Flow

### 1. User Registration (`register_screen.dart`)
- User fills registration form with email, password, name, etc.
- System creates Firestore document in `user_requests` collection
- **No Firebase Auth user is created at this stage**
- Document fields:
  ```dart
  {
    'email': email,
    'name': name,
    'password': password, // Stored temporarily for auth creation
    'status': 'pending',
    'firebase_auth_created': false,
    'approved': false,
    'created_at': timestamp
  }
  ```

### 2. Admin Review (`admin_pending_ids_screen.dart`)
- Admin views pending user registrations
- Admin can approve or reject applications

#### When Admin Approves:
1. **Firebase Auth Creation**:
   - Creates Firebase Auth user with stored email
   - Uses temporary password: `TempPass123!`
   - Updates user display name
   - Sends password reset email to user

2. **Firestore Update**:
   ```dart
   {
     'approved': true,
     'status': 'active',
     'firebase_auth_created': true,
     'approved_at': timestamp,
     'approved_by': admin_name
   }
   ```

#### When Admin Rejects:
- Updates status to 'rejected'
- No Firebase Auth user is created

### 3. User Login (`login_screen.dart` + `user_auth_service.dart`)
1. **Firestore Check**:
   - Queries `user_requests` collection by email
   - Checks user status:
     - `pending`: Shows "pending approval" message
     - `rejected`: Shows "registration rejected" message
     - `active`: Proceeds to Firebase Auth

2. **Firebase Auth**:
   - Only attempts Firebase Auth if status is 'active'
   - Uses Firebase `signInWithEmailAndPassword()`
   - Returns user data and UID on success

## Key Benefits

### Security
- No Firebase Auth users created for unapproved registrations
- Admin control over who gets access
- Password reset required on first login (secure temporary password)

### User Experience
- Clear status messages during login
- Users know exactly where they stand in the approval process
- Automatic password reset email after approval

### Admin Control
- Full visibility of pending registrations
- Easy approval/rejection workflow
- Audit trail with approval timestamps and admin names

## Database Schema

### user_requests Collection
```dart
{
  'email': String,
  'name': String,
  'password': String, // Temporary, used for auth creation
  'division': String,
  'rank': String,
  'unit': String,
  'company': String,
  'appointment': String,
  'phone': String,
  'status': String, // 'pending', 'active', 'rejected'
  'approved': Boolean,
  'firebase_auth_created': Boolean,
  'created_at': Timestamp,
  'approved_at': Timestamp?, // Only set when approved
  'approved_by': String?, // Admin who approved
}
```

## Error Handling

### Registration
- Validates all required fields
- Checks for duplicate emails
- Graceful error messages

### Approval Process
- Handles Firebase Auth creation errors
- Deals with "email already in use" gracefully
- Comprehensive error logging and user feedback

### Login
- Provides specific error messages based on status
- Handles network and authentication errors
- Clear guidance for next steps

## Security Considerations

1. **Temporary Password**: `TempPass123!` is only used briefly
2. **Password Reset**: Immediately sent after auth creation
3. **No Auth Without Approval**: Prevents unauthorized access
4. **Status-Based Access**: Multiple layers of verification
5. **Admin Audit Trail**: All approvals are logged

## Future Enhancements

1. **Email Notifications**: Notify users of approval/rejection
2. **Batch Operations**: Approve/reject multiple users at once
3. **Advanced Filters**: Filter pending users by division, rank, etc.
4. **Role-Based Admin**: Different admin permission levels
5. **Auto-Cleanup**: Remove old rejected/pending registrations

This authentication flow ensures security while providing a smooth user experience and complete administrative control.
