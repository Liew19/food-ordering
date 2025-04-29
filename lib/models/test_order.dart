import 'order_item.dart';

/// Simplified order model for testing algorithms
class Order {
  final String id;
  final DateTime createdAt;
  final List<OrderItem> items;
  double priority = 0.0;
  bool hasReadyItems = false;

  Order({
    required this.id,
    required this.createdAt,
    required this.items,
  });

  /// Calculate the total preparation time for this order
  double get totalPreparationTime {
    return items.fold(0.0, (sum, item) => sum + item.item.preparationTime * item.quantity);
  }
}
