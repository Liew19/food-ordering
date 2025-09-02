// import 'dart:convert';
// import 'package:http/http.dart' as http;
import '../models/menu_item.dart';
import './hive_service.dart';
import './menu_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApiService {
  final HiveService _hiveService;
  final MenuService _menuService = MenuService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _initialized = false;
  bool _isUpdating = false;

  ApiService({HiveService? hiveService})
    : _hiveService = hiveService ?? HiveService();

  // Ensure HiveService is initialized
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _hiveService.init();
      _initialized = true;
    }
  }

  // Get menu items with optimized caching
  Future<List<MenuItem>> getMenuItems() async {
    await _ensureInitialized();

    try {
      // Always try to get cached data first
      if (_hiveService.hasMenuCache()) {
        final cachedItems = _hiveService.getCachedMenuItems();
        // Only update cache if not already updating
        if (!_isUpdating) {
          _updateCacheInBackground();
        }
        return cachedItems;
      }

      // If no cache, fetch from Firestore with timeout
      return await _fetchFromFirestore().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // Return empty list on timeout
          return [];
        },
      );
    } catch (e) {
      // If there's an error and we have cache, return cached data
      if (_hiveService.hasMenuCache()) {
        return _hiveService.getCachedMenuItems();
      }
      // Return empty list instead of throwing
      return [];
    }
  }

  // Fetch data from Firestore and update cache
  Future<List<MenuItem>> _fetchFromFirestore() async {
    // Get all menu items and filter on client side for backward compatibility
    final querySnapshot = await _firestore.collection('menu').get();
    final List<MenuItem> menuItems =
        querySnapshot.docs
            .map((doc) {
              final data = doc.data();
              return MenuItem(
                id: doc.id,
                name: data['name'],
                price:
                    (data['price'] is int)
                        ? (data['price'] as int).toDouble()
                        : data['price'],
                category: data['category'],
                itemId: data['itemId'],
                imageUrl: data['imageUrl'],
                description: data['description'],
                rating: data['rating'],
                isPopular: data['isPopular'] ?? false,
                preparationTime:
                    (data['preparationTime'] is int)
                        ? (data['preparationTime'] as int).toDouble()
                        : data['preparationTime'],
                canPrepareInParallel: data['canPrepareInParallel'] ?? true,
                isDeleted: data['isDeleted'] ?? false,
                deletedAt: data['deletedAt']?.toDate(),
              );
            })
            .where((item) => !item.isDeleted)
            .toList(); // Filter out deleted items

    // Update cache with new data
    await _hiveService.cacheMenuItems(menuItems);
    return menuItems;
  }

  // Update cache in background without blocking UI
  Future<void> _updateCacheInBackground() async {
    if (_isUpdating) return;

    _isUpdating = true;
    try {
      await _fetchFromFirestore();
    } catch (e) {
      // Silently handle background cache update failure
    } finally {
      _isUpdating = false;
    }
  }

  /// Create a new menu item (delegates to MenuService)
  Future<String> createMenuItem(MenuItem menuItem) async {
    final documentId = await _menuService.createMenuItem(menuItem);
    // Refresh cache after creating new item
    _updateCacheInBackground();
    return documentId;
  }

  /// Update an existing menu item (delegates to MenuService)
  Future<void> updateMenuItem(String documentId, MenuItem menuItem) async {
    await _menuService.updateMenuItem(documentId, menuItem);
    // Refresh cache after updating item
    _updateCacheInBackground();
  }

  /// Delete a menu item (delegates to MenuService)
  Future<void> deleteMenuItem(String documentId) async {
    await _menuService.deleteMenuItem(documentId);
    // Refresh cache after deleting item
    _updateCacheInBackground();
  }

  /// Restore a soft-deleted menu item (delegates to MenuService)
  Future<void> restoreMenuItem(String documentId) async {
    await _menuService.restoreMenuItem(documentId);
    // Refresh cache after restoring item
    _updateCacheInBackground();
  }

  /// Permanently delete a menu item (delegates to MenuService)
  Future<void> permanentlyDeleteMenuItem(String documentId) async {
    await _menuService.permanentlyDeleteMenuItem(documentId);
    // Refresh cache after permanently deleting item
    _updateCacheInBackground();
  }

  /// Get deleted menu items (Admin only)
  Future<List<MenuItem>> getDeletedMenuItems() async {
    return await _menuService.getDeletedMenuItems();
  }

  /// Get all menu items including deleted ones (Admin only)
  Future<List<MenuItem>> getAllMenuItemsIncludingDeleted() async {
    return await _menuService.getAllMenuItemsIncludingDeleted();
  }
}
