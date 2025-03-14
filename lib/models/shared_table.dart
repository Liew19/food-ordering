/// SharedTable data model
/// Defines the properties of a restaurant table for the sharing system
/// Supports Hive persistence and includes status management

import 'package:hive/hive.dart';

part 'shared_table.g.dart';

/// Table status enum with three states as per requirements
@HiveType(typeId: 2)
enum TableStatus {
  @HiveField(0)
  available,

  @HiveField(1)
  occupied,

  @HiveField(2)
  sharing,
}

/// SharedTable model with Hive support
@HiveType(typeId: 3)
class SharedTable extends HiveObject {
  @HiveField(0)
  final int tableId;

  @HiveField(1)
  TableStatus status;

  @HiveField(2)
  String? description;

  @HiveField(3)
  final int capacity;

  @HiveField(4)
  int occupiedSeats;

  SharedTable({
    required this.tableId,
    required this.status,
    this.description,
    required this.capacity,
    required this.occupiedSeats,
  });

  /// Get remaining seats
  int get remainingSeats => capacity - occupiedSeats;

  /// Check if table is full
  bool get isFull => occupiedSeats >= capacity;

  /// Check if sharing can be initiated (only when status is occupied)
  bool get canInitiateSharing => status == TableStatus.occupied && !isFull;

  /// Check if table can be joined (only when status is sharing and not full)
  bool get canJoin => status == TableStatus.sharing && !isFull;

  /// Create a copy with updated properties
  SharedTable copyWith({
    int? tableId,
    TableStatus? status,
    String? description,
    int? capacity,
    int? occupiedSeats,
  }) {
    return SharedTable(
      tableId: tableId ?? this.tableId,
      status: status ?? this.status,
      description: description ?? this.description,
      capacity: capacity ?? this.capacity,
      occupiedSeats: occupiedSeats ?? this.occupiedSeats,
    );
  }

  /// Convert to Map for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'tableId': tableId,
      'status': status.index,
      'description': description,
      'capacity': capacity,
      'occupiedSeats': occupiedSeats,
    };
  }

  /// Create from Map for JSON deserialization
  factory SharedTable.fromJson(Map<String, dynamic> json) {
    return SharedTable(
      tableId: json['tableId'],
      status: TableStatus.values[json['status']],
      description: json['description'],
      capacity: json['capacity'],
      occupiedSeats: json['occupiedSeats'],
    );
  }
}
