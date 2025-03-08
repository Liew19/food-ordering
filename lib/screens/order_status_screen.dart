import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/order_provider.dart';
import '../widgets/order_item_card.dart';
import '../theme.dart';

class OrderStatusScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final sortedOrders = orderProvider.getSortedOrders();

    return Scaffold(
      appBar: AppTheme.gradientAppBar(
        title: 'Order Status',
        actions: [
          PopupMenuButton<OrderSortAlgorithm>(
            icon: Icon(Icons.sort),
            tooltip: 'Schedule Algorithm',
            onSelected: (OrderSortAlgorithm algorithm) {
              orderProvider.setAlgorithm(algorithm);
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<OrderSortAlgorithm>>[
                  PopupMenuItem<OrderSortAlgorithm>(
                    value: OrderSortAlgorithm.priority,
                    child: Row(
                      children: [
                        Icon(
                          Icons.priority_high,
                          color:
                              orderProvider.currentAlgorithm ==
                                      OrderSortAlgorithm.priority
                                  ? Theme.of(context).primaryColor
                                  : null,
                        ),
                        SizedBox(width: 8),
                        Text('Priority Scheduling Algorithm'),
                        if (orderProvider.currentAlgorithm ==
                            OrderSortAlgorithm.priority)
                          Icon(
                            Icons.check,
                            color: Theme.of(context).primaryColor,
                          ),
                      ],
                    ),
                  ),
                  PopupMenuItem<OrderSortAlgorithm>(
                    value: OrderSortAlgorithm.fcfs,
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color:
                              orderProvider.currentAlgorithm ==
                                      OrderSortAlgorithm.fcfs
                                  ? Theme.of(context).primaryColor
                                  : null,
                        ),
                        SizedBox(width: 8),
                        Text('First-Come, First-Served (FCFS)'),
                        if (orderProvider.currentAlgorithm ==
                            OrderSortAlgorithm.fcfs)
                          Icon(
                            Icons.check,
                            color: Theme.of(context).primaryColor,
                          ),
                      ],
                    ),
                  ),
                  PopupMenuItem<OrderSortAlgorithm>(
                    value: OrderSortAlgorithm.sjf,
                    child: Row(
                      children: [
                        Icon(
                          Icons.timelapse,
                          color:
                              orderProvider.currentAlgorithm ==
                                      OrderSortAlgorithm.sjf
                                  ? Theme.of(context).primaryColor
                                  : null,
                        ),
                        SizedBox(width: 8),
                        Text('Shortest Job First (SJF)'),
                        if (orderProvider.currentAlgorithm ==
                            OrderSortAlgorithm.sjf)
                          Icon(
                            Icons.check,
                            color: Theme.of(context).primaryColor,
                          ),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: sortedOrders.length,
        itemBuilder: (context, index) {
          final order = sortedOrders[index];
          return OrderItemCard(order: order);
        },
      ),
    );
  }
}
