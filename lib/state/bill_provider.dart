import 'package:flutter/foundation.dart';
import '../models/bill_item_model.dart';
import '../models/customer_model.dart';

class BillProvider extends ChangeNotifier {
  int _tableId;
  List<CustomerModel> _customers = [];
  List<BillItemModel> _items = [];

  BillProvider({required int tableId}) : _tableId = tableId {
    _initMockData();
  }

  // Getters
  int get tableId => _tableId;
  List<CustomerModel> get customers => _customers;
  List<BillItemModel> get items => _items;

  // Initialize mock data
  void _initMockData() {
    // Initialize with mock customers
    _customers = [
      CustomerModel(id: 1, name: "张先生"),
      CustomerModel(id: 2, name: "王小姐"),
      CustomerModel(id: 3, name: "李先生"),
    ];

    // Initialize with mock bill items
    _items = [
      BillItemModel(id: 1, name: "宫保鸡丁", price: 68, quantity: 1),
      BillItemModel(id: 2, name: "水煮鱼", price: 88, quantity: 1),
      BillItemModel(id: 3, name: "蒜蓉空心菜", price: 28, quantity: 1),
      BillItemModel(id: 4, name: "米饭", price: 5, quantity: 2),
    ];

    notifyListeners();
  }

  // Add a new bill item
  void addItem() {
    _items.add(
      BillItemModel(id: _items.length + 1, name: "", price: 0, quantity: 1),
    );
    notifyListeners();
  }

  // Update a bill item
  void updateItem(int id, String field, dynamic value) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      switch (field) {
        case 'name':
          _items[index] = _items[index].copyWith(name: value);
          break;
        case 'price':
          _items[index] = _items[index].copyWith(price: value);
          break;
        case 'quantity':
          _items[index] = _items[index].copyWith(quantity: value);
          break;
      }
      notifyListeners();
    }
  }

  // Remove a bill item
  void removeItem(int id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  // Assign/unassign a bill item to a customer
  void assignItemToCustomer(int itemId, int customerId) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final item = _items[index];
      final isAssigned = item.assignedTo.contains(customerId);

      List<int> newAssignedTo = List.from(item.assignedTo);

      if (isAssigned) {
        newAssignedTo.remove(customerId);
      } else {
        newAssignedTo.add(customerId);
      }

      _items[index] = item.copyWith(assignedTo: newAssignedTo);
      notifyListeners();
    }
  }

  // Calculate total bill amount
  double calculateTotal() {
    return _items.fold(0, (total, item) => total + item.price * item.quantity);
  }

  // Calculate bill amount for a specific customer
  double calculateCustomerBill(int customerId) {
    double total = 0;

    for (var item in _items) {
      if (item.assignedTo.contains(customerId)) {
        // If item is shared, divide the cost
        final shareCount = item.assignedTo.length;
        final sharePrice = (item.price * item.quantity) / shareCount;
        total += sharePrice;
      }
    }

    return total;
  }
}
