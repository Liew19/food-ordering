import 'dart:io';
// 'dart:typed_data' elements are available via foundation
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/cloudinary_service.dart';

class ImageUploadWidget extends StatefulWidget {
  final Function(String imageUrl) onImageUploaded;
  final String? initialImageUrl;
  final String? folder;
  final double width;
  final double height;
  final String placeholder;

  const ImageUploadWidget({
    super.key,
    required this.onImageUploaded,
    this.initialImageUrl,
    this.folder,
    this.width = 200,
    this.height = 200,
    this.placeholder = 'Tap to upload image',
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService.instance;

  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  bool _showPreview = false; // New state to show preview mode

  @override
  void initState() {
    super.initState();
    _uploadedImageUrl = widget.initialImageUrl;
  }

  @override
  void didUpdateWidget(ImageUploadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImageUrl != oldWidget.initialImageUrl) {
      setState(() {
        _uploadedImageUrl = widget.initialImageUrl;
        // Also clear any preview state when the initial URL changes to null
        if (widget.initialImageUrl == null) {
          _selectedImage = null;
          _selectedImageBytes = null;
          _showPreview = false;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      // Show options dialog
      final source = await _showImageSourceDialog();
      if (source == null) return;

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          if (kIsWeb) {
            _selectedImageBytes = bytes;
            _selectedImage = null;
          } else {
            _selectedImage = File(pickedFile.path);
            _selectedImageBytes = null;
          }
          _showPreview = true; // Show preview instead of uploading immediately
          _isUploading = false;
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image: $e');
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmUpload() async {
    if (_selectedImage == null && _selectedImageBytes == null) return;

    setState(() {
      _isUploading = true;
      _showPreview = false;
    });

    try {
      String imageUrl;
      if (kIsWeb && _selectedImageBytes != null) {
        imageUrl = await _cloudinaryService.uploadImageBytes(
          _selectedImageBytes!,
          folder: widget.folder,
        );
      } else if (_selectedImage != null) {
        imageUrl = await _cloudinaryService.uploadImage(
          _selectedImage!,
          folder: widget.folder,
        );
      } else {
        throw Exception('No image selected');
      }

      setState(() {
        _uploadedImageUrl = imageUrl;
        _isUploading = false;
        _selectedImage = null;
        _selectedImageBytes = null;
      });

      widget.onImageUploaded(imageUrl);
    } catch (e) {
      setState(() {
        _isUploading = false;
        _showPreview = true; // Go back to preview mode on error
      });
      _showErrorDialog('Upload failed: $e');
    }
  }

  void _cancelUpload() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
      _showPreview = false;
    });
  }

  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildImageWidget() {
    // Web: Use Image.memory for bytes
    if (kIsWeb && _selectedImageBytes != null) {
      return Image.memory(
        _selectedImageBytes!,
        fit: BoxFit.cover,
        width: widget.width,
        height: widget.height,
      );
    }
    // Mobile: Use Image.file for file path
    else if (!kIsWeb && _selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        width: widget.width,
        height: widget.height,
      );
    }
    // Network image for uploaded images with caching
    else if (_uploadedImageUrl != null) {
      return CachedNetworkImage(
        imageUrl: _uploadedImageUrl!,
        fit: BoxFit.cover,
        width: widget.width,
        height: widget.height,
        placeholder:
            (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget:
            (context, url, error) => const Center(
              child: Icon(Icons.error, color: Colors.red, size: 50),
            ),
        memCacheWidth: (widget.width * 2).toInt(), // Optimize memory usage
        memCacheHeight: (widget.height * 2).toInt(),
      );
    }
    // Fallback error widget
    else {
      return const Center(
        child: Icon(Icons.error, color: Colors.red, size: 50),
      );
    }
  }

  Widget _buildImageDisplay() {
    if (_isUploading) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Uploading...'),
            ],
          ),
        ),
      );
    }

    // Show preview mode with confirm/cancel buttons
    if (_showPreview &&
        (_selectedImage != null || _selectedImageBytes != null)) {
      return Column(
        children: [
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImageWidget(),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Preview - Do you want to upload this image?',
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _cancelUpload,
                icon: const Icon(Icons.cancel, color: Colors.red),
                label: const Text('Cancel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.red,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _confirmUpload,
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text('Confirm Upload'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Show uploaded image
    if (_uploadedImageUrl != null) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImageWidget(),
        ),
      );
    }

    // Default placeholder
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              widget.placeholder,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // If in preview mode, don't make the image tappable
        _showPreview
            ? _buildImageDisplay()
            : GestureDetector(
              onTap: _isUploading ? null : _pickImage,
              child: _buildImageDisplay(),
            ),
        const SizedBox(height: 8),
        // Show "Change Image" button only if image is uploaded and not in preview mode
        if (_uploadedImageUrl != null && !_showPreview && !_isUploading)
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.edit),
            label: const Text('Change Image'),
          ),
      ],
    );
  }
}
