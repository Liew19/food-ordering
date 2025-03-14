import 'package:hive/hive.dart';

part 'menu_item.g.dart';

@HiveType(typeId: 1)
class MenuItem {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final double price;
  @HiveField(3)
  final String category;
  @HiveField(4)
  final String itemId;
  @HiveField(5)
  final String imageUrl;
  @HiveField(6)
  final String? description;
  @HiveField(7)
  final double? rating;
  @HiveField(8)
  final bool isPopular;
  @HiveField(9)
  final double preparationTime;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.itemId,
    required this.imageUrl,
    this.description,
    this.rating,
    this.isPopular = false,
    required this.preparationTime,
  });

  // Get the asset path for local images
  String get imagePath {
    // Special cases mapping for exact matches
    final Map<String, String> specialCases = {
      // Main courses
      'Grilled Salmon': 'grilledSalmon.jpg',
      'Classic Burger': 'classicBurger.jpg',
      'Pizza': 'pizza.jpg',
      'Margherita Pizza': 'pizza.jpg',
      'Steak': 'Steak.jpg',
      'Grilled Steak': 'Steak.jpg',

      // Salads
      'Greek Salad': 'greekSalad.jpg',
      'Caesar Salad': 'CaesarSalad.jpg',
      'Caesar Salad with Grilled Chicken': 'CaesarSalad.jpg',

      // Desserts
      'Ice Cream': 'IceCream.jpg',
      'Chocolate Cake': 'chocolateCake.jpg',

      // Beverages
      'Sky Juice': 'skyjuice.jpg',
      'Orange Juice': 'orangejuice.jpg',
      'Americano': 'americano.jpg',
    };

    // Check for special cases first (case-insensitive)
    String normalizedName = name.toLowerCase();
    for (var entry in specialCases.entries) {
      if (entry.key.toLowerCase() == normalizedName) {
        return 'assets/images/${entry.value}';
      }
    }

    // For items not in special cases, try to find a suitable default image based on category
    switch (category.toLowerCase()) {
      case 'main course':
        return 'assets/images/Steak.jpg';
      case 'beverage':
        return 'assets/images/skyjuice.jpg';
      case 'salad':
        return 'assets/images/CaesarSalad.jpg';
      case 'dessert':
        return 'assets/images/IceCream.jpg';
      default:
        // Use a default image name based on the item name
        String fileName = name.replaceAll(' ', '');
        return 'assets/images/$fileName.jpg';
    }
  }

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      itemId: json['itemId'] as String,
      imageUrl:
          json['imageUrl'] as String? ??
          '', // Store original URL but won't use it
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      isPopular: json['isPopular'] as bool? ?? false,
      preparationTime: (json['preparationTime'] as num).toDouble(),
    );
  }
}
