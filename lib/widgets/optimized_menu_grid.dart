import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import 'menu_item_card.dart';

/// Optimized menu grid widget with lazy loading and const optimizations
class OptimizedMenuGrid extends StatelessWidget {
  final List<MenuItem> filteredItems;
  final Function(MenuItem) onItemTap;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const OptimizedMenuGrid({
    super.key,
    required this.filteredItems,
    required this.onItemTap,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.75,
    this.crossAxisSpacing = 16.0,
    this.mainAxisSpacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    if (filteredItems.isEmpty) {
      return const _EmptyMenuState();
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(), // Parent handles scrolling
      shrinkWrap: true, // Allow grid to take only the space it needs
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _MenuItemWrapper(
          key: ValueKey(item.id),
          item: item,
          onTap: () => onItemTap(item),
        );
      },
    );
  }
}

/// Wrapper widget for menu item card to optimize rebuilds
class _MenuItemWrapper extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;

  const _MenuItemWrapper({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MenuItemCard(item: item, onTap: onTap);
  }
}

/// Empty state for menu grid
class _EmptyMenuState extends StatelessWidget {
  const _EmptyMenuState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No menu items found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
