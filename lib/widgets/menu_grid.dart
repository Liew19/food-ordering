import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import 'menu_item_card.dart';

class MenuGrid extends StatelessWidget {
  final List<MenuItem> filteredItems;
  final Function(MenuItem) onItemTap;

  const MenuGrid({
    Key? key,
    required this.filteredItems,
    required this.onItemTap,
  }) : super(key: key);

  int _calculateCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return 5;
    } else if (width > 900) {
      return 4;
    } else if (width > 600) {
      return 3;
    } else {
      return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _calculateCrossAxisCount(context),
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          return MenuItemCard(
            item: item,
            onTap: () => onItemTap(item),
          );
        },
      ),
    );
  }
}