import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart' as order_model;
import '../models/menu_item.dart';
import '../state/cart_provider.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'orders';

  /// Create a new order in Firestore
  Future<String> createOrder(order_model.Order order) async {
    try {
      final docRef = _firestore.collection(_collection).doc();

      // Prepare order data for Firestore
      final orderData = {
        'id': docRef.id,
        'userId': order.userId ?? _auth.currentUser?.uid,
        'userEmail': _auth.currentUser?.email,
        'tableNumber': order.tableNumber,
        'items':
            order.items
                .map(
                  (cartItem) => {
                    'menuItem': {
                      'id': cartItem.item.id,
                      'name': cartItem.item.name,
                      'description': cartItem.item.description,
                      'price': cartItem.item.price,
                      'category': cartItem.item.category,
                      'imageUrl': cartItem.item.imageUrl,
                      'preparationTime': cartItem.item.preparationTime,
                      'canPrepareInParallel':
                          cartItem.item.canPrepareInParallel,
                      'isPopular': cartItem.item.isPopular,
                      'rating': cartItem.item.rating,
                      'isDeleted': cartItem.item.isDeleted,
                      'deletedAt': cartItem.item.deletedAt?.toIso8601String(),
                    },
                    'quantity': cartItem.quantity,
                    'totalPrice': cartItem.totalPrice,
                  },
                )
                .toList(),
        'totalPrice': order.totalPrice,
        'status':
            order.status.toString().split('.').last, // Convert enum to string
        'createdAt': FieldValue.serverTimestamp(),
        'completedAt': order.completedAt?.toIso8601String(),
        'priority': order.priority,
        'hasReadyItems': order.hasReadyItems,
        // Kitchen and staff status tracking
        'kitchenStatus': 'pending',
        'staffStatus': 'pending',
        // Individual item status tracking
        'itemStatuses': {
          for (var cartItem in order.items) cartItem.item.id: 'pending',
        },
        // Metadata
        'isKitchenOrder': order.isKitchenOrder,
        'isStaffOrder': order.isStaffOrder,
      };

      await docRef.set(orderData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Update order status in Firestore
  Future<void> updateOrderStatus(
    String orderId,
    order_model.OrderStatus status,
  ) async {
    try {
      await _firestore.collection(_collection).doc(orderId).update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
        if (status == order_model.OrderStatus.completed)
          'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  /// Update kitchen status for an order
  Future<void> updateKitchenStatus(
    String orderId,
    order_model.OrderStatus status,
  ) async {
    try {
      await _firestore.collection(_collection).doc(orderId).update({
        'kitchenStatus': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update kitchen status: $e');
    }
  }

  /// Check if all staff items in an order are ready
  Future<bool> areAllStaffItemsReady(String orderId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(orderId).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final itemStatuses = data['itemStatuses'] as Map<String, dynamic>? ?? {};
      final items = data['items'] as List<dynamic>? ?? [];

      // Get all staff item IDs
      final staffItemIds = <String>[];
      for (var item in items) {
        final menuItem = item['menuItem'] as Map<String, dynamic>;
        final category = menuItem['category']?.toString().toLowerCase() ?? '';
        if (category == 'beverage' || category == 'dessert') {
          staffItemIds.add(menuItem['id']);
        }
      }

      // Check if all staff items are ready
      for (var itemId in staffItemIds) {
        final status = itemStatuses[itemId] as String?;
        if (status != 'ready') {
          return false;
        }
      }

      return staffItemIds
          .isNotEmpty; // Only return true if there are staff items and all are ready
    } catch (e) {
      return false;
    }
  }

  /// Check if all kitchen items in an order are ready
  Future<bool> areAllKitchenItemsReady(String orderId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(orderId).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final itemStatuses = data['itemStatuses'] as Map<String, dynamic>? ?? {};
      final items = data['items'] as List<dynamic>? ?? [];

      // Get all kitchen item IDs
      final kitchenItemIds = <String>[];
      for (var item in items) {
        final menuItem = item['menuItem'] as Map<String, dynamic>;
        final category = menuItem['category']?.toString().toLowerCase() ?? '';
        if (category != 'beverage' && category != 'dessert') {
          kitchenItemIds.add(menuItem['id'].toString());
        }
      }

      // Check if all kitchen items are ready
      for (var itemId in kitchenItemIds) {
        final status = itemStatuses[itemId] as String?;
        if (status != 'ready') {
          return false;
        }
      }

      final result = kitchenItemIds.isNotEmpty;
      return result; // Only return true if there are kitchen items and all are ready
    } catch (e) {
      return false;
    }
  }

  /// Check if an order should be completed based on kitchen and staff status
  Future<bool> shouldCompleteOrder(String orderId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(orderId).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final isKitchenOrder = data['isKitchenOrder'] as bool? ?? false;
      final isStaffOrder = data['isStaffOrder'] as bool? ?? false;
      final kitchenStatus = data['kitchenStatus'] as String?;
      final staffStatus = data['staffStatus'] as String?;

      // Debug: Print items and their categories
      // final items = data['items'] as List<dynamic>? ?? [];

      // If it's only a kitchen order, complete when kitchen is ready
      if (isKitchenOrder && !isStaffOrder) {
        return kitchenStatus == 'ready';
      }

      // If it's only a staff order, complete when staff is ready
      if (isStaffOrder && !isKitchenOrder) {
        return staffStatus == 'ready';
      }

      // If it's a mixed order, complete when both are ready
      if (isKitchenOrder && isStaffOrder) {
        return kitchenStatus == 'ready' && staffStatus == 'ready';
      }
      return false;
    } catch (e) {
      throw Exception('Failed to check order completion status: $e');
    }
  }

  /// Update staff status for an order
  Future<void> updateStaffStatus(
    String orderId,
    order_model.OrderStatus status,
  ) async {
    try {
      final statusString = status.toString().split('.').last;
      await _firestore.collection(_collection).doc(orderId).update({
        'staffStatus': statusString,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update staff status: $e');
    }
  }

  /// Update individual item status
  Future<void> updateItemStatus(
    String orderId,
    String itemId,
    order_model.OrderStatus status,
  ) async {
    try {
      await _firestore.collection(_collection).doc(orderId).update({
        'itemStatuses.$itemId': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update item status: $e');
    }
  }

  /// Update order priority in Firestore
  Future<void> updateOrderPriority(String orderId, double priority) async {
    try {
      await _firestore.collection(_collection).doc(orderId).update({
        'priority': priority,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update order priority: $e');
    }
  }

  /// Recalculate and update priorities for all active orders
  Future<void> updateAllOrderPriorities() async {
    try {
      final snapshot =
          await _firestore
              .collection(_collection)
              .where('status', whereIn: ['pending', 'preparing', 'ready'])
              .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        final order = _orderFromFirestore(doc);
        order.calculatePriority();

        batch.update(doc.reference, {
          'priority': order.priority,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update all order priorities: $e');
    }
  }

  /// Get all active orders (for admin/dashboard)
  Stream<List<order_model.Order>> getActiveOrders() {
    return _firestore
        .collection(_collection)
        .where('status', whereIn: ['pending', 'preparing', 'ready'])
        .snapshots()
        .map((snapshot) {
          final orders =
              snapshot.docs.map((doc) => _orderFromFirestore(doc)).toList();
          // Sort client-side by createdAt to avoid composite index requirement
          orders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return orders;
        });
  }

  /// Get orders for kitchen (orders with kitchen items and not completed)
  Stream<List<order_model.Order>> getKitchenOrders() {
    return _firestore
        .collection(_collection)
        .where('isKitchenOrder', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final orders =
              snapshot.docs
                  .map((doc) => _orderFromFirestore(doc))
                  .where(
                    (order) =>
                        order.status != order_model.OrderStatus.completed &&
                        order.status != order_model.OrderStatus.cancelled,
                  )
                  .toList();

          // Recalculate priority for real-time updates and sort
          for (var order in orders) {
            order.calculatePriority();
          }
          // Sort by priority (higher priority first)
          orders.sort((a, b) => b.priority.compareTo(a.priority));
          return orders;
        });
  }

  /// Get orders for staff (orders with staff items and not completed)
  Stream<List<order_model.Order>> getStaffOrders() {
    return _firestore
        .collection(_collection)
        .where('isStaffOrder', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final orders =
              snapshot.docs
                  .map((doc) => _orderFromFirestore(doc))
                  .where(
                    (order) =>
                        order.status != order_model.OrderStatus.completed &&
                        order.status != order_model.OrderStatus.cancelled,
                  )
                  .toList();

          // Recalculate priority for real-time updates and sort
          for (var order in orders) {
            order.calculatePriority();
          }
          // Sort by priority (higher priority first)
          orders.sort((a, b) => b.priority.compareTo(a.priority));
          return orders;
        });
  }

  /// Get completed orders for history
  Stream<List<order_model.Order>> getCompletedOrders() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'completed')
        .limit(50) // Limit to recent 50 orders
        .snapshots()
        .map((snapshot) {
          final orders =
              snapshot.docs.map((doc) => _orderFromFirestore(doc)).toList();

          // Debug logging
          // for (var order in orders) {}

          // Sort client-side by completedAt to avoid composite index requirement
          orders.sort((a, b) {
            if (a.completedAt == null && b.completedAt == null) return 0;
            if (a.completedAt == null) return 1;
            if (b.completedAt == null) return -1;
            return b.completedAt!.compareTo(a.completedAt!);
          });
          return orders;
        });
  }

  /// Get completed staff orders for history
  Stream<List<order_model.Order>> getCompletedStaffOrders() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'completed')
        .limit(50) // Limit to recent 50 orders
        .snapshots()
        .map((snapshot) {
          // Filter for staff orders client-side to avoid composite index
          final orders =
              snapshot.docs
                  .map((doc) => _orderFromFirestore(doc))
                  .where((order) => order.isStaffOrder)
                  .toList();

          // Debug logging
          // for (var order in orders) {}

          // Sort client-side by completedAt to avoid composite index requirement
          orders.sort((a, b) {
            if (a.completedAt == null && b.completedAt == null) return 0;
            if (a.completedAt == null) return 1;
            if (b.completedAt == null) return -1;
            return b.completedAt!.compareTo(a.completedAt!);
          });
          return orders;
        });
  }

  /// Get orders for a specific user
  Stream<List<order_model.Order>> getUserOrders(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final orders =
              snapshot.docs.map((doc) => _orderFromFirestore(doc)).toList();
          // Sort client-side by createdAt to avoid composite index requirement
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  /// Get all orders for a specific table (for order status screen)
  Stream<List<order_model.Order>> getTableOrders(int tableNumber) {
    return _firestore
        .collection(_collection)
        .where('tableNumber', isEqualTo: tableNumber)
        .snapshots()
        .map((snapshot) {
          final orders =
              snapshot.docs.map((doc) => _orderFromFirestore(doc)).toList();
          // Sort client-side by createdAt to avoid composite index requirement
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  /// Get a specific order by ID
  Future<order_model.Order?> getOrder(String orderId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(orderId).get();
      if (doc.exists) {
        return _orderFromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  /// Delete an order (for admin purposes)
  Future<void> deleteOrder(String orderId) async {
    try {
      await _firestore.collection(_collection).doc(orderId).delete();
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }

  /// Convert Firestore document to Order object
  order_model.Order _orderFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convert items from Firestore format
    final List<CartItem> items =
        (data['items'] as List<dynamic>).map((itemData) {
          final menuItemData = itemData['menuItem'] as Map<String, dynamic>;

          final menuItem = MenuItem(
            id: menuItemData['id'] ?? '',
            name: menuItemData['name'] ?? '',
            description: menuItemData['description'] ?? '',
            price: (menuItemData['price'] as num?)?.toDouble() ?? 0.0,
            category: menuItemData['category'] ?? '',
            itemId: menuItemData['id'] ?? '', // Using id as itemId
            imageUrl: menuItemData['imageUrl'] ?? '',
            preparationTime:
                (menuItemData['preparationTime'] as num?)?.toDouble() ?? 0.0,
            canPrepareInParallel: menuItemData['canPrepareInParallel'] ?? false,
            rating: (menuItemData['rating'] as num?)?.toDouble(),
            isPopular: menuItemData['isPopular'] ?? false,
            isDeleted: menuItemData['isDeleted'] ?? false,
            deletedAt:
                menuItemData['deletedAt'] != null
                    ? DateTime.parse(menuItemData['deletedAt'])
                    : null,
          );

          return CartItem(
            item: menuItem,
            quantity: (itemData['quantity'] as num?)?.toInt() ?? 1,
          );
        }).toList();

    // Convert status from string to enum
    order_model.OrderStatus status = order_model.OrderStatus.pending;
    final statusString = data['status'] as String?;
    if (statusString != null) {
      status = order_model.OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == statusString,
        orElse: () => order_model.OrderStatus.pending,
      );
    }

    // Handle Firestore timestamp
    DateTime createdAt = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      createdAt = DateTime.parse(data['createdAt']);
    }

    DateTime? completedAt;
    if (data['completedAt'] is Timestamp) {
      completedAt = (data['completedAt'] as Timestamp).toDate();
    } else if (data['completedAt'] is String) {
      completedAt = DateTime.parse(data['completedAt']);
    }

    // Load item statuses from Firestore
    final Map<String, order_model.OrderStatus> itemStatuses = {};
    final itemStatusesData = data['itemStatuses'] as Map<String, dynamic>?;
    if (itemStatusesData != null) {
      itemStatusesData.forEach((itemId, statusString) {
        if (statusString is String) {
          final itemStatus = order_model.OrderStatus.values.firstWhere(
            (e) => e.toString().split('.').last == statusString,
            orElse: () => order_model.OrderStatus.pending,
          );
          itemStatuses[itemId] = itemStatus;
        }
      });
    }

    // Parse kitchen and staff status
    order_model.OrderStatus? kitchenStatus;
    final kitchenStatusString = data['kitchenStatus'] as String?;
    if (kitchenStatusString != null) {
      kitchenStatus = order_model.OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == kitchenStatusString,
        orElse: () => order_model.OrderStatus.pending,
      );
    }

    order_model.OrderStatus? staffStatus;
    final staffStatusString = data['staffStatus'] as String?;
    if (staffStatusString != null) {
      staffStatus = order_model.OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == staffStatusString,
        orElse: () => order_model.OrderStatus.pending,
      );
    }

    return order_model.Order(
        id: doc.id,
        orderId: data['id'] as String?,
        userId: data['userId'] as String?,
        tableNumber: data['tableNumber'] as int?,
        items: items,
        totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
        status: status,
        createdAt: createdAt,
        completedAt: completedAt,
        kitchenStatus: kitchenStatus,
        staffStatus: staffStatus,
      )
      ..priority = (data['priority'] as num?)?.toDouble() ?? 0.0
      ..hasReadyItems = data['hasReadyItems'] as bool? ?? false
      ..itemStatuses = itemStatuses;
  }

  /// Get kitchen status for an order
  order_model.OrderStatus getKitchenStatus(String orderId) {
    // This would need to be called with the cached order data
    // For now, return pending as default
    return order_model.OrderStatus.pending;
  }

  /// Get staff status for an order
  order_model.OrderStatus getStaffStatus(String orderId) {
    // This would need to be called with the cached order data
    // For now, return pending as default
    return order_model.OrderStatus.pending;
  }

  /// Get item status for a specific item in an order
  order_model.OrderStatus getItemStatus(String orderId, String itemId) {
    // This would need to be called with the cached order data
    // For now, return pending as default
    return order_model.OrderStatus.pending;
  }

  /// Real-time listener for order updates
  Stream<order_model.Order> watchOrder(String orderId) {
    return _firestore
        .collection(_collection)
        .doc(orderId)
        .snapshots()
        .map((doc) => _orderFromFirestore(doc));
  }

  /// Get order statistics for dashboard
  Future<Map<String, int>> getOrderStatistics() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();

      int pending = 0;
      int preparing = 0;
      int ready = 0;
      int completed = 0;

      for (var doc in snapshot.docs) {
        final status = doc.data()['status'] as String?;
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'preparing':
            preparing++;
            break;
          case 'ready':
            ready++;
            break;
          case 'completed':
            completed++;
            break;
        }
      }

      return {
        'pending': pending,
        'preparing': preparing,
        'ready': ready,
        'completed': completed,
        'total': snapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get order statistics: $e');
    }
  }
}
