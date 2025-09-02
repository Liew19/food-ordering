import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fyp/services/api_service.dart';
import 'package:fyp/models/menu_item.dart';
import 'package:fyp/screens/create_menu_item_screen.dart';
import 'package:fyp/state/auth_provider.dart' as auth;

class AdminMenuManagementScreen extends StatefulWidget {
  const AdminMenuManagementScreen({super.key});

  @override
  State<AdminMenuManagementScreen> createState() =>
      _AdminMenuManagementScreenState();
}

class _AdminMenuManagementScreenState extends State<AdminMenuManagementScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<MenuItem> _activeMenuItems = [];
  List<MenuItem> _deletedMenuItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategoryFilter = 'all';
  late TabController _tabController;

  List<String> _categories = ['all'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMenuItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMenuItems() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final activeItems = await _apiService.getMenuItems();
      final deletedItems = await _apiService.getDeletedMenuItems();

      // Extract unique categories from all menu items
      _updateCategories(activeItems, deletedItems);

      setState(() {
        _activeMenuItems = activeItems;
        _deletedMenuItems = deletedItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading menu items: $e')));
      }
    }
  }

  void _updateCategories(
    List<MenuItem> activeItems,
    List<MenuItem> deletedItems,
  ) {
    // Combine all items to get all possible categories
    final allItems = [...activeItems, ...deletedItems];

    // Extract unique categories
    final Set<String> uniqueCategories = {'all'};
    for (final item in allItems) {
      if (item.category.isNotEmpty) {
        uniqueCategories.add(item.category);
      }
    }

    // Sort categories alphabetically (except 'all' which stays first)
    final sortedCategories = uniqueCategories.toList();
    sortedCategories.remove('all');
    sortedCategories.sort();
    sortedCategories.insert(0, 'all');

    // Reset selected category if it no longer exists
    if (!sortedCategories.contains(_selectedCategoryFilter)) {
      _selectedCategoryFilter = 'all';
    }

    _categories = sortedCategories;
  }

  Future<void> _refreshMenuItems() async {
    await _loadMenuItems();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menu items and categories refreshed successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  List<MenuItem> _getFilteredItems(List<MenuItem> items) {
    return items.where((item) {
      final matchesSearch =
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.description?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);
      final matchesCategory =
          _selectedCategoryFilter == 'all' ||
          item.category == _selectedCategoryFilter;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> _softDeleteItem(MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Move to Deleted Items'),
            content: Text(
              'Are you sure you want to move "${item.name}" to deleted items? You can restore it later from the Deleted tab.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                child: const Text('Move to Deleted'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteMenuItem(item.id);
        await _loadMenuItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} moved to deleted items'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () => _restoreItem(item),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting item: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _restoreItem(MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Restore Menu Item'),
            content: Text(
              'Are you sure you want to restore "${item.name}" back to active menu items?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: const Text('Restore'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _apiService.restoreMenuItem(item.id);
        await _loadMenuItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} restored successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error restoring item: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _permanentlyDeleteItem(MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Permanently Delete Item'),
            content: Text(
              'Are you sure you want to permanently delete "${item.name}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete Permanently'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _apiService.permanentlyDeleteMenuItem(item.id);
        await _loadMenuItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} permanently deleted'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting item: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToCreateItem({MenuItem? existingItem}) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder:
                (context) => CreateMenuItemScreen(existingItem: existingItem),
          ),
        )
        .then((_) => _loadMenuItems());
  }

  Future<void> _confirmEditItem(MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Menu Item'),
            content: Text('Do you want to edit "${item.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
                child: const Text('Edit'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      _navigateToCreateItem(existingItem: item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<auth.AppAuthProvider>(context);

    // Check if current user is admin
    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Menu Management'),
          backgroundColor: const Color(0xFFE53935),
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
        title: const Text('Menu Management'),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        elevation: 4.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _refreshMenuItems,
            icon:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh menu items',
            splashColor: Colors.white.withOpacity(0.3),
            highlightColor: Colors.white.withOpacity(0.2),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateItem(),
        backgroundColor: const Color(0xFFE53935),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search menu items...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Category Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        _categories.map((category) {
                          final isSelected =
                              _selectedCategoryFilter == category;

                          // Count items in this category
                          final allItems = [
                            ..._activeMenuItems,
                            ..._deletedMenuItems,
                          ];
                          final categoryCount =
                              category == 'all'
                                  ? allItems.length
                                  : allItems
                                      .where(
                                        (item) => item.category == category,
                                      )
                                      .length;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                category == 'all'
                                    ? 'All ($categoryCount)'
                                    : '$category ($categoryCount)',
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategoryFilter = category;
                                });
                              },
                              selectedColor: const Color(
                                0xFFE53935,
                              ).withOpacity(0.2),
                              checkmarkColor: const Color(0xFFE53935),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFE53935),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFE53935),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.restaurant_menu),
                    const SizedBox(width: 8),
                    Text(
                      'Active (${_getFilteredItems(_activeMenuItems).length})',
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.delete_outline),
                    const SizedBox(width: 8),
                    Text(
                      'Deleted (${_getFilteredItems(_deletedMenuItems).length})',
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Tab Content
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildActiveItemsList(),
                        _buildDeletedItemsList(),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveItemsList() {
    final filteredItems = _getFilteredItems(_activeMenuItems);

    if (filteredItems.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshMenuItems,
        child: const Center(child: Text('No active menu items found')),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshMenuItems,
      child: ListView.builder(
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          return _buildMenuItemCard(item, isActive: true);
        },
      ),
    );
  }

  Widget _buildDeletedItemsList() {
    final filteredItems = _getFilteredItems(_deletedMenuItems);

    if (filteredItems.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshMenuItems,
        child: const Center(child: Text('No deleted menu items')),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshMenuItems,
      child: ListView.builder(
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          return _buildMenuItemCard(item, isActive: false);
        },
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item, {required bool isActive}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            item.getOptimizedImageUrl(width: 60, height: 60),
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder:
                (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.restaurant),
                ),
          ),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.black : Colors.grey,
            decoration: isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RM ${item.price.toStringAsFixed(2)}'),
            Text(item.category),
            if (!isActive && item.deletedAt != null)
              Text(
                'Deleted: ${item.deletedAt!.toLocal().toString().split(' ')[0]}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _confirmEditItem(item);
                break;
              case 'delete':
                _softDeleteItem(item);
                break;
              case 'restore':
                _restoreItem(item);
                break;
              case 'permanent_delete':
                _permanentlyDeleteItem(item);
                break;
            }
          },
          itemBuilder: (context) {
            if (isActive) {
              return [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Move to Deleted'),
                    ],
                  ),
                ),
              ];
            } else {
              return [
                const PopupMenuItem(
                  value: 'restore',
                  child: Row(
                    children: [
                      Icon(Icons.restore, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Restore'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'permanent_delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Permanently'),
                    ],
                  ),
                ),
              ];
            }
          },
        ),
      ),
    );
  }
}
