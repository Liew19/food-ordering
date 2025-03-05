import 'package:flutter/material.dart';
import 'package:fyp/models/shared_table_request.dart';
import 'package:fyp/models/table_model.dart';

class SharingRequestCard extends StatelessWidget {
  final SharingRequestModel request;
  final TableModel? table;
  final Function(int) onAccept;
  final Function(int) onReject;

  const SharingRequestCard({
    super.key,
    required this.request,
    required this.table,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = request.status == RequestStatus.pending;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shared Table Request #${request.id}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                _buildStatusBadge(),
              ],
            ),
            Text(
              '请求人: ${request.requesterName} (${request.partySize}人)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Table number:', '${request.tableId}'),
            if (table != null) ...[
              _buildInfoRow('Current Guests:', table!.customerName),
              _buildInfoRow('Table Capacity:', '${table!.capacity}人'),
              _buildInfoRow('Occupied Seats:', '${table!.occupied}人'),
              _buildInfoRow(
                'Seats After Table Sharing:',
                '${table!.occupied + request.partySize}人',
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onReject(request.id),
                      icon: Icon(Icons.close),
                      label: Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onAccept(request.id),
                      icon: Icon(Icons.check),
                      label: Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value)],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (request.status) {
      case RequestStatus.pending:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey[700]!;
        text = 'Pending';
        break;
      case RequestStatus.accepted:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green[700]!;
        text = 'Accepted';
        break;
      case RequestStatus.rejected:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red[700]!;
        text = 'Declined';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor),
      ),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 12)),
    );
  }
}
