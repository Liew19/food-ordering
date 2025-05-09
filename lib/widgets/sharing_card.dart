/// SharingCard
/// Displays information about a table and allows users to join it
/// Shows table number, status, description, seat progress, and join button

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shared_table.dart';
import '../state/table_state.dart';
import '../theme.dart';
import 'seat_progress_bar.dart';
import 'share_description_dialog.dart';

class SharingCard extends StatelessWidget {
  final SharedTable table;

  const SharingCard({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    final tableState = Provider.of<TableState>(context);
    final remainingSeats = table.capacity - table.occupiedSeats;

    // Determine card color based on table status
    Color cardColor = Colors.white;
    if (table.status == TableStatus.available) {
      cardColor = Colors.grey[50]!;
    } else if (table.status == TableStatus.occupied) {
      cardColor = Colors.blue[50]!;
    } else if (table.status == TableStatus.sharing) {
      cardColor = Colors.white;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with table info and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Table info with icon
                Row(
                  children: [
                    // Icon based on status
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _getStatusColor(
                        table.status,
                      ).withAlpha(50),
                      child: Icon(
                        _getStatusIcon(table.status),
                        color: _getStatusColor(table.status),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Table number and description
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Table ${table.tableId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _getStatusText(table.status),
                          style: TextStyle(
                            color: _getStatusColor(table.status),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (table.description != null &&
                            table.status == TableStatus.sharing)
                          Text(
                            table.description!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // Seats info chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    table.status == TableStatus.available
                        ? '${table.capacity} seats'
                        : '$remainingSeats seats left',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Capacity info
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${table.capacity} total seats',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                if (table.status != TableStatus.available) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${table.occupiedSeats} occupied',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ],
            ),

            // Only show participants for sharing tables
            if (table.status == TableStatus.sharing) ...[
              const SizedBox(height: 16),

              // Current participants text
              const Text(
                'Current participants:',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),

              const SizedBox(height: 8),

              // Seat progress bar
              SeatProgressBar(
                occupiedSeats: table.occupiedSeats,
                capacity: table.capacity,
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons based on table status
            SizedBox(
              width: double.infinity,
              child: _buildActionButton(context, tableState),
            ),
          ],
        ),
      ),
    );
  }

  // Build appropriate action button based on table status
  Widget _buildActionButton(BuildContext context, TableState tableState) {
    switch (table.status) {
      case TableStatus.available:
        return ElevatedButton(
          onPressed: () => _occupyTable(context, tableState),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor, // 使用红色主题
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // 直角
            ),
          ),
          child: const Text(
            'Occupy Table',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        );

      case TableStatus.occupied:
        return ElevatedButton(
          onPressed: () => _startSharing(context, tableState),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // 直角
            ),
          ),
          child: const Text(
            'Start Sharing',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        );

      case TableStatus.sharing:
        if (!table.isFull) {
          return ElevatedButton(
            onPressed: () => _joinTable(context, tableState),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero, // 直角
              ),
            ),
            child: const Text(
              'Join Table',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          );
        } else {
          return ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero, // 直角
              ),
            ),
            child: const Text(
              'Table Full',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          );
        }
    }
  }

  // Get color based on table status
  Color _getStatusColor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return Colors.green;
      case TableStatus.occupied:
        return Colors.blue;
      case TableStatus.sharing:
        return AppTheme.primaryColor;
    }
  }

  // Get icon based on table status
  IconData _getStatusIcon(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return Icons.check_circle;
      case TableStatus.occupied:
        return Icons.people;
      case TableStatus.sharing:
        return Icons.group_add;
    }
  }

  // Get text description based on table status
  String _getStatusText(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.sharing:
        return 'Sharing';
    }
  }

  // Join a shared table
  void _joinTable(BuildContext context, TableState tableState) async {
    try {
      final success = await tableState.joinTable(table.tableId);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined table ${table.tableId}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Occupy an available table
  void _occupyTable(BuildContext context, TableState tableState) async {
    try {
      await tableState.occupyTable(
        table.tableId,
        1,
      ); // Occupy with 1 person initially

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully occupied table ${table.tableId}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to occupy table: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Start sharing an occupied table
  void _startSharing(BuildContext context, TableState tableState) async {
    // Show dialog to enter description
    final description = await showDialog<String>(
      context: context,
      builder: (context) => const ShareDescriptionDialog(),
    );

    // Process the result
    if (description != null) {
      try {
        await tableState.startSharing(table.tableId, description);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully started sharing table ${table.tableId}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start sharing: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
