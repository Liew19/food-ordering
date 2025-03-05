class MenuItem {
  final String id;
  final String name;
  final double price;
  final String category;
  final String itemId;
  final String imageUrl;
  final String? description;
  final double? rating;
  final bool isPopular;
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

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      itemId: json['itemId'] as String,
      imageUrl: json['imageUrl'] as String,
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      isPopular: json['isPopular'] as bool,
      preparationTime: (json['preparationTime'] as num).toDouble(),
    );
  }
}
