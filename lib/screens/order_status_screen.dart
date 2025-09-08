import 'package:flutter/material.dart';
import 'package:fyp/models/order.dart';
import 'package:fyp/models/menu_item.dart';
import 'package:fyp/widgets/food_app_bar.dart';
import 'package:fyp/services/order_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderStatusScreen extends StatelessWidget {
  const OrderStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderService = OrderService();
    final currentUser = FirebaseAuth.instance.currentUser;

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
                const Icon(Icons.receipt_long, color: Colors.black54),
              ],
            ),
          ),
          Expanded(
            child:
                currentUser == null
                    ? const Center(
                      child: Text(
                        'Please log in to view your orders',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                    : StreamBuilder<List<Order>>(
                      stream: orderService.getUserOrders(currentUser.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text('Error: ${snapshot.error}'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed:
                                      () =>
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      const OrderStatusScreen(),
                                            ),
                                          ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        }

                        final orders = snapshot.data ?? [];
                        if (orders.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No orders yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            final hasKitchenItems = order.items.any(
                              (item) => !_isStaffItem(item.item),
                            );
                            final hasStaffItems = order.items.any(
                              (item) => _isStaffItem(item.item),
                            );

                            // Get kitchen and staff status from Firestore data
                            // For now, we'll derive this from the main order status
                            final kitchenStatus = _deriveKitchenStatus(order);
                            final staffStatus = _deriveStaffStatus(order);

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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Order #${order.id}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (order.status ==
                                              OrderStatus.completed)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green[50],
                                                borderRadius:
                                                    BorderRadius.circular(12),
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
                                            Flexible(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(
                                                    kitchenStatus,
                                                  ).withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  _getStatusText(kitchenStatus),
                                                  style: TextStyle(
                                                    color: _getStatusColor(
                                                      kitchenStatus,
                                                    ),
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 12,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ...order.items
                                            .where(
                                              (item) =>
                                                  !_isStaffItem(item.item),
                                            )
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
                                                    Expanded(
                                                      child: Text(
                                                        '${item.quantity} × ${item.item.name}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: _getStatusColor(
                                                          order.itemStatuses[item
                                                                  .item
                                                                  .id] ??
                                                              OrderStatus
                                                                  .pending,
                                                        ).withValues(
                                                          alpha: 0.1,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        _getStatusText(
                                                          order.itemStatuses[item
                                                                  .item
                                                                  .id] ??
                                                              OrderStatus
                                                                  .pending,
                                                        ),
                                                        style: TextStyle(
                                                          color: _getStatusColor(
                                                            order.itemStatuses[item
                                                                    .item
                                                                    .id] ??
                                                                OrderStatus
                                                                    .pending,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 10,
                                                        ),
                                                      ),
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
                                            const Flexible(
                                              child: Text(
                                                'Beverages & Desserts:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(
                                                    staffStatus,
                                                  ).withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  _getStatusText(staffStatus),
                                                  style: TextStyle(
                                                    color: _getStatusColor(
                                                      staffStatus,
                                                    ),
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 12,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ...order.items
                                            .where(
                                              (item) => _isStaffItem(item.item),
                                            )
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
                                                    Expanded(
                                                      child: Text(
                                                        '${item.quantity} × ${item.item.name}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: _getStatusColor(
                                                          order.itemStatuses[item
                                                                  .item
                                                                  .id] ??
                                                              OrderStatus
                                                                  .pending,
                                                        ).withValues(
                                                          alpha: 0.1,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        _getStatusText(
                                                          order.itemStatuses[item
                                                                  .item
                                                                  .id] ??
                                                              OrderStatus
                                                                  .pending,
                                                        ),
                                                        style: TextStyle(
                                                          color: _getStatusColor(
                                                            order.itemStatuses[item
                                                                    .item
                                                                    .id] ??
                                                                OrderStatus
                                                                    .pending,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 10,
                                                        ),
                                                      ),
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

  // Helper method to derive kitchen status from main order status
  OrderStatus _deriveKitchenStatus(Order order) {
    if (!order.isKitchenOrder) return OrderStatus.completed;
    return order.status;
  }

  // Helper method to derive staff status from main order status
  OrderStatus _deriveStaffStatus(Order order) {
    if (!order.isStaffOrder) return OrderStatus.completed;
    return order.status;
  }
}
