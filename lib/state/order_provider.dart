// lib/state/order_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/menu_item.dart';
import '../models/item_status.dart';
import '../utils/fcfs.dart';
import '../utils/sjf.dart';
import '../utils/advanced_priority.dart';
import '../services/order_service.dart';

enum OrderSortAlgorithm { advancedPriority, fcfs, sjf }

class OrderProvider with ChangeNotifier {
  final List<Order> _orders = [];
  final Map<String, OrderStatus> _kitchenStatuses = {};
  final Map<String, OrderStatus> _staffStatuses = {};
  // Track status of individual items
  final Map<String, ItemStatus> _itemStatuses = {};
  OrderSortAlgorithm _currentAlgorithm = OrderSortAlgorithm.advancedPriority;

  // Firestore service instance
  final OrderService _orderService = OrderService();

  OrderSortAlgorithm get currentAlgorithm => _currentAlgorithm;

  void setAlgorithm(OrderSortAlgorithm algorithm) {
    _currentAlgorithm = algorithm;
    notifyListeners();
  }

  // Initialize Firestore listeners
  void initializeFirestoreListeners() {
    // Listen to all active orders
    _orderService.getActiveOrders().listen((orders) {
      _updateOrdersFromFirestore(orders);
    });

    // Also listen to completed orders so history tab has data
    _orderService.getCompletedOrders().listen((completed) {
      _mergeCompletedOrders(completed);
    });
  }

  // Update local orders from Firestore
  void _updateOrdersFromFirestore(List<Order> firestoreOrders) {
    _orders.clear();
    _orders.addAll(firestoreOrders);

    // Update local status maps
    for (var order in firestoreOrders) {
      _kitchenStatuses[order.id] = OrderStatus.pending;
      _staffStatuses[order.id] = OrderStatus.pending;

      // Initialize item statuses
      for (var item in order.items) {
        final itemKey = '${order.id}_${item.item.id}';
        if (!_itemStatuses.containsKey(itemKey)) {
          _itemStatuses[itemKey] = ItemStatus(
            orderId: order.id,
            itemId: item.item.id,
            status: OrderStatus.pending,
          );
        }
      }

      // Hydrate item statuses from Firestore data if available on the Order model
      if (order.itemStatuses.isNotEmpty) {
        order.itemStatuses.forEach((itemId, status) {
          final key = ItemStatus.createKey(order.id, itemId);
          _itemStatuses[key] = ItemStatus(
            orderId: order.id,
            itemId: itemId,
            status: status,
          );
        });
      }
    }

    notifyListeners();
  }

  // Merge completed orders into local cache without dropping active ones
  void _mergeCompletedOrders(List<Order> completedOrders) {
    for (var order in completedOrders) {
      final existingIndex = _orders.indexWhere((o) => o.id == order.id);
      if (existingIndex >= 0) {
        _orders[existingIndex] = order;
      } else {
        _orders.add(order);
      }

      // Ensure status maps and item statuses are initialized
      _kitchenStatuses.putIfAbsent(order.id, () => OrderStatus.pending);
      _staffStatuses.putIfAbsent(order.id, () => OrderStatus.pending);
      for (var item in order.items) {
        final itemKey = '${order.id}_${item.item.id}';
        _itemStatuses.putIfAbsent(
          itemKey,
          () => ItemStatus(
            orderId: order.id,
            itemId: item.item.id,
            status: OrderStatus.pending,
          ),
        );
      }
    }

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

  // Add new order and save to Firestore
  Future<void> addOrder(Order order) async {
    try {
      // Save to Firestore first
      final orderId = await _orderService.createOrder(order);

      // Update the order with the Firestore document ID
      final updatedOrder = Order(
        id: orderId,
        orderId: order.orderId,
        userId: order.userId,
        tableNumber: order.tableNumber,
        items: order.items,
        totalPrice: order.totalPrice,
        status: order.status,
        createdAt: order.createdAt,
        completedAt: order.completedAt,
      );

      // Set hasReadyItems flag to false for new orders
      updatedOrder.hasReadyItems = false;

      // Calculate priority for new order using advanced priority algorithm
      updatedOrder.priority = AdvancedOrderPrioritizer.calculatePriority(
        updatedOrder,
      );

      // Initialize kitchen and staff statuses
      _kitchenStatuses[updatedOrder.id] = OrderStatus.pending;
      _staffStatuses[updatedOrder.id] = OrderStatus.pending;

      // Initialize item statuses
      for (var item in updatedOrder.items) {
        final itemKey = '${updatedOrder.id}_${item.item.id}';
        _itemStatuses[itemKey] = ItemStatus(
          orderId: updatedOrder.id,
          itemId: item.item.id,
          status: OrderStatus.pending,
        );
      }

      _orders.add(updatedOrder);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to add order: $e');
    }
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
  Future<void> updateItemStatus(
    String orderId,
    String itemId,
    OrderStatus status,
  ) async {
    try {
      // Update Firestore first
      await _orderService.updateItemStatus(orderId, itemId, status);

      // Update local state
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
        _orders[orderIndex].priority =
            AdvancedOrderPrioritizer.calculatePriority(_orders[orderIndex]);
      }

      // Check if all items in the order are ready, and if so, mark the order as completed
      if (status == OrderStatus.ready) {
        checkAndUpdateOrderStatus(orderId);
      }

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update item status: $e');
    }
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

    // If all items are ready, finalize status
    if (allItemsReady) {
      // Decide if overall order should be completed
      _orderService.shouldCompleteOrder(orderId).then((shouldComplete) async {
        if (shouldComplete) {
          // Persist completion to Firestore
          await _orderService.updateOrderStatus(orderId, OrderStatus.completed);
          _orders[orderIndex].status = OrderStatus.completed;
          _orders[orderIndex].completedAt = DateTime.now();
        } else {
          // Mark as ready (parts done but not fully completed)
          _orders[orderIndex].status = OrderStatus.ready;
          _kitchenStatuses[orderId] = OrderStatus.ready;
          _staffStatuses[orderId] = OrderStatus.ready;
        }

        // Notify listeners to update the UI
        notifyListeners();
      });
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

  Future<void> updateKitchenStatus(String orderId, OrderStatus status) async {
    try {
      // Ensure the order exists locally and in Firestore before updating
      final existsLocally = _orders.any((o) => o.id == orderId);
      if (!existsLocally) {
        // Avoid throwing when tapping actions on orders not yet synced
        return;
      }

      // Update Firestore first
      await _orderService.updateKitchenStatus(orderId, status);

      // Update local state
      _kitchenStatuses[orderId] = status;

      // Get the order
      final orderIndex = _orders.indexWhere((o) => o.id == orderId);
      if (orderIndex != -1) {
        final order = _orders[orderIndex];

        // Update all kitchen items to the same status
        for (var item in order.items) {
          if (!_isStaffItem(item.item)) {
            await updateItemStatus(orderId, item.item.id, status);
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
    } catch (e) {
      throw Exception('Failed to update kitchen status: $e');
    }
  }

  Future<void> updateStaffStatus(String orderId, OrderStatus status) async {
    try {
      // Ensure the order exists locally and in Firestore before updating
      final existsLocally = _orders.any((o) => o.id == orderId);
      if (!existsLocally) {
        return;
      }

      // Update Firestore first
      await _orderService.updateStaffStatus(orderId, status);

      // Update local state
      _staffStatuses[orderId] = status;

      // Get the order
      final orderIndex = _orders.indexWhere((o) => o.id == orderId);
      if (orderIndex != -1) {
        final order = _orders[orderIndex];

        // Update all staff items to the same status
        for (var item in order.items) {
          if (_isStaffItem(item.item)) {
            await updateItemStatus(orderId, item.item.id, status);
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
            _staffStatuses[orderId] = OrderStatus.ready;

            // Also check whether the entire order can now be completed
            _orderService.shouldCompleteOrder(orderId).then((
              shouldComplete,
            ) async {
              if (shouldComplete) {
                await _orderService.updateOrderStatus(
                  orderId,
                  OrderStatus.completed,
                );
                _orders[orderIndex].status = OrderStatus.completed;
                _orders[orderIndex].completedAt = DateTime.now();
              } else {
                // At least staff portion is ready
                _orders[orderIndex].status = OrderStatus.ready;
              }
              notifyListeners();
            });
          }
        }
      }

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update staff status: $e');
    }
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
                  _hasUnreadyStaffItems(order.id),
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
      bool hasStaffItems = false;
      for (var item in order.items) {
        if (_isStaffItem(item.item)) {
          // Only check staff items
          hasStaffItems = true;
          final itemStatus = getItemStatus(orderId, item.item.id);
          if (itemStatus != OrderStatus.ready) {
            return false;
          }
        }
      }

      if (!hasStaffItems)
        return false; // treat no staff items as not-ready here
      return true; // All staff items are ready
    } catch (e) {
      // Order not found
      return false;
    }
  }

  // Helper: does this order have at least one staff item not ready?
  bool _hasUnreadyStaffItems(String orderId) {
    try {
      final order = _orders.firstWhere((o) => o.id == orderId);
      // Prefer checking Order.itemStatuses if available (fresh from Firestore)
      if (order.itemStatuses.isNotEmpty) {
        for (var item in order.items) {
          if (_isStaffItem(item.item)) {
            final s = order.itemStatuses[item.item.id] ?? OrderStatus.pending;
            if (s != OrderStatus.ready) return true;
          }
        }
        return false;
      }

      // Fallback to provider cache
      for (var item in order.items) {
        if (_isStaffItem(item.item)) {
          final status = getItemStatus(orderId, item.item.id);
          if (status != OrderStatus.ready) return true;
        }
      }
      return false;
    } catch (e) {
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
  void completeKitchenBatch(BatchGroup batchGroup) async {
    // Get affected items
    final affectedItems = await BatchProcessor.processItemBatch(
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
        final areReady = await _orderService.areAllKitchenItemsReady(orderId);

        if (areReady) {
          // Mark kitchen part as ready in local state and Firestore
          updateKitchenStatus(orderId, OrderStatus.ready).then((_) async {
            // Now check if the entire order should be completed
            final shouldComplete = await _orderService.shouldCompleteOrder(
              orderId,
            );

            if (shouldComplete) {
              // Mark the entire order as completed
              await _orderService.updateOrderStatus(
                orderId,
                OrderStatus.completed,
              );
            }
          });
        }
      }
    }

    notifyListeners();
  }

  // Mark a staff batch as ready - updates individual item status
  void completeStaffBatch(BatchGroup batchGroup) async {
    // Get affected items
    final affectedItems = await BatchProcessor.processItemBatch(
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
        final areReady = await _orderService.areAllStaffItemsReady(orderId);

        if (areReady) {
          // Mark staff part as ready in local state and Firestore
          updateStaffStatus(orderId, OrderStatus.ready).then((_) async {
            // Now check if the entire order should be completed
            final shouldComplete = await _orderService.shouldCompleteOrder(
              orderId,
            );

            if (shouldComplete) {
              // Mark the entire order as completed
              await _orderService.updateOrderStatus(
                orderId,
                OrderStatus.completed,
              );
            }
          });
        }
      }
    }

    notifyListeners();
  }
}
