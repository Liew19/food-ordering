/// TableState management
/// Uses Provider to manage the state of tables
/// Implements the state transition logic and persistence

import 'package:flutter/foundation.dart';
import '../models/shared_table.dart';
import '../services/shared_table_service.dart';

/// ChangeNotifier for managing table state
class TableState extends ChangeNotifier {
  final SharedTableService _tableService;
  List<SharedTable> _tables = [];

  TableState(this._tableService) {
    _loadTables();
  }

  /// Get all tables
  List<SharedTable> get tables => _tables;

  /// Load tables from the service
  Future<void> _loadTables() async {
    _tables = _tableService.getAllTables();
    notifyListeners();
  }

  /// Refresh tables from the service
  Future<void> refreshTables() async {
    await _loadTables();
  }

  /// Create a new sharing table with specified table number
  Future<void> createNewSharing(int tableNumber, String? description) async {
    try {
      // Check if table number already exists
      if (_tables.any((table) => table.tableId == tableNumber)) {
        throw Exception(
          'Table number already exists, please choose another one',
        );
      }

      // Validate description length
      final validDescription =
          description != null && description.trim().isNotEmpty
              ? description.trim().length > 15
                  ? description.trim().substring(0, 15)
                  : description.trim()
              : null;

      // Create a new shared table
      final newTable = SharedTable(
        tableId: tableNumber,
        status: TableStatus.sharing,
        description: validDescription,
        capacity: 4, // Default 4-person table
        occupiedSeats: 1, // Initiator occupies 1 seat
      );

      await _tableService.saveTable(newTable);
      await _loadTables();
    } catch (e) {
      print('Error creating new sharing table: $e');
      rethrow;
    }
  }

  /// Start sharing a table
  /// Changes status from Occupied to Sharing
  Future<void> startSharing(int tableId, String? description) async {
    // Validate description length
    final validDescription =
        description != null && description.trim().isNotEmpty
            ? description.trim().length > 15
                ? description.trim().substring(0, 15)
                : description.trim()
            : null;

    await _tableService.startSharing(tableId, validDescription);
    await _loadTables();
  }

  /// Join a shared table
  /// Increments occupied seats and updates status if full
  Future<bool> joinTable(int tableId) async {
    final success = await _tableService.joinTable(tableId);
    await _loadTables();
    return success;
  }

  /// Occupy a table
  /// Changes status from Available to Occupied
  Future<void> occupyTable(int tableId, int initialSeats) async {
    await _tableService.occupyTable(tableId, initialSeats);
    await _loadTables();
  }

  /// Reset a table to Available
  Future<void> resetTable(int tableId) async {
    await _tableService.resetTable(tableId);
    await _loadTables();
  }

  /// Get a table by ID
  SharedTable? getTableById(int tableId) {
    try {
      return _tables.firstWhere((table) => table.tableId == tableId);
    } catch (e) {
      return null;
    }
  }
}
