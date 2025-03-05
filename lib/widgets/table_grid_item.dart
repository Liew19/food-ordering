// lib/widgets/table_grid_item.dart
import 'package:flutter/material.dart';
import 'package:fyp/models/table.dart';

class TableGridItem extends StatelessWidget {
  final RestaurantTable table;
  final bool isClickable;
  final Function(int) onTableTap;

  const TableGridItem({
    Key? key,
    required this.table,
    required this.isClickable,
    required this.onTableTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the corresponding color and label for the table status
    Color statusColor;
    String statusText;

    switch (table.status) {
      case TableStatus.available:
        statusColor = Colors.green;
        statusText = 'Available';
        break;
      case TableStatus.occupied:
        statusColor = Colors.red;
        statusText = 'Occupied';
        break;
      case TableStatus.reserved:
        statusColor = Colors.orange;
        statusText = 'Reserved';
        break;
      case TableStatus.cleaning:
        statusColor = Colors.grey;
        statusText = 'Cleaning';
        break;
    }

    return GestureDetector(
      onTap: isClickable ? () => onTableTap(table.id) : null,
      child: Container(
        decoration: BoxDecoration(
          color: table.isShared ? Colors.purple.shade100 : Colors.blue.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isClickable ? Colors.green.shade300 : Colors.grey.shade400,
            width: isClickable ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Table Title
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Table ${table.id}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            // Status Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Table Type
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                table.isShared ? 'Shared Table' : 'Private Table',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),

            // Capacity Information
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Capacity: ${table.occupiedSeats}/${table.maxCapacity}',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
