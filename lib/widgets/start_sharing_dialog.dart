/// StartSharingDialog
/// A dialog that allows users to start sharing a table
/// Includes table number selection and description input

import 'package:flutter/material.dart';
import '../theme.dart';

class StartSharingDialog extends StatefulWidget {
  final Function(int tableNumber, String? description) onConfirm;

  const StartSharingDialog({Key? key, required this.onConfirm})
    : super(key: key);

  @override
  State<StartSharingDialog> createState() => _StartSharingDialogState();
}

class _StartSharingDialogState extends State<StartSharingDialog> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tableNumberController = TextEditingController();
  final int _maxLength = 15;

  @override
  void dispose() {
    _descriptionController.dispose();
    _tableNumberController.dispose();
    super.dispose();
  }

  bool _isValidTableNumber() {
    if (_tableNumberController.text.isEmpty) return false;
    final number = int.tryParse(_tableNumberController.text);
    return number != null && number > 0;
  }

  void _handleConfirm() {
    if (!_isValidTableNumber()) return;
    final tableNumber = int.parse(_tableNumberController.text);
    final description =
        _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null;
    widget.onConfirm(tableNumber, description);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.backgroundColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.table_bar, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Start Table Sharing',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter Table Number',
                    style: TextStyle(
                      color:
                          isDarkMode ? AppTheme.textDarkColor : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tableNumberController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color:
                          isDarkMode ? AppTheme.textDarkColor : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter table number (e.g., 1)',
                      hintStyle: TextStyle(color: AppTheme.textMutedColor),
                      filled: true,
                      fillColor:
                          isDarkMode
                              ? AppTheme.cardColor
                              : Colors.grey.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: AppTheme.primaryColor),
                      ),
                      prefixIcon: Icon(
                        Icons.confirmation_number_outlined,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Description (Optional)',
                    style: TextStyle(
                      color:
                          isDarkMode ? AppTheme.textDarkColor : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Max $_maxLength characters',
                    style: TextStyle(
                      color: AppTheme.textMutedColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    style: TextStyle(
                      color:
                          isDarkMode ? AppTheme.textDarkColor : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g., Welcome to join',
                      hintStyle: TextStyle(color: AppTheme.textMutedColor),
                      filled: true,
                      fillColor:
                          isDarkMode
                              ? AppTheme.cardColor
                              : Colors.grey.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: AppTheme.primaryColor),
                      ),
                      prefixIcon: Icon(
                        Icons.description_outlined,
                        color: AppTheme.primaryColor,
                      ),
                      counterText:
                          '${_descriptionController.text.length}/$_maxLength',
                      counterStyle: TextStyle(color: AppTheme.textMutedColor),
                    ),
                    maxLength: _maxLength,
                    onChanged: (value) => setState(() {}),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textMutedColor,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isValidTableNumber() ? _handleConfirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero, // 直角
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle_outline, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Confirm',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
