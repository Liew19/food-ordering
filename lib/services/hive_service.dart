import 'package:fyp/models/adapters/menu_item_adapter.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/menu_item.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  late Box<MenuItem> menuBox;
  static bool _isAdapterRegistered = false;

  factory HiveService() {
    return _instance;
  }

  HiveService._internal();

  Future<void> init() async {
    // Initialize Hive
    await Hive.initFlutter();

    try {
      // Register MenuItemAdapter
      if (!_isAdapterRegistered) {
        if (!Hive.isAdapterRegistered(1)) {
          // Check if the adapter is already registered
          Hive.registerAdapter(MenuItemAdapter());
          _isAdapterRegistered = true;
        }
      }

      // Open the box for MenuItems if it doesn't exist, create it otherwise
      menuBox = await Hive.openBox<MenuItem>('menu');
    } catch (e) {
      print('Hive initialization error: $e');
      rethrow;
    }
  }

  // Save menu items to Hive
  Future<void> cacheMenuItems(List<MenuItem> items) async {
    await menuBox.clear(); // Clear existing data
    await menuBox.addAll(items); // Add new items
  }

  // Get cached menu items from Hive
  List<MenuItem> getCachedMenuItems() {
    return menuBox.values.toList();
  }

  // Check if there is a cached menu
  bool hasMenuCache() {
    return menuBox.isNotEmpty;
  }

  // Clear cached menu items from Hive
  Future<void> clearMenuCache() async {
    await menuBox.clear();
  }

  // Get a menu item by its ID
  MenuItem? getMenuItemById(String itemId) {
    try {
      return menuBox.values.firstWhere((item) => item.itemId == itemId);
    } catch (e) {
      return null;
    }
  }
}
