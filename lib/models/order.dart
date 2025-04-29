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

    // Calculate wait time factor with exponential growth
    double waitTimeFactor = _calculateWaitTimeFactor();

    // Dynamic weights based on system load
    double systemLoadFactor = _calculateSystemLoadFactor();

    // Preparation time score (inverse relationship - shorter prep time = higher score)
    double prepTimeScore =
        1.0 / (1.0 + totalPrepTime / 30.0); // Normalized to 30 minutes

    // Parallel processing efficiency score
    double parallelScore =
        parallelGroups > 0 ? parallelGroups / items.length : 0.0;

    // Wait time score with exponential growth
    double waitTimeScore = 1.0 - (1.0 / (1.0 + waitTimeFactor));

    // Dynamic priority calculation
    if (systemLoadFactor < 0.3) {
      // Light load - favor FCFS
      priority =
          (waitTimeScore * 0.7) + (prepTimeScore * 0.2) + (parallelScore * 0.1);
    } else if (systemLoadFactor < 0.7) {
      // Medium load - balanced approach
      priority =
          (waitTimeScore * 0.4) + (prepTimeScore * 0.4) + (parallelScore * 0.2);
    } else {
      // Heavy load - favor SJF with parallel processing
      priority =
          (waitTimeScore * 0.2) + (prepTimeScore * 0.5) + (parallelScore * 0.3);
    }

    // Boost priority for orders with ready items
    if (hasReadyItems) {
      priority = (priority + 1.0) / 2.0;
    }
  }

  double _calculateWaitTimeFactor() {
    final waitTimeInMinutes = DateTime.now().difference(createdAt).inMinutes;
    // Exponential growth for wait time impact
    return (waitTimeInMinutes * waitTimeInMinutes) /
        900.0; // Normalized to 30 minutes squared
  }

  double _calculateSystemLoadFactor() {
    // This is a simplified version. In a real system, this would consider:
    // 1. Number of pending orders
    // 2. Kitchen capacity
    // 3. Current processing rate
    final waitTimeInMinutes = DateTime.now().difference(createdAt).inMinutes;
    return waitTimeInMinutes > 15
        ? 0.8
        : (waitTimeInMinutes / 15.0); // Simple load estimation
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

  // Retain the original fromJson method but adjust it for the new model
  factory Order.fromJson(Map<dynamic, dynamic> json) {
    // Convert the item list in JSON to a list of MenuItem objects
    List<CartItem> items = [];
    if (json.containsKey('items') && json['items'] is List) {
      items =
          (json['items'] as List).map((item) {
            // Adjust according to actual needs
            // If items are CartItem or can be converted to CartItem, perform conversion
            return CartItem(
              item: item,
              quantity: 1,
            ); // Simplified example, adjust based on actual data structure
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
          json['timestamp'] != null
              ? DateTime.parse(json['timestamp'].toString())
              : DateTime.now(),
    );
  }
}
