import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/cart_provider.dart';
import 'menu_search_bar.dart';

class FoodAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController? searchController;
  final Function(String)? onSearchChanged;
  final bool showSearch;
  final bool showCart;
  final VoidCallback? onCartTap;
  final String? customTitle;
  final List<Widget>? actions;

  const FoodAppBar({
    super.key,
    this.searchController,
    this.onSearchChanged,
    this.showSearch = true,
    this.showCart = true,
    this.onCartTap,
    this.customTitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Text(
            customTitle ?? 'FoodApp',
            style: TextStyle(
              color:
                  customTitle != null
                      ? Colors.black87
                      : const Color(0xFFE53935), // Changed from blue to red
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showSearch) ...[
            const SizedBox(width: 16),
            Expanded(
              child: MenuSearchBar(
                controller: searchController ?? TextEditingController(),
                onSearchChanged: onSearchChanged ?? (_) {},
              ),
            ),
          ],
        ],
      ),
      actions: [
        // Custom actions
        if (actions != null) ...actions!,

        // Cart icon
        if (showCart)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Consumer<CartProvider>(
              builder:
                  (context, cart, child) => Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.black54,
                        ),
                        onPressed:
                            onCartTap ??
                            () {
                              Navigator.pushNamed(context, '/cart');
                            },
                      ),
                      if (cart.totalItems > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${cart.totalItems}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
