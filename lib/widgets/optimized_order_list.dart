import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../state/order_provider.dart';
import 'order_item_card.dart';

/// Optimized order list widget that minimizes rebuilds
class OptimizedOrderList extends StatelessWidget {
  final List<Order> orders;
  final bool showActions;
  final String emptyMessage;
  final Widget? emptyWidget;

  const OptimizedOrderList({
    super.key,
    required this.orders,
    required this.showActions,
    this.emptyMessage = 'No orders available',
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return emptyWidget ?? _EmptyState(message: emptyMessage);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderListItem(
          key: ValueKey(order.id),
          order: order,
          showActions: showActions,
        );
      },
    );
  }
}

/// Individual order list item widget to minimize rebuilds
class _OrderListItem extends StatelessWidget {
  final Order order;
  final bool showActions;

  const _OrderListItem({
    Key? key,
    required this.order,
    required this.showActions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        return OrderItemCard(
          order: order,
          displayMode: showActions ? DisplayMode.kitchen : DisplayMode.customer,
        );
      },
    );
  }
}

/// Empty state widget
class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
