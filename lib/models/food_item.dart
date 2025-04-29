/// Simple food item model for testing
class FoodItem {
  final String id;
  final String name;
  final double price;
  final double preparationTime;
  final bool canPrepareInParallel;

  FoodItem({
    this.id = '',
    this.name = '',
    this.price = 0.0,
    required this.preparationTime,
    this.canPrepareInParallel = true,
  });
}
