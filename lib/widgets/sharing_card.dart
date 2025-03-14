/// SharingCard
/// Displays information about a table and allows users to join it
/// Shows table number, status, description, seat progress, and join button

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shared_table.dart';
import '../state/table_state.dart';
import '../theme.dart';
import 'seat_progress_bar.dart';

class SharingCard extends StatelessWidget {
  final SharedTable table;

  const SharingCard({Key? key, required this.table}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tableState = Provider.of<TableState>(context);

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 5,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table number and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Table number
                Text(
                  '🪑 Table ${table.tableId}',
                  style: TextStyle(
                    color: AppTheme.textDarkColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Status label
                _buildStatusLabel(table.status),
              ],
            ),

            const SizedBox(height: 12),

            // Description (if available)
            if (table.status == TableStatus.sharing &&
                table.description != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '📌 ${table.description}',
                  style: TextStyle(
                    color: AppTheme.textDarkColor,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
              ),

            // Seat progress bar
            SeatProgressBar(
              occupiedSeats: table.occupiedSeats,
              capacity: table.capacity,
            ),

            const SizedBox(height: 16),

            // Action buttons
            if (!table.isFull)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppTheme.gradientButton(
                    text: 'Join',
                    onTap: () => _joinTable(context, tableState),
                    width: 100,
                    height: 40,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Build status label with appropriate color
  Widget _buildStatusLabel(TableStatus status) {
    Color color;
    String label;

    switch (status) {
      case TableStatus.available:
        color = Colors.green;
        label = 'Available';
        break;
      case TableStatus.occupied:
        color = AppTheme.primaryDarkColor;
        label = 'Occupied';
        break;
      case TableStatus.sharing:
        color = AppTheme.primaryColor;
        label = 'Sharing';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
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
}
