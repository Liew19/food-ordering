import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item.dart';

class MenuService {
  static final MenuService _instance = MenuService._internal();
  factory MenuService() => _instance;
  MenuService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'menu';

  /// Create a new menu item in Firestore
  Future<String> createMenuItem(MenuItem menuItem) async {
    try {
      // Create a document reference with auto-generated ID
      final docRef = _firestore.collection(_collection).doc();

      // Prepare data for Firestore
      final data = {
        'name': menuItem.name,
        'price': menuItem.price,
        'category': menuItem.category,
        'itemId': menuItem.itemId,
        'imageUrl': menuItem.imageUrl, // Cloudinary URL
        'description': menuItem.description,
        'rating': menuItem.rating,
        'isPopular': menuItem.isPopular,
        'preparationTime': menuItem.preparationTime,
        'canPrepareInParallel': menuItem.canPrepareInParallel,
        'isDeleted': false,
        'deletedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await docRef.set(data);

      return docRef.id; // Return the generated document ID
    } catch (e) {
      throw Exception('Failed to create menu item: $e');
    }
  }

  /// Update an existing menu item in Firestore
  Future<void> updateMenuItem(String documentId, MenuItem menuItem) async {
    try {
      final data = {
        'name': menuItem.name,
        'price': menuItem.price,
        'category': menuItem.category,
        'itemId': menuItem.itemId,
        'imageUrl': menuItem.imageUrl, // Cloudinary URL
        'description': menuItem.description,
        'rating': menuItem.rating,
        'isPopular': menuItem.isPopular,
        'preparationTime': menuItem.preparationTime,
        'canPrepareInParallel': menuItem.canPrepareInParallel,
        'isDeleted': menuItem.isDeleted,
        'deletedAt': menuItem.deletedAt,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(_collection).doc(documentId).update(data);
    } catch (e) {
      throw Exception('Failed to update menu item: $e');
    }
  }

  /// Soft delete a menu item (mark as deleted instead of removing)
  Future<void> deleteMenuItem(String documentId) async {
    try {
      await _firestore.collection(_collection).doc(documentId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete menu item: $e');
    }
  }

  /// Restore a soft-deleted menu item
  Future<void> restoreMenuItem(String documentId) async {
    try {
      await _firestore.collection(_collection).doc(documentId).update({
        'isDeleted': false,
        'deletedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to restore menu item: $e');
    }
  }

  /// Hard delete a menu item (permanent removal) - Admin only
  Future<void> permanentlyDeleteMenuItem(String documentId) async {
    try {
      await _firestore.collection(_collection).doc(documentId).delete();
    } catch (e) {
      throw Exception('Failed to permanently delete menu item: $e');
    }
  }

  /// Get a single menu item by document ID
  Future<MenuItem?> getMenuItem(String documentId) async {
    try {
      final doc =
          await _firestore.collection(_collection).doc(documentId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
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
        rating: data['rating']?.toDouble(),
        isPopular: data['isPopular'] ?? false,
        preparationTime:
            (data['preparationTime'] is int)
                ? (data['preparationTime'] as int).toDouble()
                : data['preparationTime'],
        canPrepareInParallel: data['canPrepareInParallel'] ?? true,
        isDeleted: data['isDeleted'] ?? false,
        deletedAt: data['deletedAt']?.toDate(),
      );
    } catch (e) {
      throw Exception('Failed to get menu item: $e');
    }
  }

  /// Get all active menu items from Firestore (excluding soft-deleted)
  Future<List<MenuItem>> getAllMenuItems() async {
    try {
      // Get all items for backward compatibility, then filter client-side
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
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
          rating: data['rating']?.toDouble(),
          isPopular: data['isPopular'] ?? false,
          preparationTime:
              (data['preparationTime'] is int)
                  ? (data['preparationTime'] as int).toDouble()
                  : data['preparationTime'],
          canPrepareInParallel: data['canPrepareInParallel'] ?? true,
          isDeleted: data['isDeleted'] ?? false,
          deletedAt: data['deletedAt']?.toDate(),
        );
      }).where((item) => !item.isDeleted).toList(); // Filter out deleted items
    } catch (e) {
      throw Exception('Failed to get menu items: $e');
    }
  }

  /// Get menu items by category (excluding soft-deleted)
  Future<List<MenuItem>> getMenuItemsByCategory(String category) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('category', isEqualTo: category)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
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
          rating: data['rating']?.toDouble(),
          isPopular: data['isPopular'] ?? false,
          preparationTime:
              (data['preparationTime'] is int)
                  ? (data['preparationTime'] as int).toDouble()
                  : data['preparationTime'],
          canPrepareInParallel: data['canPrepareInParallel'] ?? true,
          isDeleted: data['isDeleted'] ?? false,
          deletedAt: data['deletedAt']?.toDate(),
        );
      }).where((item) => !item.isDeleted).toList(); // Filter out deleted items
    } catch (e) {
      throw Exception('Failed to get menu items by category: $e');
    }
  }

  /// Get popular menu items (excluding soft-deleted)
  Future<List<MenuItem>> getPopularMenuItems() async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('isPopular', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
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
          rating: data['rating']?.toDouble(),
          isPopular: data['isPopular'] ?? false,
          preparationTime:
              (data['preparationTime'] is int)
                  ? (data['preparationTime'] as int).toDouble()
                  : data['preparationTime'],
          canPrepareInParallel: data['canPrepareInParallel'] ?? true,
          isDeleted: data['isDeleted'] ?? false,
          deletedAt: data['deletedAt']?.toDate(),
        );
      }).where((item) => !item.isDeleted).toList(); // Filter out deleted items
    } catch (e) {
      throw Exception('Failed to get popular menu items: $e');
    }
  }

  /// Stream of active menu items for real-time updates (excluding soft-deleted)
  Stream<List<MenuItem>> getMenuItemsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
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
              rating: data['rating']?.toDouble(),
              isPopular: data['isPopular'] ?? false,
              preparationTime:
                  (data['preparationTime'] is int)
                      ? (data['preparationTime'] as int).toDouble()
                      : data['preparationTime'],
              canPrepareInParallel: data['canPrepareInParallel'] ?? true,
              isDeleted: data['isDeleted'] ?? false,
              deletedAt: data['deletedAt']?.toDate(),
            );
          }).where((item) => !item.isDeleted).toList(); // Filter out deleted items
        });
  }

  /// Get all deleted menu items (Admin only)
  Future<List<MenuItem>> getDeletedMenuItems() async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('isDeleted', isEqualTo: true)
              .get();

      final items =
          querySnapshot.docs.map((doc) {
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
              rating: data['rating']?.toDouble(),
              isPopular: data['isPopular'] ?? false,
              preparationTime:
                  (data['preparationTime'] is int)
                      ? (data['preparationTime'] as int).toDouble()
                      : data['preparationTime'],
              canPrepareInParallel: data['canPrepareInParallel'] ?? true,
              isDeleted: data['isDeleted'] ?? false,
              deletedAt: data['deletedAt']?.toDate(),
            );
          }).toList();

      // Sort by deletedAt on client side (newest first)
      items.sort((a, b) {
        if (a.deletedAt == null && b.deletedAt == null) return 0;
        if (a.deletedAt == null) return 1;
        if (b.deletedAt == null) return -1;
        return b.deletedAt!.compareTo(a.deletedAt!);
      });

      return items;
    } catch (e) {
      throw Exception('Failed to get deleted menu items: $e');
    }
  }

  /// Get all menu items including deleted ones (Admin only)
  Future<List<MenuItem>> getAllMenuItemsIncludingDeleted() async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
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
          rating: data['rating']?.toDouble(),
          isPopular: data['isPopular'] ?? false,
          preparationTime:
              (data['preparationTime'] is int)
                  ? (data['preparationTime'] as int).toDouble()
                  : data['preparationTime'],
          canPrepareInParallel: data['canPrepareInParallel'] ?? true,
          isDeleted: data['isDeleted'] ?? false,
          deletedAt: data['deletedAt']?.toDate(),
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get all menu items: $e');
    }
  }
}
