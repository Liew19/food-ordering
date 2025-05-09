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
      // Check if box is already open
      if (Hive.isBoxOpen('shared_tables')) {
        _tableBox = Hive.box<SharedTable>('shared_tables');
      } else {
        _tableBox = await Hive.openBox<SharedTable>('shared_tables');
      }
      await _initializeDefaultTables();
    } catch (e) {
      print('Error initializing shared table service: $e');
      // Try to recover from corrupted box
      try {
        await Hive.deleteBoxFromDisk('shared_tables');
        _tableBox = await Hive.openBox<SharedTable>('shared_tables');
        await _initializeDefaultTables();
      } catch (deleteError) {
        print('Failed to recover from corrupted box: $deleteError');
        throw Exception('Failed to initialize shared tables storage');
      }
    }
  }

  /// Initialize default tables for testing
  Future<void> _initializeDefaultTables() async {
    try {
      if (!Hive.isBoxOpen('shared_tables')) {
        _tableBox = Hive.box<SharedTable>('shared_tables');
      }

      if (_tableBox.isEmpty) {
        print('Initializing default tables');
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
        await _tableBox.addAll(defaultTables);
        print('Added ${defaultTables.length} default tables');
      }
    } catch (e) {
      print('Error initializing default tables: $e');
    }
  }

  /// Get all tables
  List<SharedTable> getAllTables() {
    try {
      if (!Hive.isBoxOpen('shared_tables')) {
        _tableBox = Hive.box<SharedTable>('shared_tables');
      }
      return _tableBox.values.toList();
    } catch (e) {
      print('Error getting all tables: $e');
      return [];
    }
  }

  /// Get table by ID
  SharedTable? getTableById(int tableId) {
    try {
      if (!Hive.isBoxOpen('shared_tables')) {
        _tableBox = Hive.box<SharedTable>('shared_tables');
      }
      return _tableBox.values.firstWhere((table) => table.tableId == tableId);
    } catch (e) {
      print('Error getting table by ID: $e');
      return null;
    }
  }

  /// Save a table
  Future<void> saveTable(SharedTable table) async {
    try {
      if (!Hive.isBoxOpen('shared_tables')) {
        _tableBox = Hive.box<SharedTable>('shared_tables');
      }

      final index = _tableBox.values.toList().indexWhere(
        (t) => t.tableId == table.tableId,
      );

      if (index != -1) {
        await _tableBox.putAt(index, table);
      } else {
        await _tableBox.add(table);
      }

      print('Table saved successfully: ${table.tableId}');
    } catch (e) {
      print('Error saving table: $e');
      throw Exception('Failed to save table: ${e.toString()}');
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
