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

  @override
  Widget build(BuildContext context) {
    // Get screen width
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate number of columns and aspect ratio based on screen width
    int crossAxisCount;
    double childAspectRatio;

    if (screenWidth > 1200) {
      crossAxisCount = 4; // Large screens: 4 columns
      childAspectRatio = 1;
    } else if (screenWidth > 900) {
      crossAxisCount = 3; // Medium screens: 3 columns
      childAspectRatio = 1;
    } else if (screenWidth > 600) {
      crossAxisCount = 2; // Small screens: 2 columns
      childAspectRatio = 1;
    } else {
      crossAxisCount = 2; // Very small screens: 1 column
      childAspectRatio = 0.8;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        return MenuItemCard(
          item: filteredItems[index],
          onTap: () => onItemTap(filteredItems[index]),
        );
      },
    );
  }
}
