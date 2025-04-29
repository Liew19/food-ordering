# Algorithm Testing Utility

This utility allows you to test and compare different order scheduling algorithms in your food ordering application.

## Features

- Test multiple scheduling algorithms (FCFS, SJF, Priority) with the same dataset
- Generate random test orders with configurable parameters
- Calculate key performance metrics:
  - Average waiting time
  - Average turnaround time
  - Throughput (orders per minute)
- Export results to CSV for further analysis

## How to Use

### Basic Usage

```dart
import 'utils/algorithm_tester.dart';

void main() async {
  // Run tests with default parameters
  final filePath = await AlgorithmTester.runAllTests();
  
  print("Results saved to: $filePath");
}
```

### Custom Parameters

```dart
import 'utils/algorithm_tester.dart';

void main() async {
  // Run tests with custom parameters
  final filePath = await AlgorithmTester.runAllTests(
    numberOfOrders: 200,        // Number of test orders to generate
    maxItems: 5,                // Maximum items per order
    maxPrepTime: 15.0,          // Maximum preparation time per item
    maxRandomTimeSeconds: 600,  // Maximum time window for order creation
  );
  
  print("Results saved to: $filePath");
}
```

### Running the Test

1. Make sure you have the `path_provider` package installed (add it to pubspec.yaml)
2. Run the test script:
   ```
   flutter run -d chrome lib/test_algorithms.dart
   ```
   or
   ```
   dart lib/test_algorithms.dart
   ```

3. Check the console for results and the file path of the exported CSV

## Understanding the Results

- **Average Waiting Time**: The average time orders wait before processing begins
- **Average Turnaround Time**: The average time from order creation to completion
- **Throughput**: The number of orders processed per minute

Lower waiting and turnaround times are better, while higher throughput is better.

## Algorithms Included

1. **FCFS (First Come First Serve)**: Orders are processed in the order they arrive
2. **SJF (Shortest Job First)**: Orders with the shortest preparation time are processed first
3. **Priority**: Orders are prioritized based on a combination of preparation time and waiting time

## Extending the Utility

You can add your own algorithms by:

1. Creating a new sorter class with a static `sortOrders` method
2. Adding your algorithm to the test in `algorithm_tester.dart`
