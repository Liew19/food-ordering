// Create a test file named lib/test_adaptive_priority.dart

import 'dart:math';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp/models/order.dart';
import 'package:fyp/models/menu_item.dart';
import 'package:fyp/state/cart_provider.dart';
import 'package:fyp/utils/fcfs.dart';
import 'package:fyp/utils/sjf.dart';
import 'package:fyp/utils/advanced_priority.dart';

// Test class to simulate the behavior of different algorithms
class OrderSchedulingTester {
  static void testAdaptiveAlgorithm() {
    print("=== ADAPTIVE ALGORITHM TEST SUITE ===\n");

    // 1. Light load test (≤3 orders)
    print("1. LIGHT LOAD TEST (3 orders)");
    testLightLoad();

    // 2. Load transition test
    print("\n2. LOAD TRANSITION TEST");
    testLoadTransition();

    // 3. Peak load test
    print("\n3. PEAK LOAD TEST");
    testPeakLoad();
  }

  // Test light load scenario (should behave like FCFS)
  static void testLightLoad() {
    final List<Order> orders = [];
    final startTime = DateTime.now().subtract(
      Duration(minutes: 15),
    ); // 从15分钟前开始

    // Create 3 orders with mixed sizes
    orders.add(
      createOrder(
        "order1",
        startTime,
        15.0, // longer prep time
        2,
      ),
    );

    orders.add(
      createOrder(
        "order2",
        startTime.add(Duration(minutes: 5)), // 5分钟后
        5.0, // short prep time
        1,
      ),
    );

    orders.add(
      createOrder(
        "order3",
        startTime.add(Duration(minutes: 10)), // 10分钟后
        10.0, // medium prep time
        1,
      ),
    );

    // Process with different algorithms
    final fcfsOrder = FCFSOrderSorter.sortOrders(List.from(orders));
    final sjfOrder = SJFOrderSorter.sortOrders(List.from(orders));
    final adaptiveOrder = processWithAdaptive(List.from(orders));

    print("\nLight Load Results Comparison:");
    print("FCFS sequence: ${fcfsOrder.map((o) => o.id).join(' -> ')}");
    print("SJF sequence: ${sjfOrder.map((o) => o.id).join(' -> ')}");
    print("Adaptive sequence: ${adaptiveOrder.map((o) => o.id).join(' -> ')}");

    // Print priorities for debugging
    print("\nPriorities:");
    for (var order in adaptiveOrder) {
      final waitTime = DateTime.now().difference(order.createdAt).inMinutes;
      print(
        "Order ${order.id}: priority=${order.priority.toStringAsFixed(3)}, wait=${waitTime}min, prep=${order.items.first.item.preparationTime}min",
      );
    }

    // Verify if adaptive matches FCFS under light load
    final matchesFCFS = listsEqual(fcfsOrder, adaptiveOrder);
    print(
      "\nDoes adaptive algorithm match FCFS under light load? ${matchesFCFS ? 'Yes' : 'No'}",
    );
  }

  // Test transition from light to heavy load
  static void testLoadTransition() {
    final List<Order> orders = [];
    final startTime = DateTime.now().subtract(
      Duration(minutes: 30),
    ); // 从30分钟前开始

    // First add 3 orders (light load)
    for (int i = 0; i < 3; i++) {
      orders.add(
        createOrder(
          "light_$i",
          startTime.add(Duration(minutes: i * 5)), // 每5分钟一个订单
          5.0 + i * 2, // increasing prep times
          1,
        ),
      );
    }

    // Then quickly add more orders (transition to heavy load)
    for (int i = 0; i < 5; i++) {
      orders.add(
        createOrder(
          "heavy_$i",
          startTime.add(Duration(minutes: 15 + i)), // 每1分钟一个订单
          i % 2 == 0 ? 15.0 : 5.0, // alternating long/short orders
          1,
        ),
      );
    }

    // Process orders and observe transition
    final processedOrders = processWithAdaptive(orders);

    print("\nOrder Processing Sequence During Load Transition:");
    for (int i = 0; i < processedOrders.length; i++) {
      final order = processedOrders[i];
      final waitTime = DateTime.now().difference(order.createdAt).inMinutes;
      print(
        "${i + 1}. ${order.id} (Priority: ${order.priority.toStringAsFixed(3)}, Wait: ${waitTime}min, Prep: ${order.items.first.item.preparationTime} min)",
      );
    }
  }

  // Test peak load scenario
  static void testPeakLoad() {
    final List<Order> orders = [];
    final startTime = DateTime.now();

    // Create one large order
    orders.add(createOrder("large_order", startTime, 25.0, 2));

    // Rapidly add small orders to simulate peak time
    for (int i = 0; i < 10; i++) {
      orders.add(
        createOrder(
          "small_$i",
          startTime.add(
            Duration(seconds: 10 * (i + 1)),
          ), // new order every 10 seconds
          5.0,
          1,
        ),
      );
    }

    // Process with different algorithms
    final fcfsResults = analyzeProcessing(orders, FCFSOrderSorter.sortOrders);
    final sjfResults = analyzeProcessing(orders, SJFOrderSorter.sortOrders);
    final adaptiveResults = analyzeAdaptiveProcessing(orders);

    print("\nPeak Time Performance Comparison:");
    print("Metric\t\tFCFS\t\tSJF\t\tAdaptive");
    print(
      "Avg Wait Time\t${fcfsResults[0].toStringAsFixed(1)}s\t\t${sjfResults[0].toStringAsFixed(1)}s\t\t${adaptiveResults[0].toStringAsFixed(1)}s",
    );
    print(
      "Max Wait Time\t${fcfsResults[1].toStringAsFixed(1)}s\t\t${sjfResults[1].toStringAsFixed(1)}s\t\t${adaptiveResults[1].toStringAsFixed(1)}s",
    );
    print(
      "Large Order Pos\t${fcfsResults[2]}\t\t${sjfResults[2]}\t\t${adaptiveResults[2]}",
    );
  }

  // Helper methods
  static Order createOrder(
    String id,
    DateTime time,
    double prepTime,
    int quantity,
  ) {
    return Order(
      id: id,
      createdAt: time,
      items: [
        CartItem(
          item: MenuItem(
            id: "test_item",
            itemId: "test_item_$id",
            name: "Test Item",
            description: "Test item",
            price: 10.0,
            category: "Main",
            preparationTime: prepTime,
            imageUrl: "test.jpg",
            canPrepareInParallel: true,
          ),
          quantity: quantity,
        ),
      ],
      totalPrice: 10.0 * quantity,
      status: OrderStatus.pending,
    );
  }

  static List<Order> processWithAdaptive(List<Order> orders) {
    final processedOrders = <Order>[];
    final pendingOrders = List<Order>.from(orders);
    DateTime currentTime = orders.first.createdAt;

    while (pendingOrders.isNotEmpty) {
      // Get orders that have arrived by current time
      final activeOrders =
          pendingOrders
              .where(
                (o) =>
                    o.createdAt.isBefore(currentTime) ||
                    o.createdAt.isAtSameMomentAs(currentTime),
              )
              .toList();

      if (activeOrders.isEmpty) {
        currentTime = currentTime.add(Duration(seconds: 10));
        continue;
      }

      // 应用批处理逻辑，限制时间窗口为30秒
      final timeWindow = Duration(seconds: 30);
      final ordersInTimeWindow =
          activeOrders.where((order) {
            final orderAge = currentTime.difference(order.createdAt);
            return orderAge <= timeWindow;
          }).toList();

      var batches = BatchProcessor.identifySimilarFoodItems(
        ordersInTimeWindow, // 使用时间窗口内的订单
        (orderId) => OrderStatus.pending,
        null,
      );

      var beverageBatches = BatchProcessor.identifySimilarBeverages(
        ordersInTimeWindow, // 使用时间窗口内的订单
        (orderId) => OrderStatus.pending,
        null,
      );

      // 合并所有批次
      batches.addAll(beverageBatches);

      if (batches.isNotEmpty) {
        // 处理批次中的订单
        var batchToProcess = batches.reduce(
          (a, b) => a.totalQuantity > b.totalQuantity ? a : b,
        );
        var maxPrepTime = 0.0;

        // 找出批次中最长的准备时间，并限制最大准备时间
        for (var item in batchToProcess.items) {
          maxPrepTime = max(maxPrepTime, item.item.item.preparationTime);
        }
        // 限制单个批次的最大准备时间为10分钟
        maxPrepTime = min(maxPrepTime, 10.0);

        // 处理批次中的所有订单
        for (var item in batchToProcess.items) {
          var order = item.order;
          pendingOrders.remove(order);
          processedOrders.add(order);
        }

        // 只前进最长的准备时间（因为是并行处理）
        currentTime = currentTime.add(Duration(seconds: maxPrepTime.round()));
      } else {
        // 如果没有可以批处理的订单，使用普通的优先级处理
        for (var order in activeOrders) {
          order.calculatePriority();
        }
        activeOrders.sort((a, b) => b.priority.compareTo(a.priority));

        final nextOrder = activeOrders[0];
        pendingOrders.remove(nextOrder);
        processedOrders.add(nextOrder);

        // 前进该订单的准备时间
        currentTime = currentTime.add(
          Duration(seconds: nextOrder.items.first.item.preparationTime.round()),
        );
      }
    }

    return processedOrders;
  }

  static List<double> analyzeProcessing(
    List<Order> orders,
    List<Order> Function(List<Order>) sorter,
  ) {
    final sortedOrders = sorter(List.from(orders));
    DateTime currentTime = orders.first.createdAt;
    double totalWaitTime = 0;
    double maxWaitTime = 0;
    int largeOrderPosition = -1;

    for (int i = 0; i < sortedOrders.length; i++) {
      final order = sortedOrders[i];
      final waitTime =
          currentTime.difference(order.createdAt).inSeconds.toDouble();

      if (order.id == "large_order") {
        largeOrderPosition = i + 1;
      }

      totalWaitTime += waitTime;
      maxWaitTime = max(maxWaitTime, waitTime);

      currentTime = currentTime.add(
        Duration(seconds: order.items.first.item.preparationTime.round()),
      );
    }

    return [
      totalWaitTime / orders.length,
      maxWaitTime,
      largeOrderPosition.toDouble(),
    ];
  }

  static List<double> analyzeAdaptiveProcessing(List<Order> orders) {
    final processedOrders = processWithAdaptive(orders);
    double totalWaitTime = 0;
    double maxWaitTime = 0;
    int largeOrderPosition = -1;
    DateTime currentTime = orders.first.createdAt;

    for (int i = 0; i < processedOrders.length; i++) {
      final order = processedOrders[i];
      if (order.id == "large_order") {
        largeOrderPosition = i + 1;
      }

      final waitTime =
          currentTime.difference(order.createdAt).inSeconds.toDouble();
      totalWaitTime += waitTime;
      maxWaitTime = max(maxWaitTime, waitTime);

      currentTime = currentTime.add(
        Duration(seconds: order.items.first.item.preparationTime.round()),
      );
    }

    return [
      totalWaitTime / orders.length,
      maxWaitTime,
      largeOrderPosition.toDouble(),
    ];
  }

  static bool listsEqual(List<Order> a, List<Order> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
}

void main() {
  group('Order Scheduling Algorithm Tests', () {
    test('Adaptive Algorithm Test Suite', () {
      OrderSchedulingTester.testAdaptiveAlgorithm();
    });

    test('Light Load Test', () {
      OrderSchedulingTester.testLightLoad();
    });

    test('Load Transition Test', () {
      OrderSchedulingTester.testLoadTransition();
    });

    test('Peak Load Test', () {
      OrderSchedulingTester.testPeakLoad();
    });

    test('Random Orders Test', () {
      testRandomOrders();
    });
  });
}

void testOrderProcessingAlgorithms() {
  print("=== RESTAURANT ORDER PROCESSING ALGORITHMS COMPARISON ===\n");

  // 1. Peak Time Test (with batch processing)
  testPeakTimeScenario();

  // 2. Mixed Order Types Test
  testMixedOrderTypes();

  // 3. Batch Processing Efficiency Test
  testBatchProcessingEfficiency();
}

// 1. Peak Time Test
void testPeakTimeScenario() {
  print("1. PEAK TIME SCENARIO TEST");
  print("Simulating busy restaurant period with multiple similar orders\n");

  final orders = [
    // 第一批：汉堡批次
    createTestOrder(
      "order1",
      items: [
        createMenuItem("Burger", 15.0, "Main Course", true),
        createMenuItem("Fries", 5.0, "Side", true),
      ],
    ),
    createTestOrder(
      "order2",
      items: [createMenuItem("Burger", 15.0, "Main Course", true)],
    ),
    createTestOrder(
      "order3",
      items: [
        createMenuItem("Burger", 15.0, "Main Course", true),
        createMenuItem("Cola", 2.0, "Beverage", true),
      ],
    ),
    // 第二批：混合订单
    createTestOrder(
      "order4",
      items: [createMenuItem("Pizza", 20.0, "Main Course", false)],
    ),
    createTestOrder(
      "order5",
      items: [createMenuItem("Salad", 8.0, "Main Course", true)],
    ),
    // 添加更多订单以触发高负载模式
    createTestOrder(
      "order6",
      items: [
        createMenuItem("Steak", 25.0, "Main Course", false),
        createMenuItem("Wine", 1.0, "Beverage", true),
      ],
    ),
    createTestOrder(
      "order7",
      items: [createMenuItem("Pasta", 12.0, "Main Course", true)],
    ),
    createTestOrder(
      "order8",
      items: [
        createMenuItem("Fish", 18.0, "Main Course", false),
        createMenuItem("Soup", 5.0, "Starter", true),
      ],
    ),
  ];

  compareAlgorithms(orders, "Peak Time");
}

// 2. Mixed Order Types Test
void testMixedOrderTypes() {
  print("\n2. MIXED ORDER TYPES TEST");
  print("Testing how algorithms handle variety of order types\n");

  final orders = [
    // Long preparation items
    createTestOrder(
      "complex1",
      items: [
        createMenuItem("Steak", 25.0, "Main Course", false),
        createMenuItem("Soup", 10.0, "Starter", true),
      ],
    ),
    // Quick items
    createTestOrder(
      "quick1",
      items: [
        createMenuItem("Sandwich", 8.0, "Main Course", true),
        createMenuItem("Coffee", 3.0, "Beverage", true),
      ],
    ),
    // Mixed items
    createTestOrder(
      "mixed1",
      items: [
        createMenuItem("Fish", 18.0, "Main Course", false),
        createMenuItem("Salad", 5.0, "Side", true),
        createMenuItem("Juice", 2.0, "Beverage", true),
      ],
    ),
  ];

  compareAlgorithms(orders, "Mixed Types");
}

// 3. Batch Processing Efficiency Test
void testBatchProcessingEfficiency() {
  print("\n3. BATCH PROCESSING EFFICIENCY TEST");
  print("Testing batch processing capabilities\n");

  final orders = [
    // Batch 1: Similar beverages
    createTestOrder(
      "bev1",
      items: [createMenuItem("Coffee", 3.0, "Beverage", true)],
    ),
    createTestOrder(
      "bev2",
      items: [createMenuItem("Coffee", 3.0, "Beverage", true)],
    ),
    createTestOrder(
      "bev3",
      items: [createMenuItem("Coffee", 3.0, "Beverage", true)],
    ),

    // Batch 2: Similar food items
    createTestOrder(
      "food1",
      items: [createMenuItem("Pasta", 12.0, "Main Course", true)],
    ),
    createTestOrder(
      "food2",
      items: [createMenuItem("Pasta", 12.0, "Main Course", true)],
    ),

    // Non-batchable order
    createTestOrder(
      "special1",
      items: [createMenuItem("Special Dish", 20.0, "Main Course", false)],
    ),
  ];

  // Test batch processing
  var batches = BatchProcessor.identifySimilarFoodItems(
    orders,
    (orderId) => OrderStatus.pending,
    null,
  );

  print("Food Batches Identified:");
  for (var batch in batches) {
    print("""
    Batch: ${batch.menuItemName}
    Items: ${batch.totalQuantity}
    Orders: ${batch.items.map((i) => i.order.id).join(', ')}
    """);
  }

  var beverageBatches = BatchProcessor.identifySimilarBeverages(
    orders,
    (orderId) => OrderStatus.pending,
    null,
  );

  print("Beverage Batches Identified:");
  for (var batch in beverageBatches) {
    print("""
    Batch: ${batch.menuItemName}
    Items: ${batch.totalQuantity}
    Orders: ${batch.items.map((i) => i.order.id).join(', ')}
    """);
  }

  compareAlgorithms(orders, "Batch Processing");
}

// Helper function to compare algorithms
void compareAlgorithms(List<Order> orders, String scenario) {
  print("\nResults for $scenario:");
  print("----------------------------------------");

  // Test FCFS
  var fcfsOrders = FCFSOrderSorter.sortOrders(List.from(orders));
  printOrderSequence("FCFS", fcfsOrders);

  // Test SJF
  var sjfOrders = SJFOrderSorter.sortOrders(List.from(orders));
  printOrderSequence("SJF", sjfOrders);

  // Test Adaptive Priority with Batching
  var adaptiveOrders = OrderSchedulingTester.processWithAdaptive(
    List.from(orders),
  );
  printOrderSequence("Adaptive Priority", adaptiveOrders);

  // Calculate and print metrics
  print("\nPerformance Metrics:");
  print("Algorithm | Avg Wait Time | Max Wait Time | Batch Util");
  print("----------|--------------|---------------|------------");
  printMetrics("FCFS", fcfsOrders);
  printMetrics("SJF", sjfOrders);
  printMetrics("Adaptive", adaptiveOrders);
}

MenuItem createMenuItem(
  String name,
  double prepTime,
  String category,
  bool canPrepareInParallel,
) {
  return MenuItem(
    id: "test_${name.toLowerCase()}",
    itemId: "test_item_${name.toLowerCase()}",
    name: name,
    price: 10.0,
    category: category,
    preparationTime: prepTime,
    imageUrl: "test.jpg",
    canPrepareInParallel: canPrepareInParallel,
  );
}

Order createTestOrder(String id, {required List<MenuItem> items}) {
  return Order(
    id: id,
    createdAt: DateTime.now(),
    items: items.map((item) => CartItem(item: item, quantity: 1)).toList(),
    totalPrice: items.length * 10.0,
    status: OrderStatus.pending,
  );
}

void printOrderSequence(String algorithmName, List<Order> orders) {
  print("\n$algorithmName Order Sequence:");
  for (var i = 0; i < orders.length; i++) {
    final order = orders[i];
    print("""    ${i + 1}. Order ${order.id}
       Prep Time: ${order.items.map((item) => item.item.preparationTime).reduce((a, b) => a + b)} min
       Items: ${order.items.length}""");
  }
}

void printMetrics(String algorithmName, List<Order> orders) {
  final avgWaitTime = calculateAverageWaitTime(orders);
  final maxWaitTime = calculateMaxWaitTime(orders);

  if (algorithmName == "Adaptive") {
    final batchUtil = calculateBatchUtilization(orders);
    print(
      "$algorithmName | ${avgWaitTime.toStringAsFixed(1)}s | ${maxWaitTime.toStringAsFixed(1)}s | ${batchUtil.toStringAsFixed(1)}%",
    );
  } else {
    print(
      "$algorithmName | ${avgWaitTime.toStringAsFixed(1)}s | ${maxWaitTime.toStringAsFixed(1)}s | N/A",
    );
  }
}

double calculateAverageWaitTime(List<Order> orders) {
  if (orders.isEmpty) return 0.0;
  var totalWait = 0.0;
  var currentTime = orders.first.createdAt;
  var i = 0;

  while (i < orders.length) {
    var currentOrder = orders[i];
    var batchOrders = <Order>[currentOrder];
    var j = i + 1;

    // 检查后续订单是否可以批处理
    while (j < orders.length) {
      var nextOrder = orders[j];
      if (canBatchProcess(currentOrder, nextOrder)) {
        batchOrders.add(nextOrder);
        j++;
      } else {
        break;
      }
    }

    // 计算这批订单的等待时间
    var maxPrepTime = batchOrders
        .map(
          (o) => o.items.fold(
            0.0,
            (sum, item) => max(sum, item.item.preparationTime),
          ),
        )
        .reduce(max);

    for (var order in batchOrders) {
      totalWait += currentTime.difference(order.createdAt).inSeconds;
    }

    // 更新时间和索引
    currentTime = currentTime.add(Duration(seconds: maxPrepTime.round()));
    i = j;
  }

  return totalWait / orders.length;
}

double calculateMaxWaitTime(List<Order> orders) {
  if (orders.isEmpty) return 0.0;
  var maxWait = 0.0;
  var currentTime = orders.first.createdAt;
  var i = 0;

  while (i < orders.length) {
    var currentOrder = orders[i];
    var batchOrders = <Order>[currentOrder];
    var j = i + 1;

    // 检查后续订单是否可以批处理
    while (j < orders.length) {
      var nextOrder = orders[j];
      if (canBatchProcess(currentOrder, nextOrder)) {
        batchOrders.add(nextOrder);
        j++;
      } else {
        break;
      }
    }

    // 计算这批订单的最大等待时间
    var maxPrepTime = batchOrders
        .map(
          (o) => o.items.fold(
            0.0,
            (sum, item) => max(sum, item.item.preparationTime),
          ),
        )
        .reduce(max);

    for (var order in batchOrders) {
      var waitTime = currentTime.difference(order.createdAt).inSeconds;
      maxWait = max(maxWait, waitTime.toDouble());
    }

    // 更新时间和索引
    currentTime = currentTime.add(Duration(seconds: maxPrepTime.round()));
    i = j;
  }

  return maxWait;
}

double calculateBatchUtilization(List<Order> orders) {
  if (orders.isEmpty) return 0.0;
  var batchableItems = 0;
  var totalItems = 0;

  for (var order in orders) {
    for (var item in order.items) {
      totalItems++;
      if (item.item.canPrepareInParallel) {
        batchableItems++;
      }
    }
  }

  return totalItems > 0 ? (batchableItems / totalItems) * 100 : 0.0;
}

// Check if two orders can be batch processed
bool canBatchProcess(Order order1, Order order2) {
  // Check if there are common items
  for (var item1 in order1.items) {
    for (var item2 in order2.items) {
      if (item1.item.id == item2.item.id &&
          item1.item.canPrepareInParallel &&
          item2.item.canPrepareInParallel) {
        return true;
      }
    }
  }
  return false;
}

// Generate random test orders
List<Order> generateRandomOrders({
  int numberOfOrders = 100,
  int maxItemsPerOrder = 3,
  double maxPrepTime = 8.0, // 降低最大准备时间
  int maxRandomTimeSeconds = 60, // 显著减少时间窗口到1分钟
}) {
  final random = Random();
  final List<Order> orders = [];
  final baseTime = DateTime.now().subtract(Duration(minutes: 2)); // 减少基础时间偏移

  // Optimized menu items pool with more parallel-friendly items
  final menuItems = [
    // Fast, parallel items (1-3 minutes)
    createMenuItem("Salad", 2.0, "Starter", true),
    createMenuItem("Soup", 3.0, "Starter", true),
    createMenuItem("Sandwich", 3.0, "Main Course", true),
    createMenuItem("Coffee", 1.0, "Beverage", true),
    createMenuItem("Tea", 1.0, "Beverage", true),
    createMenuItem("Juice", 1.0, "Beverage", true),

    // Medium items (4-6 minutes)
    createMenuItem("Pasta", 5.0, "Main Course", true),
    createMenuItem("Fish", 6.0, "Main Course", true),
    createMenuItem("Burger", 4.0, "Main Course", true),

    // Longer items (7-10 minutes)
    createMenuItem("Pizza", 8.0, "Main Course", false),
    createMenuItem("Steak", maxPrepTime, "Main Course", false),
  ];

  // Group similar preparation time items for better batching
  final fastItems =
      menuItems.where((item) => item.preparationTime <= 3.0).toList();
  final mediumItems =
      menuItems
          .where(
            (item) => item.preparationTime > 3.0 && item.preparationTime <= 6.0,
          )
          .toList();
  final slowItems =
      menuItems.where((item) => item.preparationTime > 6.0).toList();

  for (int i = 0; i < numberOfOrders; i++) {
    // Random number of items for this order (1 to maxItemsPerOrder)
    final itemCount = random.nextInt(maxItemsPerOrder) + 1;
    final orderItems = <CartItem>[];

    // Smart item selection to promote better parallel processing
    for (int j = 0; j < itemCount; j++) {
      List<MenuItem> itemPool;

      // Distribute items with better probability for parallel processing
      final itemType = random.nextDouble();
      if (itemType < 0.6) {
        // 60% chance for fast items
        itemPool = fastItems;
      } else if (itemType < 0.85) {
        // 25% chance for medium items
        itemPool = mediumItems;
      } else {
        // 15% chance for slow items
        itemPool = slowItems;
      }

      final menuItem = itemPool[random.nextInt(itemPool.length)];
      orderItems.add(
        CartItem(
          item: menuItem,
          quantity: random.nextInt(2) + 1, // 1 or 2 items
        ),
      );
    }

    // Compress time window to reduce wait times
    final randomSeconds = random.nextInt(
      maxRandomTimeSeconds ~/ 2,
    ); // Reduce time window by half
    final orderTime = baseTime.add(Duration(seconds: randomSeconds));

    orders.add(
      Order(
        id: "order_${i + 1}",
        createdAt: orderTime,
        items: orderItems,
        totalPrice: orderItems.fold(
          0.0,
          (sum, item) => sum + (item.item.price * item.quantity),
        ),
        status: OrderStatus.pending,
      ),
    );
  }

  return orders;
}

// Add new test case for random orders
void testRandomOrders() {
  print("\n=== RANDOM ORDERS TEST ===");
  print("Testing algorithm performance with random orders\n");

  final orders = generateRandomOrders(
    numberOfOrders: 100,
    maxItemsPerOrder: 3,
    maxPrepTime: 8.0,
    maxRandomTimeSeconds: 180,
  );

  print("Generated ${orders.length} random orders");
  print("Order distribution:");

  // Analyze order distribution
  var totalItems = 0;
  var totalPrepTime = 0.0;
  var parallelItems = 0;
  var fastItems = 0;
  var mediumItems = 0;
  var slowItems = 0;

  for (var order in orders) {
    totalItems += order.items.length;
    for (var item in order.items) {
      final prepTime = item.item.preparationTime;
      totalPrepTime += prepTime * item.quantity;
      if (item.item.canPrepareInParallel) parallelItems++;

      // Count items by preparation time
      if (prepTime <= 3.0)
        fastItems++;
      else if (prepTime <= 6.0)
        mediumItems++;
      else
        slowItems++;
    }
  }

  print("""
Distribution Statistics:
- Average items per order: ${(totalItems / orders.length).toStringAsFixed(2)}
- Average prep time per order: ${(totalPrepTime / orders.length).toStringAsFixed(2)} minutes
- Parallel items percentage: ${(parallelItems * 100 / totalItems).toStringAsFixed(2)}%
- Fast items (≤3min): ${(fastItems * 100 / totalItems).toStringAsFixed(2)}%
- Medium items (4-6min): ${(mediumItems * 100 / totalItems).toStringAsFixed(2)}%
- Slow items (>6min): ${(slowItems * 100 / totalItems).toStringAsFixed(2)}%
""");

  compareAlgorithms(orders, "Random Orders");
}
