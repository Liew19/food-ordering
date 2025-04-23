import 'package:flutter/material.dart';
import '../models/order.dart';
import 'order_item_card.dart';

class OrdersList extends StatelessWidget {
  final List<Order> orders;
  final DisplayMode displayMode;

  const OrdersList({Key? key, required this.orders, required this.displayMode})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            'Your Orders',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return OrderItemCard(
                order: orders[index],
                displayMode: displayMode,
              );
            },
          ),
        ),
      ],
    );
  }
}
