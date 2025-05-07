<<<<<<< Updated upstream
import '../models/test_order.dart';
=======
import '../models/order.dart';
>>>>>>> Stashed changes

/// Priority-based order sorting algorithm
class PriorityOrderSorter {
  /// Sorts orders based on a priority calculation
  static List<Order> sortOrders(List<Order> orders) {
    final sortedOrders = List<Order>.from(orders);
<<<<<<< Updated upstream
    
    // Calculate priority for each order
    for (var order in sortedOrders) {
      order.priority = calculatePriority(order);
    }
    
=======

    // Calculate priority for each order
    for (var order in sortedOrders) {
      order.calculatePriority();
    }

>>>>>>> Stashed changes
    // Sort by priority (highest first)
    sortedOrders.sort((a, b) => b.priority.compareTo(a.priority));
    return sortedOrders;
  }
<<<<<<< Updated upstream
  
  /// Calculate priority score for an order
  /// Combines preparation time and wait time with dynamic weighting
  static double calculatePriority(Order order) {
    // Calculate preparation score (shorter prep time = higher score)
    final prepTime = order.totalPreparationTime;
    final preparationScore = 1.0 / (1.0 + prepTime / 10.0); // Normalize to 0-1 range
    
    // Calculate wait time score (longer wait = higher score)
    final waitTimeMinutes = DateTime.now().difference(order.createdAt).inMinutes;
    final waitTimeScore = waitTimeMinutes / 10.0; // Normalize to 0-1 range for 10 minute window
    
    // Combine scores with weighting
    // 40% preparation time, 60% wait time
    double priority = (preparationScore * 0.4) + (waitTimeScore * 0.6);
    
    // Boost priority for orders with ready items
    if (order.hasReadyItems) {
      priority += 0.2;
    }
    
    // Ensure priority is between 0 and 1
    return priority.clamp(0.0, 1.0);
  }
=======
>>>>>>> Stashed changes
}
