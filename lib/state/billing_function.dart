import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Local enum for bill filtering since external types are not available here
enum BillFilterType { all, unpaid, paid }

// Minimal stub for FirebaseService to satisfy references in this file
class FirebaseService {
  Future<List<Map<String, dynamic>>> getParentBills(String parentId) async {
    return [];
  }

  Future<String?> getParentId() async {
    return null;
  }

  Future<void> updateBillPaymentStatus(
    String billNumber,
    String status, {
    String? paymentDate,
  }) async {}

  Future<void> updateMultipleBillsPaymentStatus(
    List<String> billNumbers,
    String status,
  ) async {}
}

class BillingFunctions {
  final FirebaseService _firebaseService = FirebaseService();
  final _billsUpdateController = StreamController<void>.broadcast();
  Stream<void> get onBillsUpdate => _billsUpdateController.stream;

  void dispose() {
    _billsUpdateController.close();
  }

  // Get parent's children data
  Future<List<Map<String, dynamic>>> getParentChildren(String parentId) async {
    try {
      final parentDoc =
          await FirebaseFirestore.instance
              .collection('parents')
              .doc(parentId)
              .get();

      if (!parentDoc.exists) return [];

      final parentData = parentDoc.data();
      final studentIds = parentData?['student_id'] as List<dynamic>? ?? [];

      List<Map<String, dynamic>> children = [];

      for (String studentId in studentIds) {
        final studentDoc =
            await FirebaseFirestore.instance
                .collection('students')
                .doc(studentId)
                .get();

        if (studentDoc.exists) {
          final studentData = studentDoc.data()!;
          children.add({
            'id': studentId,
            'name': studentData['name'] ?? 'Unknown',
            'class_id': studentData['class_id'] ?? '',
            'age': studentData['age'] ?? '',
          });
        }
      }

      return children;
    } catch (e) {
      log('Error getting parent children: $e');
      return [];
    }
  }

  // Get bills for a specific student
  Future<List<Map<String, dynamic>>> getStudentBills(String studentId) async {
    try {
      // Try to query by studentId first
      QuerySnapshot billsQuery =
          await FirebaseFirestore.instance
              .collection('bills')
              .where('studentId', isEqualTo: studentId)
              .get();

      // If no results, try alternative field names
      if (billsQuery.docs.isEmpty) {
        billsQuery =
            await FirebaseFirestore.instance
                .collection('bills')
                .where('student_id', isEqualTo: studentId)
                .get();
      }

      // If no bills found, return empty list (don't fall back to all bills)
      if (billsQuery.docs.isEmpty) {
        return [];
      }

      return billsQuery.docs
          .map((doc) => {'id': doc.id, ...(doc.data() as Map<String, dynamic>)})
          .toList();
    } catch (e) {
      log('Error getting student bills: $e');
      return [];
    }
  }

  // Get all bills for parent's children
  Future<List<Map<String, dynamic>>> getParentBills(String parentId) async {
    try {
      final children = await getParentChildren(parentId);

      List<Map<String, dynamic>> allBills = [];

      // First try to get bills by individual children
      for (var child in children) {
        final childBills = await getStudentBills(child['id']);

        // Add child information to each bill
        for (var bill in childBills) {
          bill['childName'] = child['name'];
          bill['childId'] = child['id'];
          bill['childClass'] = child['class_id'];
        }
        allBills.addAll(childBills);
      }

      // If no bills found by children, try to get bills by parentId
      if (allBills.isEmpty) {
        final parentBills = await _firebaseService.getParentBills(parentId);

        // Add child information to these bills if possible
        for (var bill in parentBills) {
          // Try to find which child this bill belongs to
          for (var child in children) {
            if (bill['studentId'] == child['id'] ||
                bill['student_id'] == child['id'] ||
                bill['studentName'] == child['name']) {
              bill['childName'] = child['name'];
              bill['childId'] = child['id'];
              bill['childClass'] = child['class_id'];
              break;
            }
          }
        }
        allBills.addAll(parentBills);
      }

      return allBills;
    } catch (e) {
      log('Error getting parent bills: $e');
      return [];
    }
  }

  // Get bills for a specific child
  Future<List<Map<String, dynamic>>> getChildBills(
    String parentId,
    String childId,
  ) async {
    try {
      // If childId is 'all_children', return all parent bills
      if (childId == 'all_children') {
        return await getParentBills(parentId);
      }

      final childBills = await getStudentBills(childId);

      final children = await getParentChildren(parentId);
      final child = children.firstWhere(
        (c) => c['id'] == childId,
        orElse: () => {'name': 'Unknown', 'class_id': ''},
      );

      // Add child information to each bill
      for (var bill in childBills) {
        bill['childName'] = child['name'];
        bill['childId'] = childId;
        bill['childClass'] = child['class_id'];
      }

      return childBills;
    } catch (e) {
      log('Error getting child bills: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> makeIntentForPayment(
    double amount,
    String currency,
  ) async {
    try {
      int amountInCents = (amount * 100).toInt();
      Map<String, String> paymentInfo = {
        "amount": amountInCents.toString(),
        "currency": currency,
      };

      var request = http.Request(
        'POST',
        Uri.parse("https://api.stripe.com/v1/payment_intents"),
      );
      request.headers.addAll({
        "Authorization": "Bearer ${dotenv.env['STRIPE_SECRET_KEY']}",
        "Content-Type": "application/x-www-form-urlencoded",
      });

      request.bodyFields = paymentInfo;
      request.bodyFields["payment_method_types[]"] = "card";
      request.bodyFields.addAll({"payment_method_types[]": "fpx"});
      request.bodyFields.addAll({"payment_method_types[]": "grabpay"});

      if (kDebugMode) {
        print("Creating payment intent with methods: card, fpx, grabpay");
        print(
          "Amount: $currency ${amount.toStringAsFixed(2)} (${amountInCents.toString()} cents)",
        );
      }

      var streamedResponse = await request.send();
      var responseFromStripeAPI = await http.Response.fromStream(
        streamedResponse,
      );

      if (kDebugMode) {
        print("Response status code: ${responseFromStripeAPI.statusCode}");
        print("Response body: ${responseFromStripeAPI.body}");
      }

      if (responseFromStripeAPI.statusCode == 200) {
        return jsonDecode(responseFromStripeAPI.body);
      } else {
        log("Error creating payment intent: ${responseFromStripeAPI.body}");
        return null;
      }
    } catch (errorMsg) {
      if (kDebugMode) {
        print("Exception in makeIntentForPayment: $errorMsg");
      }
      log(errorMsg.toString());
      return null;
    }
  }

  Future<int> calculateDaysRemaining(String? dueDateStr) async {
    try {
      if (dueDateStr == null || dueDateStr.isEmpty) {
        return 0;
      }

      final parts = dueDateStr.split('-');
      if (parts.length >= 3) {
        final dueDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );

        final today = DateTime.now();
        final difference = dueDate.difference(today).inDays;
        return difference;
      }
      return 0;
    } catch (e) {
      log("Error calculating days remaining: $e");
      return 0;
    }
  }

  Future<String?> getParentId() async {
    return await _firebaseService.getParentId();
  }

  Future<void> updateBillPaymentStatus(String billNumber, String status) async {
    await _firebaseService.updateBillPaymentStatus(billNumber, status);
  }

  Future<void> paymentSheetInitialization(
    BuildContext context,
    double totalAmount,
    String currency,
    Map<String, dynamic>? intentPaymentData,
    Function(Map<String, dynamic>?) setIntentPaymentData,
    Future<void> Function() showPaymentSheet,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final paymentIntentData = await makeIntentForPayment(
        totalAmount,
        currency,
      );

      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (paymentIntentData == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Payment setup failed. Please try again."),
            ),
          );
        }
        return;
      }

      setIntentPaymentData(paymentIntentData);

      try {
        await stripe.Stripe.instance.initPaymentSheet(
          paymentSheetParameters: stripe.SetupPaymentSheetParameters(
            allowsDelayedPaymentMethods: true,
            paymentIntentClientSecret: paymentIntentData['client_secret'],
            style: ThemeMode.dark,
            merchantDisplayName: 'Kinder App',
            billingDetails: const stripe.BillingDetails(
              address: stripe.Address(
                country: 'MY',
                city: 'Kuala Lumpur',
                postalCode: '50000',
                state: 'Wilayah Persekutuan',
                line1: '123 Main Street',
                line2: 'Apartment 4B',
              ),
            ),
          ),
        );

        await showPaymentSheet();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Payment setup error: ${e.toString()}")),
          );
        }
      }
    } catch (errorMsg) {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Payment setup failed: ${errorMsg.toString()}"),
          ),
        );
      }
    }
  }

  Future<void> showPaymentSheet(
    BuildContext context,
    Map<String, dynamic>? selectedBill,
    List<Map<String, dynamic>> bills,
    Function() fetchParentIdAndBills,
  ) async {
    try {
      await stripe.Stripe.instance.presentPaymentSheet();

      if (context.mounted) {
        final currentBill =
            selectedBill ??
            bills.firstWhere(
              (bill) => bill['paymentStatus'] != 'paid',
              orElse: () => bills.first,
            );

        final String? billNumber = currentBill['billNumber'] as String?;
        if (billNumber == null) {
          throw Exception("No valid bill number found");
        }

        // Get current date in YYYY-MM-DD format
        final now = DateTime.now();
        final paymentDate =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        // Update bill with payment status and payment date
        await _firebaseService.updateBillPaymentStatus(
          billNumber,
          'paid',
          paymentDate: paymentDate,
        );
        _billsUpdateController.add(null);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment completed successfully!")),
          );
        }

        await fetchParentIdAndBills();
      }
    } on stripe.StripeException catch (e) {
      if (!context.mounted) return;

      if (e.error.code != stripe.FailureCode.Canceled) {
        showDialog(
          context: context,
          builder:
              (c) => AlertDialog(
                content: Text(e.error.localizedMessage ?? "Payment failed"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment failed: ${e.toString()}")),
        );
      }
    }
  }

  // New method for multi-bill payments
  Future<void> showMultiBillPaymentSheet(
    BuildContext context,
    List<Map<String, dynamic>> selectedBills,
    Function() fetchParentIdAndBills,
  ) async {
    try {
      await stripe.Stripe.instance.presentPaymentSheet();

      if (context.mounted) {
        // Extract bill numbers from selected bills
        List<String> billNumbers =
            selectedBills
                .map((bill) => bill['billNumber'] as String?)
                .where((billNumber) => billNumber != null)
                .cast<String>()
                .toList();

        if (billNumbers.isEmpty) {
          throw Exception("No valid bill numbers found");
        }

        // Update all selected bills with payment status
        await _firebaseService.updateMultipleBillsPaymentStatus(
          billNumbers,
          'paid',
        );

        _billsUpdateController.add(null);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Payment completed successfully for ${billNumbers.length} bill${billNumbers.length > 1 ? 's' : ''}!",
              ),
            ),
          );
        }

        await fetchParentIdAndBills();
      }
    } on stripe.StripeException catch (e) {
      if (!context.mounted) return;

      if (e.error.code != stripe.FailureCode.Canceled) {
        showDialog(
          context: context,
          builder:
              (c) => AlertDialog(
                content: Text(e.error.localizedMessage ?? "Payment failed"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment failed: ${e.toString()}")),
        );
      }
    }
  }

  List<Map<String, dynamic>> filterBills(
    List<Map<String, dynamic>> allBills,
    BillFilterType filterType,
  ) {
    switch (filterType) {
      case BillFilterType.all:
        return List.from(allBills);
      case BillFilterType.unpaid:
        return allBills
            .where((bill) => bill['paymentStatus'] != 'paid')
            .toList();
      case BillFilterType.paid:
        return allBills
            .where((bill) => bill['paymentStatus'] == 'paid')
            .toList();
    }
  }
}
