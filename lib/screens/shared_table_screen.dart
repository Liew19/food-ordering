// lib/screens/shared_table_screen.dart
import 'package:flutter/material.dart';
import 'package:fyp/models/table.dart';
import '../widgets/shared_table_dialog.dart';
import '../widgets/table_legend.dart';
import '../widgets/table_grid_item.dart';

class SharedTableScreen extends StatefulWidget {
  const SharedTableScreen({Key? key}) : super(key: key);

  @override
  State<SharedTableScreen> createState() => _SharedTableScreenState();
}

class _SharedTableScreenState extends State<SharedTableScreen> {
  // Track user's sharing preference
  bool? acceptSharing;

  // List of tables with sharing status
  List<RestaurantTable> tables = [
    RestaurantTable(
      id: 1,
      status: TableStatus.available,
      isShared: true,
      occupiedSeats: 0,
      maxCapacity: 4,
      canShare: true,
    ),
    RestaurantTable(
      id: 2,
      status: TableStatus.occupied,
      isShared: true,
      occupiedSeats: 2,
      maxCapacity: 4,
      canShare: true,
    ),
    RestaurantTable(
      id: 3,
      status: TableStatus.cleaning,
      isShared: false,
      occupiedSeats: 0,
      maxCapacity: 2,
      canShare: false,
    ),
    RestaurantTable(
      id: 4,
      status: TableStatus.available,
      isShared: false,
      occupiedSeats: 0,
      maxCapacity: 2,
      canShare: false,
    ),
    RestaurantTable(
      id: 5,
      status: TableStatus.reserved,
      isShared: true,
      occupiedSeats: 1,
      maxCapacity: 6,
      canShare: true,
    ),
    RestaurantTable(
      id: 6,
      status: TableStatus.available,
      isShared: true,
      occupiedSeats: 2,
      maxCapacity: 4,
      canShare: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Show the sharing preference dialog when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInitialSharingDialog();
    });
  }

  // Show initial sharing preference dialog
  void _showInitialSharingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder:
          (context) => SharedTableDialog(
            onAccept: (accept) {
              setState(() {
                acceptSharing = accept;
              });
              Navigator.of(context).pop();
            },
          ),
    );
  }

  // Reserve a table
  void _reserveTable(int tableId) {
    setState(() {
      final tableIndex = tables.indexWhere((table) => table.id == tableId);
      if (tableIndex != -1) {
        final table = tables[tableIndex];

        // If it's a shared table, increment the capacity
        if (table.isShared) {
          tables[tableIndex] = table.copyWith(
            occupiedSeats: table.occupiedSeats + 1,
            status:
                table.occupiedSeats + 1 >= table.maxCapacity
                    ? TableStatus.occupied
                    : TableStatus.available,
          );
        } else {
          // For non-shared tables, mark as reserved
          tables[tableIndex] = table.copyWith(status: TableStatus.reserved);
        }

        // Show confirmation
        _showReservationConfirmation(table);
      }
    });
  }

  // Show reservation confirmation
  void _showReservationConfirmation(RestaurantTable table) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Reservation Confirmed'),
            content: Text(
              'You have reserved ${table.isShared ? "a seat at" : ""} Table ${table.id}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  // Change sharing preference
  void _changeSharingPreference() {
    showDialog(
      context: context,
      builder:
          (context) => SharedTableDialog(
            onAccept: (accept) {
              setState(() {
                acceptSharing = accept;
              });
              Navigator.of(context).pop();
            },
          ),
    );
  }

  // Check if a table should be clickable
  bool _isTableClickable(RestaurantTable table) {
    if (table.status == TableStatus.available) {
      return true;
    }

    // Shared tables that aren't full yet can still be clicked
    if (table.isShared &&
        (table.status == TableStatus.occupied ||
            table.status == TableStatus.reserved) &&
        table.occupiedSeats < table.maxCapacity) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Filter tables based on user's sharing preference
    final visibleTables =
        acceptSharing != null
            ? tables
                .where((table) => acceptSharing! || !table.isShared)
                .toList()
            : <RestaurantTable>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Table Reservations'),
        actions: [
          // Allow users to change sharing preference anytime
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _changeSharingPreference,
            tooltip: 'Change sharing preference',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show current sharing preference
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade200,
                  child: Row(
                    children: [
                      Icon(
                        acceptSharing == true ? Icons.people : Icons.person,
                        color:
                            acceptSharing == true ? Colors.green : Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          acceptSharing == true
                              ? 'You are willing to share tables with others'
                              : acceptSharing == false
                              ? 'You prefer not to share tables'
                              : 'Please set your sharing preference',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Table legend
                TableLegend(),

                const SizedBox(height: 16),

                // Tables grid
                acceptSharing != null
                    ? visibleTables.isEmpty
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No tables available for your preference',
                            ),
                          ),
                        )
                        : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.8,
                              ),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: visibleTables.length,
                          itemBuilder: (context, index) {
                            final table = visibleTables[index];
                            final bool isClickable = _isTableClickable(table);

                            return TableGridItem(
                              table: table,
                              isClickable: isClickable,
                              onTableTap: _reserveTable,
                            );
                          },
                        )
                    : const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Please set your sharing preference'),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
