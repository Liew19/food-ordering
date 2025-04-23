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
  // 更合理的权重分配
  const weightPreparation = 0.4;
  const weightType = 0.2;
  const weightAmount = 0.2;
  const weightWait = 0.2;

  final preparation =
      calculatePreparationTimePriority(order, menuItems) * weightPreparation;
  final type = (order.type == 'takeout' ? 3 : 2) * weightType;
  final amount = calculateAmountPriority(order.totalAmount) * weightAmount;
  final wait = calculateWaitTimePriority(order.createdAt) * weightWait;

  return preparation + type + amount + wait;
}

int calculatePreparationTimePriority(Order order, List<MenuItem> menuItems) {
  // 计算总准备时间
  final totalPrepTime = order.items.fold(0, (sum, item) {
    final menuItem = menuItems.firstWhere(
      (mi) => mi.id == item.menuItemId,
      orElse: () => throw Exception('MenuItem ${item.menuItemId} not found'),
    );
    return sum + menuItem.preparationTime * item.quantity;
  });

  if (totalPrepTime <= 10) return 3;
  if (totalPrepTime <= 30) return 2;
  return 1;
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
