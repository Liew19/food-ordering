import 'package:cloud_firestore/cloud_firestore.dart';

class MigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// One-time migration to add isDeleted field to existing menu items
  static Future<void> migrateMenuItemsForSoftDelete() async {
    try {
      // Get all menu items
      final querySnapshot = await _firestore.collection('menu').get();

      final batch = _firestore.batch();
      int updateCount = 0;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();

        // Only update if isDeleted field doesn't exist
        if (!data.containsKey('isDeleted')) {
          batch.update(doc.reference, {'isDeleted': false, 'deletedAt': null});
          updateCount++;
        }
      }

      if (updateCount > 0) {
        await batch.commit();
      } else {}
    } catch (e) {
      throw Exception('Failed to migrate menu items: $e');
    }
  }
}
