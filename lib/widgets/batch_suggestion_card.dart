import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/advanced_priority.dart';
import '../state/order_provider.dart';
import '../models/order.dart';

class BatchSuggestionCard extends StatelessWidget {
  final BatchGroup batchGroup;
  final bool isKitchen; // true for kitchen, false for staff
  final List<BatchGroup> allGroups;
  final int index;

  const BatchSuggestionCard({
    Key? key,
    required this.batchGroup,
    required this.isKitchen,
    required this.allGroups,
    required this.index,
  }) : super(key: key);

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

  // Get priority text based on priority value
  String _getPriorityText(double priority) {
    if (priority >= 0.8) {
      return 'High'; // High priority
    } else if (priority >= 0.5) {
      return 'Medium'; // Medium priority
    } else if (priority >= 0.3) {
      return 'Low-Medium'; // Low-medium priority
    } else {
      return 'Low'; // Low priority
    }
  }

  // Format time ago string
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  // Group batch items by order ID and count them
  Map<String, int> _groupBatchItemsByOrder() {
    final Map<String, int> orderCounts = {};

    for (var batchItem in batchGroup.items) {
      final orderId = batchItem.order.id;
      orderCounts[orderId] = (orderCounts[orderId] ?? 0) + 1;
    }

    return orderCounts;
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final batchLabel = BatchProcessor.getBatchLabel(
      allGroups,
      batchGroup,
      index,
    );

    // Check if any items in the batch are already being prepared
    bool isBatchBeingPrepared = false;
    for (var batchItem in batchGroup.items) {
      final itemStatus = orderProvider.getItemStatus(
        batchItem.order.id,
        batchItem.item.item.id,
      );
      if (itemStatus == OrderStatus.preparing) {
        isBatchBeingPrepared = true;
        break;
      }
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isKitchen ? Colors.orange.shade200 : Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Batch header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Batch: ${batchGroup.totalQuantity}× ${batchGroup.menuItemName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (batchLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isKitchen
                              ? Colors.orange.shade50
                              : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      batchLabel,
                      style: TextStyle(
                        color: isKitchen ? Colors.orange : Colors.blue,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Priority indicator
            Row(
              children: [
                Text(
                  'Priority: ${(batchGroup.priority * 100).round()}%',
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
                      value: batchGroup.priority.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getPriorityColor(batchGroup.priority.clamp(0.0, 1.0)),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
              ],
            ),
            // Show batch creation time
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Created: ${_getTimeAgo(batchGroup.createdAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 12),

            // Order details
            // Group items by order ID to avoid duplicates
            ..._groupBatchItemsByOrder().entries.map((entry) {
              final orderId = entry.key;
              final count = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Text('•'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Order #$orderId: $count× ${batchGroup.menuItemName}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // Only show "Start Cooking/Preparing Batch" button if the batch is not being prepared
                if (!isBatchBeingPrepared)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (isKitchen) {
                          orderProvider.processKitchenBatch(batchGroup);
                        } else {
                          orderProvider.processStaffBatch(batchGroup);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isKitchen ? Colors.orange : Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        isKitchen
                            ? 'Start Cooking Batch'
                            : 'Start Preparing Batch',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                // Add spacing between buttons if both are shown
                if (!isBatchBeingPrepared) const SizedBox(width: 12),

                // Always show "Mark Batch Ready" button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (isKitchen) {
                        orderProvider.completeKitchenBatch(batchGroup);
                      } else {
                        orderProvider.completeStaffBatch(batchGroup);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Mark Batch Ready',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
