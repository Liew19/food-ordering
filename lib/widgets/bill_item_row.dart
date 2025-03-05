import 'package:flutter/material.dart';
import '../models/bill_item_model.dart';
import '../models/customer_model.dart';

class BillItemRow extends StatelessWidget {
  final BillItemModel item;
  final List<CustomerModel> customers;
  final Function(int, String, dynamic) onUpdateItem;
  final Function(int) onRemoveItem;
  final Function(int, int) onAssignCustomer;

  const BillItemRow({
    Key? key,
    required this.item,
    required this.customers,
    required this.onUpdateItem,
    required this.onRemoveItem,
    required this.onAssignCustomer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            // Name TextField
            Expanded(
              flex: 3,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Dish Name',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: item.name),
                onChanged: (value) => onUpdateItem(item.id, 'name', value),
              ),
            ),
            SizedBox(width: 8),

            // Price TextField
            Expanded(
              flex: 2,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Price',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: item.price.toString()),
                onChanged:
                    (value) => onUpdateItem(
                      item.id,
                      'price',
                      double.tryParse(value) ?? 0,
                    ),
              ),
            ),
            SizedBox(width: 8),

            // Quantity Stepper
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed:
                        item.quantity > 1
                            ? () => onUpdateItem(
                              item.id,
                              'quantity',
                              item.quantity - 1,
                            )
                            : null,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    iconSize: 20,
                  ),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                        text: item.quantity.toString(),
                      ),
                      onChanged:
                          (value) => onUpdateItem(
                            item.id,
                            'quantity',
                            int.tryParse(value) ?? 1,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed:
                        () => onUpdateItem(
                          item.id,
                          'quantity',
                          item.quantity + 1,
                        ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),

            // Assign Button
            ElevatedButton.icon(
              icon: Icon(Icons.person_add, size: 16),
              label: Text('Assign to Customer'),
              onPressed: () => _showAssignDialog(context),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              ),
            ),

            // Remove Button
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => onRemoveItem(item.id),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Assign Customer'),
            content: Container(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  // Instead of using item.assignedCustomers, we'll check if this customer
                  // is assigned to this item through a different approach since that property doesn't exist
                  final isAssigned =
                      false; // This needs to be determined based on your data model

                  return ListTile(
                    title: Text(customer.name),
                    trailing: Checkbox(
                      value: isAssigned,
                      onChanged: (value) {
                        Navigator.pop(context);
                        if (value == true) {
                          onAssignCustomer(item.id, customer.id);
                        }
                        // Logic to unassign if needed
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
            ],
          ),
    );
  }
}

// Here's a suggested implementation for BillItemModel
// You should implement this class in your models/bill_item_model.dart file
/*
class BillItemModel {
  final int id;
  final String name;
  final double price;
  final int quantity;
  final List<int> assignedCustomerIds; // Store assigned customer IDs

  BillItemModel({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    List<int>? assignedCustomerIds,
  }) : this.assignedCustomerIds = assignedCustomerIds ?? [];

  double get total => price * quantity;

  // Create a copy with updated fields
  BillItemModel copyWith({
    String? name,
    double? price,
    int? quantity,
    List<int>? assignedCustomerIds,
  }) {
    return BillItemModel(
      id: this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      assignedCustomerIds: assignedCustomerIds ?? this.assignedCustomerIds,
    );
  }
}
*/
