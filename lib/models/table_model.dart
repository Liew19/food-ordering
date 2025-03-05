class TableModel {
  final int id;
  final int capacity;
  int occupied;
  final String customerName;
  final bool canShare;
  bool isShared;

  TableModel({
    required this.id,
    required this.capacity,
    required this.occupied,
    required this.customerName,
    required this.canShare,
    this.isShared = false,
  });

  // Calculate if table can be shared (less than 50% occupied and sharing is allowed)
  bool get canRequestSharing =>
      canShare && occupied / capacity < 0.5 && !isShared;

  // Calculate remaining seats
  int get remainingSeats => capacity - occupied;

  // Create a copy with updated fields
  TableModel copyWith({
    int? id,
    int? capacity,
    int? occupied,
    String? customerName,
    bool? canShare,
    bool? isShared,
  }) {
    return TableModel(
      id: id ?? this.id,
      capacity: capacity ?? this.capacity,
      occupied: occupied ?? this.occupied,
      customerName: customerName ?? this.customerName,
      canShare: canShare ?? this.canShare,
      isShared: isShared ?? this.isShared,
    );
  }
}
