import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/order_provider.dart';
import '../widgets/order_item_card.dart';
import '../models/order.dart';
import '../theme.dart';

class KitchenScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    return Scaffold(
      appBar: AppTheme.gradientAppBar(title: 'Kitchen Orders'),
      body: ListView.builder(
        itemCount: orderProvider.kitchenOrders.length,
        itemBuilder: (context, index) {
          final order = orderProvider.kitchenOrders[index];
          final kitchenOrder = Order(
            id: order.id,
            orderId: order.orderId,
            userId: order.userId,
            tableNumber: order.tableNumber,
            items: order.kitchenItems,
            totalPrice: order.kitchenItems.fold(
              0.0,
              (sum, item) => sum + (item.item.price * item.quantity),
            ),
            status: order.status,
            createdAt: order.createdAt,
            completedAt: order.completedAt,
          );
          return OrderItemCard(order: kitchenOrder);
        },
      ),
    );
  }
}
