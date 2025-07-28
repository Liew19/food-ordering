import 'package:flutter/material.dart';
import 'package:fyp/screens/admin_notifications_screen.dart';
import 'package:fyp/screens/admin_role_management_screen.dart';
import 'package:fyp/widgets/food_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:fyp/state/auth_provider.dart' as auth;
import 'package:fyp/screens/login_screen.dart';
import '../main.dart';
import 'package:fyp/screens/edit_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<auth.AppAuthProvider>(context);
    final user = authProvider.user;
    final userEmail = user?.email ?? 'Guest User';
    final userRole = authProvider.role ?? 'customer';

    return Scaffold(
      appBar: const FoodAppBar(
        showSearch: false,
        showCart: true,
        customTitle: 'Profile',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User profile header
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // User avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    child:
                        user != null
                            ? Text(
                              userEmail.isNotEmpty
                                  ? userEmail[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            )
                            : const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.black54,
                            ),
                  ),
                  const SizedBox(height: 16),

                  // User name and email from Firestore
                  user != null
                      ? StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }
                          final data = snapshot.data!.data();
                          final name =
                              data != null &&
                                      data['name'] != null &&
                                      (data['name'] as String).isNotEmpty
                                  ? data['name'] as String
                                  : userEmail.split('@')[0];
                          final gender = data?['gender'] ?? 'other';
                          IconData genderIcon;
                          Color genderColor;
                          switch (gender) {
                            case 'male':
                              genderIcon = Icons.male;
                              genderColor = Colors.blue;
                              break;
                            case 'female':
                              genderIcon = Icons.female;
                              genderColor = Colors.pink;
                              break;
                            default:
                              genderIcon = Icons.person;
                              genderColor = Colors.grey;
                          }
                          return Column(
                            children: [
                              Icon(genderIcon, size: 32, color: genderColor),
                              SizedBox(height: 8),
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userEmail,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          );
                        },
                      )
                      : Column(
                        children: [
                          Text(
                            'Guest User',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  const SizedBox(height: 4),

                  // User role
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getRoleColor(userRole).withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _capitalizeRole(userRole),
                      style: TextStyle(
                        color: _getRoleColor(userRole),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Edit profile button
                  SizedBox(
                    width: 150,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero, // 直角
                        ),
                      ),
                      child: const Text('Edit Profile'),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Settings options
            _buildSettingItem(
              context,
              icon: Icons.history,
              title: 'Order History',
              onTap: () {
                // Navigate to the Orders tab (index 2)
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const MainScreen(initialIndex: 2),
                  ),
                );
              },
            ),

            // Admin notifications (only for admin and staff)
            if (userRole == 'admin' || userRole == 'staff')
              _buildSettingItem(
                context,
                icon: Icons.notifications,
                title: 'Admin Notifications',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminNotificationsScreen(),
                    ),
                  );
                },
              ),

            // Admin role management (only for admin)
            if (userRole == 'admin')
              _buildSettingItem(
                context,
                icon: Icons.people,
                title: 'Manage Roles',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminRoleManagementScreen(),
                    ),
                  );
                },
              ),

            _buildSettingItem(
              context,
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon')),
                );
              },
            ),

            const Divider(),

            // Log out button
            _buildSettingItem(
              context,
              icon: Icons.logout,
              title: 'Log Out',
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () async {
                // Show confirmation dialog
                final shouldLogout =
                    await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Log Out'),
                            content: const Text(
                              'Are you sure you want to log out?',
                            ),
                            actions: [
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                child: const Text(
                                  'Log Out',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                    ) ??
                    false;

                if (shouldLogout) {
                  if (context.mounted) {
                    await authProvider.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  }
                }
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.black54),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black45),
      onTap: onTap,
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'kitchen':
        return Colors.orange;
      case 'staff':
        return Colors.blue;
      case 'customer':
      default:
        return Colors.green;
    }
  }

  String _capitalizeRole(String role) {
    if (role.isEmpty) return '';
    return role[0].toUpperCase() + role.substring(1);
  }
}
