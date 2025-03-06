import 'package:flutter/material.dart';
import 'package:fyp/screens/cart_screen.dart';
import 'package:fyp/screens/home_screen.dart';
import 'package:fyp/screens/kitchen_screen.dart';
import 'package:fyp/screens/order_status_screen.dart';
import 'package:fyp/screens/shared_table_screen.dart';
import 'package:fyp/screens/staff_screen.dart';
import 'package:fyp/theme.dart';
import 'package:provider/provider.dart';
import 'state/cart_provider.dart';
import 'state/order_provider.dart';
import 'state/theme_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder:
            (context, themeProvider, child) => MaterialApp(
              title: 'Restaurant App',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode:
                  themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              debugShowCheckedModeBanner: false,
              home: MainScreen(),
            ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    HomeScreen(),
    CartScreen(),
    OrderStatusScreen(),
    SharedTableScreen(),
    KitchenScreen(),
    StaffScreen(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Share Table',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Kitchen'),
          BottomNavigationBarItem(icon: Icon(Icons.badge), label: 'Staff'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
