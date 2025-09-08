// lib/models/order.dart
import 'package:fyp/models/menu_item.dart';
import '../state/cart_provider.dart';

enum OrderStatus { pending, preparing, ready, completed, cancelled }

class Order {
  final String id;
  final String? orderId;
  final String? userId;
  final int? tableNumber;
  final List<CartItem> items;
  final double totalPrice;
  OrderStatus status;
  final DateTime createdAt;
  DateTime? completedAt;
  double priority = 0.0;

  // Flag to indicate if any items in this order are ready
  // This will be set by OrderProvider when calculating priorities
  bool hasReadyItems = false;

  // Map of item IDs to their individual statuses
  Map<String, OrderStatus> itemStatuses = {};

  // Kitchen and staff status tracking
  OrderStatus? kitchenStatus;
  OrderStatus? staffStatus;

  Order({
    required this.id,
    this.orderId,
    this.userId,
    this.tableNumber,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.kitchenStatus,
    this.staffStatus,
  });
  // Calculate order priority based on preparation time and parallel processing capability
  void calculatePriority() {
    if (items.isEmpty) {
      priority = 0.0;
      return;
    }

    // Calculate total preparation time
    double totalPrepTime = 0.0;
    int parallelGroups = 0;
    List<CartItem> remainingItems = List.from(items);

    while (remainingItems.isNotEmpty) {
      // Find items that can be prepared in parallel
      var parallelItems =
          remainingItems
              .where((item) => item.item.canPrepareInParallel)
              .toList();
      var serialItems =
          remainingItems
              .where((item) => !item.item.canPrepareInParallel)
              .toList();

      if (parallelItems.isNotEmpty) {
        // For parallel items, take the maximum preparation time
        double maxParallelTime = parallelItems
            .map((item) => item.item.preparationTime)
            .reduce((max, value) => max > value ? max : value);
        totalPrepTime += maxParallelTime;
        parallelGroups++;
      }

      if (serialItems.isNotEmpty) {
        // For serial items, add their preparation times
        totalPrepTime += serialItems
            .map((item) => item.item.preparationTime)
            .reduce((a, b) => a + b);
      }

      // Remove processed items
      remainingItems.removeWhere(
        (item) => parallelItems.contains(item) || serialItems.contains(item),
      );
    }

    // Calculate priority based on:
    // 1. Total preparation time (inversely proportional)
    // 2. Number of parallel groups (directly proportional)
    // 3. Wait time factor
    double prepTimeWeight =
        1.0 / (1.0 + totalPrepTime / 60.0); // Normalize to hour
    double parallelWeight = parallelGroups / items.length;
    double waitTimeFactor = _calculateWaitTimeFactor();

    priority =
        (prepTimeWeight * 0.5) +
        (parallelWeight * 0.3) +
        (waitTimeFactor * 0.2);
  }

  double _calculateWaitTimeFactor() {
    final waitTimeInMinutes = DateTime.now().difference(createdAt).inMinutes;
    return waitTimeInMinutes / 30.0; // Normalize to 30 minutes
  }

  // Check if the order is handled by the kitchen
  bool get isKitchenOrder {
    return items.any((item) => !_isStaffItem(item.item));
  }

  // Check if the order is handled by staff
  bool get isStaffOrder {
    return items.any((item) => _isStaffItem(item.item));
  }

  // Get order items handled by the kitchen
  List<CartItem> get kitchenItems {
    return items.where((item) => !_isStaffItem(item.item)).toList();
  }

  // Get order items handled by staff
  List<CartItem> get staffItems {
    return items.where((item) => _isStaffItem(item.item)).toList();
  }

  // Check if an item is handled by staff (beverages and desserts)
  bool _isStaffItem(MenuItem item) {
    return item.category.toLowerCase() == 'beverage' ||
        item.category.toLowerCase() == 'dessert';
  }

  // Get the total number of items in the order
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  // Order status text
  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Convert Order to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'tableNumber': tableNumber,
      'items':
          items
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
                    'canPrepareInParallel': cartItem.item.canPrepareInParallel,
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
      'totalPrice': totalPrice,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'priority': priority,
      'hasReadyItems': hasReadyItems,
      'isKitchenOrder': isKitchenOrder,
      'isStaffOrder': isStaffOrder,
      'kitchenStatus': kitchenStatus?.toString().split('.').last,
      'staffStatus': staffStatus?.toString().split('.').last,
    };
  }

  // Retain the original fromJson method but adjust it for the new model
  factory Order.fromJson(Map<dynamic, dynamic> json) {
    // Convert the item list in JSON to a list of MenuItem objects
    List<CartItem> items = [];
    if (json.containsKey('items') && json['items'] is List) {
      items =
          (json['items'] as List).map((itemData) {
            final menuItemData = itemData['menuItem'] as Map<String, dynamic>;
            final menuItem = MenuItem(
              id: menuItemData['id'],
              name: menuItemData['name'],
              description: menuItemData['description'],
              price: (menuItemData['price'] as num).toDouble(),
              category: menuItemData['category'],
              itemId: menuItemData['id'], // Using id as itemId for consistency
              imageUrl: menuItemData['imageUrl'] ?? '',
              preparationTime:
                  (menuItemData['preparationTime'] as num).toDouble(),
              canPrepareInParallel:
                  menuItemData['canPrepareInParallel'] ?? false,
              isPopular: menuItemData['isPopular'] ?? false,
              rating: (menuItemData['rating'] ?? 0).toDouble(),
              isDeleted: menuItemData['isDeleted'] ?? false,
              deletedAt:
                  menuItemData['deletedAt'] != null
                      ? DateTime.parse(menuItemData['deletedAt'])
                      : null,
            );

            return CartItem(
              item: menuItem,
              quantity: itemData['quantity'] ?? 1,
            );
          }).toList();
    }

    // Handle status conversion
    OrderStatus orderStatus;
    if (json.containsKey('status')) {
      String statusStr = json['status'].toString();
      switch (statusStr.toLowerCase()) {
        case 'pending':
          orderStatus = OrderStatus.pending;
          break;
        case 'preparing':
          orderStatus = OrderStatus.preparing;
          break;
        case 'ready':
          orderStatus = OrderStatus.ready;
          break;
        case 'completed':
          orderStatus = OrderStatus.completed;
          break;
        case 'cancelled':
          orderStatus = OrderStatus.cancelled;
          break;
        default:
          orderStatus = OrderStatus.pending;
      }
    } else {
      orderStatus = OrderStatus.pending;
    }

    return Order(
      id:
          json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      orderId: json['orderId']?.toString(),
      userId: json['userId']?.toString(),
      tableNumber:
          json['tableNumber'] != null
              ? int.parse(json['tableNumber'].toString())
              : null,
      items: items,
      totalPrice:
          json['totalPrice'] != null
              ? double.parse(json['totalPrice'].toString())
              : 0.0,
      status: orderStatus,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'].toString())
              : DateTime.now(),
      completedAt:
          json['completedAt'] != null
              ? DateTime.parse(json['completedAt'].toString())
              : null,
      kitchenStatus:
          json['kitchenStatus'] != null
              ? _parseOrderStatus(json['kitchenStatus'].toString())
              : null,
      staffStatus:
          json['staffStatus'] != null
              ? _parseOrderStatus(json['staffStatus'].toString())
              : null,
    );
  }

  // Helper method to parse OrderStatus from string
  static OrderStatus _parseOrderStatus(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}
