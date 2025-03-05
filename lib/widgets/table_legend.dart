import 'package:flutter/material.dart';

class TableLegend extends StatelessWidget {
  const TableLegend({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Table Status Legend:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildLegendItem(Colors.green, 'Available'),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.red, 'Occupied'),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.grey, 'Cleaning'),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.orange, 'Reserved'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildLegendItem(Colors.blue.shade200, 'Private Table'),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.purple.shade200, 'Shared Table'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}