import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/order_provider.dart';
import '../widgets/order_item_card.dart';
import '../models/order.dart';

class StaffScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Staff Orders')),
      body: ListView.builder(
        itemCount: orderProvider.staffOrders.length,
        itemBuilder: (context, index) {
          final order = orderProvider.staffOrders[index];
          final staffOrder = Order(
            id: order.id,
            orderId: order.orderId,
            userId: order.userId,
            tableNumber: order.tableNumber,
            items: order.staffItems,
            totalPrice: order.staffItems.fold(
              0.0,
              (sum, item) => sum + (item.item.price * item.quantity),
            ),
            status: order.status,
            createdAt: order.createdAt,
            completedAt: order.completedAt,
          );
          return OrderItemCard(order: staffOrder);
        },
      ),
    );
  }
}
