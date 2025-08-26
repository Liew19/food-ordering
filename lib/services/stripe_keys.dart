import 'package:flutter_dotenv/flutter_dotenv.dart';

String get publishableKey => dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
String get secretKey => dotenv.env['STRIPE_SECRET_KEY'] ?? '';
