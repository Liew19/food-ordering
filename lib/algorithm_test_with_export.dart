import 'dart:math';
import 'models/test_order.dart';
import 'models/food_item.dart';
import 'models/order_item.dart';
import 'utils/test_fcfs.dart';
import 'utils/test_sjf.dart';
import 'utils/priority_sorter.dart';
import 'utils/csv_exporter.dart';

void main() async {
  print(
    "=== Order Scheduling Algorithm Comparison Test (with CSV Export) ===\n",
  );

  // Run all tests and collect data
  final List<List<dynamic>> allTestData = [];

  // Add header row
  allTestData.add(["Test Type", "Algorithm", "Metric", "Value"]);

  // Run basic performance test
  await runBasicPerformanceTest(allTestData);

  // Run starvation test
  await runStarvationTest(allTestData);

  // Run fairness test
  await runFairnessTest(allTestData);

  // Export all test results to CSV
  final fileName =
      'algorithm_test_results_${DateTime.now().millisecondsSinceEpoch}.csv';
  await CSVExporter.exportResults(allTestData, fileName);

  print("\nAll test results have been exported to: $fileName");
}

Future<void> runBasicPerformanceTest(List<List<dynamic>> data) async {
  print("1. Basic Performance Test");
  print("---------------------");
  print("Scenario: 100 random orders with varying sizes and arrival times\n");

  final random = Random(42); // Use fixed seed for reproducible results
  final int numberOfOrders = 100;
  final DateTime simulationStart = DateTime.now();

  // 生成测试订单
  final List<Order> testOrders = [];

  for (int i = 0; i < numberOfOrders; i++) {
    final createdAt = simulationStart.add(
      Duration(seconds: random.nextInt(300)),
    );
    final items = <OrderItem>[];

    final itemCount = random.nextInt(3) + 1;
    for (int j = 0; j < itemCount; j++) {
      items.add(
        OrderItem(
          item: FoodItem(preparationTime: random.nextDouble() * 10 + 1),
        ),
      );
    }

    testOrders.add(Order(id: i.toString(), createdAt: createdAt, items: items));
  }

  // 运行每个算法的测试
  final fcfsResults = runPerformanceTest(
    "FCFS",
    FCFSOrderSorter.sortOrders,
    testOrders,
    simulationStart,
  );
  final sjfResults = runPerformanceTest(
    "SJF",
    SJFOrderSorter.sortOrders,
    testOrders,
    simulationStart,
  );
  final priorityResults = runPerformanceTest(
    "Priority",
    PriorityOrderSorter.sortOrders,
    testOrders,
    simulationStart,
  );

  // 提取指标
  final fcfsWaitTime = double.parse(fcfsResults[0]);
  final sjfWaitTime = double.parse(sjfResults[0]);
  final priorityWaitTime = double.parse(priorityResults[0]);

  final fcfsTurnaroundTime = double.parse(fcfsResults[1]);
  final sjfTurnaroundTime = double.parse(sjfResults[1]);
  final priorityTurnaroundTime = double.parse(priorityResults[1]);

  // 计算改进百分比
  final sjfVsFcfsWaitImprovement =
      ((fcfsWaitTime - sjfWaitTime) / fcfsWaitTime * 100).toStringAsFixed(2);
  final priorityVsFcfsWaitImprovement = ((fcfsWaitTime - priorityWaitTime) /
          fcfsWaitTime *
          100)
      .toStringAsFixed(2);

  // 添加数据到CSV - 基本性能测试结果
  final basicPerformanceData = [
    // FCFS 算法结果
    {
      "Algorithm": "FCFS",
      "Metrics": {
        "Average Wait Time (sec)": fcfsResults[0],
        "Average Turnaround Time (sec)": fcfsResults[1],
        "Throughput (orders/min)": fcfsResults[2],
      },
    },
    // SJF 算法结果
    {
      "Algorithm": "SJF",
      "Metrics": {
        "Average Wait Time (sec)": sjfResults[0],
        "Average Turnaround Time (sec)": sjfResults[1],
        "Throughput (orders/min)": sjfResults[2],
      },
    },
    // Priority 算法结果
    {
      "Algorithm": "Priority",
      "Metrics": {
        "Average Wait Time (sec)": priorityResults[0],
        "Average Turnaround Time (sec)": priorityResults[1],
        "Throughput (orders/min)": priorityResults[2],
      },
    },
  ];

  // 将结构化数据转换为CSV格式
  for (var algorithmData in basicPerformanceData) {
    final algorithm = algorithmData["Algorithm"];
    final metrics = algorithmData["Metrics"] as Map<String, String>;

    metrics.forEach((metric, value) {
      data.add(["Basic Performance", algorithm, metric, value]);
    });
  }

  // 添加算法比较数据
  data.addAll([
    [
      "Basic Performance",
      "SJF vs FCFS",
      "Wait Time Improvement (%)",
      sjfVsFcfsWaitImprovement,
    ],
    [
      "Basic Performance",
      "Priority vs FCFS",
      "Wait Time Improvement (%)",
      priorityVsFcfsWaitImprovement,
    ],
  ]);

  // 打印结果表格
  print(
    "Algorithm | Avg Wait Time (sec) | Avg Turnaround Time (sec) | Throughput (orders/min)",
  );
  print(
    "----------|-------------------|------------------------|--------------------",
  );
  print(
    "FCFS     | ${fcfsResults[0]}          | ${fcfsResults[1]}         | ${fcfsResults[2]}",
  );
  print(
    "SJF      | ${sjfResults[0]}          | ${sjfResults[1]}         | ${sjfResults[2]}",
  );
  print(
    "Priority | ${priorityResults[0]}          | ${priorityResults[1]}         | ${priorityResults[2]}",
  );

  print("\nImprovement Percentages:");
  print(
    "- SJF reduced average wait time by $sjfVsFcfsWaitImprovement% compared to FCFS",
  );
  print(
    "- Priority reduced average wait time by $priorityVsFcfsWaitImprovement% compared to FCFS",
  );
  print("");
}

Future<void> runStarvationTest(List<List<dynamic>> data) async {
  print("2. Starvation Test");
  print("----------------");
  print(
    "Scenario: 1 large order followed by 20 small orders (gradually decreasing order flow)\n",
  );

  final DateTime simulationStart = DateTime.now();
  final List<Order> testOrders = [];

  // 添加1个大订单（长准备时间）
  testOrders.add(
    Order(
      id: "large_order",
      createdAt: simulationStart,
      items: List.generate(
        5,
        (i) => OrderItem(
          item: FoodItem(preparationTime: 15.0), // 长准备时间
        ),
      ),
    ),
  );

  // 添加20个小订单（短准备时间）
  for (int i = 0; i < 20; i++) {
    final arrivalTime =
        i < 10
            ? Duration(seconds: (i + 1) * 10)
            : Duration(seconds: 100 + (i - 10) * 30);

    testOrders.add(
      Order(
        id: "small_order_$i",
        createdAt: simulationStart.add(arrivalTime),
        items: List.generate(
          1,
          (j) => OrderItem(
            item: FoodItem(preparationTime: 3.0), // 短准备时间
          ),
        ),
      ),
    );
  }

  // 测试每个算法
  final fcfsResults = testOrderStarvation(
    "FCFS",
    FCFSOrderSorter.sortOrders,
    testOrders,
    simulationStart,
  );
  final sjfResults = testOrderStarvation(
    "SJF",
    SJFOrderSorter.sortOrders,
    testOrders,
    simulationStart,
  );
  final priorityResults = testOrderStarvation(
    "Priority",
    PriorityOrderSorter.sortOrders,
    testOrders,
    simulationStart,
  );

  // 添加数据到CSV
  data.addAll([
    ["Starvation Test", "FCFS", "Large Order Wait Time (sec)", fcfsResults[0]],
    ["Starvation Test", "FCFS", "Large Order Position", fcfsResults[2]],
    ["Starvation Test", "SJF", "Large Order Wait Time (sec)", sjfResults[0]],
    ["Starvation Test", "SJF", "Large Order Position", sjfResults[2]],
    [
      "Starvation Test",
      "Priority",
      "Large Order Wait Time (sec)",
      priorityResults[0],
    ],
    ["Starvation Test", "Priority", "Large Order Position", priorityResults[2]],
  ]);

  // 打印结果表格
  print(
    "Algorithm | Large Order Wait Time (sec) | Order Position | Wait Time Increase vs FCFS",
  );
  print(
    "----------|--------------------------|---------------|----------------------",
  );
  print(
    "FCFS     | ${fcfsResults[0]}             | ${fcfsResults[2]}          | 0.00%",
  );
  print(
    "SJF      | ${sjfResults[0]}             | ${sjfResults[2]}          | ${((double.parse(sjfResults[0]) - double.parse(fcfsResults[0])) / double.parse(fcfsResults[0]) * 100).toStringAsFixed(2)}%",
  );
  print(
    "Priority | ${priorityResults[0]}             | ${priorityResults[2]}          | ${((double.parse(priorityResults[0]) - double.parse(fcfsResults[0])) / double.parse(fcfsResults[0]) * 100).toStringAsFixed(2)}%",
  );
  print("");
}

Future<void> runFairnessTest(List<List<dynamic>> data) async {
  print("3. Fairness Test");
  print("-----------");
  print("Scenario: Processing Mixed-Size Orders\n");

  final random = Random(42); // Use fixed seed for reproducible results
  final DateTime simulationStart = DateTime.now();
  final List<Order> testOrders = [];

  // 生成30个混合大小的订单
  for (int i = 0; i < 30; i++) {
    final bool isLargeOrder = i % 3 == 0; // 每第3个订单是大订单
    final int itemCount = isLargeOrder ? 5 : 1;
    final double prepTime = isLargeOrder ? 15.0 : 3.0;

    testOrders.add(
      Order(
        id: isLargeOrder ? "large_$i" : "small_$i",
        createdAt: simulationStart.add(Duration(seconds: i * 20)), // 每20秒一个订单
        items: List.generate(
          itemCount,
          (j) => OrderItem(item: FoodItem(preparationTime: prepTime)),
        ),
      ),
    );
  }

  // 测试每个算法
  final fcfsResults = testOrderFairness(
    "FCFS",
    FCFSOrderSorter.sortOrders,
    testOrders,
    simulationStart,
  );
  final sjfResults = testOrderFairness(
    "SJF",
    SJFOrderSorter.sortOrders,
    testOrders,
    simulationStart,
  );
  final priorityResults = testOrderFairness(
    "Priority",
    PriorityOrderSorter.sortOrders,
    testOrders,
    simulationStart,
  );

  // 添加数据到CSV
  data.addAll([
    [
      "Fairness Test",
      "FCFS",
      "Small Orders Avg Wait Time (sec)",
      fcfsResults[0],
    ],
    [
      "Fairness Test",
      "FCFS",
      "Large Orders Avg Wait Time (sec)",
      fcfsResults[1],
    ],
    ["Fairness Test", "FCFS", "Wait Time Ratio", fcfsResults[2]],
    ["Fairness Test", "FCFS", "Fairness Index (0-100)", fcfsResults[3]],
    ["Fairness Test", "SJF", "Small Orders Avg Wait Time (sec)", sjfResults[0]],
    ["Fairness Test", "SJF", "Large Orders Avg Wait Time (sec)", sjfResults[1]],
    ["Fairness Test", "SJF", "Wait Time Ratio", sjfResults[2]],
    ["Fairness Test", "SJF", "Fairness Index (0-100)", sjfResults[3]],
    [
      "Fairness Test",
      "Priority",
      "Small Orders Avg Wait Time (sec)",
      priorityResults[0],
    ],
    [
      "Fairness Test",
      "Priority",
      "Large Orders Avg Wait Time (sec)",
      priorityResults[1],
    ],
    ["Fairness Test", "Priority", "Wait Time Ratio", priorityResults[2]],
    ["Fairness Test", "Priority", "Fairness Index (0-100)", priorityResults[3]],
  ]);

  // Print results table
  print(
    "Algorithm | Small Orders Wait (sec) | Large Orders Wait (sec) | Wait Time Ratio | Fairness Index (0-100)",
  );
  print(
    "----------|---------------------|---------------------|----------------|-------------------",
  );
  print(
    "FCFS      | ${fcfsResults[0]}               | ${fcfsResults[1]}               | ${fcfsResults[2]}            | ${fcfsResults[3]}",
  );
  print(
    "SJF       | ${sjfResults[0]}               | ${sjfResults[1]}               | ${sjfResults[2]}            | ${sjfResults[3]}",
  );
  print(
    "Priority  | ${priorityResults[0]}               | ${priorityResults[1]}               | ${priorityResults[2]}            | ${priorityResults[3]}",
  );
  print("");
}

List<String> runPerformanceTest(
  String algorithmName,
  List<Order> Function(List<Order>) sorter,
  List<Order> originalOrders,
  DateTime simulationStart,
) {
  final orders = sorter(List<Order>.from(originalOrders));
  DateTime currentTime = simulationStart;

  double totalWaitingTime = 0.0;
  double totalTurnaroundTime = 0.0;

  for (var order in orders) {
    final waitingTime =
        currentTime.difference(order.createdAt).inSeconds.toDouble();
    final prepTime = order.totalPreparationTime;

    final completeTime = currentTime.add(Duration(seconds: prepTime.round()));

    totalWaitingTime += waitingTime;
    totalTurnaroundTime += completeTime.difference(order.createdAt).inSeconds;

    currentTime = currentTime.add(Duration(seconds: prepTime.round()));
  }

  final avgWaitingTime = totalWaitingTime / orders.length;
  final avgTurnaroundTime = totalTurnaroundTime / orders.length;

  final simulationDurationMinutes =
      currentTime.difference(simulationStart).inMinutes;
  final throughput =
      simulationDurationMinutes > 0
          ? orders.length / simulationDurationMinutes
          : orders.length;

  return [
    avgWaitingTime.toStringAsFixed(2),
    avgTurnaroundTime.toStringAsFixed(2),
    throughput.toStringAsFixed(2),
  ];
}

List<String> testOrderStarvation(
  String algorithmName,
  List<Order> Function(List<Order>) sorter,
  List<Order> originalOrders,
  DateTime simulationStart,
) {
  final orders = sorter(List<Order>.from(originalOrders));
  DateTime currentTime = simulationStart;

  // 在排序列表中找到大订单的位置
  int largeOrderPosition = -1;
  for (int i = 0; i < orders.length; i++) {
    if (orders[i].id == "large_order") {
      largeOrderPosition = i + 1; // 位置从1开始
      break;
    }
  }

  double largeOrderWaitTime = 0;
  double largeOrderCompletionTime = 0;

  for (int i = 0; i < orders.length; i++) {
    final order = orders[i];
    final waitingTime =
        currentTime.difference(order.createdAt).inSeconds.toDouble();
    final prepTime = order.totalPreparationTime;

    if (order.id == "large_order") {
      largeOrderWaitTime = waitingTime;
      largeOrderCompletionTime = waitingTime + prepTime;
    }

    currentTime = currentTime.add(Duration(seconds: prepTime.round()));
  }

  return [
    largeOrderWaitTime.toStringAsFixed(2),
    largeOrderCompletionTime.toStringAsFixed(2),
    largeOrderPosition.toString(),
  ];
}

List<String> testOrderFairness(
  String algorithmName,
  List<Order> Function(List<Order>) sorter,
  List<Order> originalOrders,
  DateTime simulationStart,
) {
  final orders = sorter(List<Order>.from(originalOrders));
  DateTime currentTime = simulationStart;

  double smallOrdersTotalWait = 0;
  int smallOrdersCount = 0;
  double largeOrdersTotalWait = 0;
  int largeOrdersCount = 0;

  for (final order in orders) {
    final waitingTime =
        currentTime.difference(order.createdAt).inSeconds.toDouble();
    final prepTime = order.totalPreparationTime;

    if (order.id.startsWith("small_")) {
      smallOrdersTotalWait += waitingTime;
      smallOrdersCount++;
    } else if (order.id.startsWith("large_")) {
      largeOrdersTotalWait += waitingTime;
      largeOrdersCount++;
    }

    currentTime = currentTime.add(Duration(seconds: prepTime.round()));
  }

  final smallOrdersAvgWait =
      smallOrdersCount > 0 ? smallOrdersTotalWait / smallOrdersCount : 0;
  final largeOrdersAvgWait =
      largeOrdersCount > 0 ? largeOrdersTotalWait / largeOrdersCount : 0;

  // 计算等待时间比率（大/小）
  final waitTimeRatio =
      smallOrdersAvgWait > 0 ? largeOrdersAvgWait / smallOrdersAvgWait : 0;

  // 计算公平性指数 (0-100)
  double fairnessIndex = 100;
  if (waitTimeRatio > 1) {
    // 大订单等待时间比小订单长
    fairnessIndex -= (waitTimeRatio - 1) * 20; // 每倍数减20分
  }
  fairnessIndex = fairnessIndex.clamp(0, 100);

  return [
    smallOrdersAvgWait.toStringAsFixed(2),
    largeOrdersAvgWait.toStringAsFixed(2),
    waitTimeRatio.toStringAsFixed(2),
    fairnessIndex.toStringAsFixed(2),
  ];
}
