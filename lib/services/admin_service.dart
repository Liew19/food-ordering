import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all users with their roles
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final QuerySnapshot querySnapshot =
          await _firestore.collection('users').get();
      final List<Map<String, dynamic>> users = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        users.add({
          'uid': doc.id,
          'email': data['email'] ?? '',
          'name': data['name'] ?? '',
          'role': data['role'] ?? 'customer',
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
        });
      }

      return users;
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  // Update user role
  Future<void> updateUserRole(String uid, String newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  // Get user statistics
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final users = await getAllUsers();
      final Map<String, int> stats = {};

      for (final user in users) {
        final role = user['role'] ?? 'customer';
        stats[role] = (stats[role] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get user statistics: $e');
    }
  }

  // Get order statistics
  Future<Map<String, dynamic>> getOrderStatistics() async {
    try {
      final QuerySnapshot querySnapshot =
          await _firestore.collection('orders').get();
      final List<Map<String, dynamic>> orders = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        orders.add({
          'status': data['status'] ?? 'pending',
          'total': data['total'] ?? 0.0,
          'createdAt': data['createdAt'],
        });
      }

      // Calculate statistics
      final totalOrders = orders.length;
      final pendingOrders =
          orders.where((order) => order['status'] == 'pending').length;
      final completedOrders =
          orders.where((order) => order['status'] == 'completed').length;
      final totalRevenue = orders.fold<double>(
        0.0,
        (sum, order) => sum + (order['total'] ?? 0.0),
      );

      return {
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'completedOrders': completedOrders,
        'totalRevenue': totalRevenue,
      };
    } catch (e) {
      throw Exception('Failed to get order statistics: $e');
    }
  }

  // Delete user (admin only)
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // Get user by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final QuerySnapshot querySnapshot =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        return {
          'uid': doc.id,
          'email': data['email'] ?? '',
          'name': data['name'] ?? '',
          'role': data['role'] ?? 'customer',
          'createdAt': data['createdAt'],
        };
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get user by email: $e');
    }
  }
}
