import 'package:fyp/models/order.dart';

/// Tracks the status of individual food items within orders
class ItemStatus {
  final String orderId;
  final String itemId;
  OrderStatus status;

  ItemStatus({
    required this.orderId,
    required this.itemId,
    this.status = OrderStatus.pending,
  });

  /// Creates a unique key for this item status
  String get key => '$orderId:$itemId';

  /// Factory method to create a key from order ID and item ID
  static String createKey(String orderId, String itemId) {
    return '$orderId:$itemId';
  }
}
