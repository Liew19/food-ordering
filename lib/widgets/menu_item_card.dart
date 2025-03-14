import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../state/cart_provider.dart';
import '../theme.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;

  const MenuItemCard({Key? key, required this.item, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image container
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  _buildItemImage(context, isDesktop, isDarkMode),
                  _buildCategoryBadge(context),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dish name
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: isDesktop ? 16 : 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),
                    // Price
                    Text(
                      'RM ${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: isDesktop ? 14 : 12,
                      ),
                    ),

                    // Preparation time
                    const SizedBox(height: 2),
                    _buildPrepTimeIndicator(context, isDesktop, isDarkMode),

                    const Spacer(),
                    // Add to cart button
                    _buildAddToCartButton(context, isDesktop),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage(
    BuildContext context,
    bool isDesktop,
    bool isDarkMode,
  ) {
    if (item.imageUrl.isNotEmpty) {
      return Image.network(
        item.imageUrl,
        height: isDesktop ? 140 : 100,
        width: double.infinity,
        fit: BoxFit.cover,
        // Add caching
        cacheWidth: isDesktop ? 280 : 200,
        cacheHeight: isDesktop ? 280 : 200,
        // Add loading placeholder
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: isDesktop ? 140 : 100,
            width: double.infinity,
            color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
            child: Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Fallback to local image if network image fails
          return Image.asset(
            item.imagePath,
            height: isDesktop ? 140 : 100,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorPlaceholder(context, isDesktop, isDarkMode);
            },
          );
        },
      );
    }

    // If no network image URL, try local image
    return Image.asset(
      item.imagePath,
      height: isDesktop ? 140 : 100,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorPlaceholder(context, isDesktop, isDarkMode);
      },
    );
  }

  // Extract error placeholder as a separate method
  Widget _buildErrorPlaceholder(
    BuildContext context,
    bool isDesktop,
    bool isDarkMode,
  ) {
    return Container(
      height: isDesktop ? 140 : 100,
      color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: isDesktop ? 40 : 30,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              'Image Error!',
              style: TextStyle(
                fontSize: isDesktop ? 14 : 12,
                color:
                    isDarkMode
                        ? AppTheme.textDarkColor
                        : AppTheme.textLightColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          item.category,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPrepTimeIndicator(
    BuildContext context,
    bool isDesktop,
    bool isDarkMode,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time,
          size: isDesktop ? 14 : 12,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        SizedBox(width: isDesktop ? 4 : 2),
        Text(
          "${item.preparationTime}min",
          style: TextStyle(
            fontSize: isDesktop ? 12 : 10,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAddToCartButton(BuildContext context, bool isDesktop) {
    return SizedBox(
      width: double.infinity,
      height: isDesktop ? 36 : 30,
      child: ElevatedButton(
        onPressed: () => _addToCart(context),
        // ElevatedButton theme customization
        style: AppTheme.primaryButtonStyle.copyWith(
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
        ),
        child: Transform.translate(
          offset: const Offset(0, -1), // Shift up by 1 pixel unit
          child: Center(
            child: Icon(
              Icons.shopping_cart,
              size: isDesktop ? 20 : 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _addToCart(BuildContext context) {
    Provider.of<CartProvider>(context, listen: false).addToCart(item);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${item.name} to cart!',
          style: TextStyle(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
          ),
        ),
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.white,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }
}
