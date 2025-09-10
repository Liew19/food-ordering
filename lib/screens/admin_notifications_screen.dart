import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/widgets/food_app_bar.dart';
import 'package:intl/intl.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Avoid composite index by splitting into two queries
      final pendingSnap =
          await _firestore
              .collection('reservations')
              .where('status', isEqualTo: 'pending')
              .get();

      final confirmedSnap =
          await _firestore
              .collection('reservations')
              .where('status', isEqualTo: 'confirmed')
              .get();

      final pending =
          pendingSnap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      final confirmed =
          confirmedSnap.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();

      int byCreatedAtDesc(Map<String, dynamic> a, Map<String, dynamic> b) {
        final ta = a['createdAt'];
        final tb = b['createdAt'];
        DateTime da =
            ta is Timestamp
                ? ta.toDate()
                : DateTime.fromMillisecondsSinceEpoch(0);
        DateTime db =
            tb is Timestamp
                ? tb.toDate()
                : DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      }

      pending.sort(byCreatedAtDesc);
      confirmed.sort(byCreatedAtDesc);

      setState(() {
        _notifications = [...pending, ...confirmed];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load reservations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Removed unused admin_notifications helpers after switching to reservations list

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    }

    return 'Unknown';
  }

  Widget _buildNotificationCard(Map<String, dynamic> reservation) {
    final String status = reservation['status'] ?? 'pending';
    final bool isPending = status == 'pending';
    final String formattedTime = _formatTimestamp(reservation['createdAt']);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: isPending ? Colors.orange.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusChip(status),
                Text(
                  formattedTime,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const Divider(),
            _buildReservationDetails(reservation),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isPending)
                  TextButton(
                    onPressed:
                        () => _updateReservationStatus(
                          reservation['id'],
                          'confirmed',
                        ),
                    child: const Text('Confirm'),
                  ),
                TextButton(
                  onPressed:
                      () => _updateReservationStatus(
                        reservation['id'],
                        'cancelled',
                      ),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationDetails(Map<String, dynamic> r) {
    final String userName = r['userName'] ?? 'Unknown';
    final String userEmail = r['userEmail'] ?? 'Unknown';
    final String time = r['time'] ?? 'Unknown';
    final int tableId = r['tableId'] ?? 0;
    final int guests = r['numberOfGuests'] ?? 0;
    final String date = _formatTimestamp(r['date']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Table Reservation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text('Customer: $userName'),
        Text('Email: $userEmail'),
        Text('Date: $date'),
        Text('Time: $time'),
        Text('Table: $tableId'),
        Text('Guests: $guests'),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'confirmed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _updateReservationStatus(
    String reservationId,
    String status,
  ) async {
    try {
      await _firestore.collection('reservations').doc(reservationId).update({
        'status': status,
      });
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reservation ${status.toLowerCase()}'),
            backgroundColor: status == 'confirmed' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FoodAppBar(showSearch: false, showCart: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and refresh button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Admin Notifications',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadNotifications,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          // Notifications list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _notifications.isEmpty
                    ? const Center(child: Text('No notifications'))
                    : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        return _buildNotificationCard(_notifications[index]);
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
