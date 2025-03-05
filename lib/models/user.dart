class User {
  final String userId;
  final String role;
  final bool preferenceSharedTable;
  final int tableNumber;

  User({
    required this.userId,
    required this.role,
    required this.preferenceSharedTable,
    required this.tableNumber,
  });
}
