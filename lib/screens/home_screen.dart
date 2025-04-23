import 'package:flutter/material.dart';
import 'package:fyp/widgets/loading_indicator.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart';
import '../widgets/special_menu_carousel.dart';
import '../widgets/menu_item_detail_dialog.dart';
import '../widgets/food_app_bar.dart';
import '../widgets/menu_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();
  String? selectedCategory;
  final TextEditingController searchController = TextEditingController();
  List<MenuItem> filteredItems = [];
  List<MenuItem> _allMenuItems = [];
  List<String> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final items = await apiService.getMenuItems();
      if (mounted) {
        setState(() {
          _allMenuItems = items;
          _categories = items.map((item) => item.category).toSet().toList();
          selectedCategory = _categories.isNotEmpty ? _categories.first : null;
          filteredItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void filterItems(String query) {
    setState(() {
      filteredItems =
          _allMenuItems.where((item) {
            bool matchesSearch =
                query.isEmpty ||
                item.name.toLowerCase().contains(query.toLowerCase());
            bool matchesCategory =
                selectedCategory == null || item.category == selectedCategory;
            return matchesSearch && matchesCategory;
          }).toList();
    });
  }

  void showMenuItemDetails(BuildContext context, MenuItem item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => MenuItemDetailDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: FoodAppBar(
        searchController: searchController,
        onSearchChanged: filterItems,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadInitialData,
          child:
              _isLoading
                  ? Center(child: LoadingIndicator())
                  : _error != null
                  ? Center(child: Text('Error: $_error'))
                  : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Categories
                        Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 8),
                          height: 48,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected = category == selectedCategory;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedCategory = category;
                                      filterItems(searchController.text);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? const Color(
                                                0xFFE53935,
                                              ) // Changed from blue to red
                                              : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? const Color(
                                                  0xFFE53935,
                                                ) // Changed from blue to red
                                                : Colors.black12,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Special Menu Carousel
                        if (_allMenuItems.isNotEmpty) ...[
                          SpecialMenuCarousel(
                            specialMenus:
                                _allMenuItems
                                    .where(
                                      (item) =>
                                          item.price >=
                                              30 || // Higher priced items
                                          item.category ==
                                              'Main Course', // Main courses
                                    )
                                    .take(5)
                                    .toList(),
                            onItemTap:
                                (item) => showMenuItemDetails(context, item),
                          ),
                        ],

                        // Category Title
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            selectedCategory ?? 'All Categories',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        // Menu Grid
                        MenuGrid(
                          filteredItems: filteredItems,
                          onItemTap:
                              (item) => showMenuItemDetails(context, item),
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
