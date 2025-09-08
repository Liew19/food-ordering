import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fyp/models/order.dart';
import 'package:fyp/models/menu_item.dart';
import 'package:fyp/state/cart_provider.dart';
import 'package:fyp/widgets/food_app_bar.dart';
import 'package:fyp/widgets/priority_progress_bar.dart';
import 'package:fyp/widgets/batch_suggestion_card.dart';
import 'package:fyp/utils/advanced_priority.dart';
import 'package:fyp/services/order_service.dart';
import 'package:provider/provider.dart';
import 'package:fyp/state/order_provider.dart';

class KitchenScreenFirestore extends StatefulWidget {
  const KitchenScreenFirestore({super.key});

  @override
  State<KitchenScreenFirestore> createState() => _KitchenScreenFirestoreState();
}

class _KitchenScreenFirestoreState extends State<KitchenScreenFirestore>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();
  Timer? _priorityUpdateTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Update priorities every 30 seconds to reflect wait time changes
    _priorityUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _orderService.updateAllOrderPriorities();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _priorityUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const FoodAppBar(showSearch: true, showCart: false),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Kitchen Orders',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelStyle: const TextStyle(fontSize: 13),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: const [
                Tab(height: 40, text: 'Active Orders'),
                Tab(height: 40, text: 'Order History'),
              ],
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Active Orders Tab
                Consumer<OrderProvider>(
                  builder: (context, orderProvider, child) {
                    return StreamBuilder<List<Order>>(
                      stream: _orderService.getKitchenOrders(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }

                        final activeOrders = snapshot.data ?? [];

                        if (activeOrders.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.restaurant,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No active orders',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return _buildOrderList(activeOrders, showActions: true);
                      },
                    );
                  },
                ),
                // Completed Orders Tab
                Consumer<OrderProvider>(
                  builder: (context, orderProvider, child) {
                    return StreamBuilder<List<Order>>(
                      stream: _orderService.getCompletedOrders(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }

                        final orders = snapshot.data ?? [];
                        if (orders.isEmpty) {
                          return const Center(
                            child: Text(
                              'No completed orders',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }

                        return _buildOrderList(orders, showActions: false);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders, {required bool showActions}) {
    // Filter orders to show only those with kitchen items
    final kitchenOrders =
        orders.where((order) => order.isKitchenOrder).toList();

    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        // Get batch suggestions if actions are shown (active orders tab)
        final batchSuggestions =
            showActions
                ? _getBatchSuggestionsForOrders(
                  kitchenOrders,
                  orderProvider,
                  true,
                )
                : <BatchGroup>[];

        // Combine orders and batch suggestions
        final List<Map<String, dynamic>> combinedItems = [];

        // Add batch suggestions first
        for (int i = 0; i < batchSuggestions.length; i++) {
          combinedItems.add({
            'type': 'batch',
            'item': batchSuggestions[i],
            'index': i,
            'priority': batchSuggestions[i].priority,
          });
        }

        // Add individual orders
        for (final order in kitchenOrders) {
          combinedItems.add({
            'type': 'order',
            'item': order,
            'priority': order.priority,
          });
        }

        // Sort by priority and preparation status
        combinedItems.sort((a, b) {
          bool aIsPreparing = false;
          bool bIsPreparing = false;
          bool aHasReadyItems = false;
          bool bHasReadyItems = false;

          if (a['type'] == 'order') {
            final order = a['item'] as Order;
            aIsPreparing = order.kitchenStatus == OrderStatus.preparing;

            // Check if any items in this order are ready
            for (var item in order.items) {
              if (!_isStaffItem(item.item)) {
                final itemStatus =
                    order.itemStatuses[item.item.id] ?? OrderStatus.pending;
                if (itemStatus == OrderStatus.ready) {
                  aHasReadyItems = true;
                  break;
                }
              }
            }
          } else if (a['type'] == 'batch') {
            final batch = a['item'] as BatchGroup;
            for (var item in batch.items) {
              final itemStatus = orderProvider.getItemStatus(
                item.order.id,
                item.item.item.id,
              );
              if (itemStatus == OrderStatus.preparing) {
                aIsPreparing = true;
              }
              if (itemStatus == OrderStatus.ready) {
                aHasReadyItems = true;
              }
            }
          }

          if (b['type'] == 'order') {
            final order = b['item'] as Order;
            bIsPreparing = order.kitchenStatus == OrderStatus.preparing;

            for (var item in order.items) {
              if (!_isStaffItem(item.item)) {
                final itemStatus =
                    order.itemStatuses[item.item.id] ?? OrderStatus.pending;
                if (itemStatus == OrderStatus.ready) {
                  bHasReadyItems = true;
                  break;
                }
              }
            }
          } else if (b['type'] == 'batch') {
            final batch = b['item'] as BatchGroup;
            for (var item in batch.items) {
              final itemStatus = orderProvider.getItemStatus(
                item.order.id,
                item.item.item.id,
              );
              if (itemStatus == OrderStatus.preparing) {
                bIsPreparing = true;
              }
              if (itemStatus == OrderStatus.ready) {
                bHasReadyItems = true;
              }
            }
          }

          // Prioritize items being prepared or with ready items
          if (aIsPreparing && !bIsPreparing) return -1;
          if (bIsPreparing && !aIsPreparing) return 1;
          if (aHasReadyItems && !bHasReadyItems) return -1;
          if (bHasReadyItems && !aHasReadyItems) return 1;

          return b['priority'].compareTo(a['priority']);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: combinedItems.length,
          itemBuilder: (context, index) {
            final item = combinedItems[index];

            if (item['type'] == 'batch') {
              final batchGroup = item['item'] as BatchGroup;
              return BatchSuggestionCard(
                batchGroup: batchGroup,
                isKitchen: true,
                allGroups: batchSuggestions,
                index: item['index'],
              );
            } else {
              final order = item['item'] as Order;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #${order.id.substring(0, 8)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            _buildStatusBadge(order.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Received: ${_getTimeAgo(order.createdAt)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        PriorityProgressBar(priority: order.priority),
                        if (order.completedAt != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Completed: ${_getTimeAgo(order.completedAt!)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Text(
                          'Food Items:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        // Single list with inline controls on the right
                        ...order.items
                            .where((item) => !_isStaffItem(item.item))
                            .map(
                              (item) => _buildMealStatusControl(order.id, item),
                            ),
                        if (showActions &&
                            order.status != OrderStatus.completed) ...[
                          const SizedBox(height: 16),
                          if (order.status == OrderStatus.pending)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed:
                                        () => _updateOrderStatus(
                                          order.id,
                                          OrderStatus.preparing,
                                        ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text(
                                      'Start Cooking',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed:
                                        () => _updateOrderStatus(
                                          order.id,
                                          OrderStatus.ready,
                                        ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4CAF50),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text(
                                      'Ready',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else if (order.status == OrderStatus.preparing)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    () => _updateOrderStatus(
                                      order.id,
                                      OrderStatus.ready,
                                    ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Ready',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                          // Order-level buttons below act as bulk operations only
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'New Order',
            style: TextStyle(
              color: Color(0xFFFFA000),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        );
      case OrderStatus.preparing:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Cooking',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        );
      case OrderStatus.ready:
      case OrderStatus.completed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Ready',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        );
      default:
        return Container();
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    final minutes = difference.inMinutes;

    if (minutes < 1) {
      return 'Just now';
    } else if (minutes == 1) {
      return '1 min ago';
    } else if (minutes < 60) {
      return '$minutes mins ago';
    } else {
      final hours = difference.inHours;
      if (hours == 1) {
        return '1 hour ago';
      } else {
        return '$hours hours ago';
      }
    }
  }

  bool _isStaffItem(MenuItem item) {
    return item.category.toLowerCase() == 'beverage' ||
        item.category.toLowerCase() == 'dessert';
  }

  // Get batch suggestions for a specific set of orders
  List<BatchGroup> _getBatchSuggestionsForOrders(
    List<Order> orders,
    OrderProvider orderProvider,
    bool isKitchen,
  ) {
    // Only show batch suggestions when using advanced priority algorithm
    if (orderProvider.currentAlgorithm != OrderSortAlgorithm.advancedPriority) {
      return [];
    }

    // Get batch suggestions based on the provided orders
    final batches =
        isKitchen
            ? BatchProcessor.identifySimilarFoodItems(
              orders,
              orderProvider.getKitchenStatus,
              (orderId, itemId) => orderProvider.getItemStatus(orderId, itemId),
            )
            : BatchProcessor.identifySimilarBeverages(
              orders,
              orderProvider.getStaffStatus,
              (orderId, itemId) => orderProvider.getItemStatus(orderId, itemId),
            );

    // Calculate priority for each batch based on the orders it contains
    final Map<BatchGroup, double> batchPriorities = {};

    for (var batch in batches) {
      double maxPriority = 0.0;
      bool hasInProgressItems = false;
      bool hasReadyItems = false;

      for (var item in batch.items) {
        final order = item.order;
        if (order.priority > maxPriority) {
          maxPriority = order.priority;
        }

        final itemStatus = orderProvider.getItemStatus(
          order.id,
          item.item.item.id,
        );
        if (itemStatus == OrderStatus.preparing) {
          hasInProgressItems = true;
        } else if (itemStatus == OrderStatus.ready) {
          hasReadyItems = true;
        }
      }

      // Boost priority for batches with items in progress
      if (hasInProgressItems) {
        maxPriority = 0.95; // Very high priority for in-progress batches
      } else if (hasReadyItems) {
        maxPriority = 0.9; // High priority for batches with ready items
      }

      batchPriorities[batch] = maxPriority;
      batch.priority = maxPriority; // Set the batch's priority
    }

    // Sort batches by priority (highest first)
    batches.sort((a, b) => batchPriorities[b]!.compareTo(batchPriorities[a]!));

    return batches;
  }

  // Get color for meal status
  Color _getMealStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.amber;
      case OrderStatus.preparing:
        return Colors.orange;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  // Get text for meal status
  String _getMealStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Build individual meal status control widget
  Widget _buildMealStatusControl(String orderId, CartItem cartItem) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        // Get the actual status of this meal from the order data
        final order = orderProvider.orders.firstWhere(
          (o) => o.id == orderId,
          orElse:
              () => Order(
                id: orderId,
                items: [],
                totalPrice: 0,
                status: OrderStatus.pending,
                createdAt: DateTime.now(),
              ),
        );
        final currentStatus =
            order.itemStatuses[cartItem.item.id] ?? OrderStatus.pending;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${cartItem.quantity} × ${cartItem.item.name}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Status badge with actual status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getMealStatusColor(
                    currentStatus,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getMealStatusText(currentStatus),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getMealStatusColor(currentStatus),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Status control buttons - show only relevant buttons based on current status
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show different buttons based on current status
                  if (currentStatus == OrderStatus.pending) ...[
                    // Preparing button - only show when pending
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed:
                            () => _updateMealStatus(
                              orderId,
                              cartItem.item.id,
                              OrderStatus.preparing,
                            ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'Preparing',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Ready button - can go directly from pending to ready
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed:
                            () => _updateMealStatus(
                              orderId,
                              cartItem.item.id,
                              OrderStatus.ready,
                            ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'Ready',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ] else if (currentStatus == OrderStatus.preparing) ...[
                    // Only Ready button when preparing
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed:
                            () => _updateMealStatus(
                              orderId,
                              cartItem.item.id,
                              OrderStatus.ready,
                            ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'Ready',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                  // No buttons when ready or completed - status cannot be changed
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Update individual meal status
  Future<void> _updateMealStatus(
    String orderId,
    String itemId,
    OrderStatus status,
  ) async {
    try {
      // Get the OrderProvider from context
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      // Update individual item status
      await orderProvider.updateItemStatus(orderId, itemId, status);

      // If marking as ready, check if all kitchen items are ready
      if (status == OrderStatus.ready) {
        // Check if all kitchen items are now ready
        final allKitchenItemsReady = await _orderService
            .areAllKitchenItemsReady(orderId);

        if (allKitchenItemsReady) {
          // Update kitchen status to ready since all kitchen items are ready
          await orderProvider.updateKitchenStatus(orderId, OrderStatus.ready);

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
        } else {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Meal status updated to ${status.toString().split('.').last}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update meal status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      // Get the OrderProvider from context
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      // Update kitchen status using OrderProvider (this will also update individual item statuses)
      await orderProvider.updateKitchenStatus(orderId, status);

      // If marking as ready, check if the entire order should be completed
      if (status == OrderStatus.ready) {
        // Check if all parts of the order are ready
        final shouldComplete = await _orderService.shouldCompleteOrder(orderId);

        if (shouldComplete) {
          // Mark the entire order as completed
          await _orderService.updateOrderStatus(orderId, OrderStatus.completed);
        } else {
          // Just update main status to ready
          await _orderService.updateOrderStatus(orderId, OrderStatus.ready);
        }
      } else {
        // For other statuses (preparing), update both kitchen and main status
        await _orderService.updateOrderStatus(orderId, status);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order status updated to ${status.toString().split('.').last}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
