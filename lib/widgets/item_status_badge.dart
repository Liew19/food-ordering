import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../state/order_provider.dart';

class ItemStatusBadge extends StatelessWidget {
  final String orderId;
  final String itemId;
  final bool isKitchen; // true for kitchen items, false for staff items

  const ItemStatusBadge({
    Key? key,
    required this.orderId,
    required this.itemId,
    required this.isKitchen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final status = orderProvider.getItemStatus(orderId, itemId);

    // Skip badge for pending items
    if (status == OrderStatus.pending) {
      return const SizedBox.shrink();
    }

    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (status) {
      case OrderStatus.preparing:
        backgroundColor = isKitchen 
            ? Colors.orange.withOpacity(0.1) 
            : Colors.blue.withOpacity(0.1);
        textColor = isKitchen ? Colors.orange : Colors.blue;
        statusText = isKitchen ? 'Cooking' : 'Preparing';
        break;
      case OrderStatus.ready:
      case OrderStatus.completed:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        statusText = 'Ready';
        break;
      case OrderStatus.cancelled:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        statusText = 'Cancelled';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
