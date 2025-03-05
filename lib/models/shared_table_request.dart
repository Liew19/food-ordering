enum RequestStatus { pending, accepted, rejected }

class SharingRequestModel {
  final int id;
  final int tableId;
  final String requesterName;
  final int partySize;
  RequestStatus status;

  SharingRequestModel({
    required this.id,
    required this.tableId,
    required this.requesterName,
    required this.partySize,
    this.status = RequestStatus.pending,
  });

  // Create a copy with updated fields
  SharingRequestModel copyWith({
    int? id,
    int? tableId,
    String? requesterName,
    int? partySize,
    RequestStatus? status,
  }) {
    return SharingRequestModel(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      requesterName: requesterName ?? this.requesterName,
      partySize: partySize ?? this.partySize,
      status: status ?? this.status,
    );
  }
}
