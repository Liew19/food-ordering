import 'dart:math';
import '../models/order.dart';
import '../state/cart_provider.dart';

/// Represents a group of similar items from different orders that can be batch processed
class BatchGroup {
  /// The menu item ID for this batch group
  final String menuItemId;

  /// The menu item name for this batch group
  final String menuItemName;

  /// The list of batch items in this group
  final List<BatchItem> items = [];

  /// The priority score of this batch group (calculated based on orders)
  double priority = 0.0;

  /// The creation time of this batch group (used for sorting batches by creation order)
  final DateTime createdAt;

  /// The unique ID for this batch group (used to maintain batch integrity)
  final String batchId;

  BatchGroup({required this.menuItemId, required this.menuItemName})
    : batchId = '${menuItemId}_${DateTime.now().millisecondsSinceEpoch}',
      createdAt = DateTime.now();

  /// Adds an item to this batch group
  void addItem(CartItem item, Order order) {
    items.add(BatchItem(item: item, order: order));
  }

  /// Gets the total quantity of items in this batch group
  /// Since we're now splitting items with quantity > 1 into multiple batch items with quantity 1,
  /// we can simply count the number of items in the batch
  int get totalQuantity => items.length;

  /// Gets the priority score as a percentage (0-100)
  int get priorityPercentage => (priority * 100).round().clamp(0, 100);
}

/// Represents an item in a batch group
class BatchItem {
  /// The cart item
  final CartItem item;

  /// The order containing the item
  final Order order;

  BatchItem({required this.item, required this.order});
}

/// Handles batch processing of similar items across multiple orders
class BatchProcessor {
  /// Maximum number of items that can be cooked simultaneously in a batch
  static const int maxBatchSize = 3;

  /// Maximum number of beverages that can be prepared simultaneously in a batch
  static const int maxBeverageBatchSize = 5;

  /// Maximum time window (in minutes) for considering orders for batch processing
  static const int maxBatchTimeWindowMinutes = 1;

  /// Identifies similar food items across multiple orders that can be batch processed
  ///
  /// Returns a list of BatchGroup objects, each containing similar items from different orders
  /// Each batch group is limited to a maximum of 3 items due to cooking equipment constraints
  /// Only items that can be prepared in parallel will be batched together
  ///
  /// The statusGetter parameter is a function that returns the status of an order
  /// The itemStatusGetter parameter is a function that returns the status of an individual item
  /// This allows the method to be used with different status types (e.g., kitchen status, staff status)
  static List<BatchGroup> identifySimilarFoodItems(
    List<Order> orders,
    OrderStatus Function(String orderId) statusGetter,
    OrderStatus Function(String orderId, String itemId)? itemStatusGetter,
  ) {
    // First, collect all food items by menu item ID, but only if they can be prepared in parallel
    final Map<String, List<BatchItem>> itemsMap = {};

    // Get the current time
    final now = DateTime.now();

    // Group orders by time window
    final Map<String, List<Order>> ordersByTimeWindow = {};

    for (var order in orders) {
      // Calculate time difference in minutes
      final timeDifference = now.difference(order.createdAt).inMinutes;

      // We no longer skip orders that are older than the maximum time window
      // This allows all orders to be considered for batch processing
      // if (timeDifference > maxBatchTimeWindowMinutes) continue;

      // Create a key for the time window (0-5 minutes, 5-10 minutes, etc.)
      final timeWindowKey =
          (timeDifference ~/ maxBatchTimeWindowMinutes).toString();

      if (!ordersByTimeWindow.containsKey(timeWindowKey)) {
        ordersByTimeWindow[timeWindowKey] = [];
      }

      ordersByTimeWindow[timeWindowKey]!.add(order);
    }

    // Process each time window separately
    for (var timeWindow in ordersByTimeWindow.keys) {
      final ordersInWindow = ordersByTimeWindow[timeWindow]!;

      for (var order in ordersInWindow) {
        // Get the order status using the provided statusGetter function
        final orderStatus = statusGetter(order.id);

        // Skip orders that are already being prepared or ready
        if (orderStatus == OrderStatus.preparing ||
            orderStatus == OrderStatus.ready) {
          continue;
        }

        // Get all food items from the order (excluding beverages and desserts)
        final foodItems =
            order.items.where((item) {
              final category = item.item.category.toLowerCase();
              return category != 'beverage' && category != 'dessert';
            }).toList();

        for (var item in foodItems) {
          // Skip items that cannot be prepared in parallel
          bool canPrepareInParallel;
          try {
            // Access the property directly
            canPrepareInParallel = item.item.canPrepareInParallel;
          } catch (e) {
            // If the property doesn't exist, default to true for backward compatibility
            canPrepareInParallel = true;
          }

          if (!canPrepareInParallel) continue;

          // Skip items that are already ready (but allow items that are being prepared)
          if (itemStatusGetter != null) {
            final itemStatus = itemStatusGetter(order.id, item.item.id);
            if (itemStatus == OrderStatus.ready) {
              continue;
            }
          }

          // Create a composite key that includes the time window
          final itemKey = '${item.item.id}_$timeWindow';

          if (!itemsMap.containsKey(itemKey)) {
            itemsMap[itemKey] = [];
          }

          // Handle items with quantity > 1 by creating individual batch items
          // This ensures that large quantities are properly split into multiple batches
          if (item.quantity > 1) {
            // Create individual batch items for each quantity
            for (int i = 0; i < item.quantity; i++) {
              // Create a new CartItem with quantity 1 for each unit
              final singleItem = CartItem(item: item.item, quantity: 1);
              itemsMap[itemKey]!.add(BatchItem(item: singleItem, order: order));
            }
          } else {
            // For items with quantity 1, add them directly
            itemsMap[itemKey]!.add(BatchItem(item: item, order: order));
          }
        }
      }
    }

    // Then, create batch groups with a maximum of 3 items each
    final List<BatchGroup> result = [];

    itemsMap.forEach((itemKey, items) {
      // Skip if there's only one item (no batching needed)
      if (items.length <= 1) return;

      // Get the menu item name from the first item
      final menuItemName = items.first.item.item.name;

      // Extract the actual item ID from the composite key (remove the time window suffix)
      final itemId = itemKey.split('_')[0];

      // Create batches of maximum 3 items
      for (int i = 0; i < items.length; i += maxBatchSize) {
        final batchGroup = BatchGroup(
          menuItemId: itemId,
          menuItemName: menuItemName,
        );

        // Add up to maxBatchSize items to this batch
        final endIndex =
            (i + maxBatchSize < items.length) ? i + maxBatchSize : items.length;

        for (int j = i; j < endIndex; j++) {
          batchGroup.items.add(items[j]);
        }

        // Only add the batch if it has at least 2 items
        if (batchGroup.items.length > 1) {
          result.add(batchGroup);
        }
      }
    });

    return result;
  }

  /// Identifies similar beverage items across multiple orders that can be batch processed
  ///
  /// Returns a list of BatchGroup objects, each containing similar beverage items from different orders
  /// Each batch group is limited to a maximum of 5 items for beverages
  /// Only items that can be prepared in parallel will be batched together
  ///
  /// The statusGetter parameter is a function that returns the status of an order
  /// The itemStatusGetter parameter is a function that returns the status of an individual item
  /// This allows the method to be used with different status types (e.g., kitchen status, staff status)
  static List<BatchGroup> identifySimilarBeverages(
    List<Order> orders,
    OrderStatus Function(String orderId) statusGetter,
    OrderStatus Function(String orderId, String itemId)? itemStatusGetter,
  ) {
    // First, collect all beverage items by menu item ID, but only if they can be prepared in parallel
    final Map<String, List<BatchItem>> itemsMap = {};

    // Get the current time
    final now = DateTime.now();

    // Group orders by time window
    final Map<String, List<Order>> ordersByTimeWindow = {};

    for (var order in orders) {
      // Calculate time difference in minutes
      final timeDifference = now.difference(order.createdAt).inMinutes;

      // We no longer skip orders that are older than the maximum time window
      // This allows all orders to be considered for batch processing
      // if (timeDifference > maxBatchTimeWindowMinutes) continue;

      // Create a key for the time window (0-5 minutes, 5-10 minutes, etc.)
      final timeWindowKey =
          (timeDifference ~/ maxBatchTimeWindowMinutes).toString();

      if (!ordersByTimeWindow.containsKey(timeWindowKey)) {
        ordersByTimeWindow[timeWindowKey] = [];
      }

      ordersByTimeWindow[timeWindowKey]!.add(order);
    }

    // Process each time window separately
    for (var timeWindow in ordersByTimeWindow.keys) {
      final ordersInWindow = ordersByTimeWindow[timeWindow]!;

      for (var order in ordersInWindow) {
        // Get the order status using the provided statusGetter function
        final orderStatus = statusGetter(order.id);

        // Skip orders that are already being prepared or ready
        if (orderStatus == OrderStatus.preparing ||
            orderStatus == OrderStatus.ready) {
          continue;
        }

        // Get all beverage items from the order
        final beverageItems =
            order.items
                .where(
                  (item) =>
                      item.item.category.toLowerCase() == 'beverage' ||
                      item.item.category.toLowerCase() == 'dessert',
                )
                .toList();

        for (var item in beverageItems) {
          // Skip items that cannot be prepared in parallel
          bool canPrepareInParallel;
          try {
            // Access the property directly
            canPrepareInParallel = item.item.canPrepareInParallel;
          } catch (e) {
            // If the property doesn't exist, default to true for backward compatibility
            canPrepareInParallel = true;
          }

          if (!canPrepareInParallel) continue;

          // Skip items that are already ready (but allow items that are being prepared)
          if (itemStatusGetter != null) {
            final itemStatus = itemStatusGetter(order.id, item.item.id);
            if (itemStatus == OrderStatus.ready) {
              continue;
            }
          }

          // Create a composite key that includes the time window
          final itemKey = '${item.item.id}_$timeWindow';

          if (!itemsMap.containsKey(itemKey)) {
            itemsMap[itemKey] = [];
          }

          // Handle items with quantity > 1 by creating individual batch items
          // This ensures that large quantities are properly split into multiple batches
          if (item.quantity > 1) {
            // Create individual batch items for each quantity
            for (int i = 0; i < item.quantity; i++) {
              // Create a new CartItem with quantity 1 for each unit
              final singleItem = CartItem(item: item.item, quantity: 1);
              itemsMap[itemKey]!.add(BatchItem(item: singleItem, order: order));
            }
          } else {
            // For items with quantity 1, add them directly
            itemsMap[itemKey]!.add(BatchItem(item: item, order: order));
          }
        }
      }
    }

    // Then, create batch groups with a maximum of 5 items each (beverages can be prepared in larger batches)
    final List<BatchGroup> result = [];

    itemsMap.forEach((itemKey, items) {
      // Skip if there's only one item (no batching needed)
      if (items.length <= 1) return;

      // Get the menu item name from the first item
      final menuItemName = items.first.item.item.name;

      // Extract the actual item ID from the composite key (remove the time window suffix)
      final itemId = itemKey.split('_')[0];

      // Create batches of maximum 5 items for beverages
      for (int i = 0; i < items.length; i += maxBeverageBatchSize) {
        final batchGroup = BatchGroup(
          menuItemId: itemId,
          menuItemName: menuItemName,
        );

        // Add up to maxBeverageBatchSize items to this batch
        final endIndex =
            (i + maxBeverageBatchSize < items.length)
                ? i + maxBeverageBatchSize
                : items.length;

        for (int j = i; j < endIndex; j++) {
          batchGroup.items.add(items[j]);
        }

        // Only add the batch if it has at least 2 items
        if (batchGroup.items.length > 1) {
          result.add(batchGroup);
        }
      }
    });

    return result;
  }

  /// Gets the batch number for display purposes
  /// For example, "Batch 1 of 2" for the first batch when there are 2 batches
  static String getBatchLabel(
    List<BatchGroup> allGroups,
    BatchGroup group,
    int index,
  ) {
    // Count how many batches have the same menu item ID
    final totalBatches =
        allGroups.where((g) => g.menuItemId == group.menuItemId).length;

    // If there's only one batch, don't show a batch number
    if (totalBatches <= 1) return '';

    // Count which batch this is (1-based index)
    final batchNumber =
        allGroups
            .where((g) => g.menuItemId == group.menuItemId)
            .toList()
            .indexOf(group) +
        1;

    return 'Batch $batchNumber of $totalBatches';
  }

  /// Process a batch of items, updating their status in all affected orders
  ///
  /// Returns a list of order IDs that were affected by this batch processing
  static List<String> processBatch(
    BatchGroup group,
    Function(String orderId, OrderStatus status) updateOrderStatus,
    OrderStatus newStatus,
  ) {
    // Get unique order IDs affected by this batch
    final Set<String> affectedOrderIds = {};

    // Update each item in the batch
    for (var batchItem in group.items) {
      final orderId = batchItem.order.id;
      affectedOrderIds.add(orderId);
    }

    // Update the status of all affected orders
    for (var orderId in affectedOrderIds) {
      updateOrderStatus(orderId, newStatus);
    }

    return affectedOrderIds.toList();
  }

  /// Process a batch of items, updating only the individual items' status
  ///
  /// Returns a list of item keys that were affected by this batch processing
  static List<Map<String, String>> processItemBatch(
    BatchGroup group,
    Function(String orderId, String itemId, OrderStatus status)
    updateItemStatus,
    OrderStatus newStatus,
  ) {
    final List<Map<String, String>> affectedItems = [];

    // Track which items we've already processed to avoid duplicates
    final Set<String> processedItems = {};

    // Update each item in the batch
    for (var batchItem in group.items) {
      final orderId = batchItem.order.id;
      final itemId = batchItem.item.item.id;

      // Create a unique key for this item
      final itemKey = '$orderId:$itemId';

      // Skip if we've already processed this item
      if (processedItems.contains(itemKey)) continue;

      // Mark this item as processed
      processedItems.add(itemKey);

      // Update the item status
      updateItemStatus(orderId, itemId, newStatus);

      // Add to affected items
      affectedItems.add({'orderId': orderId, 'itemId': itemId});
    }

    return affectedItems;
  }
}

// Adaptive priority system that switches between algorithms based on system load
class AdaptiveOrderPrioritizer {
  // Threshold for switching between FCFS and advanced algorithm
  static const int orderThreshold = 3;

  // Main priority calculation method that adapts to system load
  static double calculatePriority(Order order, List<Order> allOrders) {
    // 1. Determine the current system load based on order count
    if (allOrders.length <= orderThreshold) {
      // Light load: Use simple FCFS (First Come, First Served)
      // Earlier orders get higher priority (negative minutes makes earlier orders higher)
      final minutesSinceCreation =
          DateTime.now().difference(order.createdAt).inMinutes;
      return -minutesSinceCreation
          .toDouble(); // Negative so earlier orders have higher priority
    } else {
      // Heavy load: Use advanced priority algorithm
      return AdvancedOrderPrioritizer.calculatePriority(order);
    }
  }
}

// Refined priority algorithm with progressive non-linear wait time scaling
class AdvancedOrderPrioritizer {
  // Kitchen configuration parameters
  static const _maxObservedPrepTime =
      30.0; // Maximum observed preparation time in minutes (reduced from 90.0 for testing)
  static const _customerPatienceThreshold =
      10.0; // Customer patience threshold in minutes (reduced from 30.0 for testing)
  static const _parallelWorkstations =
      3; // Number of parallel workstations in kitchen

  // Calculate overall priority score for an order
  // Combines preparation time and wait time with dynamic weighting
  static double calculatePriority(Order order) {
    // Calculate component scores
    final preparationScore = _calculatePreparationScore(order);

    // Calculate how long the order has been waiting
    final waitTimeMinutes =
        DateTime.now().difference(order.createdAt).inMinutes;

    // Base priority starts low and increases with wait time
    // Start with preparation time as the base (0.0-0.3 range)
    double priority = preparationScore * 0.3;

    // Add wait time component with very gradual scaling
    // For orders under 10 minutes, priority increases very slowly
    if (waitTimeMinutes >= _customerPatienceThreshold) {
      // Orders waiting more than the patience threshold get maximum priority
      priority = 0.95;
    } else if (waitTimeMinutes >= 5) {
      // Orders waiting 5-10 minutes get high priority (0.6-0.9)
      final waitFactor =
          (waitTimeMinutes - 5) / (_customerPatienceThreshold - 5);
      priority = 0.6 + (waitFactor * 0.3);
    } else if (waitTimeMinutes >= 3) {
      // Orders waiting 3-5 minutes get medium priority (0.4-0.6)
      final waitFactor = (waitTimeMinutes - 3) / 2.0;
      priority = 0.4 + (waitFactor * 0.2);
    } else if (waitTimeMinutes >= 1) {
      // Orders waiting 1-3 minutes get low-medium priority (0.2-0.4)
      final waitFactor = (waitTimeMinutes - 1) / 2.0;
      priority = 0.2 + (waitFactor * 0.2);
    } else {
      // Orders waiting less than 1 minute get very low priority (0.05-0.2)
      priority = 0.05 + (waitTimeMinutes * 0.15);
    }

    // Check if the order has any ready items (this will be set by OrderProvider)
    if (order.hasReadyItems) {
      // Add a moderate boost to prioritize orders with ready items
      priority += 0.2;
    }

    // Ensure the final priority is between 0.0 and 1.0
    return priority.clamp(0.0, 1.0);
  }

  // This method was removed as it's no longer used in the new priority calculation

  // Calculate preparation score considering parallel workstations
  // This simulates how multiple items can be prepared simultaneously
  static double _calculatePreparationScore(Order order) {
    // Group items by whether they can be prepared in parallel
    final parallelItems =
        order.items.where((item) {
          try {
            return item.item.canPrepareInParallel;
          } catch (e) {
            // If the property doesn't exist, default to true
            return true;
          }
        }).toList();

    final sequentialItems =
        order.items.where((item) {
          try {
            return !item.item.canPrepareInParallel;
          } catch (e) {
            // If the property doesn't exist, default to false (meaning it's parallel)
            return false;
          }
        }).toList();

    // Calculate total time for parallel items
    double parallelTime = 0;
    if (parallelItems.isNotEmpty) {
      // Extract and sort preparation times in descending order
      final prepTimes =
          parallelItems.map((item) => item.item.preparationTime).toList()
            ..sort((a, b) => b.compareTo(a));

      // Calculate total preparation time with parallel processing
      for (int i = 0; i < prepTimes.length; i += _parallelWorkstations) {
        // For each batch of items that can be prepared in parallel,
        // find the longest preparation time (bottleneck)
        final batchMax = prepTimes
            .sublist(i, min(i + _parallelWorkstations, prepTimes.length))
            .reduce((a, b) => a > b ? a : b);

        // Add the batch time to total (simulating sequential batches)
        parallelTime += batchMax;
      }
    }

    // Calculate total time for sequential items (must be prepared one by one)
    final sequentialTime = sequentialItems.fold(
      0.0,
      (sum, item) => sum + item.item.preparationTime,
    );

    // Total time is the sum of parallel and sequential processing times
    final totalTime = parallelTime + sequentialTime;

    // Normalize to 0-1 scale (inverse relationship: shorter prep time = higher score)
    return (1 - (totalTime / _maxObservedPrepTime).clamp(0.0, 1.0));
  }

  // This method was removed as it's no longer used in the new priority calculation
}

/// Integrated smart kitchen processing system that combines prioritization and batching
class SmartKitchenProcessor {
  /// Process orders intelligently using both prioritization and batching techniques
  static List<Order> processOrders(
    List<Order> orders,
    OrderStatus Function(String orderId) statusGetter,
    Function(String orderId, OrderStatus status) updateOrderStatus,
  ) {
    // Step 1: First prioritize all orders using the adaptive prioritizer
    final Map<String, double> orderPriorities = {};

    for (var order in orders) {
      orderPriorities[order.id] = AdaptiveOrderPrioritizer.calculatePriority(
        order,
        orders,
      );
    }

    // Sort orders by priority (highest first)
    final List<Order> prioritizedOrders = List.from(
      orders,
    )..sort((a, b) => orderPriorities[b.id]!.compareTo(orderPriorities[a.id]!));

    // Step 2: Identify batch opportunities in the prioritized orders
    final List<BatchGroup> foodBatches =
        BatchProcessor.identifySimilarFoodItems(
          prioritizedOrders,
          statusGetter,
          null, // No item status getter for this case
        );

    final List<BatchGroup> beverageBatches =
        BatchProcessor.identifySimilarBeverages(
          prioritizedOrders,
          statusGetter,
          null, // No item status getter for this case
        );

    // Step 3: Apply batch processing, but preserve overall priority order
    // Process high-priority batches first
    final allBatches = [...foodBatches, ...beverageBatches];

    // Calculate batch priorities based on the highest priority order in each batch
    final Map<BatchGroup, double> batchPriorities = {};

    for (var batch in allBatches) {
      // Use the highest priority order in the batch to set batch priority
      double maxPriority = 0.0;
      bool hasPreparingItems = false;
      bool hasReadyItems = false;

      for (var item in batch.items) {
        final orderPriority = orderPriorities[item.order.id] ?? 0.0;
        if (orderPriority > maxPriority) {
          maxPriority = orderPriority;
        }

        // Check item status
        final itemStatus = statusGetter(item.order.id);
        if (itemStatus == OrderStatus.preparing) {
          hasPreparingItems = true;
        } else if (itemStatus == OrderStatus.ready) {
          hasReadyItems = true;
        }
      }

      // Boost priority for batches with items in progress
      if (hasPreparingItems) {
        maxPriority = 0.95; // Very high priority for in-progress batches
      } else if (hasReadyItems) {
        maxPriority = 0.9; // High priority for batches with ready items
      }

      batchPriorities[batch] = maxPriority;
      batch.priority = maxPriority; // Set the batch's priority
    }

    // Sort batches by priority
    allBatches.sort(
      (a, b) => batchPriorities[b]!.compareTo(batchPriorities[a]!),
    );

    // Step 4: For remaining orders that aren't in batches, process individually by priority
    final Set<String> batchProcessedOrderIds = {};

    for (var batch in allBatches) {
      for (var item in batch.items) {
        batchProcessedOrderIds.add(item.order.id);
      }
    }

    // Get orders that aren't part of any batch
    final List<Order> nonBatchOrders =
        prioritizedOrders
            .where((order) => !batchProcessedOrderIds.contains(order.id))
            .toList();

    // Step 5: Combine both processing methods into one ordered list
    // First the batches (already sorted by priority)
    final List<dynamic> processingPlan = [];

    // Add batches to the plan
    for (var batch in allBatches) {
      processingPlan.add(batch);
    }

    // Add individual orders to the plan
    for (var order in nonBatchOrders) {
      processingPlan.add(order);
    }

    // Return the prioritized order list (combination of batched and non-batched orders)
    return prioritizedOrders;
  }

  /// Get preparation instructions for kitchen staff
  static List<String> getPreparationInstructions(List<dynamic> processingPlan) {
    final List<String> instructions = [];

    for (var item in processingPlan) {
      if (item is BatchGroup) {
        instructions.add(
          "BATCH: Prepare ${item.totalQuantity}x ${item.menuItemName}",
        );

        // Add details for each order in the batch
        for (var batchItem in item.items) {
          instructions.add(
            "  - Order #${batchItem.order.id}: ${batchItem.item.quantity}x",
          );
        }
      } else if (item is Order) {
        instructions.add("ORDER #${item.id}:");

        // Group items by category
        final Map<String, List<CartItem>> itemsByCategory = {};

        for (var cartItem in item.items) {
          final category = cartItem.item.category;
          if (!itemsByCategory.containsKey(category)) {
            itemsByCategory[category] = [];
          }
          itemsByCategory[category]!.add(cartItem);
        }

        // Add instructions by category
        itemsByCategory.forEach((category, items) {
          instructions.add("  - $category:");
          for (var item in items) {
            instructions.add("    • ${item.quantity}x ${item.item.name}");
          }
        });
      }
    }

    return instructions;
  }
}
