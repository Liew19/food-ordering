import '../models/test_order.dart';

/// SJF (Shortest Job First) algorithm implementation for testing
class SJFOrderSorter {
  /// Sorts a list of orders based on preparation time.
  static List<Order> sortOrders(List<Order> orders) {
    final sortedOrders = List<Order>.from(orders);
    sortedOrders.sort((a, b) => a.totalPreparationTime.compareTo(b.totalPreparationTime));
    return sortedOrders;
  }
}
