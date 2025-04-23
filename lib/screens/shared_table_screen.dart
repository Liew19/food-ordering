// lib/screens/shared_table_screen.dart
/// SharedTableScreen
/// Displays a list of tables available for sharing
/// Implements the anonymous table sharing system

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/table_state.dart';
import '../widgets/sharing_card.dart';
import '../widgets/start_sharing_dialog.dart';
import '../theme.dart';

class SharedTableScreen extends StatelessWidget {
  const SharedTableScreen({super.key});

  void _showStartSharingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder:
          (context) => StartSharingDialog(
            onConfirm: (tableNumber, description) {
              final tableState = Provider.of<TableState>(
                context,
                listen: false,
              );
              tableState.createNewSharing(tableNumber, description);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tableState = Provider.of<TableState>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppTheme.gradientAppBar(
        title: 'Table Sharing',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => tableState.refreshTables(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDarkMode
                  ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.backgroundColor, Color(0xFF1a1a1a)],
                  )
                  : AppTheme.backgroundGradient,
        ),
        child: Consumer<TableState>(
          builder: (context, tableState, child) {
            final tables = tableState.tables;

            if (tables.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.table_bar,
                      size: 80,
                      color: isDarkMode ? AppTheme.textMutedColor : Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tables available',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textDarkColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start sharing a table or wait for others to share',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMutedColor,
                      ),
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
                  bottom: 80,
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
      floatingActionButton: AppTheme.gradientButton(
        text: 'Start Sharing',
        onTap: () => _showStartSharingDialog(context),
        height: 56,
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
