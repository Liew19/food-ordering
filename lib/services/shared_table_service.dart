/// SharedTableService
/// Manages the persistence and retrieval of SharedTable data using Hive
/// Handles table status transitions and sharing operations

import 'package:hive/hive.dart';
import '../models/shared_table.dart';

class SharedTableService {
  static final SharedTableService _instance = SharedTableService._internal();
  late Box<SharedTable> _tableBox;
  static bool _isAdapterRegistered = false;
  static const int MAX_RETRIES = 3;

  factory SharedTableService() {
    return _instance;
  }

  SharedTableService._internal();

  /// Initialize the service and register adapters
  Future<void> init() async {
    try {
      await Hive.openBox<SharedTable>('shared_tables');
      await _initializeDefaultTables();
    } catch (e) {
      // Try to recover from corrupted box
      try {
        await Hive.deleteBoxFromDisk('shared_tables');
        await Hive.openBox<SharedTable>('shared_tables');
        await _initializeDefaultTables();
      } catch (deleteError) {
        throw Exception('Failed to initialize shared tables storage');
      }
    }
  }

  /// Initialize default tables for testing
  Future<void> _initializeDefaultTables() async {
    try {
      final box = Hive.box<SharedTable>('shared_tables');
      if (box.isEmpty) {
        // Initialize with some default tables
        final defaultTables = List.generate(
          10,
          (index) => SharedTable(
            tableId: index + 1,
            status: TableStatus.available,
            capacity: 4,
            occupiedSeats: 0,
          ),
        );
        await box.addAll(defaultTables);
      }
    } catch (e) {
      // Silently handle initialization errors
    }
  }

  /// Get all tables
  List<SharedTable> getAllTables() {
    try {
      final box = Hive.box<SharedTable>('shared_tables');
      return box.values.toList();
    } catch (e) {
      return [];
    }
  }

  /// Get table by ID
  SharedTable? getTableById(int tableId) {
    try {
      final box = Hive.box<SharedTable>('shared_tables');
      return box.values.firstWhere((table) => table.tableId == tableId);
    } catch (e) {
      return null;
    }
  }

  /// Save a table
  Future<void> saveTable(SharedTable table) async {
    try {
      final box = Hive.box<SharedTable>('shared_tables');
      final index = box.values.toList().indexWhere(
        (t) => t.tableId == table.tableId,
      );
      if (index != -1) {
        await box.putAt(index, table);
      } else {
        await box.add(table);
      }
    } catch (e) {
      throw Exception('Failed to save table');
    }
  }

  /// Start sharing a table
  /// Changes status from Occupied to Sharing
  Future<void> startSharing(int tableId, String? description) async {
    try {
      final table = getTableById(tableId);
      if (table != null) {
        table.status = TableStatus.sharing;
        table.description = description;
        await saveTable(table);
      }
    } catch (e) {
      throw Exception('Failed to start table sharing');
    }
  }

  /// Join a shared table
  /// Increments occupied seats and updates status if full
  Future<bool> joinTable(int tableId) async {
    try {
      final table = getTableById(tableId);
      if (table != null && table.status == TableStatus.sharing) {
        if (table.occupiedSeats < table.capacity) {
          table.occupiedSeats++;
          if (table.occupiedSeats >= table.capacity) {
            table.status = TableStatus.occupied;
          }
          await saveTable(table);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Occupy a table
  /// Changes status from Available to Occupied
  Future<void> occupyTable(int tableId, int initialSeats) async {
    try {
      final table = getTableById(tableId);
      if (table != null) {
        table.status = TableStatus.occupied;
        table.occupiedSeats = initialSeats;
        await saveTable(table);
      }
    } catch (e) {
      throw Exception('Failed to occupy table');
    }
  }

  /// Reset a table to Available
  Future<void> resetTable(int tableId) async {
    try {
      final table = getTableById(tableId);
      if (table != null) {
        table.status = TableStatus.available;
        table.occupiedSeats = 0;
        table.description = null;
        await saveTable(table);
      }
    } catch (e) {
      throw Exception('Failed to reset table');
    }
  }
}
