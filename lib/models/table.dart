enum TableStatus { available, occupied, cleaning, reserved }

class RestaurantTable {
  final int id;
  final TableStatus status;
  final bool isShared;
  final int occupiedSeats;
  final int maxCapacity;
  final bool canShare;

  RestaurantTable({
    required this.id,
    required this.status,
    required this.isShared,
    required this.occupiedSeats,
    required this.maxCapacity,
    required this.canShare,
  });

  // 计算是否可共享
  bool get canRequestSharing =>
      canShare && occupiedSeats / maxCapacity < 0.5 && !isShared;

  // 计算剩余座位
  int get remainingSeats => maxCapacity - occupiedSeats;

  RestaurantTable copyWith({
    int? id,
    TableStatus? status,
    bool? isShared,
    int? occupiedSeats,
    int? maxCapacity,
    bool? canShare,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      status: status ?? this.status,
      isShared: isShared ?? this.isShared,
      occupiedSeats: occupiedSeats ?? this.occupiedSeats,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      canShare: canShare ?? this.canShare,
    );
  }
}
