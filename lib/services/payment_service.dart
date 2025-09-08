import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  // Validate API keys
  bool _validateApiKeys() {
    final publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
    final secretKey = dotenv.env['STRIPE_SECRET_KEY'] ?? '';

    if (publishableKey.isEmpty || secretKey.isEmpty) {
      return false;
    }

    if (!publishableKey.startsWith('pk_')) {
      return false;
    }

    if (!secretKey.startsWith('sk_')) {
      return false;
    }

    // Check for placeholder values
    if (publishableKey.contains('YOUR_') || secretKey.contains('your_')) {
      return false;
    }

    return true;
  }

  Future<Map<String, dynamic>?> createPaymentIntent({
    required double amount,
    required String currency,
    List<String> paymentMethods = const ['card'],
  }) async {
    try {
      // Validate API keys first
      if (!_validateApiKeys()) {
        throw Exception(
          'Invalid or missing Stripe API keys. Please check your env.txt file.',
        );
      }

      final secretKey = dotenv.env['STRIPE_SECRET_KEY']!;
      final amountInCents = (amount * 100).round();

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amountInCents.toString(),
          'currency': currency.toLowerCase(),
          'metadata[app]': 'food_ordering_app',
          ...{
            for (int i = 0; i < paymentMethods.length; i++)
              'payment_method_types[$i]': paymentMethods[i],
          },
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']['message'] ?? 'Unknown error';
        final errorType = errorData['error']['type'] ?? 'unknown';

        // Provide user-friendly error messages
        String userMessage = _getUserFriendlyErrorMessage(
          errorType,
          errorMessage,
        );
        throw Exception(userMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  String _getUserFriendlyErrorMessage(String errorType, String errorMessage) {
    switch (errorType) {
      case 'invalid_request_error':
        if (errorMessage.contains('API Key')) {
          return 'Payment system configuration error. Please contact support.';
        }
        return 'Invalid payment request. Please try again.';
      case 'authentication_error':
        return 'Payment authentication failed. Please contact support.';
      case 'card_error':
        return 'Card payment failed: $errorMessage';
      case 'rate_limit_error':
        return 'Too many payment requests. Please wait a moment and try again.';
      default:
        return 'Payment processing error. Please try again or contact support.';
    }
  }

  Future<void> initializePaymentSheet({
    required Map<String, dynamic> paymentIntentData,
    required String merchantDisplayName,
  }) async {
    try {
      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['client_secret'],
          merchantDisplayName: merchantDisplayName,
          style: ThemeMode.system,
          billingDetails: const stripe.BillingDetails(
            address: stripe.Address(
              country: 'MY',
              city: 'Kuala Lumpur',
              postalCode: '50000',
              state: 'Wilayah Persekutuan',
              line1: '123 Main Street',
              line2: '',
            ),
          ),
        ),
      );
    } catch (e) {
      throw Exception('Payment setup failed: ${e.toString()}');
    }
  }

  Future<bool> presentPaymentSheet() async {
    try {
      await stripe.Stripe.instance.presentPaymentSheet();
      return true;
    } on stripe.StripeException catch (e) {
      if (e.error.code == stripe.FailureCode.Canceled) {
        return false;
      } else {
        throw Exception(e.error.localizedMessage ?? 'Payment failed');
      }
    } catch (e) {
      throw Exception('Payment processing error: ${e.toString()}');
    }
  }

  // Test connection to Stripe API
  Future<bool> testConnection() async {
    try {
      if (!_validateApiKeys()) {
        return false;
      }

      final secretKey = dotenv.env['STRIPE_SECRET_KEY']!;
      final response = await http.get(
        Uri.parse('https://api.stripe.com/v1/payment_methods'),
        headers: {'Authorization': 'Bearer $secretKey'},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Validate payment amount
  bool validateAmount(double amount) {
    // Minimum amount for MYR is 0.50
    if (amount < 0.50) {
      return false;
    }

    // Maximum amount (reasonable limit)
    if (amount > 10000.00) {
      return false;
    }

    return true;
  }

  // Get supported payment methods for Malaysia
  List<String> getSupportedPaymentMethods() {
    return ['card']; // Start with card only, add others after testing
  }

  // Format currency for display
  String formatCurrency(double amount, String currency) {
    switch (currency.toUpperCase()) {
      case 'MYR':
        return 'RM ${amount.toStringAsFixed(2)}';
      case 'USD':
        return '\$${amount.toStringAsFixed(2)}';
      default:
        return '${currency.toUpperCase()} ${amount.toStringAsFixed(2)}';
    }
  }
}
