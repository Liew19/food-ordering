// lib/state/order_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/menu_item.dart';
import '../models/item_status.dart';
import '../utils/fcfs.dart';
import '../utils/sjf.dart';
import '../utils/advanced_priority.dart';

enum OrderSortAlgorithm { advancedPriority, fcfs, sjf }

class OrderProvider with ChangeNotifier {
  final List<Order> _orders = [];
  final Map<String, OrderStatus> _kitchenStatuses = {};
  final Map<String, OrderStatus> _staffStatuses = {};
  // Track status of individual items
  final Map<String, ItemStatus> _itemStatuses = {};
  OrderSortAlgorithm _currentAlgorithm = OrderSortAlgorithm.advancedPriority;

  OrderSortAlgorithm get currentAlgorithm => _currentAlgorithm;

  void setAlgorithm(OrderSortAlgorithm algorithm) {
    _currentAlgorithm = algorithm;
    notifyListeners();
  }

  List<Order> getSortedOrders() {
    final sortedOrders = List<Order>.from(_orders);

    switch (_currentAlgorithm) {
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

    // Check for ready items in each order
    for (var order in sortedOrders) {
      // Reset the flag
      order.hasReadyItems = false;

      // Check if any items in the order are ready
      for (var item in order.items) {
        final itemStatus = getItemStatus(order.id, item.item.id);
        if (itemStatus == OrderStatus.ready) {
          order.hasReadyItems = true;
          break;
        }
      }

      // Calculate priority (now with hasReadyItems flag set)
      order.priority = AdvancedOrderPrioritizer.calculatePriority(order);
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

    // Check for ready items in each order
    for (var order in filteredOrders) {
      // Reset the flag
      order.hasReadyItems = false;

      // Check if any items in the order are ready
      for (var item in order.items) {
        final itemStatus = getItemStatus(order.id, item.item.id);
        if (itemStatus == OrderStatus.ready) {
          order.hasReadyItems = true;
          break;
        }
      }

      // Calculate priority (now with hasReadyItems flag set)
      order.priority = AdvancedOrderPrioritizer.calculatePriority(order);
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

    // Check for ready items in each order
    for (var order in filteredOrders) {
      // Reset the flag
      order.hasReadyItems = false;

      // Check if any items in the order are ready
      for (var item in order.items) {
        final itemStatus = getItemStatus(order.id, item.item.id);
        if (itemStatus == OrderStatus.ready) {
          order.hasReadyItems = true;
          break;
        }
      }

      // Calculate priority (now with hasReadyItems flag set)
      order.priority = AdvancedOrderPrioritizer.calculatePriority(order);
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

    // Check for ready items in each order
    for (var order in filteredOrders) {
      // Reset the flag
      order.hasReadyItems = false;

      // Check if any items in the order are ready
      for (var item in order.items) {
        final itemStatus = getItemStatus(order.id, item.item.id);
        if (itemStatus == OrderStatus.ready) {
          order.hasReadyItems = true;
          break;
        }
      }

      // Calculate priority (now with hasReadyItems flag set)
      order.priority = AdvancedOrderPrioritizer.calculatePriority(order);
    }

    // Sort by priority in descending order
    filteredOrders.sort((a, b) => b.priority.compareTo(a.priority));
    return filteredOrders;
  }

  // Add new order
  void addOrder(Order order) {
    // Set hasReadyItems flag to false for new orders
    order.hasReadyItems = false;

    // Calculate priority for new order using advanced priority algorithm
    order.priority = AdvancedOrderPrioritizer.calculatePriority(order);
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

      // Check if any items in the order are ready
      _orders[orderIndex].hasReadyItems = false;
      for (var item in _orders[orderIndex].items) {
        final itemStatus = getItemStatus(orderId, item.item.id);
        if (itemStatus == OrderStatus.ready) {
          _orders[orderIndex].hasReadyItems = true;
          break;
        }
      }

      // Update order priority
      _orders[orderIndex].priority = AdvancedOrderPrioritizer.calculatePriority(
        _orders[orderIndex],
      );

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

  // Get status of an individual item
  OrderStatus getItemStatus(String orderId, String itemId) {
    final key = ItemStatus.createKey(orderId, itemId);
    return _itemStatuses[key]?.status ?? OrderStatus.pending;
  }

  // Update status of an individual item
  void updateItemStatus(String orderId, String itemId, OrderStatus status) {
    final key = ItemStatus.createKey(orderId, itemId);

    if (_itemStatuses.containsKey(key)) {
      _itemStatuses[key]!.status = status;
    } else {
      _itemStatuses[key] = ItemStatus(
        orderId: orderId,
        itemId: itemId,
        status: status,
      );
    }

    // Update the hasReadyItems flag for the order
    final orderIndex = _orders.indexWhere((o) => o.id == orderId);
    if (orderIndex != -1) {
      // If this item is now ready, set the flag
      if (status == OrderStatus.ready) {
        _orders[orderIndex].hasReadyItems = true;
      } else {
        // Otherwise, check if any other items are ready
        _orders[orderIndex].hasReadyItems = false;
        for (var item in _orders[orderIndex].items) {
          final itemStatus = getItemStatus(orderId, item.item.id);
          if (itemStatus == OrderStatus.ready) {
            _orders[orderIndex].hasReadyItems = true;
            break;
          }
        }
      }

      // Update the order's priority
      _orders[orderIndex].priority = AdvancedOrderPrioritizer.calculatePriority(
        _orders[orderIndex],
      );
    }

    // Check if all items in the order are ready, and if so, mark the order as completed
    if (status == OrderStatus.ready) {
      checkAndUpdateOrderStatus(orderId);
    }

    notifyListeners();
  }

  // Check if all items in an order are ready and update order status accordingly
  void checkAndUpdateOrderStatus(String orderId) {
    final orderIndex = _orders.indexWhere((o) => o.id == orderId);
    if (orderIndex == -1) return;

    final order = _orders[orderIndex];

    // Check if all items in the order are ready
    bool allItemsReady = true;
    for (var item in order.items) {
      final itemStatus = getItemStatus(orderId, item.item.id);
      if (itemStatus != OrderStatus.ready) {
        allItemsReady = false;
        break;
      }
    }

    // If all items are ready, mark the order as completed
    if (allItemsReady) {
      // Update the main order status
      _orders[orderIndex].status = OrderStatus.ready;

      // Also update kitchen and staff statuses
      _kitchenStatuses[orderId] = OrderStatus.ready;
      _staffStatuses[orderId] = OrderStatus.ready;

      // Notify listeners to update the UI
      notifyListeners();
    }
  }

  bool isOrderComplete(String orderId) {
    try {
      final order = _orders.firstWhere((o) => o.id == orderId);

      // Check if all items in the order are ready
      for (var item in order.items) {
        final itemStatus = getItemStatus(orderId, item.item.id);
        if (itemStatus != OrderStatus.ready) {
          return false;
        }
      }

      return true; // All items are ready
    } catch (e) {
      // Order not found
      return false;
    }
  }

  void updateKitchenStatus(String orderId, OrderStatus status) {
    // Update the kitchen status for the order
    _kitchenStatuses[orderId] = status;

    // Get the order
    final orderIndex = _orders.indexWhere((o) => o.id == orderId);
    if (orderIndex != -1) {
      final order = _orders[orderIndex];

      // Update all kitchen items to the same status
      for (var item in order.items) {
        if (!_isStaffItem(item.item)) {
          updateItemStatus(orderId, item.item.id, status);
        }
      }

      // If status is ready, check if all kitchen items are ready
      if (status == OrderStatus.ready) {
        // Check if all kitchen items are ready
        bool allKitchenItemsReady = true;
        for (var item in order.items) {
          if (!_isStaffItem(item.item)) {
            // Only check kitchen items
            final itemStatus = getItemStatus(orderId, item.item.id);
            if (itemStatus != OrderStatus.ready) {
              allKitchenItemsReady = false;
              break;
            }
          }
        }

        // If all kitchen items are ready, mark kitchen part as ready
        if (allKitchenItemsReady) {
          // We don't need to update the main order status
          // Just keep the kitchen status as ready
          _kitchenStatuses[orderId] = OrderStatus.ready;
        }
      }
    }

    notifyListeners();
  }

  void updateStaffStatus(String orderId, OrderStatus status) {
    // Update the staff status for the order
    _staffStatuses[orderId] = status;

    // Get the order
    final orderIndex = _orders.indexWhere((o) => o.id == orderId);
    if (orderIndex != -1) {
      final order = _orders[orderIndex];

      // Update all staff items to the same status
      for (var item in order.items) {
        if (_isStaffItem(item.item)) {
          updateItemStatus(orderId, item.item.id, status);
        }
      }

      // If status is ready, check if all staff items are ready
      if (status == OrderStatus.ready) {
        // Check if all staff items are ready
        bool allStaffItemsReady = true;
        for (var item in order.items) {
          if (_isStaffItem(item.item)) {
            // Only check staff items
            final itemStatus = getItemStatus(orderId, item.item.id);
            if (itemStatus != OrderStatus.ready) {
              allStaffItemsReady = false;
              break;
            }
          }
        }

        // If all staff items are ready, mark staff part as ready
        if (allStaffItemsReady) {
          // We don't need to update the main order status
          // Just keep the staff status as ready
          _staffStatuses[orderId] = OrderStatus.ready;
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
      case OrderSortAlgorithm.advancedPriority:
        // Use advanced priority algorithm
        for (var order in filteredOrders) {
          // Calculate base priority
          double basePriority = AdvancedOrderPrioritizer.calculatePriority(
            order,
          );

          // Check if this order is partially processed (has some items in preparing or ready state)
          bool hasPreparingItems = false;
          for (var item in order.items) {
            if (!_isStaffItem(item.item)) {
              // Only check kitchen items
              final itemStatus = getItemStatus(order.id, item.item.id);
              if (itemStatus == OrderStatus.preparing) {
                hasPreparingItems = true;
                break;
              }
            }
          }

          // Boost priority for partially processed orders
          if (hasPreparingItems) {
            // Ensure partially processed orders have higher priority
            basePriority =
                0.9; // High priority but still allows for sorting between partially processed orders
          }

          order.priority = basePriority;
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

    // Sort items within orders by preparation time
    // For kitchen items: longest first, for staff items: shortest first
    for (var order in filteredOrders) {
      // Check if this is a staff-only order
      bool isStaffOnly = order.items.every((item) => _isStaffItem(item.item));

      if (isStaffOnly) {
        // For staff orders, sort by preparation time (shortest first)
        order.items.sort(
          (a, b) => a.item.preparationTime.compareTo(b.item.preparationTime),
        );
      } else {
        // For kitchen orders, sort by preparation time (longest first)
        order.items.sort(
          (a, b) => b.item.preparationTime.compareTo(a.item.preparationTime),
        );
      }
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
      case OrderSortAlgorithm.advancedPriority:
        // Use advanced priority algorithm
        for (var order in filteredOrders) {
          // Calculate base priority
          double basePriority = AdvancedOrderPrioritizer.calculatePriority(
            order,
          );

          // Check if this order is partially processed (has some items in preparing or ready state)
          bool hasPreparingItems = false;
          for (var item in order.items) {
            if (_isStaffItem(item.item)) {
              // Only check staff items
              final itemStatus = getItemStatus(order.id, item.item.id);
              if (itemStatus == OrderStatus.preparing) {
                hasPreparingItems = true;
                break;
              }
            }
          }

          // Boost priority for partially processed orders
          if (hasPreparingItems) {
            // Ensure partially processed orders have higher priority
            basePriority =
                0.9; // High priority but still allows for sorting between partially processed orders
          }

          order.priority = basePriority;
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

    // Sort items within orders by preparation time
    // For kitchen items: longest first, for staff items: shortest first
    for (var order in filteredOrders) {
      // Check if this is a staff-only order
      bool isStaffOnly = order.items.every((item) => _isStaffItem(item.item));

      if (isStaffOnly) {
        // For staff orders, sort by preparation time (shortest first)
        order.items.sort(
          (a, b) => a.item.preparationTime.compareTo(b.item.preparationTime),
        );
      } else {
        // For kitchen orders, sort by preparation time (longest first)
        order.items.sort(
          (a, b) => b.item.preparationTime.compareTo(a.item.preparationTime),
        );
      }
    }

    return filteredOrders;
  }

  List<Order> getActiveKitchenOrders() {
    final orders = getKitchenOrders(includeCompleted: false);

    // Check for ready items in each order
    for (var order in orders) {
      // Reset the flag
      order.hasReadyItems = false;

      // Check if any items in the order are ready
      for (var item in order.items) {
        if (!_isStaffItem(item.item)) {
          // Only check kitchen items
          final itemStatus = getItemStatus(order.id, item.item.id);
          if (itemStatus == OrderStatus.ready) {
            order.hasReadyItems = true;
            break;
          }
        }
      }
    }

    // Filter out orders where all kitchen items are ready
    return orders.where((order) => !areKitchenItemsReady(order.id)).toList();
  }

  // Check if all kitchen items in an order are ready
  bool areKitchenItemsReady(String orderId) {
    try {
      final order = _orders.firstWhere((o) => o.id == orderId);

      // Check if all kitchen items in the order are ready
      for (var item in order.items) {
        if (!_isStaffItem(item.item)) {
          // Only check kitchen items
          final itemStatus = getItemStatus(orderId, item.item.id);
          if (itemStatus != OrderStatus.ready) {
            return false;
          }
        }
      }

      return true; // All kitchen items are ready
    } catch (e) {
      // Order not found
      return false;
    }
  }

  List<Order> getActiveStaffOrders() {
    final filteredOrders =
        _orders
            .where(
              (order) =>
                  order.status != OrderStatus.completed &&
                  order.status != OrderStatus.cancelled &&
                  order.items.any((item) => _isStaffItem(item.item)) &&
                  !areStaffItemsReady(order.id),
            )
            .toList();

    // Apply the current sorting algorithm
    switch (_currentAlgorithm) {
      case OrderSortAlgorithm.advancedPriority:
        // Use advanced priority algorithm
        for (var order in filteredOrders) {
          // Reset the hasReadyItems flag
          order.hasReadyItems = false;

          // Check if any items in the order are ready
          bool hasPreparingItems = false;
          for (var item in order.items) {
            if (_isStaffItem(item.item)) {
              // Only check staff items
              final itemStatus = getItemStatus(order.id, item.item.id);
              if (itemStatus == OrderStatus.preparing) {
                hasPreparingItems = true;
              } else if (itemStatus == OrderStatus.ready) {
                order.hasReadyItems = true;
              }
            }
          }

          // Calculate base priority
          double basePriority = AdvancedOrderPrioritizer.calculatePriority(
            order,
          );

          // Boost priority for partially processed orders
          if (hasPreparingItems) {
            // Ensure partially processed orders have higher priority
            basePriority =
                0.9; // High priority but still allows for sorting between partially processed orders
          }

          order.priority = basePriority;
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

    // Sort items within orders by preparation time
    // For kitchen items: longest first, for staff items: shortest first
    for (var order in filteredOrders) {
      // Check if this is a staff-only order
      bool isStaffOnly = order.items.every((item) => _isStaffItem(item.item));

      if (isStaffOnly) {
        // For staff orders, sort by preparation time (shortest first)
        order.items.sort(
          (a, b) => a.item.preparationTime.compareTo(b.item.preparationTime),
        );
      } else {
        // For kitchen orders, sort by preparation time (longest first)
        order.items.sort(
          (a, b) => b.item.preparationTime.compareTo(a.item.preparationTime),
        );
      }
    }

    return filteredOrders;
  }

  // Check if all staff items in an order are ready
  bool areStaffItemsReady(String orderId) {
    try {
      final order = _orders.firstWhere((o) => o.id == orderId);

      // Check if all staff items in the order are ready
      for (var item in order.items) {
        if (_isStaffItem(item.item)) {
          // Only check staff items
          final itemStatus = getItemStatus(orderId, item.item.id);
          if (itemStatus != OrderStatus.ready) {
            return false;
          }
        }
      }

      return true; // All staff items are ready
    } catch (e) {
      // Order not found
      return false;
    }
  }

  List<Order> getCompletedStaffOrders() {
    final filteredOrders =
        _orders
            .where(
              (order) =>
                  order.items.any((item) => _isStaffItem(item.item)) &&
                  (order.status == OrderStatus.completed ||
                      areStaffItemsReady(order.id)),
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

    // For completed staff orders, sort by preparation time (shortest first)
    for (var order in filteredOrders) {
      order.items.sort(
        (a, b) => a.item.preparationTime.compareTo(b.item.preparationTime),
      );
    }

    return filteredOrders;
  }

  List<Order> getCompletedKitchenOrders() {
    final filteredOrders =
        _orders
            .where(
              (order) =>
                  order.items.any((item) => !_isStaffItem(item.item)) &&
                  (order.status == OrderStatus.completed ||
                      areKitchenItemsReady(order.id)),
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

    // For completed kitchen orders, sort by preparation time (longest first)
    for (var order in filteredOrders) {
      order.items.sort(
        (a, b) => b.item.preparationTime.compareTo(a.item.preparationTime),
      );
    }

    return filteredOrders;
  }

  bool _isStaffItem(MenuItem item) {
    return item.category.toLowerCase() == 'beverage' ||
        item.category.toLowerCase() == 'dessert';
  }

  // Get batch processing suggestions for kitchen items
  List<BatchGroup> getKitchenBatchSuggestions() {
    // Only show batch suggestions when using advanced priority algorithm
    if (_currentAlgorithm != OrderSortAlgorithm.advancedPriority) {
      return []; // Return empty list for FCFS and SJF
    }

    final activeOrders = getActiveKitchenOrders();

    // Get batch suggestions
    final batches = BatchProcessor.identifySimilarFoodItems(
      activeOrders,
      getKitchenStatus,
      (orderId, itemId) => getItemStatus(orderId, itemId),
    );

    // Calculate priority for each batch based on the orders it contains
    final batchPriorities = _calculateBatchPriorities(batches);

    // Sort batches by priority (highest first)
    batches.sort((a, b) => batchPriorities[b]!.compareTo(batchPriorities[a]!));

    return batches;
  }

  // Get batch processing suggestions for staff items (beverages)
  List<BatchGroup> getStaffBatchSuggestions() {
    // Only show batch suggestions when using advanced priority algorithm
    if (_currentAlgorithm != OrderSortAlgorithm.advancedPriority) {
      return []; // Return empty list for FCFS and SJF
    }

    final activeOrders = getActiveStaffOrders();

    // Get batch suggestions
    final batches = BatchProcessor.identifySimilarBeverages(
      activeOrders,
      getStaffStatus,
      (orderId, itemId) => getItemStatus(orderId, itemId),
    );

    // Calculate priority for each batch based on the orders it contains
    final batchPriorities = _calculateBatchPriorities(batches);

    // Sort batches by priority (highest first)
    batches.sort((a, b) => batchPriorities[b]!.compareTo(batchPriorities[a]!));

    return batches;
  }

  // Calculate priority scores for batches based on the orders they contain
  Map<BatchGroup, double> _calculateBatchPriorities(List<BatchGroup> batches) {
    final Map<BatchGroup, double> batchPriorities = {};

    // Find the maximum possible priority to normalize values
    double maxPriority = 0.0;

    // First pass: calculate raw priorities
    for (var batch in batches) {
      // Calculate average priority of orders in this batch
      double totalPriority = 0;
      final Set<String> uniqueOrderIds = {};
      bool containsPartiallyProcessedOrder = false;
      bool containsOrderWithReadyItems = false;

      for (var item in batch.items) {
        if (!uniqueOrderIds.contains(item.order.id)) {
          uniqueOrderIds.add(item.order.id);

          // Check if any items in the order are ready
          item.order.hasReadyItems = false;
          for (var orderItem in item.order.items) {
            final itemStatus = getItemStatus(item.order.id, orderItem.item.id);
            if (itemStatus == OrderStatus.ready) {
              item.order.hasReadyItems = true;
              containsOrderWithReadyItems = true;
              break;
            }
          }

          // Calculate priority for this order
          item.order.priority = AdvancedOrderPrioritizer.calculatePriority(
            item.order,
          );
          totalPriority += item.order.priority;

          // Check if this order is already partially processed
          // (has some items in preparing or ready state)
          bool isPartiallyProcessed = false;
          for (var orderItem in item.order.items) {
            final itemStatus = getItemStatus(item.order.id, orderItem.item.id);
            if (itemStatus == OrderStatus.preparing ||
                itemStatus == OrderStatus.ready) {
              isPartiallyProcessed = true;
              break;
            }
          }

          if (isPartiallyProcessed) {
            containsPartiallyProcessedOrder = true;
          }
        }
      }

      // Calculate average priority for this batch
      double avgPriority =
          uniqueOrderIds.isEmpty ? 0 : totalPriority / uniqueOrderIds.length;

      // Consider the average wait time of orders in this batch
      // This helps prevent brand new batches from immediately getting top priority
      double totalWaitTime = 0.0;
      for (var orderId in uniqueOrderIds) {
        final order = _orders.firstWhere((o) => o.id == orderId);
        final waitTimeMinutes =
            DateTime.now().difference(order.createdAt).inMinutes;
        totalWaitTime += waitTimeMinutes;
      }

      // Apply a small wait time factor (0.01 per minute waited, up to 0.1)
      // Reduced from 0.2 to prevent excessive priority growth
      if (uniqueOrderIds.isNotEmpty) {
        final avgWaitTime = totalWaitTime / uniqueOrderIds.length;
        final waitTimeFactor = (avgWaitTime * 0.01).clamp(0.0, 0.1);
        avgPriority += waitTimeFactor;
      }

      // If this batch contains partially processed orders, boost its priority
      // but not so much that it always gets 100% priority
      if (containsPartiallyProcessedOrder) {
        avgPriority +=
            0.2; // Reduced from 0.3 to prevent excessive priority growth
      }

      // If this batch contains orders with ready items, boost its priority even more
      if (containsOrderWithReadyItems) {
        avgPriority +=
            0.1; // Reduced from 0.2 to prevent excessive priority growth
      }

      // Cap the batch priority at 0.8 to prevent it from always being at the top
      avgPriority = avgPriority.clamp(0.0, 0.8);

      // Store the priority
      batchPriorities[batch] = avgPriority;

      // Update max priority if needed
      if (avgPriority > maxPriority) {
        maxPriority = avgPriority;
      }
    }

    // Second pass: normalize priorities and set them on batch objects
    if (maxPriority > 0) {
      for (var batch in batches) {
        // We no longer need to calculate average wait time since we're not capping priority
        // based on batch age. We'll use the raw priority value directly.

        // We no longer need to cap batch priority or use maxBatchPriority

        // Use the raw priority value directly without normalization
        // This ensures batch priorities are directly comparable to order priorities
        batch.priority = batchPriorities[batch]!;

        // Update the map value as well
        batchPriorities[batch] = batch.priority;
      }
    }

    return batchPriorities;
  }

  // Process a kitchen batch - updates individual item status
  void processKitchenBatch(BatchGroup batchGroup) {
    BatchProcessor.processItemBatch(
      batchGroup,
      updateItemStatus,
      OrderStatus.preparing,
    );

    // Mark this batch as being processed by setting a high priority
    // This ensures it stays at the top of the list
    batchGroup.priority = 0.95; // Very high priority, but not maximum

    notifyListeners();
  }

  // Process a staff batch - updates individual item status
  void processStaffBatch(BatchGroup batchGroup) {
    BatchProcessor.processItemBatch(
      batchGroup,
      updateItemStatus,
      OrderStatus.preparing,
    );

    // Mark this batch as being processed by setting a high priority
    // This ensures it stays at the top of the list
    batchGroup.priority = 0.95; // Very high priority, but not maximum

    notifyListeners();
  }

  // Mark a kitchen batch as ready - updates individual item status
  void completeKitchenBatch(BatchGroup batchGroup) {
    // Get affected items
    final affectedItems = BatchProcessor.processItemBatch(
      batchGroup,
      updateItemStatus,
      OrderStatus.ready,
    );

    // Update kitchen status for each affected order
    final Set<String> processedOrderIds = {};
    for (var item in affectedItems) {
      final orderId = item['orderId']!;
      if (!processedOrderIds.contains(orderId)) {
        processedOrderIds.add(orderId);

        // Check if all kitchen items in this order are ready
        if (areKitchenItemsReady(orderId)) {
          // Mark kitchen part as ready
          _kitchenStatuses[orderId] = OrderStatus.ready;
        }
      }
    }

    notifyListeners();
  }

  // Mark a staff batch as ready - updates individual item status
  void completeStaffBatch(BatchGroup batchGroup) {
    // Get affected items
    final affectedItems = BatchProcessor.processItemBatch(
      batchGroup,
      updateItemStatus,
      OrderStatus.ready,
    );

    // Update staff status for each affected order
    final Set<String> processedOrderIds = {};
    for (var item in affectedItems) {
      final orderId = item['orderId']!;
      if (!processedOrderIds.contains(orderId)) {
        processedOrderIds.add(orderId);

        // Check if all staff items in this order are ready
        if (areStaffItemsReady(orderId)) {
          // Mark staff part as ready
          _staffStatuses[orderId] = OrderStatus.ready;
        }
      }
    }

    notifyListeners();
  }
}
