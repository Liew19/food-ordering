// import 'dart:convert';
// import 'package:http/http.dart' as http;
import '../models/menu_item.dart';
import './hive_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApiService {
  final HiveService _hiveService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _initialized = false;

  ApiService({HiveService? hiveService})
    : _hiveService = hiveService ?? HiveService();

  // Ensure HiveService is initialized
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _hiveService.init();
      _initialized = true;
    }
  }

  // Get menu items from Firestore
  Future<List<MenuItem>> getMenuItems() async {
    await _ensureInitialized();
    try {
      final querySnapshot = await _firestore.collection('menu').get();
      final List<MenuItem> menuItems =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            return MenuItem(
              id: doc.id,
              name: data['name'],
              price: data['price'],
              category: data['category'],
              itemId: data['itemId'],
              imageUrl: data['imageUrl'],
              description: data['description'],
              rating: data['rating'],
              isPopular: data['isPopular'],
              preparationTime: data['preparationTime'],
            );
          }).toList();

      // Save menu items to Hive cache
      await _hiveService.cacheMenuItems(menuItems);

      return menuItems;
    } catch (e) {
      // If there's an error, return cached data if available
      if (_hiveService.hasMenuCache()) {
        return _hiveService.getCachedMenuItems();
      } else {
        // If no cached data, throw an exception
        throw Exception('Failed to load menu items: ${e.toString()}');
      }
    }
  }
}
