import 'dart:math';
import '../models/test_order.dart';
import '../models/food_item.dart';
import '../models/order_item.dart';
import 'csv_exporter.dart';
import 'test_fcfs.dart';
import 'test_sjf.dart';
import 'priority_sorter.dart';

/// Utility class for testing and comparing different order scheduling algorithms
class AlgorithmTester {
  /// Run performance tests on all algorithms and export results to CSV
  static Future<String> runAllTests({
    int numberOfOrders = 100,
    int maxItems = 3,
    double maxPrepTime = 10.0,
    int maxRandomTimeSeconds = 300,
  }) async {
    final random = Random();
    final DateTime simulationStart = DateTime.now();

    // Generate test orders
    final List<Order> testOrders = List.generate(numberOfOrders, (index) {
      final createdAt = simulationStart.add(Duration(seconds: random.nextInt(maxRandomTimeSeconds)));
      final items = List.generate(
        random.nextInt(maxItems) + 1,
        (i) => OrderItem(
          item: FoodItem(preparationTime: random.nextDouble() * maxPrepTime + 1),
        ),
      );
      return Order(
        id: index.toString(),
        createdAt: createdAt,
        items: items,
      );
    });

    // Prepare CSV data
    final List<List<dynamic>> csvData = [
      ["Algorithm", "Average Waiting Time (s)", "Average Turnaround Time (s)", "Throughput (orders/min)"]
    ];

    // Run tests for each algorithm
    csvData.add(runPerformanceTest("FCFS", FCFSOrderSorter.sortOrders, testOrders, simulationStart));
    csvData.add(runPerformanceTest("SJF", SJFOrderSorter.sortOrders, testOrders, simulationStart));
    csvData.add(runPerformanceTest("Priority", PriorityOrderSorter.sortOrders, testOrders, simulationStart));

    // Export results to CSV
    final filePath = await CSVExporter.exportResults(csvData, 'algorithm_performance_results.csv');
    return filePath;
  }

  /// Run a performance test for a specific algorithm
  static List<dynamic> runPerformanceTest(
    String algorithmName,
    List<Order> Function(List<Order>) sorter,
    List<Order> originalOrders,
    DateTime simulationStart,
  ) {
    // Create a deep copy of the orders to avoid modifying the original
    final orders = sorter(List<Order>.from(originalOrders));
    DateTime currentTime = simulationStart;

    double totalWaitingTime = 0.0;
    double totalTurnaroundTime = 0.0;

    // Process each order and calculate metrics
    for (var order in orders) {
      // Waiting time is the time from order creation to start of processing
      final waitingTime = currentTime.difference(order.createdAt).inSeconds.toDouble();
      
      // Preparation time for the order
      final prepTime = order.totalPreparationTime;

      // Calculate completion time
      final completeTime = currentTime.add(Duration(seconds: prepTime.round()));

      // Add to totals
      totalWaitingTime += waitingTime;
      totalTurnaroundTime += completeTime.difference(order.createdAt).inSeconds;

      // Update current time to when this order is completed
      currentTime = completeTime;
    }

    // Calculate averages and throughput
    final avgWaitingTime = totalWaitingTime / orders.length;
    final avgTurnaroundTime = totalTurnaroundTime / orders.length;
    
    // Calculate throughput (orders per minute)
    final simulationDurationMinutes = currentTime.difference(simulationStart).inMinutes;
    final throughput = simulationDurationMinutes > 0 
        ? orders.length / simulationDurationMinutes 
        : orders.length; // Handle case where simulation is very short

    // Print results
    print("\n=== [$algorithmName] Performance ===");
    print("Average Waiting Time: ${avgWaitingTime.toStringAsFixed(2)} seconds");
    print("Average Turnaround Time: ${avgTurnaroundTime.toStringAsFixed(2)} seconds");
    print("Throughput: ${throughput.toStringAsFixed(2)} orders per minute");

    // Return row for CSV
    return [
      algorithmName,
      avgWaitingTime.toStringAsFixed(2),
      avgTurnaroundTime.toStringAsFixed(2),
      throughput.toStringAsFixed(2),
    ];
  }
}
