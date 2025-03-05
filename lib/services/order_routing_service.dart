import '../state/cart_provider.dart';

enum OrderDestination { kitchen, staff }

class OrderRoutingService {
  // Determine order destination based on menu item category
  static OrderDestination determineOrderDestination(CartItem item) {
    // Categories handled by kitchen: Main, Snacks, Salad
    if (item.menuItem.category == 'Main' ||
        item.menuItem.category == 'Snacks' ||
        item.menuItem.category == 'Salad') {
      return OrderDestination.kitchen;
    }
    // Categories handled by staff: Dessert and others
    else {
      return OrderDestination.staff;
    }
  }

  // Determine destination for entire order
  static Map<OrderDestination, List<CartItem>> routeOrder(
    List<CartItem> items,
  ) {
    Map<OrderDestination, List<CartItem>> routedItems = {
      OrderDestination.kitchen: [],
      OrderDestination.staff: [],
    };

    for (var item in items) {
      OrderDestination destination = determineOrderDestination(item);
      routedItems[destination]!.add(item);
    }

    return routedItems;
  }

  // Check if order requires kitchen processing
  static bool requiresKitchen(List<CartItem> items) {
    return items.any(
      (item) => determineOrderDestination(item) == OrderDestination.kitchen,
    );
  }

  // Check if order requires staff processing
  static bool requiresStaff(List<CartItem> items) {
    return items.any(
      (item) => determineOrderDestination(item) == OrderDestination.staff,
    );
  }
}
