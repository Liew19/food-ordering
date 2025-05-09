import 'package:flutter/foundation.dart';
import 'package:fyp/models/reservation.dart';
import 'package:fyp/services/reservation_service.dart';

class ReservationProvider with ChangeNotifier {
  final ReservationService _reservationService;

  List<Reservation> _reservations = [];
  List<Reservation> _userReservations = [];
  bool _isLoading = false;
  String? _error;

  ReservationProvider(this._reservationService);

  // Getters
  List<Reservation> get reservations => _reservations;
  List<Reservation> get userReservations => _userReservations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all reservations (for staff)
  Future<void> loadAllReservations() async {
    _isLoading = true;
    notifyListeners();

    try {
      _reservations = await _reservationService.getAllReservations();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load user reservations
  Future<void> loadUserReservations(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _userReservations = await _reservationService.getUserReservations(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if user has active reservation
  Future<bool> hasActiveReservation(String userId) async {
    try {
      return await _reservationService.hasActiveReservation(userId);
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Create a new reservation
  Future<Reservation?> createReservation(Reservation reservation) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newReservation = await _reservationService.createReservation(
        reservation,
      );
      _userReservations.add(newReservation);
      _error = null;
      return newReservation;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update reservation status
  Future<void> updateReservationStatus(
    String reservationId,
    String status,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _reservationService.updateReservationStatus(reservationId, status);

      // Update local lists
      _updateReservationInLists(reservationId, status);

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancel reservation
  Future<void> cancelReservation(String reservationId) async {
    await updateReservationStatus(reservationId, 'cancelled');
  }

  // Helper methods

  void _updateReservationInLists(String reservationId, String status) {
    // Update in all reservations list
    final allIndex = _reservations.indexWhere((r) => r.id == reservationId);
    if (allIndex != -1) {
      _reservations[allIndex] = _reservations[allIndex].copyWith(
        status: status,
      );
    }

    // Update in user reservations list
    final userIndex = _userReservations.indexWhere(
      (r) => r.id == reservationId,
    );
    if (userIndex != -1) {
      _userReservations[userIndex] = _userReservations[userIndex].copyWith(
        status: status,
      );
    }

    notifyListeners();
  }
}
