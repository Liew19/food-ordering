import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/menu_item.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  Box<MenuItem>? _menuBox;
  Box<int>? _metaBox;
  static const String MENU_BOX_NAME = 'menu';
  static const String META_BOX_NAME = 'menu_meta';
  static const String CACHE_TIMESTAMP_KEY = 'cache_timestamp';
  static const Duration CACHE_DURATION = Duration(hours: 24);

  factory HiveService() {
    return _instance;
  }

  HiveService._internal();

  Future<void> init() async {
    if (_menuBox != null && _metaBox != null) return;

    try {
      _menuBox = await Hive.openBox<MenuItem>(MENU_BOX_NAME);
      _metaBox = await Hive.openBox<int>(META_BOX_NAME);
    } catch (e) {
      // Try to recover from corrupted boxes
      try {
        await Hive.deleteBoxFromDisk(MENU_BOX_NAME);
        await Hive.deleteBoxFromDisk(META_BOX_NAME);
        _menuBox = await Hive.openBox<MenuItem>(MENU_BOX_NAME);
        _metaBox = await Hive.openBox<int>(META_BOX_NAME);
      } catch (deleteError) {
        throw Exception('Failed to initialize Hive storage');
      }
    }
  }

  Future<void> cacheMenuItems(List<MenuItem> items) async {
    if (_menuBox == null || _metaBox == null) await init();

    try {
      await _menuBox!.clear();

      // Store items with indices as keys for faster retrieval
      for (var i = 0; i < items.length; i++) {
        await _menuBox!.put(i, items[i]);
      }

      // Update cache timestamp in meta box
      await _metaBox!.put(
        CACHE_TIMESTAMP_KEY,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      throw Exception('Failed to cache menu items');
    }
  }

  List<MenuItem> getCachedMenuItems() {
    if (_menuBox == null || !_menuBox!.isOpen) return [];

    try {
      return _menuBox!.values.toList();
    } catch (e) {
      return [];
    }
  }

  bool hasMenuCache() {
    if (_menuBox == null ||
        _metaBox == null ||
        !_menuBox!.isOpen ||
        !_metaBox!.isOpen)
      return false;

    try {
      // Check if cache exists and is not expired
      final timestamp = _metaBox!.get(CACHE_TIMESTAMP_KEY);
      if (timestamp == null) return false;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      return _menuBox!.isNotEmpty &&
          now.difference(cacheTime) <= CACHE_DURATION;
    } catch (e) {
      return false;
    }
  }

  Future<void> clearMenuCache() async {
    if (_menuBox == null || _metaBox == null) await init();

    try {
      await _menuBox!.clear();
      await _metaBox!.clear();
    } catch (e) {
      // Silently handle cache clearing errors
    }
  }

  MenuItem? getMenuItemById(String id) {
    if (_menuBox == null || !_menuBox!.isOpen) return null;

    try {
      return _menuBox!.values.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }
}
