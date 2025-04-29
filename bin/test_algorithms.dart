import 'dart:io';
import '../lib/utils/algorithm_tester.dart';

void main() async {
  print("Starting algorithm performance tests...");
  
  // Run all tests with default parameters
  final filePath = await AlgorithmTester.runAllTests();
  
  if (filePath.isNotEmpty) {
    print("\nTests completed successfully!");
    print("Results saved to: $filePath");
    
    // Open the file to show the results
    try {
      final file = File(filePath);
      final contents = await file.readAsString();
      print("\nResults:\n");
      print(contents);
    } catch (e) {
      print("Error reading results file: $e");
    }
  } else {
    print("\nError: Failed to save test results.");
  }
  
  print("\nYou can also run tests with custom parameters by modifying the AlgorithmTester.runAllTests call.");
}
