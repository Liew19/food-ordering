import 'package:flutter/material.dart';
import 'package:fyp/widgets/loading_indicator.dart';
import 'package:fyp/widgets/menu_grid.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart';
import '../state/theme_provider.dart';
import '../widgets/menu_app_bar.dart';
import '../widgets/menu_search_bar.dart';
import '../widgets/category_filter.dart';
import '../widgets/special_menu_carousel.dart';
import '../widgets/menu_item_detail_dialog.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();
  String selectedCategory = 'All';
  final TextEditingController searchController = TextEditingController();
  List<MenuItem> filteredItems = [];
  List<MenuItem> _allMenuItems = [];
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
      if (query.isEmpty && selectedCategory == 'All') {
        filteredItems = _allMenuItems;
      } else {
        filteredItems =
            _allMenuItems.where((item) {
              bool matchesSearch =
                  query.isEmpty ||
                  item.name.toLowerCase().contains(query.toLowerCase());
              bool matchesCategory =
                  selectedCategory == 'All' ||
                  item.category == selectedCategory;
              return matchesSearch && matchesCategory;
            }).toList();
      }
    });
  }

  void onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
      filterItems(searchController.text);
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            MenuAppBar(
              isDarkMode: isDarkMode,
              onThemeChanged: (isLightMode) {
                themeProvider.toggleTheme();
              },
            ),
          ];
        },
        body: Column(
          children: [
            MenuSearchBar(
              controller: searchController,
              onSearchChanged: (value) {
                filterItems(value);
              },
            ),
            Expanded(
              child:
                  _isLoading
                      ? Center(child: LoadingIndicator())
                      : _error != null
                      ? Center(child: Text('Error: $_error'))
                      : RefreshIndicator(
                        onRefresh: () async {
                          setState(() => _isLoading = true);
                          await _loadInitialData();
                        },
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              if (_allMenuItems.isNotEmpty) ...[
                                // Select featured menu items
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
                                  onItemTap: (item) {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) =>
                                              MenuItemDetailDialog(item: item),
                                    );
                                  },
                                ),
                                CategoryFilter(
                                  categories: [
                                    'All',
                                    ...{
                                      ..._allMenuItems.map((e) => e.category),
                                    },
                                  ],
                                  selectedCategory: selectedCategory,
                                  isDarkMode: isDarkMode,
                                  onCategorySelected: (category) {
                                    setState(() {
                                      selectedCategory = category;
                                      filterItems(searchController.text);
                                    });
                                  },
                                ),
                                MenuGrid(
                                  filteredItems: filteredItems,
                                  onItemTap: (item) {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) =>
                                              MenuItemDetailDialog(item: item),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
