// import 'package:firebase_database/firebase_database.dart';
// import '../models/order.dart';
// import '../models/menu_item.dart';
//
// typedef OrderList = List<Order>;
//
// class FirebaseService {
//   final bool useMockData;
//   final DatabaseReference _database = FirebaseDatabase.instance.ref();
//
//   FirebaseService({this.useMockData = false});
//
//   Future<void> updateOrderStatus(String orderId, String status) async {
//     if (useMockData) {
//       await Future.delayed(const Duration(milliseconds: 500));
//     } else {
//       await _database.child('orders').child(orderId).update({'status': status});
//     }
//   }
//
//   Stream<OrderList> getKitchenOrders() {
//     if (useMockData) {
//   
//       final List<MenuItem> burgerMeal = [
//         MenuItem(
//           id: "item1",
//           name: "Burger",
//           price: 5.99,
//           category: "Main",
//           itemId: '',
//           imageUrl: '',
//         ),
//         MenuItem(
//           id: "item2",
//           name: "Fries",
//           price: 2.99,
//           category: "Side",
//           itemId: '',
//           imageUrl: '',
//         ),
//       ];
//
//       final List<MenuItem> pizzaMeal = [
//         MenuItem(
//           id: "item3",
//           name: "Pizza",
//           price: 8.99,
//           category: "Main",
//           itemId: '',
//           imageUrl: '',
//         ),
//       ];
//
//      
//       return Stream.periodic(const Duration(seconds: 1), (_) {
//         return [
//           Order(
//             id: "1",
//             orderId: "order1",
//             userId: "user1",
//             tableNumber: 5,
//             items: burgerMeal,
//             status: "pending",
//             timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
//           ),
//           Order(
//             id: "2",
//             orderId: "order2",
//             userId: "user2",
//             tableNumber: 8,
//             items: pizzaMeal,
//             status: "cooking",
//             timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
//           ),
//         ];
//       });
//     } else {
//      
//       return _database.child('orders').onValue.map((event) {
//         final dataSnapshot = event.snapshot;
//         if (dataSnapshot.value == null) return [];
//
//         final Map<dynamic, dynamic> ordersMap = Map<dynamic, dynamic>.from(
//           dataSnapshot.value as Map,
//         );
//
//         return ordersMap.entries.map((entry) {
//           Map<String, dynamic> orderData = Map<String, dynamic>.from(
//             entry.value as Map,
//           );
//
//        
//           List<dynamic> itemsData = orderData['items'] as List<dynamic>;
//           List<MenuItem> menuItems =
//               itemsData.map((item) {
//                 if (item is Map) {
//                   return MenuItem.fromJson(Map<String, dynamic>.from(item));
//                 } else {
//                   
//                   return MenuItem(
//                     id: "unknown",
//                     name: item.toString(),
//                     price: 0.0,
//                     category: "Unknown",
//                     itemId: '',
//                     imageUrl: '',
//                   );
//                 }
//               }).toList();
//
//           // Create Order object using all required parameters
//           return Order(
//             id: orderData['id'] as String,
//             orderId: orderData['orderId'] as String,
//             userId: orderData['userId'] as String,
//             tableNumber: orderData['tableNumber'] as int,
//             items: menuItems,
//             status: orderData['status'] as String,
//             timestamp: DateTime.parse(orderData['timestamp'] as String),
//           );
//         }).toList();
//       });
//     }
//   }
// }
