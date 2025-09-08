import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../widgets/image_upload_widget.dart';
import '../services/menu_service.dart';
import '../state/auth_provider.dart' as auth;

class ImageUploadExampleScreen extends StatefulWidget {
  const ImageUploadExampleScreen({super.key});

  @override
  State<ImageUploadExampleScreen> createState() =>
      _ImageUploadExampleScreenState();
}

class _ImageUploadExampleScreenState extends State<ImageUploadExampleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _preparationTimeController = TextEditingController();
  final MenuService _menuService = MenuService();

  String _selectedCategory = 'Main Course';
  String? _uploadedImageUrl;
  bool _isPopular = false;
  bool _canPrepareInParallel = true;
  bool _isLoading = false;

  final List<String> _categories = [
    'Main Course',
    'Appetizer',
    'Salad',
    'Dessert',
    'Beverage',
    'Soup',
    'Side Dish',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _preparationTimeController.dispose();
    super.dispose();
  }

  void _onImageUploaded(String imageUrl) {
    setState(() {
      _uploadedImageUrl = imageUrl;
    });
  }

  Future<void> _saveMenuItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_uploadedImageUrl == null || _uploadedImageUrl!.isEmpty) {
      _showErrorSnackBar('Please upload an image for the menu item');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final menuItem = MenuItem(
        id: '', // Will be set by Firestore for new items
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        category: _selectedCategory,
        itemId: 'item_${DateTime.now().millisecondsSinceEpoch}',
        imageUrl: _uploadedImageUrl!,
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        isPopular: _isPopular,
        preparationTime: double.parse(_preparationTimeController.text.trim()),
        canPrepareInParallel: _canPrepareInParallel,
      );

      await _menuService.createMenuItem(menuItem);
      _showSuccessSnackBar('Menu item created successfully!');

      // Reset form after successful creation
      _resetForm();
    } catch (e) {
      _showErrorSnackBar('Failed to save menu item: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    _nameController.clear();
    _priceController.clear();
    _descriptionController.clear();
    _preparationTimeController.clear();
    setState(() {
      _selectedCategory = 'Main Course';
      _uploadedImageUrl = null;
      _isPopular = false;
      _canPrepareInParallel = true;
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<auth.AppAuthProvider>(context);

    // Check if current user is admin
    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Menu Item'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 4.0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
        ),
        body: const Center(
          child: Text(
            'Access Denied. Admin privileges required.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Menu Item'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 4.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Upload Section
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Menu Item Image',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ImageUploadWidget(
                            onImageUploaded: _onImageUploaded,
                            initialImageUrl: _uploadedImageUrl,
                            folder: 'menu_items',
                            width: 250,
                            height: 200,
                            placeholder: 'Upload menu item image',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Basic Information Section
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Basic Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Name Field
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Item Name *',
                            hintText: 'Enter menu item name',
                            prefixIcon: Icon(Icons.restaurant_menu),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter item name';
                            }
                            if (value.trim().length < 2) {
                              return 'Item name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Price and Category Row
                        Row(
                          children: [
                            // Price Field
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _priceController,
                                decoration: const InputDecoration(
                                  labelText: 'Price (RM) *',
                                  hintText: '0.00',
                                  prefixIcon: Icon(Icons.attach_money),
                                  border: OutlineInputBorder(),
                                  prefixText: 'RM ',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter price';
                                  }
                                  final price = double.tryParse(value.trim());
                                  if (price == null || price <= 0) {
                                    return 'Enter valid price';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Category Dropdown
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration: const InputDecoration(
                                  labelText: 'Category *',
                                  prefixIcon: Icon(Icons.category),
                                  border: OutlineInputBorder(),
                                ),
                                items:
                                    _categories.map((category) {
                                      return DropdownMenuItem(
                                        value: category,
                                        child: Text(category),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategory = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Description Field
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Enter item description (optional)',
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          maxLength: 200,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Kitchen Information Section
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kitchen Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Preparation Time
                        TextFormField(
                          controller: _preparationTimeController,
                          decoration: const InputDecoration(
                            labelText: 'Preparation Time (minutes) *',
                            hintText: 'Enter preparation time',
                            prefixIcon: Icon(Icons.timer),
                            border: OutlineInputBorder(),
                            suffixText: 'min',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter preparation time';
                            }
                            final time = double.tryParse(value.trim());
                            if (time == null || time <= 0) {
                              return 'Enter valid preparation time';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Parallel Preparation Switch
                        SwitchListTile(
                          title: const Text('Can Prepare in Parallel'),
                          subtitle: const Text(
                            'Can this item be prepared alongside other items?',
                          ),
                          value: _canPrepareInParallel,
                          onChanged: (value) {
                            setState(() {
                              _canPrepareInParallel = value;
                            });
                          },
                          activeColor: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Marketing Section
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Marketing Options',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Popular Item Switch
                        SwitchListTile(
                          title: const Text('Mark as Popular'),
                          subtitle: const Text(
                            'Display this item as a popular choice',
                          ),
                          value: _isPopular,
                          onChanged: (value) {
                            setState(() {
                              _isPopular = value;
                            });
                          },
                          activeColor: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Save Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveMenuItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child:
                      _isLoading
                          ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Saving...'),
                            ],
                          )
                          : const Text(
                            'Create Menu Item',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
