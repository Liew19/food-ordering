import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final DateTime date;
  final String time;
  final int numberOfGuests;
  final int tableId;
  final int tableSeats;
  final String status; // 'pending', 'confirmed', 'cancelled'
  final DateTime createdAt;

  Reservation({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.date,
    required this.time,
    required this.numberOfGuests,
    required this.tableId,
    required this.tableSeats,
    required this.status,
    required this.createdAt,
  });

  // Convert Reservation to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'date': date,
      'time': time,
      'numberOfGuests': numberOfGuests,
      'tableId': tableId,
      'tableSeats': tableSeats,
      'status': status,
      'createdAt': createdAt,
    };
  }

  // Create Reservation from Map
  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      time: map['time'] ?? '',
      numberOfGuests: map['numberOfGuests'] ?? 0,
      tableId: map['tableId'] ?? 0,
      tableSeats: map['tableSeats'] ?? 0,
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // Create a copy of Reservation with updated fields
  Reservation copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    DateTime? date,
    String? time,
    int? numberOfGuests,
    int? tableId,
    int? tableSeats,
    String? status,
    DateTime? createdAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      date: date ?? this.date,
      time: time ?? this.time,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
      tableId: tableId ?? this.tableId,
      tableSeats: tableSeats ?? this.tableSeats,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
