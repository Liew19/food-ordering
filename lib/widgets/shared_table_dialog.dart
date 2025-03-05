import 'package:flutter/material.dart';

class SharedTableDialog extends StatelessWidget {
  final Function(bool) onAccept;

  const SharedTableDialog({Key? key, required this.onAccept}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Table Sharing Preference'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Would you be willing to share a table with other guests?',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          const Text(
            'You can change this preference at any time.',
            style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => onAccept(false),
          child: const Text('No, I prefer private seating'),
        ),
        ElevatedButton(
          onPressed: () => onAccept(true),
          child: const Text('Yes, I\'m willing to share'),
        ),
      ],
    );
  }
}