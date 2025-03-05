class BillItemModel {
  final int id;
  String name;
  double price;
  int quantity;
  List<int> assignedTo;

  BillItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.assignedTo = const [],
  });

  // Create a copy with updated fields
  BillItemModel copyWith({
    int? id,
    String? name,
    double? price,
    int? quantity,
    List<int>? assignedTo,
  }) {
    return BillItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      assignedTo: assignedTo ?? List.from(this.assignedTo),
    );
  }

  // Calculate total price for this item
  double get totalPrice => price * quantity;
}
