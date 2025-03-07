// lib/widgets/order_item_card.dart
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/menu_item.dart';

class OrderItemCard extends StatelessWidget {
  final Order order;

  const OrderItemCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(order.id.length - 6)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(context),
              ],
            ),
            const Divider(height: 24),

            // Show table number (if exists)
            if (order.tableNumber != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Table: ${order.tableNumber}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

            // Order items list
            ...order.items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        // Item quantity
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${item.quantity}',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Item name
                        Expanded(
                          child: Text(
                            item.item.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),

                        // Item category label
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _isStaffItem(item.item)
                                    ? Colors.purple.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _isStaffItem(item.item) ? 'Staff' : 'Kitchen',
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  _isStaffItem(item.item)
                                      ? Colors.purple
                                      : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Item price
                        Text(
                          '¥${(item.item.price * item.quantity).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),

            const Divider(height: 24),

            // Order footer information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '¥${order.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Order time
            Text(
              'Ordered at: ${_formatDateTime(order.createdAt)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),

            // If order is completed, show completion time
            if (order.completedAt != null)
              Text(
                'Completed at: ${_formatDateTime(order.completedAt!)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  // Build status chip
  Widget _buildStatusChip(BuildContext context) {
    Color chipColor;

    // Set color based on order status
    switch (order.status) {
      case OrderStatus.pending:
        chipColor = Colors.orange;
        break;
      case OrderStatus.preparing:
        chipColor = Colors.blue;
        break;
      case OrderStatus.ready:
        chipColor = Colors.green;
        break;
      case OrderStatus.completed:
        chipColor = Colors.purple;
        break;
      case OrderStatus.cancelled:
        chipColor = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        order.statusText,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // Format date time
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Determine if item is handled by staff (beverages and desserts)
  bool _isStaffItem(MenuItem item) {
    return item.category.toLowerCase() == 'beverage' ||
        item.category.toLowerCase() == 'dessert';
  }
}
