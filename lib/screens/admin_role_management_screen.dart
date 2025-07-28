import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fyp/state/auth_provider.dart' as auth;
import 'package:fyp/widgets/food_app_bar.dart';
import 'package:fyp/services/admin_service.dart';

class AdminRoleManagementScreen extends StatefulWidget {
  const AdminRoleManagementScreen({super.key});

  @override
  State<AdminRoleManagementScreen> createState() =>
      _AdminRoleManagementScreenState();
}

class _AdminRoleManagementScreenState extends State<AdminRoleManagementScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedRoleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final users = await _adminService.getAllUsers();

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading users: $e')));
      }
    }
  }

  Future<void> _updateUserRole(String uid, String newRole) async {
    try {
      await _adminService.updateUserRole(uid, newRole);

      // Update local state
      setState(() {
        final userIndex = _users.indexWhere((user) => user['uid'] == uid);
        if (userIndex != -1) {
          _users[userIndex]['role'] = newRole;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role updated to $newRole'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRoleUpdateDialog(Map<String, dynamic> user) {
    String selectedRole = user['role'];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Update Role for ${user['name']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current email: ${user['email']}'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Select Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'customer',
                      child: Text('Customer'),
                    ),
                    DropdownMenuItem(value: 'staff', child: Text('Staff')),
                    DropdownMenuItem(value: 'kitchen', child: Text('Kitchen')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      selectedRole = value;
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _updateUserRole(user['uid'], selectedRole);
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  List<Map<String, dynamic>> get _filteredUsers {
    List<Map<String, dynamic>> filtered = _users;

    // Apply role filter
    if (_selectedRoleFilter != 'all') {
      filtered =
          filtered
              .where((user) => user['role'] == _selectedRoleFilter)
              .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((user) {
            final email = user['email'].toString().toLowerCase();
            final name = user['name'].toString().toLowerCase();
            final role = user['role'].toString().toLowerCase();
            final query = _searchQuery.toLowerCase();

            return email.contains(query) ||
                name.contains(query) ||
                role.contains(query);
          }).toList();
    }

    return filtered;
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

  String _getUserInitial(String? name, String? email) {
    if (name != null && name.isNotEmpty) {
      return name[0].toUpperCase();
    } else if (email != null && email.isNotEmpty) {
      return email.split('@')[0][0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<auth.AppAuthProvider>(context);

    // Check if current user is admin
    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: const FoodAppBar(
          showSearch: false,
          showCart: false,
          customTitle: 'Role Management',
        ),
        body: const Center(
          child: Text(
            'Access Denied. Admin privileges required.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const FoodAppBar(
        showSearch: false,
        showCart: false,
        customTitle: 'Role Management',
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Filters
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Search Bar
                        TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search users by email, name, or role...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        // Role Filter
                        DropdownButtonFormField<String>(
                          value: _selectedRoleFilter,
                          decoration: const InputDecoration(
                            labelText: 'Filter by Role',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('All Roles'),
                            ),
                            DropdownMenuItem(
                              value: 'customer',
                              child: Text('Customer'),
                            ),
                            DropdownMenuItem(
                              value: 'staff',
                              child: Text('Staff'),
                            ),
                            DropdownMenuItem(
                              value: 'kitchen',
                              child: Text('Kitchen'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedRoleFilter = value ?? 'all';
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Users List
                  Expanded(
                    child:
                        _filteredUsers.isEmpty
                            ? const Center(child: Text('No users found'))
                            : ListView.builder(
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _getRoleColor(
                                        user['role'],
                                      ),
                                      child: Text(
                                        _getUserInitial(
                                          user['name'],
                                          user['email'],
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      user['name'] ?? 'No Name',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(user['email'] ?? ''),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getRoleColor(
                                              user['role'],
                                            ).withAlpha(25),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            user['role'].toUpperCase(),
                                            style: TextStyle(
                                              color: _getRoleColor(
                                                user['role'],
                                              ),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed:
                                          () => _showRoleUpdateDialog(user),
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadUsers,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
