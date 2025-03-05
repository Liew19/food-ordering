import '../models/order.dart';

/// SJF (Shortest Job First)
class SJFOrderSorter {
  /// Sorts a list of orders based on preparation time.
  static List<Order> sortOrders(List<Order> orders) {
    final sortedOrders = List<Order>.from(orders);
    sortedOrders.sort((a, b) {
      // Calculate the preparation time for each order
      final aTime = a.items.fold(
        0.0,
        (sum, item) => sum + item.item.preparationTime,
      );
      final bTime = b.items.fold(
        0.0,
        (sum, item) => sum + item.item.preparationTime,
      );
      return aTime.compareTo(bTime);
    });
    return sortedOrders;
  }
}
