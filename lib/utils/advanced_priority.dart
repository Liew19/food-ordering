import '../models/order.dart';
import '../state/cart_provider.dart';

// Advanced priority algorithm implementation
// This version focuses only on preparation time and wait time
// for a fair and practical order prioritization

// Order priority calculator
class AdvancedOrderPrioritizer {
  // Calculate order priority
  static double calculatePriority(Order order) {
    final preparationScore = _calculatePreparationScore(order);
    final waitScore = _calculateWaitScore(order);

    // Equal weights for preparation time and wait time
    const double prepTimeWeight = 0.5; // Preparation time weight
    const double waitTimeWeight = 0.5; // Wait time weight

    return (preparationScore * prepTimeWeight) + (waitScore * waitTimeWeight);
  }

  // Calculate preparation time score (shorter prep time gets higher score)
  static double _calculatePreparationScore(Order order) {
    // Get the longest preparation time in the order
    final maxPrepTime =
        order.items.isEmpty
            ? 0
            : order.items
                .map((item) => item.item.preparationTime)
                .reduce((max, value) => max > value ? max : value);

    // Normalize to 0-10 scale (inverse relationship)
    // Assume maximum preparation time is 60 minutes
    const maxPossiblePrepTime = 60.0;
    return 10.0 * (1 - (maxPrepTime / maxPossiblePrepTime).clamp(0.0, 1.0));
  }

  // Calculate wait time score (longer wait gets higher score)
  static double _calculateWaitScore(Order order) {
    final waitTimeMinutes =
        DateTime.now().difference(order.createdAt).inMinutes;

    // Normalize to 0-10 scale (direct relationship)
    // Maximum wait time threshold is 30 minutes
    const maxWaitTime = 30.0;
    return 10.0 * (waitTimeMinutes / maxWaitTime).clamp(0.0, 1.0);
  }

  // Note: We removed order type, amount, and kitchen resource factors
  // to ensure more fair and practical order processing

  // Get prioritized items in an order
  static List<CartItem> getPrioritizedItems(Order order) {
    return List<CartItem>.from(
      order.items,
    )..sort((a, b) => a.item.preparationTime.compareTo(b.item.preparationTime));
  }
}
