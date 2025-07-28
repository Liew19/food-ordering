enum TableStatus { available, occupied, cleaning, reserved }

class RestaurantTable {
  final int id;
  final String name;
  final int seats;
  final bool canShare;
  final bool isShared;
  final int occupiedSeats;
  final String? status;

  RestaurantTable({
    required this.id,
    required this.name,
    required this.seats,
    required this.canShare,
    this.isShared = false,
    this.occupiedSeats = 0,
    this.status,
  });

  factory RestaurantTable.fromMap(Map<String, dynamic> map) {
    return RestaurantTable(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      seats: map['seats'] ?? 0,
      canShare: map['canShare'] ?? false,
      isShared: map['isShared'] ?? false,
      occupiedSeats: map['occupiedSeats'] ?? 0,
      status: map['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'seats': seats,
      'canShare': canShare,
      'isShared': isShared,
      'occupiedSeats': occupiedSeats,
      'status': status,
    };
  }

  // 计算是否可共享
  bool get canRequestSharing =>
      canShare && occupiedSeats / seats < 0.5 && !isShared;

  // 计算剩余座位
  int get remainingSeats => seats - occupiedSeats;

  RestaurantTable copyWith({
    int? id,
    String? name,
    int? seats,
    bool? canShare,
    bool? isShared,
    int? occupiedSeats,
    String? status,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      name: name ?? this.name,
      seats: seats ?? this.seats,
      canShare: canShare ?? this.canShare,
      isShared: isShared ?? this.isShared,
      occupiedSeats: occupiedSeats ?? this.occupiedSeats,
      status: status ?? this.status,
    );
  }
}
