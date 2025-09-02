import 'dart:io';
import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  late final CloudinaryPublic _cloudinary;
  static CloudinaryService? _instance;

  // Singleton pattern
  CloudinaryService._internal() {
    _initializeCloudinary();
  }

  static CloudinaryService get instance {
    _instance ??= CloudinaryService._internal();
    return _instance!;
  }

  void _initializeCloudinary() {
    String cloudName = 'dvzozrfyv'; // Default cloud name
    String uploadPreset = 'food-menu'; // Default upload preset

    // Try to get values from environment variables if available
    try {
      cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? cloudName;
      uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? uploadPreset;
    } catch (e) {
      // Silently use defaults if environment variables are not available
    }

    _cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);
  }

  /// Upload an image file to Cloudinary
  ///
  /// [file] - The image file to upload
  /// [folder] - Optional folder name in Cloudinary (e.g., 'menu_items', 'profiles')
  /// [publicId] - Optional public ID for the uploaded image
  ///
  /// Returns the secure URL of the uploaded image
  Future<String> uploadImage(
    File file, {
    String? folder,
    String? publicId,
  }) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
          folder: folder,
          publicId: publicId,
        ),
      );

      if (response.secureUrl.isNotEmpty) {
        return response.secureUrl;
      } else {
        throw Exception('Upload successful but no URL returned');
      }
    } on CloudinaryException catch (e) {
      throw CloudinaryUploadException('Cloudinary upload failed: ${e.message}');
    } catch (e) {
      throw CloudinaryUploadException('Unexpected error during upload: $e');
    }
  }

  /// Upload image bytes to Cloudinary (for web compatibility)
  ///
  /// [bytes] - The image bytes to upload
  /// [folder] - Optional folder name in Cloudinary (e.g., 'menu_items', 'profiles')
  /// [publicId] - Optional public ID for the uploaded image
  /// [fileName] - Optional filename for the uploaded image
  ///
  /// Returns the secure URL of the uploaded image
  Future<String> uploadImageBytes(
    Uint8List bytes, {
    String? folder,
    String? publicId,
    String fileName = 'image.jpg',
  }) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          bytes,
          resourceType: CloudinaryResourceType.Image,
          folder: folder,
          publicId: publicId,
          identifier: fileName,
        ),
      );

      if (response.secureUrl.isNotEmpty) {
        return response.secureUrl;
      } else {
        throw Exception('Upload successful but no URL returned');
      }
    } on CloudinaryException catch (e) {
      throw CloudinaryUploadException('Cloudinary upload failed: ${e.message}');
    } catch (e) {
      throw CloudinaryUploadException('Unexpected error during upload: $e');
    }
  }

  /// Upload multiple images to Cloudinary
  ///
  /// [files] - List of image files to upload
  /// [folder] - Optional folder name in Cloudinary
  ///
  /// Returns a list of secure URLs of the uploaded images
  Future<List<String>> uploadMultipleImages(
    List<File> files, {
    String? folder,
  }) async {
    List<String> urls = [];

    for (File file in files) {
      try {
        String url = await uploadImage(file, folder: folder);
        urls.add(url);
      } catch (e) {
        // Continue uploading other images even if one fails
        rethrow; // Re-throw to let caller handle the error
      }
    }

    return urls;
  }

  /// Delete an image from Cloudinary
  /// Note: Image deletion requires server-side implementation with Cloudinary Admin API
  /// This method is a placeholder for future implementation
  ///
  /// [publicId] - The public ID of the image to delete
  Future<void> deleteImage(String publicId) async {
    // Note: The cloudinary_public package doesn't support deletion
    // You would need to implement this on your backend using the Cloudinary Admin API
    throw UnimplementedError(
      'Image deletion requires server-side implementation with Cloudinary Admin API',
    );
  }

  /// Get optimized URL for an image with transformations
  ///
  /// [publicId] - The public ID of the image
  /// [width] - Desired width
  /// [height] - Desired height
  /// [quality] - Image quality (1-100)
  /// [cloudName] - Your Cloudinary cloud name
  ///
  /// Returns the transformed image URL
  String getOptimizedImageUrl(
    String publicId,
    String cloudName, {
    int? width,
    int? height,
    int quality = 80,
  }) {
    List<String> transformations = [];

    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    transformations.add('q_$quality');
    transformations.add('f_auto'); // Auto format selection

    String transformation = transformations.join(',');

    return 'https://res.cloudinary.com/$cloudName/image/upload/$transformation/$publicId';
  }
}

/// Custom exception for Cloudinary upload errors
class CloudinaryUploadException implements Exception {
  final String message;

  CloudinaryUploadException(this.message);

  @override
  String toString() => 'CloudinaryUploadException: $message';
}
