// lib/state/order_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/menu_item.dart';
import '../utils/fcfs.dart';
import '../utils/sjf.dart';
import '../utils/advanced_priority.dart';

enum OrderSortAlgorithm { priority, advancedPriority, fcfs, sjf }

class OrderProvider with ChangeNotifier {
  final List<Order> _orders = [];
  final Map<String, OrderStatus> _kitchenStatuses = {};
  final Map<String, OrderStatus> _staffStatuses = {};
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
      case OrderSortAlgorithm.advancedPriority:
        // Sort using Advanced Priority algorithm
        for (var order in sortedOrders) {
          // Calculate and store advanced priority score
          order.priority = AdvancedOrderPrioritizer.calculatePriority(order);
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
    // Update priority for all orders based on current algorithm
    final sortedOrders = List<Order>.from(_orders);

    if (_currentAlgorithm == OrderSortAlgorithm.advancedPriority) {
      // Use advanced priority algorithm
      for (var order in sortedOrders) {
        order.priority = AdvancedOrderPrioritizer.calculatePriority(order);
      }
    } else {
      // 使用传统优先级算法
      for (var order in sortedOrders) {
        order.calculatePriority();
      }
    }

    // Sort by priority in descending order
    sortedOrders.sort((a, b) => b.priority.compareTo(a.priority));
    return sortedOrders;
  }

  // Get orders by status (sorted by priority)
  List<Order> getOrdersByStatus(OrderStatus status) {
    // First get orders with specified status
    final filteredOrders =
        _orders.where((order) => order.status == status).toList();

    // Update priority for these orders based on current algorithm
    if (_currentAlgorithm == OrderSortAlgorithm.advancedPriority) {
      // Use advanced priority algorithm
      for (var order in filteredOrders) {
        order.priority = AdvancedOrderPrioritizer.calculatePriority(order);
      }
    } else {
      // 使用传统优先级算法
      for (var order in filteredOrders) {
        order.calculatePriority();
      }
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

    // Update priority for these orders based on current algorithm
    if (_currentAlgorithm == OrderSortAlgorithm.advancedPriority) {
      // Use advanced priority algorithm
      for (var order in filteredOrders) {
        order.priority = AdvancedOrderPrioritizer.calculatePriority(order);
      }
    } else {
      // 使用传统优先级算法
      for (var order in filteredOrders) {
        order.calculatePriority();
      }
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

    // Update priority for these orders based on current algorithm
    if (_currentAlgorithm == OrderSortAlgorithm.advancedPriority) {
      // Use advanced priority algorithm
      for (var order in filteredOrders) {
        order.priority = AdvancedOrderPrioritizer.calculatePriority(order);
      }
    } else {
      // 使用传统优先级算法
      for (var order in filteredOrders) {
        order.calculatePriority();
      }
    }

    // Sort by priority in descending order
    filteredOrders.sort((a, b) => b.priority.compareTo(a.priority));
    return filteredOrders;
  }

  // Add new order
  void addOrder(Order order) {
    // Calculate priority for new order based on current algorithm
    if (_currentAlgorithm == OrderSortAlgorithm.advancedPriority) {
      order.priority = AdvancedOrderPrioritizer.calculatePriority(order);
    } else {
      order.calculatePriority();
    }
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

  OrderStatus getKitchenStatus(String orderId) {
    return _kitchenStatuses[orderId] ?? OrderStatus.pending;
  }

  OrderStatus getStaffStatus(String orderId) {
    return _staffStatuses[orderId] ?? OrderStatus.pending;
  }

  bool isOrderComplete(String orderId) {
    final order = _orders.firstWhere((o) => o.id == orderId);
    final hasKitchenItems = order.items.any((item) => !_isStaffItem(item.item));
    final hasStaffItems = order.items.any((item) => _isStaffItem(item.item));

    if (hasKitchenItems && hasStaffItems) {
      return getKitchenStatus(orderId) == OrderStatus.ready &&
          getStaffStatus(orderId) == OrderStatus.ready;
    } else if (hasKitchenItems) {
      return getKitchenStatus(orderId) == OrderStatus.ready;
    } else {
      return getStaffStatus(orderId) == OrderStatus.ready;
    }
  }

  void updateKitchenStatus(String orderId, OrderStatus status) {
    _kitchenStatuses[orderId] = status;
    if (isOrderComplete(orderId)) {
      final orderIndex = _orders.indexWhere((o) => o.id == orderId);
      if (orderIndex != -1) {
        _orders[orderIndex].status = OrderStatus.completed;
        _orders[orderIndex].completedAt = DateTime.now();
      }
    }
    notifyListeners();
  }

  void updateStaffStatus(String orderId, OrderStatus status) {
    _staffStatuses[orderId] = status;
    final order = _orders.firstWhere((o) => o.id == orderId);

    // Only mark as completed if both kitchen and staff are ready (for mixed orders)
    // or if this is a staff-only order and it's ready
    if (order.items.any((item) => !_isStaffItem(item.item))) {
      // Mixed order - wait for kitchen to be ready too
      if (isOrderComplete(orderId)) {
        final orderIndex = _orders.indexWhere((o) => o.id == orderId);
        if (orderIndex != -1) {
          _orders[orderIndex].status = OrderStatus.completed;
          _orders[orderIndex].completedAt = DateTime.now();
        }
      }
    } else {
      // Staff-only order
      if (status == OrderStatus.ready) {
        final orderIndex = _orders.indexWhere((o) => o.id == orderId);
        if (orderIndex != -1) {
          _orders[orderIndex].status = OrderStatus.completed;
          _orders[orderIndex].completedAt = DateTime.now();
        }
      }
    }
    notifyListeners();
  }

  List<Order> getKitchenOrders({bool includeCompleted = true}) {
    final filteredOrders =
        _orders
            .where(
              (order) =>
                  (includeCompleted ||
                      (order.status != OrderStatus.completed &&
                          order.status != OrderStatus.cancelled)) &&
                  order.items.any((item) => !_isStaffItem(item.item)),
            )
            .toList();

    // Apply the current sorting algorithm
    switch (_currentAlgorithm) {
      case OrderSortAlgorithm.priority:
        // Use traditional priority algorithm
        for (var order in filteredOrders) {
          order.calculatePriority();
        }
        filteredOrders.sort((a, b) => b.priority.compareTo(a.priority));
        break;
      case OrderSortAlgorithm.advancedPriority:
        // Use advanced priority algorithm
        for (var order in filteredOrders) {
          order.priority = AdvancedOrderPrioritizer.calculatePriority(order);
        }
        filteredOrders.sort((a, b) => b.priority.compareTo(a.priority));
        break;
      case OrderSortAlgorithm.fcfs:
        // First Come First Serve - sort by creation time (ascending)
        filteredOrders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case OrderSortAlgorithm.sjf:
        // Shortest Job First - sort by preparation time
        filteredOrders.sort((a, b) {
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
        break;
      // No default case needed as all enum values are covered
    }

    // For each order, sort the items using SJF
    for (var order in filteredOrders) {
      order.items.sort(
        (a, b) => a.item.preparationTime.compareTo(b.item.preparationTime),
      );
    }

    return filteredOrders;
  }

  List<Order> getStaffOrders({bool includeCompleted = true}) {
    final filteredOrders =
        _orders
            .where(
              (order) =>
                  (includeCompleted ||
                      (order.status != OrderStatus.completed &&
                          order.status != OrderStatus.cancelled)) &&
                  order.items.any((item) => _isStaffItem(item.item)),
            )
            .toList();

    // Apply the current sorting algorithm
    switch (_currentAlgorithm) {
      case OrderSortAlgorithm.priority:
        // Use traditional priority algorithm
        for (var order in filteredOrders) {
          order.calculatePriority();
        }
        filteredOrders.sort((a, b) => b.priority.compareTo(a.priority));
        break;
      case OrderSortAlgorithm.advancedPriority:
        // Use advanced priority algorithm
        for (var order in filteredOrders) {
          order.priority = AdvancedOrderPrioritizer.calculatePriority(order);
        }
        filteredOrders.sort((a, b) => b.priority.compareTo(a.priority));
        break;
      case OrderSortAlgorithm.fcfs:
        // First Come First Serve - sort by creation time (ascending)
        filteredOrders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case OrderSortAlgorithm.sjf:
        // Shortest Job First - sort by preparation time
        filteredOrders.sort((a, b) {
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
        break;
      // No default case needed as all enum values are covered
    }

    // For each order, sort the items using SJF
    for (var order in filteredOrders) {
      order.items.sort(
        (a, b) => a.item.preparationTime.compareTo(b.item.preparationTime),
      );
    }

    return filteredOrders;
  }

  List<Order> getActiveKitchenOrders() {
    return getKitchenOrders(includeCompleted: false);
  }

  List<Order> getActiveStaffOrders() {
    final filteredOrders =
        _orders
            .where(
              (order) =>
                  order.status != OrderStatus.completed &&
                  order.status != OrderStatus.cancelled &&
                  order.items.any((item) => _isStaffItem(item.item)) &&
                  getStaffStatus(order.id) != OrderStatus.ready,
            )
            .toList();

    // Apply the current sorting algorithm
    switch (_currentAlgorithm) {
      case OrderSortAlgorithm.priority:
        // Use traditional priority algorithm
        for (var order in filteredOrders) {
          order.calculatePriority();
        }
        filteredOrders.sort((a, b) => b.priority.compareTo(a.priority));
        break;
      case OrderSortAlgorithm.advancedPriority:
        // Use advanced priority algorithm
        for (var order in filteredOrders) {
          order.priority = AdvancedOrderPrioritizer.calculatePriority(order);
        }
        filteredOrders.sort((a, b) => b.priority.compareTo(a.priority));
        break;
      case OrderSortAlgorithm.fcfs:
        // First Come First Serve - sort by creation time (ascending)
        filteredOrders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case OrderSortAlgorithm.sjf:
        // Shortest Job First - sort by preparation time
        filteredOrders.sort((a, b) {
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
        break;
      // No default case needed as all enum values are covered
    }

    // For each order, sort the items using SJF
    for (var order in filteredOrders) {
      order.items.sort(
        (a, b) => a.item.preparationTime.compareTo(b.item.preparationTime),
      );
    }

    return filteredOrders;
  }

  List<Order> getCompletedStaffOrders() {
    final filteredOrders =
        _orders
            .where(
              (order) =>
                  order.items.any((item) => _isStaffItem(item.item)) &&
                  (order.status == OrderStatus.completed ||
                      getStaffStatus(order.id) == OrderStatus.ready),
            )
            .toList();

    // Sort by completion time (descending)
    filteredOrders.sort((a, b) {
      if (a.completedAt == null && b.completedAt == null) {
        return b.createdAt.compareTo(a.createdAt);
      } else if (a.completedAt == null) {
        return 1;
      } else if (b.completedAt == null) {
        return -1;
      } else {
        return b.completedAt!.compareTo(a.completedAt!);
      }
    });

    // For each order, sort the items using SJF
    for (var order in filteredOrders) {
      order.items.sort(
        (a, b) => a.item.preparationTime.compareTo(b.item.preparationTime),
      );
    }

    return filteredOrders;
  }

  bool _isStaffItem(MenuItem item) {
    return item.category.toLowerCase() == 'beverage' ||
        item.category.toLowerCase() == 'dessert';
  }
}
