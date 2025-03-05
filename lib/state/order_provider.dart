// lib/state/order_provider.dart
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../utils/fcfs.dart';
import '../utils/sjf.dart';

enum OrderSortAlgorithm { priority, fcfs, sjf }

class OrderProvider with ChangeNotifier {
  final List<Order> _orders = [];
  OrderSortAlgorithm _currentAlgorithm = OrderSortAlgorithm.priority;

  OrderSortAlgorithm get currentAlgorithm => _currentAlgorithm;

  void setAlgorithm(OrderSortAlgorithm algorithm) {
    _currentAlgorithm = algorithm;
    notifyListeners();
  }

  List<Order> getSortedOrders() {
    final sortedOrders = List<Order>.from(_orders);

    switch (_currentAlgorithm) {
      case OrderSortAlgorithm.priority:
        for (var order in sortedOrders) {
          order.calculatePriority();
        }
        sortedOrders.sort((a, b) => b.priority.compareTo(a.priority));
        break;
      case OrderSortAlgorithm.fcfs:
        // Sort using FCFS algorithm
        return FCFSOrderSorter.sortOrders(_orders);
      case OrderSortAlgorithm.sjf:
        // Sort using SJF algorithm
        return SJFOrderSorter.sortOrders(_orders);
    }

    return sortedOrders;
  }

  // Get all orders
  List<Order> get orders => _orders;

  // Get orders sorted by priority
  List<Order> get prioritizedOrders {
    // Update priority for all orders
    for (var order in _orders) {
      order.calculatePriority();
    }

    // Create a copy of orders list and sort by priority in descending order
    final sortedOrders = List<Order>.from(_orders);
    sortedOrders.sort((a, b) => b.priority.compareTo(a.priority));
    return sortedOrders;
  }

  // Get orders by status (sorted by priority)
  List<Order> getOrdersByStatus(OrderStatus status) {
    // First get orders with specified status
    final filteredOrders =
        _orders.where((order) => order.status == status).toList();

    // Update priority for these orders
    for (var order in filteredOrders) {
      order.calculatePriority();
    }

    // Sort by priority in descending order
    filteredOrders.sort((a, b) => b.priority.compareTo(a.priority));
    return filteredOrders;
  }

  // Get kitchen orders (sorted by priority)
  List<Order> get kitchenOrders {
    // First get orders handled by kitchen
    final filteredOrders =
        _orders.where((order) => order.isKitchenOrder).toList();

    // Update priority for these orders
    for (var order in filteredOrders) {
      order.calculatePriority();
    }

    // Sort by priority in descending order
    filteredOrders.sort((a, b) => b.priority.compareTo(a.priority));
    return filteredOrders;
  }

  // Get staff orders (sorted by priority)
  List<Order> get staffOrders {
    // First get orders handled by staff
    final filteredOrders =
        _orders.where((order) => order.isStaffOrder).toList();

    // Update priority for these orders
    for (var order in filteredOrders) {
      order.calculatePriority();
    }

    // Sort by priority in descending order
    filteredOrders.sort((a, b) => b.priority.compareTo(a.priority));
    return filteredOrders;
  }

  // Add new order
  void addOrder(Order order) {
    // Calculate priority for new order
    order.calculatePriority();
    _orders.add(order);
    notifyListeners();
  }

  // Update order status - supports both String and OrderStatus types
  void updateOrderStatus(String orderId, dynamic newStatus) {
    final orderIndex = _orders.indexWhere(
      (order) =>
          order.id == orderId ||
          (order.orderId != null && order.orderId == orderId),
    );

    if (orderIndex != -1) {
      // Handle different types of status input
      if (newStatus is OrderStatus) {
        _orders[orderIndex].status = newStatus;
      } else if (newStatus is String) {
        // Convert string to enum
        switch (newStatus.toLowerCase()) {
          case 'pending':
            _orders[orderIndex].status = OrderStatus.pending;
            break;
          case 'preparing':
            _orders[orderIndex].status = OrderStatus.preparing;
            break;
          case 'ready':
            _orders[orderIndex].status = OrderStatus.ready;
            break;
          case 'completed':
            _orders[orderIndex].status = OrderStatus.completed;
            break;
          case 'cancelled':
            _orders[orderIndex].status = OrderStatus.cancelled;
            break;
        }
      }

      // If order is completed, set completion time
      if (_orders[orderIndex].status == OrderStatus.completed) {
        _orders[orderIndex].completedAt = DateTime.now();
      }

      // Update order priority
      _orders[orderIndex].calculatePriority();

      notifyListeners();
    }
  }

  // Cancel order
  void cancelOrder(String orderId) {
    updateOrderStatus(orderId, OrderStatus.cancelled);
  }
}
