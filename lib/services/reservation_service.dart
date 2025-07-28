import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/models/reservation.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reservations';

  // Create a new reservation
  Future<Reservation> createReservation(Reservation reservation) async {
    try {
      // Create the reservation document
      final docRef = _firestore.collection(_collection).doc();
      final newReservation = reservation.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
      );

      // Convert to map with proper Firestore timestamp
      final Map<String, dynamic> reservationData = {
        'id': newReservation.id,
        'userId': newReservation.userId,
        'userName': newReservation.userName,
        'userEmail': newReservation.userEmail,
        'date': Timestamp.fromDate(newReservation.date),
        'time': newReservation.time,
        'numberOfGuests': newReservation.numberOfGuests,
        'tableId': newReservation.tableId,
        'tableSeats': newReservation.tableSeats,
        'status': newReservation.status,
        'createdAt': Timestamp.fromDate(newReservation.createdAt),
      };

      // Save the reservation
      await docRef.set(reservationData);

      // Try to update the user's document if it exists
      try {
        await _firestore.collection('users').doc(reservation.userId).update({
          'reservations': FieldValue.arrayUnion([docRef.id]),
        });
      } catch (userError) {
        // If the user document doesn't exist or can't be updated, just continue
        // but don't fail the reservation creation
      }

      return newReservation;
    } catch (e) {
      throw Exception('Failed to create reservation: $e');
    }
  }

  // Get all reservations
  Future<List<Reservation>> getAllReservations() async {
    try {
      final snapshot =
          await _firestore
              .collection(_collection)
              .orderBy('date', descending: false)
              .get();

      return snapshot.docs
          .map((doc) => Reservation.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reservations: $e');
    }
  }

  // Get reservations for a specific user
  Future<List<Reservation>> getUserReservations(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection(_collection)
              .where('userId', isEqualTo: userId)
              // .where('status', whereIn: ['pending', 'confirmed'])
              // .orderBy('date', descending: false)
              .get();
      return snapshot.docs
          .map((doc) => Reservation.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user reservations: $e');
    }
  }

  // Check if user already has a pending or confirmed reservation
  Future<bool> hasActiveReservation(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection(_collection)
              .where('userId', isEqualTo: userId)
              .where('status', whereIn: ['pending', 'confirmed'])
              .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check active reservations: $e');
    }
  }

  // Check if user already has a reservation on the same day
  Future<bool> hasReservationOnDate(String userId, DateTime date) async {
    try {
      // We'll check the date manually by comparing year, month, and day

      final snapshot =
          await _firestore
              .collection(_collection)
              .where('userId', isEqualTo: userId)
              .where('status', whereIn: ['pending', 'confirmed'])
              .get();

      // Check if any reservation is on the same day
      for (var doc in snapshot.docs) {
        final reservationData = doc.data();
        final reservationDate = (reservationData['date'] as Timestamp).toDate();

        // Check if the reservation date is on the same day
        if (reservationDate.year == date.year &&
            reservationDate.month == date.month &&
            reservationDate.day == date.day) {
          return true;
        }
      }

      return false;
    } catch (e) {
      throw Exception('Failed to check reservations on date: $e');
    }
  }

  // Update reservation status
  Future<void> updateReservationStatus(
    String reservationId,
    String status,
  ) async {
    try {
      // Get the reservation document
      final reservationDoc =
          await _firestore.collection(_collection).doc(reservationId).get();
      if (!reservationDoc.exists) {
        throw Exception('Reservation not found');
      }

      // Update the status
      await _firestore.collection(_collection).doc(reservationId).update({
        'status': status,
      });

      // If status is confirmed, notify the admin
      if (status == 'confirmed') {
        final reservationData = reservationDoc.data() as Map<String, dynamic>;
        await _notifyAdmin(reservationData);
      }
    } catch (e) {
      throw Exception('Failed to update reservation status: $e');
    }
  }

  // Notify admin about a new confirmed reservation
  Future<void> _notifyAdmin(Map<String, dynamic> reservationData) async {
    try {
      // Get user details
      final userId = reservationData['userId'] as String;
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Prepare notification data
      final notificationData = {
        'reservationId': reservationData['id'],
        'userId': userId,
        'userName': reservationData['userName'],
        'userEmail': reservationData['userEmail'],
        'date': (reservationData['date'] as Timestamp).toDate().toString(),
        'time': reservationData['time'],
        'tableId': reservationData['tableId'],
        'numberOfGuests': reservationData['numberOfGuests'],
        'userDetails': userData,
      };

      // Store notification in Firestore for admin
      await _firestore.collection('admin_notifications').add({
        'type': 'reservation_confirmed',
        'data': notificationData,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // You could also send an email or push notification here
      // For example:
      // await _sendEmailNotification(notificationData);
    } catch (e) {
      // Error occurred while notifying admin
      // Don't throw here, as this is a secondary operation
    }
  }

  // Delete a reservation
  Future<void> deleteReservation(String reservationId) async {
    try {
      await _firestore.collection(_collection).doc(reservationId).delete();
    } catch (e) {
      throw Exception('Failed to delete reservation: $e');
    }
  }
}
