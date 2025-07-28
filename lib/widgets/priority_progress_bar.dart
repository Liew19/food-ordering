import 'package:flutter/material.dart';

class PriorityProgressBar extends StatelessWidget {
  final double priority;

  const PriorityProgressBar({Key? key, required this.priority})
    : super(key: key);

  // Get color based on priority value
  Color _getPriorityColor(double priority) {
    if (priority >= 0.8) {
      return Colors.red; // High priority
    } else if (priority >= 0.5) {
      return Colors.orange; // Medium priority
    } else if (priority >= 0.3) {
      return Colors.amber; // Low-medium priority
    } else {
      return Colors.green; // Low priority
    }
  }

  // This method was removed as we're now using percentage values instead of text labels

  @override
  Widget build(BuildContext context) {
    // Clamp priority value to 0.0-1.0 range for progress bar
    final clampedPriority = priority.clamp(0.0, 1.0);

    // We no longer need to calculate priority percentage since we're using text labels

    return Row(
      children: [
        Text(
          'Priority: ${(priority * 100).round()}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clampedPriority,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getPriorityColor(clampedPriority),
              ),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }
}
