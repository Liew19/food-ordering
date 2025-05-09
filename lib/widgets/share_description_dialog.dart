import 'package:flutter/material.dart';

class ShareDescriptionDialog extends StatefulWidget {
  const ShareDescriptionDialog({Key? key}) : super(key: key);

  @override
  State<ShareDescriptionDialog> createState() => _ShareDescriptionDialogState();
}

class _ShareDescriptionDialogState extends State<ShareDescriptionDialog> {
  final TextEditingController _controller = TextEditingController();
  final int _maxLength = 15;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Start Sharing'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Enter a description (optional)',
          border: OutlineInputBorder(),
        ),
        maxLength: _maxLength,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop('');
          },
          child: const Text('Start Without Description'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_controller.text);
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
    );
  }
}
