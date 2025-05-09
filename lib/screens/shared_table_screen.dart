// lib/screens/shared_table_screen.dart
/// SharedTableScreen
/// Displays a list of tables available for sharing
/// Implements the anonymous table sharing system

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/table_state.dart';
import '../widgets/sharing_card.dart';
import '../widgets/start_sharing_dialog.dart';
import '../widgets/food_app_bar.dart';
import '../theme.dart';
import '../models/shared_table.dart';

class SharedTableScreen extends StatelessWidget {
  const SharedTableScreen({super.key});

  void _showStartSharingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(204),
      builder:
          (context) => StartSharingDialog(
            onConfirm: (tableNumber, description) async {
              final tableState = Provider.of<TableState>(
                context,
                listen: false,
              );
              try {
                await tableState.createNewSharing(tableNumber, description);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Successfully created shared table'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to create shared table: ${e.toString()}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tableState = Provider.of<TableState>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: FoodAppBar(showSearch: true, showCart: true),
      body: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.backgroundColor : Colors.grey[100],
        ),
        child: Column(
          children: [
            // Title and Share Table button row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Shared Tables',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    width: 120, // 固定宽度
                    child: ElevatedButton(
                      onPressed: () => _showStartSharingDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero, // 直角
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Share Table',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Refresh button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => tableState.refreshTables(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ),

            // Table list
            Expanded(
              child: Consumer<TableState>(
                builder: (context, tableState, child) {
                  // Show all tables, not just sharing ones
                  final tables = tableState.tables;

                  if (tables.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.table_bar,
                            size: 80,
                            color:
                                isDarkMode
                                    ? AppTheme.textMutedColor
                                    : Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tables available',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: AppTheme.textDarkColor),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start sharing a table or wait for others to share',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textMutedColor),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => tableState.refreshTables(),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 8,
                        right: 8,
                        top: 8,
                        bottom: 16,
                      ),
                      itemCount: tables.length,
                      itemBuilder: (context, index) {
                        return SharingCard(table: tables[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
