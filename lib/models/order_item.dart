import 'food_item.dart';

/// Simple order item model for testing
class OrderItem {
  final FoodItem item;
  final int quantity;

  OrderItem({
    required this.item,
    this.quantity = 1,
  });
}
