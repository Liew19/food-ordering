/// SeatProgressBar
/// Displays the current seat occupancy as a progress bar
/// Shows the format "2/4 seats"

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SeatProgressBar extends StatelessWidget {
  final int occupiedSeats;
  final int capacity;

  const SeatProgressBar({
    Key? key,
    required this.occupiedSeats,
    required this.capacity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate progress percentage
    final double progress = capacity > 0 ? occupiedSeats / capacity : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seat count text
        Text(
          '$occupiedSeats/$capacity seats',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(progress),
            ),
          ),
        ),
      ],
    );
  }

  // Get color based on occupancy percentage
  Color _getProgressColor(double progress) {
    if (progress >= 0.8) {
      return Colors.red;
    } else if (progress >= 0.5) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
