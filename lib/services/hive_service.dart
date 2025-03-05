// import 'package:fyp/models/adapters/menu_item_adapter.dart';
// import 'package:hive/hive.dart';
// import '../models/menu_item.dart';
//
// class HiveService {
//   late Box<MenuItem> menuBox;
//
//   Future<void> init() async {
//     Hive.registerAdapter(MenuItemAdapter());
//     menuBox = await Hive.openBox<MenuItem>('menu');
//   }
//
//   Future<void> cacheMenuItems(List<MenuItem> items) async {
//     await menuBox.clear();
//     await menuBox.addAll(items);
//   }
//
//   List<MenuItem> getCachedMenuItems() {
//     return menuBox.values.toList();
//   }
// }
