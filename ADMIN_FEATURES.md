# Admin Features Documentation

## Overview
The food ordering app includes admin functionality that allows administrators to manage user roles. Only users with the 'admin' role can access these features.

## Admin Features

### Role Management Screen
**Location**: Profile Screen → Manage Roles (admin only)

**Features**:
- Dedicated interface for role management
- Filter users by role (All, Customer, Staff, Kitchen, Admin)
- Search users by email, name, or role
- Update user roles with dropdown selection
- Real-time role updates

## User Roles

### Available Roles:
1. **Customer** (default)
   - Can place orders
   - Can make reservations
   - Can view order history

2. **Staff**
   - Can view admin notifications
   - Can manage orders
   - Can manage reservations

3. **Kitchen**
   - Can view kitchen screen
   - Can update order status
   - Can manage food preparation

4. **Admin**
   - Full access to all features
   - Can manage user roles
   - Can delete users

## Security Features

### Firestore Security Rules
The app includes comprehensive security rules that:
- Only allow admins to read and update user roles
- Prevent users from modifying their own roles
- Allow role-based access to different collections
- Protect sensitive operations with proper authentication

### Access Control
- Admin features are only visible to users with 'admin' role
- Role checks are performed both on the client and server side
- Unauthorized access attempts show "Access Denied" message

## How to Use

### For Administrators:

1. **Access Admin Features**:
   - Log in with an admin account
   - Go to Profile screen
   - You'll see "Manage Roles" option

2. **Manage User Roles**:
   - Navigate to "Manage Roles"
   - Search for users or filter by role
   - Click the edit icon next to a user
   - Select new role from dropdown
   - Confirm the change

### For Other Users:
- Non-admin users will not see admin options in the profile screen
- Attempting to access admin URLs directly will show access denied message

## Technical Implementation

### Files Created/Modified:
1. `lib/screens/admin_role_management_screen.dart` - Role management interface
2. `lib/services/admin_service.dart` - Admin service for backend operations
3. `lib/screens/profile_screen.dart` - Added admin navigation options
4. `firestore.rules` - Updated security rules

### Key Components:
- **AdminService**: Handles all admin-related Firestore operations
- **Role-based UI**: Different screens show different options based on user role
- **Real-time updates**: Changes are reflected immediately in the UI
- **Error handling**: Comprehensive error handling with user feedback

## Security Considerations

1. **Role Verification**: All admin operations verify the user's role before proceeding
2. **Firestore Rules**: Server-side security rules prevent unauthorized access
3. **Input Validation**: All user inputs are validated before processing
4. **Audit Trail**: Role changes are timestamped in Firestore

## Future Enhancements

Potential improvements for the admin system:
1. User activity logs
2. Bulk role updates
3. User invitation system
4. Role-based permissions matrix
5. Audit trail for all admin actions 