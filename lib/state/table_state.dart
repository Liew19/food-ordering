/// TableState management
/// Uses Provider to manage the state of tables
/// Implements the state transition logic and persistence

import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
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
    // 检查桌号是否已存在
    if (_tables.any((table) => table.tableId == tableNumber)) {
      throw Exception('该桌号已存在，请选择其他桌号');
    }

    // 创建一个新的拼桌记录
    final newTable = SharedTable(
      tableId: tableNumber,
      status: TableStatus.sharing,
      description: description,
      capacity: 4, // 默认4人桌
      occupiedSeats: 1, // 发起者占用1个座位
    );

    await _tableService.saveTable(newTable);
    await _loadTables();
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
