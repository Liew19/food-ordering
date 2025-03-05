import 'package:flutter/material.dart';
import '../models/menu_item.dart';

// First, let's define the CartItem class that was missing
class CartItem {
  final MenuItem item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});

  double get totalPrice => item.price * quantity;

  get menuItem => null;
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _cartItems = [];

  // Getter for cart items
  List<CartItem> get cartItems => _cartItems;

  // Get total number of items in cart
  int get totalItems => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  // Get all items (alternative getter that was referenced in errors)
  List<CartItem> get items => _cartItems;

  // Add item to cart
  void addToCart(MenuItem item) {
    // Check if item already exists in cart
    int index = _findItemIndex(item);

    if (index != -1) {
      // Item already exists, increase quantity
      _cartItems[index].quantity++;
    } else {
      // Add new item
      _cartItems.add(CartItem(item: item));
    }
    notifyListeners();
  }

  // Remove item from cart
  void removeFromCart(MenuItem item) {
    int index = _findItemIndex(item);

    if (index != -1) {
      _cartItems.removeAt(index);
      notifyListeners();
    }
  }

  // Decrease quantity of an item
  void decreaseQuantity(MenuItem item) {
    int index = _findItemIndex(item);

    if (index != -1) {
      if (_cartItems[index].quantity > 1) {
        // Decrease quantity if more than 1
        _cartItems[index].quantity--;
      } else {
        // Remove item if quantity would be 0
        _cartItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  // Increase quantity of an item
  void increaseQuantity(MenuItem item) {
    int index = _findItemIndex(item);

    if (index != -1) {
      // Increase quantity of existing item
      _cartItems[index].quantity++;
      notifyListeners();
    } else {
      // If item doesn't exist in cart, add it
      addToCart(item);
    }
  }

  // Clear all items from cart
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // Calculate total price
  double get totalPrice {
    return _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  // Helper method to find an item's index in the cart
  int _findItemIndex(MenuItem item) {
    return _cartItems.indexWhere((cartItem) => cartItem.item.id == item.id);
  }
}
