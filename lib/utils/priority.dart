// Data model definitions
class Order {
  final List<OrderItem> items;
  final String type;
  final double totalAmount;
  final DateTime createdAt;

  Order({
    required this.items,
    required this.type,
    required this.totalAmount,
    required this.createdAt,
  });
}

class OrderItem {
  final String menuItemId;
  final int quantity;

  OrderItem({required this.menuItemId, required this.quantity});
}

class MenuItem {
  final String id;
  final String name;
  final double price;
  final int preparationTime;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.preparationTime,
  });
}

// Priority calculation function
double calculatePriority(Order order, List<MenuItem> menuItems) {
  // Get preparation time priority (40% weight)
  final preparationTimePriority =
      calculatePreparationTimePriority(order, menuItems) * 0.4;

  // Get order type priority (30% weight)
  final orderTypePriority = (order.type == 'takeout' ? 3 : 2) * 0.3;

  // Get amount priority (20% weight)
  final amountPriority = calculateAmountPriority(order.totalAmount) * 0.2;

  // Get wait time priority (10% weight)
  final waitTimePriority = calculateWaitTimePriority(order.createdAt) * 0.1;

  return preparationTimePriority +
      orderTypePriority +
      amountPriority +
      waitTimePriority;
}

int calculatePreparationTimePriority(Order order, List<MenuItem> menuItems) {
  final orderItems =
      order.items.map((item) {
        final menuItem = menuItems.firstWhere(
          (mi) => mi.id == item.menuItemId,
          orElse:
              () => MenuItem(id: '', name: '', price: 0, preparationTime: 0),
        );
        return menuItem.preparationTime;
      }).toList();

  final maxPrepTime =
      orderItems.isEmpty
          ? 0
          : orderItems.reduce((max, value) => max > value ? max : value);

  if (maxPrepTime <= 10) return 3; // Quick preparation
  if (maxPrepTime <= 20) return 2; // Standard preparation
  return 1; // Long preparation
}

int calculateAmountPriority(double amount) {
  if (amount > 200) return 3;
  if (amount >= 100) return 2;
  return 1;
}

int calculateWaitTimePriority(DateTime createdAt) {
  final waitTimeInMinutes = DateTime.now().difference(createdAt).inMinutes;
  if (waitTimeInMinutes > 15) return 3;
  if (waitTimeInMinutes > 10) return 2;
  return 1;
}
