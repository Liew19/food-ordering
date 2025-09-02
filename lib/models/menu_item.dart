import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  @HiveField(10)
  final bool canPrepareInParallel;
  @HiveField(11)
  final bool isDeleted;
  @HiveField(12)
  final DateTime? deletedAt;

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
    this.canPrepareInParallel = true,
    this.isDeleted = false,
    this.deletedAt,
  });

  // Check if item has a valid Cloudinary image URL
  bool get hasCloudinaryImage =>
      imageUrl.isNotEmpty && imageUrl.contains('cloudinary.com');

  // Get optimized Cloudinary URL for different display sizes
  String getOptimizedImageUrl({int? width, int? height, int quality = 80}) {
    if (!hasCloudinaryImage) return imageUrl;

    // Extract public ID from Cloudinary URL for optimization
    final uri = Uri.parse(imageUrl);
    if (uri.host.contains('cloudinary.com')) {
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 3) {
        final publicId = pathSegments.sublist(3).join('/');
        final cloudName = pathSegments[0]; // Should be the cloud name

        List<String> transformations = [];
        if (width != null) transformations.add('w_$width');
        if (height != null) transformations.add('h_$height');
        transformations.add('q_$quality');
        transformations.add('f_auto'); // Auto format selection
        transformations.add(
          'c_fill',
        ); // Fill mode for better aspect ratio handling

        String transformation = transformations.join(',');
        return 'https://res.cloudinary.com/$cloudName/image/upload/$transformation/$publicId';
      }
    }

    return imageUrl; // Return original if not a standard Cloudinary URL
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
      canPrepareInParallel: json['canPrepareInParallel'] as bool? ?? true,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt:
          json['deletedAt'] != null
              ? (json['deletedAt'] as Timestamp).toDate()
              : null,
    );
  }
}
