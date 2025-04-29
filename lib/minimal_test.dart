import 'dart:math';
import 'models/test_order.dart';
import 'models/food_item.dart';
import 'models/order_item.dart';
import 'utils/test_fcfs.dart';

void main() {
  print("=== 最小化算法性能测试 ===");
  
  final random = Random();
  final int numberOfOrders = 10;
  final DateTime simulationStart = DateTime.now();

  // 生成测试订单
  print("生成 $numberOfOrders 个随机测试订单...");
  final List<Order> testOrders = [];
  
  for (int i = 0; i < numberOfOrders; i++) {
    final createdAt = simulationStart.add(Duration(seconds: random.nextInt(300)));
    final items = <OrderItem>[];
    
    final itemCount = random.nextInt(3) + 1;
    for (int j = 0; j < itemCount; j++) {
      items.add(OrderItem(
        item: FoodItem(preparationTime: random.nextDouble() * 10 + 1),
      ));
    }
    
    testOrders.add(Order(
      id: i.toString(),
      createdAt: createdAt,
      items: items,
    ));
  }
  
  print("测试订单生成完成。");

  // 运行FCFS算法测试
  print("测试FCFS算法...");
  final sortedOrders = FCFSOrderSorter.sortOrders(testOrders);
  DateTime currentTime = simulationStart;

  double totalWaitingTime = 0.0;
  double totalTurnaroundTime = 0.0;

  for (var order in sortedOrders) {
    final waitingTime = currentTime.difference(order.createdAt).inSeconds.toDouble();
    final prepTime = order.totalPreparationTime;

    final completeTime = currentTime.add(Duration(seconds: prepTime.round()));

    totalWaitingTime += waitingTime;
    totalTurnaroundTime += completeTime.difference(order.createdAt).inSeconds;

    currentTime = completeTime;
  }

  final avgWaitingTime = totalWaitingTime / sortedOrders.length;
  final avgTurnaroundTime = totalTurnaroundTime / sortedOrders.length;
  
  final simulationDurationMinutes = currentTime.difference(simulationStart).inMinutes;
  final throughput = simulationDurationMinutes > 0 
      ? sortedOrders.length / simulationDurationMinutes 
      : sortedOrders.length;

  print("平均等待时间: ${avgWaitingTime.toStringAsFixed(2)} 秒");
  print("平均周转时间: ${avgTurnaroundTime.toStringAsFixed(2)} 秒");
  print("吞吐量: ${throughput.toStringAsFixed(2)} 订单/分钟");
  
  print("测试完成！");
}
