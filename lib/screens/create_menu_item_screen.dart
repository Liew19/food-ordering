import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../widgets/image_upload_widget.dart';
import '../services/menu_service.dart';
import '../state/auth_provider.dart' as auth;

class CreateMenuItemScreen extends StatefulWidget {
  final MenuItem? existingItem; // For editing existing items

  const CreateMenuItemScreen({Key? key, this.existingItem}) : super(key: key);

  @override
  State<CreateMenuItemScreen> createState() => _CreateMenuItemScreenState();
}

class _CreateMenuItemScreenState extends State<CreateMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _preparationTimeController = TextEditingController();
  final MenuService _menuService = MenuService();

  // State management with ValueNotifier for better performance
  final ValueNotifier<String> _selectedCategoryNotifier = ValueNotifier(
    'Main Course',
  );
  final ValueNotifier<String?> _uploadedImageUrlNotifier = ValueNotifier(null);
  final ValueNotifier<bool> _isPopularNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _canPrepareInParallelNotifier = ValueNotifier(true);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);

  static const List<String> _categories = [
    'Main Course',
    'Appetizer',
    'Salad',
    'Dessert',
    'Beverage',
    'Soup',
    'Side Dish',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _nameController.text = item.name;
      _priceController.text = item.price.toString();
      _descriptionController.text = item.description ?? '';
      _preparationTimeController.text = item.preparationTime.toString();
      _selectedCategoryNotifier.value = item.category;
      _uploadedImageUrlNotifier.value = item.imageUrl;
      _isPopularNotifier.value = item.isPopular;
      _canPrepareInParallelNotifier.value = item.canPrepareInParallel;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _preparationTimeController.dispose();
    _selectedCategoryNotifier.dispose();
    _uploadedImageUrlNotifier.dispose();
    _isPopularNotifier.dispose();
    _canPrepareInParallelNotifier.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  void _onImageUploaded(String imageUrl) {
    _uploadedImageUrlNotifier.value = imageUrl;
  }

  Future<void> _saveMenuItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_uploadedImageUrlNotifier.value == null ||
        _uploadedImageUrlNotifier.value!.isEmpty) {
      _showErrorSnackBar('Please upload an image for the menu item');
      return;
    }

    _isLoadingNotifier.value = true;

    try {
      final menuItem = MenuItem(
        id:
            widget.existingItem?.id ??
            '', // Will be set by Firestore for new items
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        category: _selectedCategoryNotifier.value,
        itemId:
            widget.existingItem?.itemId ??
            'item_${DateTime.now().millisecondsSinceEpoch}',
        imageUrl:
            _uploadedImageUrlNotifier
                .value!, // Cloudinary URL from image upload
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        isPopular: _isPopularNotifier.value,
        preparationTime: double.parse(_preparationTimeController.text.trim()),
        canPrepareInParallel: _canPrepareInParallelNotifier.value,
      );

      String documentId;

      if (widget.existingItem != null) {
        // Update existing menu item
        await _menuService.updateMenuItem(widget.existingItem!.id, menuItem);
        documentId = widget.existingItem!.id;
        _showSuccessSnackBar('Menu item updated successfully!');
      } else {
        // Create new menu item
        documentId = await _menuService.createMenuItem(menuItem);
        _showSuccessSnackBar('Menu item created successfully!');
      }

      // Create updated menu item with the document ID
      final savedMenuItem = MenuItem(
        id: documentId,
        name: menuItem.name,
        price: menuItem.price,
        category: menuItem.category,
        itemId: menuItem.itemId,
        imageUrl: menuItem.imageUrl,
        description: menuItem.description,
        isPopular: menuItem.isPopular,
        preparationTime: menuItem.preparationTime,
        canPrepareInParallel: menuItem.canPrepareInParallel,
      );

      // Navigate back after a short delay
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop(savedMenuItem);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save menu item: ${e.toString()}');
    } finally {
      _isLoadingNotifier.value = false;
    }
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
          title: Text(
            widget.existingItem != null ? 'Edit Menu Item' : 'Create Menu Item',
          ),
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
        title: Text(
          widget.existingItem != null ? 'Edit Menu Item' : 'Create Menu Item',
        ),
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
              Theme.of(context).primaryColor.withOpacity(0.1),
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
                          child: ValueListenableBuilder<String?>(
                            valueListenable: _uploadedImageUrlNotifier,
                            builder: (context, uploadedImageUrl, child) {
                              return ImageUploadWidget(
                                onImageUploaded: _onImageUploaded,
                                initialImageUrl: uploadedImageUrl,
                                folder: 'menu_items',
                                width: 250,
                                height: 200,
                                placeholder: 'Upload menu item image',
                              );
                            },
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
                              child: ValueListenableBuilder<String>(
                                valueListenable: _selectedCategoryNotifier,
                                builder: (context, selectedCategory, child) {
                                  return DropdownButtonFormField<String>(
                                    value: selectedCategory,
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
                                      _selectedCategoryNotifier.value = value!;
                                    },
                                  );
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
                        ValueListenableBuilder<bool>(
                          valueListenable: _canPrepareInParallelNotifier,
                          builder: (context, canPrepareInParallel, child) {
                            return SwitchListTile(
                              title: const Text('Can Prepare in Parallel'),
                              subtitle: const Text(
                                'Can this item be prepared alongside other items?',
                              ),
                              value: canPrepareInParallel,
                              onChanged: (value) {
                                _canPrepareInParallelNotifier.value = value;
                              },
                              activeColor: Theme.of(context).primaryColor,
                            );
                          },
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
                        ValueListenableBuilder<bool>(
                          valueListenable: _isPopularNotifier,
                          builder: (context, isPopular, child) {
                            return SwitchListTile(
                              title: const Text('Mark as Popular'),
                              subtitle: const Text(
                                'Display this item as a popular choice',
                              ),
                              value: isPopular,
                              onChanged: (value) {
                                _isPopularNotifier.value = value;
                              },
                              activeColor: Theme.of(context).primaryColor,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Save Button
                ValueListenableBuilder<bool>(
                  valueListenable: _isLoadingNotifier,
                  builder: (context, isLoading, child) {
                    return ElevatedButton(
                      onPressed: isLoading ? null : _saveMenuItem,
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
                          isLoading
                              ? const _LoadingButtonContent()
                              : _SaveButtonText(
                                existingItem: widget.existingItem,
                              ),
                    );
                  },
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

// Extracted const widgets for better performance
class _LoadingButtonContent extends StatelessWidget {
  const _LoadingButtonContent();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        SizedBox(width: 12),
        Text('Saving...'),
      ],
    );
  }
}

class _SaveButtonText extends StatelessWidget {
  const _SaveButtonText({required this.existingItem});

  final MenuItem? existingItem;

  @override
  Widget build(BuildContext context) {
    return Text(
      existingItem != null ? 'Update Menu Item' : 'Create Menu Item',
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
