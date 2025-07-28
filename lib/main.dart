import 'package:flutter/material.dart';
import 'package:fyp/screens/cart_screen.dart';
import 'package:fyp/screens/home_screen.dart';
import 'package:fyp/screens/kitchen_screen.dart';
import 'package:fyp/screens/login_screen.dart';
import 'package:fyp/screens/order_status_screen.dart';
import 'package:fyp/screens/profile_screen.dart';
import 'package:fyp/screens/staff_screen.dart';
import 'package:fyp/screens/table_reservation_screen.dart';
import 'package:fyp/theme.dart';
import 'package:provider/provider.dart';
import 'state/auth_provider.dart' as auth;
import 'state/cart_provider.dart';
import 'state/order_provider.dart';
import 'state/reservation_provider.dart';
import 'state/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/hive_service.dart';
import 'services/api_service.dart';
import 'services/reservation_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/menu_item.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the options for your app
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive and register adapters
  await Hive.initFlutter();

  // Clear any corrupted Hive data
  try {
    await Hive.deleteBoxFromDisk('menu');
  } catch (e) {
    // Silently handle Hive data clearing errors
  }

  // Register all adapters before opening any boxes
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(MenuItemAdapter());
  }

  // Initialize services after registering all adapters
  final hiveService = HiveService();
  await hiveService.init();

  // Create an instance of ApiService with the HiveService as a dependency
  final apiService = ApiService(hiveService: hiveService);

  runApp(MyApp(apiService: apiService));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;

  const MyApp({required this.apiService, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => auth.AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => ReservationProvider(ReservationService()),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Restaurant App',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {
              '/':
                  (context) => StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }

                      // If the user is logged in, show the main screen
                      if (snapshot.hasData) {
                        return MainScreen();
                      }

                      // Otherwise, show the login screen
                      return const LoginScreen();
                    },
                  ),
              '/cart': (context) => MainScreen(initialIndex: 1),
              '/orders': (context) => MainScreen(initialIndex: 2),
              '/order-status': (context) => MainScreen(initialIndex: 2),
              '/kitchen': (context) => MainScreen(initialIndex: 3),
              '/staff': (context) => MainScreen(initialIndex: 4),
              '/profile': (context) => MainScreen(initialIndex: 5),
              '/reserve': (context) => MainScreen(initialIndex: 6),
              '/login': (context) => const LoginScreen(),
            },
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  static final List<Widget> _screens = [
    HomeScreen(),
    CartScreen(),
    OrderStatusScreen(),
    KitchenScreen(),
    StaffScreen(),
    ProfileScreen(),
    TableReservationScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFE53935), // Red color to match AppBar
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Kitchen'),
          BottomNavigationBarItem(icon: Icon(Icons.badge), label: 'Staff'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Reserve',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
