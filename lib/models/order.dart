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
  // Calculate order priority
  void calculatePriority() {
    // Get preparation time priority (40% weight)
    final preparationTimePriority = _calculatePreparationTimePriority() * 0.4;

    // Get order type priority (30% weight)
    final orderTypePriority =
        (tableNumber == null ? 3 : 2) *
        0.3; // Takeaway orders have higher priority

    // Get amount priority (20% weight)
    final amountPriority = _calculateAmountPriority() * 0.2;

    // Get wait time priority (10% weight)
    final waitTimePriority = _calculateWaitTimePriority() * 0.1;

    priority =
        preparationTimePriority +
        orderTypePriority +
        amountPriority +
        waitTimePriority;
  }

  int _calculatePreparationTimePriority() {
    final maxPrepTime =
        items.isEmpty
            ? 0
            : items
                .map((item) => item.item.preparationTime)
                .reduce((max, value) => max > value ? max : value);

    if (maxPrepTime <= 10) return 3; // Quick preparation
    if (maxPrepTime <= 20) return 2; // Standard preparation
    return 1; // Long preparation
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
    return item.category.toLowerCase() == 'beverages' ||
        item.category.toLowerCase() == 'dessert';
  }

  int _calculateAmountPriority() {
    if (totalPrice > 200) return 3;
    if (totalPrice >= 100) return 2;
    return 1;
  }

  int _calculateWaitTimePriority() {
    final waitTimeInMinutes = DateTime.now().difference(createdAt).inMinutes;
    if (waitTimeInMinutes > 15) return 3;
    if (waitTimeInMinutes > 10) return 2;
    return 1;
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
