import 'package:flutter/material.dart';
import 'package:fyp/models/reservation.dart';
import 'package:fyp/services/reservation_service.dart';
import 'package:fyp/state/auth_provider.dart' as auth;
import 'package:fyp/state/reservation_provider.dart';
import 'package:fyp/widgets/food_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TableReservationScreen extends StatefulWidget {
  const TableReservationScreen({super.key});

  @override
  State<TableReservationScreen> createState() => _TableReservationScreenState();
}

class _TableReservationScreenState extends State<TableReservationScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _numberOfGuests = 2;
  int? _selectedTableId;
  bool _showMyReservations = false;

  final List<Map<String, dynamic>> _tables = [
    {'id': 1, 'name': 'Table 1', 'seats': 2},
    {'id': 2, 'name': 'Table 2', 'seats': 4},
    {'id': 3, 'name': 'Table 3', 'seats': 6},
    {'id': 4, 'name': 'Table 4', 'seats': 8},
  ];

  @override
  void initState() {
    super.initState();
    // 使用 addPostFrameCallback 确保在构建完成后加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReservations();
    });
  }

  // Load reservations from Firestore
  Future<void> _loadReservations() async {
    if (!mounted) return;

    final authProvider = Provider.of<auth.AppAuthProvider>(
      context,
      listen: false,
    );
    final reservationProvider = Provider.of<ReservationProvider>(
      context,
      listen: false,
    );

    if (authProvider.user != null) {
      await reservationProvider.loadUserReservations(authProvider.user!.uid);
    }

    // Staff should see all reservations
    if (authProvider.role == 'staff' || authProvider.role == 'admin') {
      await reservationProvider.loadAllReservations();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _confirmReservation() async {
    // Check if user is logged in
    final authProvider = Provider.of<auth.AppAuthProvider>(
      context,
      listen: false,
    );
    final user = authProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to make a reservation'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDate == null ||
        _selectedTime == null ||
        _selectedTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if selected table has enough seats
    final selectedTable = _tables.firstWhere(
      (table) => table['id'] == _selectedTableId,
    );
    if (selectedTable['seats'] < _numberOfGuests) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selected table does not have enough seats for your party',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if user already has an active reservation
    final reservationProvider = Provider.of<ReservationProvider>(
      context,
      listen: false,
    );
    final hasActiveReservation = await reservationProvider.hasActiveReservation(
      user.uid,
    );

    if (hasActiveReservation) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You already have an active reservation'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Check if user already has a reservation on the same day
    final reservationService = ReservationService();
    final hasReservationOnSameDay = await reservationService
        .hasReservationOnDate(user.uid, _selectedDate!);

    if (hasReservationOnSameDay) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You already have a reservation on this day'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    // Format date and time for display
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final formattedTime = _selectedTime!.format(context);

    // Show confirmation dialog
    if (mounted) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Confirm Reservation'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: $formattedDate'),
                  const SizedBox(height: 8),
                  Text('Time: $formattedTime'),
                  const SizedBox(height: 8),
                  Text('Number of Guests: $_numberOfGuests'),
                  const SizedBox(height: 8),
                  Text(
                    'Table: ${selectedTable['name']} (${selectedTable['seats']} seats)',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();

                    // Create reservation object
                    final newReservation = Reservation(
                      id: '', // Will be set by the service
                      userId: user.uid,
                      userName: user.displayName ?? 'User',
                      userEmail: user.email ?? '',
                      date: _selectedDate!,
                      time: _selectedTime!.format(context),
                      numberOfGuests: _numberOfGuests,
                      tableId: _selectedTableId!,
                      tableSeats: selectedTable['seats'],
                      status: 'pending',
                      createdAt: DateTime.now(),
                    );

                    // Save reservation to database
                    try {
                      await reservationProvider.createReservation(
                        newReservation,
                      );

                      // Reload reservations to show the new one
                      if (mounted) {
                        await _loadReservations();
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Reservation submitted! Staff will confirm shortly.',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );

                        // Reset form
                        setState(() {
                          _selectedDate = null;
                          _selectedTime = null;
                          _numberOfGuests = 2;
                          _selectedTableId = null;
                        });
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to create reservation: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // 直角
                    ),
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            ),
      );
    }
  }

  // Update reservation status
  void _updateReservationStatus(String reservationId, String status) async {
    if (!mounted) return;

    final reservationProvider = Provider.of<ReservationProvider>(
      context,
      listen: false,
    );
    try {
      await reservationProvider.updateReservationStatus(reservationId, status);

      // Reload reservations to reflect the status change
      if (mounted) {
        await _loadReservations();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reservation ${status.toLowerCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update reservation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Build reservation list
  Widget _buildReservationList() {
    final authProvider = Provider.of<auth.AppAuthProvider>(context);
    final reservationProvider = Provider.of<ReservationProvider>(context);
    final isStaff =
        authProvider.role == 'staff' || authProvider.role == 'admin';

    // Determine which reservations to show
    final reservations =
        isStaff && !_showMyReservations
            ? reservationProvider.reservations
            : reservationProvider.userReservations;

    if (reservationProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reservations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            isStaff && !_showMyReservations
                ? 'No reservations found'
                : 'You have no reservations',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        final reservation = reservations[index];
        final formattedDate = DateFormat(
          'dd MMM yyyy',
        ).format(reservation.date);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Table ${reservation.tableId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    _buildStatusChip(reservation.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Date: $formattedDate'),
                Text('Time: ${reservation.time}'),
                Text('Guests: ${reservation.numberOfGuests}'),
                if (isStaff && !_showMyReservations) ...[
                  const SizedBox(height: 4),
                  Text('Customer: ${reservation.userName}'),
                  Text('Email: ${reservation.userEmail}'),
                ],
                const SizedBox(height: 12),

                // Action buttons for staff
                if (isStaff &&
                    !_showMyReservations &&
                    reservation.status == 'pending') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            () => _updateReservationStatus(
                              reservation.id,
                              'cancelled',
                            ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed:
                            () => _updateReservationStatus(
                              reservation.id,
                              'confirmed',
                            ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                ],

                // Cancel button for users
                if (!isStaff && reservation.status == 'pending') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            () => _updateReservationStatus(
                              reservation.id,
                              'cancelled',
                            ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Cancel Reservation'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Build status chip
  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'confirmed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(12),
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<auth.AppAuthProvider>(context);
    final user = authProvider.user;
    final isStaff =
        authProvider.role == 'staff' || authProvider.role == 'admin';

    return Scaffold(
      appBar: FoodAppBar(showSearch: true, showCart: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and toggle button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Table Reservation',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (isStaff)
                    TextButton.icon(
                      onPressed: () async {
                        setState(() {
                          _showMyReservations = !_showMyReservations;
                        });
                        if (mounted) {
                          await _loadReservations();
                        }
                      },
                      icon: Icon(
                        _showMyReservations ? Icons.people : Icons.person,
                      ),
                      label: Text(
                        _showMyReservations ? 'Show All' : 'My Reservations',
                      ),
                    ),
                ],
              ),
            ),

            // Existing reservations section
            if (user != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  isStaff && !_showMyReservations
                      ? 'All Reservations'
                      : 'My Reservations',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildReservationList(),
              const Divider(height: 32),
            ],

            // New reservation form
            if (!isStaff || _showMyReservations) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: const Text(
                  'Make a Reservation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              // Reservation form
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date
                    const Text(
                      'Date',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate == null
                                  ? 'dd/mm/yyyy'
                                  : DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(_selectedDate!),
                              style: TextStyle(
                                color:
                                    _selectedDate == null
                                        ? Colors.grey[600]
                                        : Colors.black,
                              ),
                            ),
                            Icon(Icons.calendar_today, color: Colors.grey[600]),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Time
                    const Text(
                      'Time',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectTime(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedTime == null
                                  ? '--:-- --'
                                  : _selectedTime!.format(context),
                              style: TextStyle(
                                color:
                                    _selectedTime == null
                                        ? Colors.grey[600]
                                        : Colors.black,
                              ),
                            ),
                            Icon(Icons.access_time, color: Colors.grey[600]),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Number of Guests
                    const Text(
                      'Number of Guests',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<int>(
                        value: _numberOfGuests,
                        isExpanded: true,
                        underline: Container(),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey[600],
                        ),
                        items:
                            List.generate(8, (index) => index + 1)
                                .map(
                                  (int value) => DropdownMenuItem<int>(
                                    value: value,
                                    child: Text('$value guests'),
                                  ),
                                )
                                .toList(),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _numberOfGuests = newValue;
                            });
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Select Table
                    const Text(
                      'Select Table',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: _tables.length,
                      itemBuilder: (context, index) {
                        final table = _tables[index];
                        final isSelected = _selectedTableId == table['id'];

                        // Determine if table has enough seats
                        final bool hasEnoughSeats =
                            table['seats'] >= _numberOfGuests;

                        return InkWell(
                          onTap:
                              hasEnoughSeats
                                  ? () {
                                    setState(() {
                                      _selectedTableId = table['id'];
                                    });
                                  }
                                  : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  !hasEnoughSeats
                                      ? Colors.grey[300]
                                      : isSelected
                                      ? Theme.of(
                                        context,
                                      ).primaryColor.withAlpha(25)
                                      : Colors.grey[200],
                              border:
                                  isSelected
                                      ? Border.all(
                                        color: Theme.of(context).primaryColor,
                                        width: 2,
                                      )
                                      : null,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  table['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        !hasEnoughSeats
                                            ? Colors.grey[500]
                                            : isSelected
                                            ? Theme.of(context).primaryColor
                                            : Colors.black,
                                  ),
                                ),
                                Text(
                                  '${table['seats']} seats',
                                  style: TextStyle(
                                    color:
                                        !hasEnoughSeats
                                            ? Colors.grey[500]
                                            : isSelected
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey[600],
                                  ),
                                ),
                                if (!hasEnoughSeats)
                                  Text(
                                    'Not enough seats',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red[300],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Confirm Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: user == null ? null : _confirmReservation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero, // 直角
                          ),
                          disabledBackgroundColor: Colors.grey,
                        ),
                        child: Text(
                          user == null
                              ? 'Login to Make Reservation'
                              : 'Confirm Reservation',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    if (user == null) ...[
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'You need to be logged in to make a reservation',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
