import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fyp/state/order_provider.dart';
import 'package:fyp/models/order.dart';
import 'package:fyp/models/menu_item.dart';
import 'package:fyp/widgets/food_app_bar.dart';

class OrderStatusScreen extends StatelessWidget {
  const OrderStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final sortedOrders = orderProvider.getSortedOrders();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const FoodAppBar(showSearch: true, showCart: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Orders',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                PopupMenuButton<OrderSortAlgorithm>(
                  icon: const Icon(Icons.sort, color: Colors.black54),
                  tooltip: 'Schedule Algorithm',
                  onSelected: (OrderSortAlgorithm algorithm) {
                    orderProvider.setAlgorithm(algorithm);
                  },
                  constraints: const BoxConstraints(
                    minWidth: 220,
                    maxWidth: 280,
                  ),
                  itemBuilder:
                      (
                        BuildContext context,
                      ) => <PopupMenuEntry<OrderSortAlgorithm>>[
                        PopupMenuItem<OrderSortAlgorithm>(
                          value: OrderSortAlgorithm.priority,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.priority_high,
                                color:
                                    orderProvider.currentAlgorithm ==
                                            OrderSortAlgorithm.priority
                                        ? Theme.of(context).primaryColor
                                        : null,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Flexible(
                                child: Text('Basic Priority Algorithm'),
                              ),
                              if (orderProvider.currentAlgorithm ==
                                  OrderSortAlgorithm.priority)
                                Icon(
                                  Icons.check,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                        PopupMenuItem<OrderSortAlgorithm>(
                          value: OrderSortAlgorithm.advancedPriority,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color:
                                    orderProvider.currentAlgorithm ==
                                            OrderSortAlgorithm.advancedPriority
                                        ? Theme.of(context).primaryColor
                                        : null,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Flexible(
                                child: Text('Fair Priority Algorithm'),
                              ),
                              if (orderProvider.currentAlgorithm ==
                                  OrderSortAlgorithm.advancedPriority)
                                Icon(
                                  Icons.check,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                        PopupMenuItem<OrderSortAlgorithm>(
                          value: OrderSortAlgorithm.fcfs,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                color:
                                    orderProvider.currentAlgorithm ==
                                            OrderSortAlgorithm.fcfs
                                        ? Theme.of(context).primaryColor
                                        : null,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Flexible(
                                child: Text('First-Come, First-Served (FCFS)'),
                              ),
                              if (orderProvider.currentAlgorithm ==
                                  OrderSortAlgorithm.fcfs)
                                Icon(
                                  Icons.check,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                        PopupMenuItem<OrderSortAlgorithm>(
                          value: OrderSortAlgorithm.sjf,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timelapse,
                                color:
                                    orderProvider.currentAlgorithm ==
                                            OrderSortAlgorithm.sjf
                                        ? Theme.of(context).primaryColor
                                        : null,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Flexible(
                                child: Text('Shortest Job First (SJF)'),
                              ),
                              if (orderProvider.currentAlgorithm ==
                                  OrderSortAlgorithm.sjf)
                                Icon(
                                  Icons.check,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedOrders.length,
              itemBuilder: (context, index) {
                final order = sortedOrders[index];
                final hasKitchenItems = order.items.any(
                  (item) => !_isStaffItem(item.item),
                );
                final hasStaffItems = order.items.any(
                  (item) => _isStaffItem(item.item),
                );
                final kitchenStatus = orderProvider.getKitchenStatus(order.id);
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
                              if (order.status == OrderStatus.completed)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Completed',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (hasKitchenItems) ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.restaurant,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Kitchen:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      kitchenStatus,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getStatusText(kitchenStatus),
                                    style: TextStyle(
                                      color: _getStatusColor(kitchenStatus),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...order.items
                                .where((item) => !_isStaffItem(item.item))
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 8,
                                      left: 24,
                                    ),
                                    child: Row(
                                      children: [
                                        const Text('•'),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${item.quantity} × ${item.item.name}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                          if (hasKitchenItems && hasStaffItems)
                            const SizedBox(height: 16),
                          if (hasStaffItems) ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_cafe,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Beverages & Desserts:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      staffStatus,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getStatusText(staffStatus),
                                    style: TextStyle(
                                      color: _getStatusColor(staffStatus),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...order.items
                                .where((item) => _isStaffItem(item.item))
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 8,
                                      left: 24,
                                    ),
                                    child: Row(
                                      children: [
                                        const Text('•'),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${item.quantity} × ${item.item.name}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
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
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
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

  String _getStatusText(OrderStatus status) {
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

  bool _isStaffItem(MenuItem item) {
    return item.category.toLowerCase() == 'beverage' ||
        item.category.toLowerCase() == 'dessert';
  }
}
