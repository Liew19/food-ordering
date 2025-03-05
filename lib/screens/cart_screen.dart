import 'package:flutter/material.dart';
import 'package:fyp/models/order.dart';
import 'package:fyp/state/order_provider.dart';
import 'package:fyp/theme.dart';
import 'package:provider/provider.dart';
import '../state/cart_provider.dart';

class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shopping cart',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _showClearCartDialog(context);
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final cartItems = cartProvider.items;

          if (cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: isDarkMode ? AppTheme.textMutedColor : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some items to your cart and enjoy the delicious food!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate back to the menu page
                      Navigator.of(context).pop();
                    },
                    child: const Text('Back to Menu'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final cartItem = cartItems[index];
                    return _buildCartItemCard(context, cartItem, cartProvider);
                  },
                ),
              ),
              _buildOrderSummary(context, cartProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItemCard(
    BuildContext context,
    CartItem cartItem,
    CartProvider cartProvider,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                cartItem.item.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                    child: const Icon(Icons.image_not_supported_outlined),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.item.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RM ${cartItem.item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    cartProvider.decreaseQuantity(cartItem.item);
                  },
                ),
                Text(
                  '${cartItem.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    cartProvider.increaseQuantity(cartItem.item);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context, CartProvider cartProvider) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.backgroundColor : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Checkout', style: Theme.of(context).textTheme.titleMedium),
              Text(
                'RM ${cartProvider.totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppTheme.gradientButton(
            text: 'Checkout',
            onTap: () {
              _showCheckoutDialog(context);
            },
            height: 50,
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: isDarkMode ? Color(0xFF333333) : Colors.white,
            title: Text(
              'Clear Cart',
              style: TextStyle(
                color:
                    isDarkMode
                        ? AppTheme.textDarkColor
                        : AppTheme.textLightColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to clear the cart?',
              style: TextStyle(
                color:
                    isDarkMode
                        ? AppTheme.textDarkColor
                        : AppTheme.textLightColor,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Provider.of<CartProvider>(context, listen: false).clearCart();
                  Navigator.pop(context);
                },
                child: Text(
                  'Confirm',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
    );
  }

  void _showCheckoutDialog(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your cart is empty now.')));
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: isDarkMode ? Color(0xFF333333) : Colors.white,
            title: Text(
              'Checkout',
              style: TextStyle(
                color:
                    isDarkMode
                        ? AppTheme.textDarkColor
                        : AppTheme.textLightColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure to checkout?',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? AppTheme.textDarkColor
                            : AppTheme.textLightColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Total: RM ${cartProvider.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? AppTheme.textDarkColor
                            : AppTheme.textLightColor,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final newOrder = Order(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    items: List.from(cartProvider.items),
                    totalPrice: cartProvider.totalPrice,
                    status: OrderStatus.pending,
                    createdAt: DateTime.now(),
                  );

                  orderProvider.addOrder(newOrder);

                  cartProvider.clearCart();
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order placed successfully!')),
                  );

                  // Optional: Navigate to the order status page
                  // Navigator.of(context).pushReplacement(
                  //   MaterialPageRoute(builder: (context) => OrderStatusScreen()),
                  // );
                },
                child: Text(
                  'Confirm',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
    );
  }
}
