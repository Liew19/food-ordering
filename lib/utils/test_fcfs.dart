import '../models/test_order.dart';

/// FCFS (First Come First Serve) algorithm implementation for testing
/// Sort orders by creation time, earliest created orders are processed first
class FCFSOrderSorter {
  /// Sort the order list by creation time
  /// Returns the sorted order list without modifying the original list
  static List<Order> sortOrders(List<Order> orders) {
    final sortedOrders = List<Order>.from(orders);
    sortedOrders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sortedOrders;
  }
}
