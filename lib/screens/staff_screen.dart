import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fyp/state/order_provider.dart';
import 'package:fyp/models/order.dart';
import 'package:fyp/models/menu_item.dart';
import 'package:fyp/widgets/food_app_bar.dart';
import 'package:fyp/widgets/batch_suggestion_card.dart';
import 'package:fyp/widgets/item_status_badge.dart';
import 'package:fyp/widgets/priority_progress_bar.dart';
import 'package:fyp/utils/advanced_priority.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => StaffScreenState();
}

class StaffScreenState extends State<StaffScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const FoodAppBar(showSearch: true, showCart: false),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Staff Orders',
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
                _buildOrderList(
                  orderProvider.getActiveStaffOrders(),
                  showActions: true,
                ),
                // Completed Orders Tab
                _buildOrderList(
                  orderProvider.getCompletedStaffOrders(),
                  showActions: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders, {required bool showActions}) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final List<BatchGroup> batchSuggestions =
        showActions ? orderProvider.getStaffBatchSuggestions() : [];

    // Create a combined list of batches and orders for priority-based sorting
    if (showActions && batchSuggestions.isNotEmpty) {
      // Create a list of all items (batches and orders) with their priorities
      final List<Map<String, dynamic>> combinedItems = [];

      // Add batches with their priorities
      for (var batch in batchSuggestions) {
        combinedItems.add({
          'type': 'batch',
          'item': batch,
          'priority': batch.priority,
          'index': batchSuggestions.indexOf(batch),
        });
      }

      // Add orders with their priorities
      for (var order in orders) {
        combinedItems.add({
          'type': 'order',
          'item': order,
          'priority': order.priority,
          'index': orders.indexOf(order),
        });
      }

      // Sort the combined list by priority (highest first)
      // But also consider the item type, order status, and age
      combinedItems.sort((a, b) {
        // First, check if either item is an order with preparing status
        bool aIsPreparing = false;
        bool bIsPreparing = false;

        // Check if either item is an order with some ready items
        bool aHasReadyItems = false;
        bool bHasReadyItems = false;

        // Check if either item is a batch with items being prepared
        bool aIsBatchBeingPrepared = false;
        bool bIsBatchBeingPrepared = false;

        if (a['type'] == 'order') {
          final order = a['item'] as Order;
          aIsPreparing =
              orderProvider.getStaffStatus(order.id) == OrderStatus.preparing;

          // Check if any items in this order are ready
          for (var item in order.items) {
            if (_isStaffItem(item.item)) {
              // Only check staff items
              final itemStatus = orderProvider.getItemStatus(
                order.id,
                item.item.id,
              );
              if (itemStatus == OrderStatus.ready) {
                aHasReadyItems = true;
                break;
              }
            }
          }
        } else if (a['type'] == 'batch') {
          // Check if any items in this batch are being prepared
          final batch = a['item'] as BatchGroup;
          for (var item in batch.items) {
            final itemStatus = orderProvider.getItemStatus(
              item.order.id,
              item.item.item.id,
            );
            if (itemStatus == OrderStatus.preparing) {
              aIsBatchBeingPrepared = true;
              break;
            }
          }
        }

        if (b['type'] == 'order') {
          final order = b['item'] as Order;
          bIsPreparing =
              orderProvider.getStaffStatus(order.id) == OrderStatus.preparing;

          // Check if any items in this order are ready
          for (var item in order.items) {
            if (_isStaffItem(item.item)) {
              // Only check staff items
              final itemStatus = orderProvider.getItemStatus(
                order.id,
                item.item.id,
              );
              if (itemStatus == OrderStatus.ready) {
                bHasReadyItems = true;
                break;
              }
            }
          }
        } else if (b['type'] == 'batch') {
          // Check if any items in this batch are being prepared
          final batch = b['item'] as BatchGroup;
          for (var item in batch.items) {
            final itemStatus = orderProvider.getItemStatus(
              item.order.id,
              item.item.item.id,
            );
            if (itemStatus == OrderStatus.preparing) {
              bIsBatchBeingPrepared = true;
              break;
            }
          }
        }

        // Batches being prepared come first
        if (aIsBatchBeingPrepared && !bIsBatchBeingPrepared) return -1;
        if (!aIsBatchBeingPrepared && bIsBatchBeingPrepared) return 1;

        // Then orders with ready items
        if (aHasReadyItems && !bHasReadyItems) return -1;
        if (!aHasReadyItems && bHasReadyItems) return 1;

        // Then orders with preparing status
        if (aIsPreparing && !bIsPreparing) return -1;
        if (!aIsPreparing && bIsPreparing) return 1;

        // If both items have the same status (both have ready items, both preparing, or neither),
        // then sort by priority
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
              isKitchen: false,
              allGroups: batchSuggestions,
              index: item['index'],
            );
          } else {
            final order = item['item'] as Order;
            final staffStatus = orderProvider.getStaffStatus(order.id);

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
                            'Order #${order.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          _buildStatusBadge(staffStatus),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Received: ${_getTimeAgo(order.createdAt)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      PriorityProgressBar(priority: order.priority),
                      if (order.status == OrderStatus.completed &&
                          order.completedAt != null)
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
                      const SizedBox(height: 16),
                      const Text(
                        'Beverages & Desserts:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...order.items
                          .where((item) => _isStaffItem(item.item))
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('•'),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${item.quantity} × ${item.item.name}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        // Add status badge for this item
                                        ItemStatusBadge(
                                          orderId: order.id,
                                          itemId: item.item.id,
                                          isKitchen: false,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      if (showActions &&
                          order.status != OrderStatus.completed) ...[
                        const SizedBox(height: 16),
                        if (staffStatus == OrderStatus.pending)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    orderProvider.updateStaffStatus(
                                      order.id,
                                      OrderStatus.preparing,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text(
                                    'Start Preparing',
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
                                  onPressed: () {
                                    orderProvider.updateStaffStatus(
                                      order.id,
                                      OrderStatus.ready,
                                    );
                                  },
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
                        else if (staffStatus == OrderStatus.preparing)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                orderProvider.updateStaffStatus(
                                  order.id,
                                  OrderStatus.ready,
                                );
                              },
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
                    ],
                  ),
                ),
              ),
            );
          }
        },
      );
    } else {
      // If no batch suggestions, just show orders
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final staffStatus = orderProvider.getStaffStatus(order.id);

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
                          'Order #${order.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        _buildStatusBadge(staffStatus),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Received: ${_getTimeAgo(order.createdAt)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    PriorityProgressBar(priority: order.priority),
                    if (order.status == OrderStatus.completed &&
                        order.completedAt != null)
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
                    const SizedBox(height: 16),
                    const Text(
                      'Beverages & Desserts:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...order.items
                        .where((item) => _isStaffItem(item.item))
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('•'),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${item.quantity} × ${item.item.name}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      // Add status badge for this item
                                      ItemStatusBadge(
                                        orderId: order.id,
                                        itemId: item.item.id,
                                        isKitchen: false,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    if (showActions &&
                        order.status != OrderStatus.completed) ...[
                      const SizedBox(height: 16),
                      if (staffStatus == OrderStatus.pending)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  orderProvider.updateStaffStatus(
                                    order.id,
                                    OrderStatus.preparing,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Start Preparing',
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
                                onPressed: () {
                                  orderProvider.updateStaffStatus(
                                    order.id,
                                    OrderStatus.ready,
                                  );
                                },
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
                      else if (staffStatus == OrderStatus.preparing)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              orderProvider.updateStaffStatus(
                                order.id,
                                OrderStatus.ready,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildStatusBadge(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'New Order',
            style: TextStyle(
              color: Color(0xFF1976D2),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        );
      case OrderStatus.preparing:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Preparing',
            style: TextStyle(
              color: Colors.blue,
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
}
