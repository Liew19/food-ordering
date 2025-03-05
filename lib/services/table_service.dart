// lib/services/table_service.dart
import 'dart:async';

class TableService {
  // Simulate a server request with a delay
  Future<Map<String, dynamic>> _simulateServerRequest({
    required Duration delay,
    required Map<String, dynamic> response,
  }) async {
    await Future.delayed(delay);
    return response;
  }

  // Create a table sharing request
  Future<Map<String, dynamic>> createTableSharing({
    required int tableId,
    required String requesterName,
    required int partySize,
  }) async {
    try {
      // Simulate API call
      return await _simulateServerRequest(
        delay: Duration(milliseconds: 500),
        response: {'success': true},
      );
    } catch (e) {
      print('Error creating table sharing: $e');
      return {'success': false, 'error': 'Creating table sharing failed'};
    }
  }

  // Accept a table sharing request
  Future<Map<String, dynamic>> acceptTableSharing(int requestId) async {
    try {
      // Simulate API call
      return await _simulateServerRequest(
        delay: Duration(milliseconds: 500),
        response: {'success': true},
      );
    } catch (e) {
      print('Error accepting table sharing: $e');
      return {'success': false, 'error': 'Accepting table sharing failed'};
    }
  }

  // Reject a table sharing request
  Future<Map<String, dynamic>> rejectTableSharing(int requestId) async {
    try {
      // Simulate API call
      return await _simulateServerRequest(
        delay: Duration(milliseconds: 500),
        response: {'success': true},
      );
    } catch (e) {
      print('Error rejecting table sharing: $e');
      return {'success': false, 'error': 'Declining table sharing failed'};
    }
  }
}
