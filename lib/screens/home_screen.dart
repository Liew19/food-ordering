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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void filterItems(List<MenuItem> items, String query) {
    setState(() {
      if (query.isEmpty && selectedCategory == 'All') {
        filteredItems = items;
      } else {
        filteredItems =
            items.where((item) {
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

  void onCategorySelected(String category, List<MenuItem> menuItems) {
    setState(() {
      selectedCategory = category;
      filterItems(menuItems, searchController.text);
    });
  }

  void showMenuItemDetails(BuildContext context, MenuItem item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => MenuItemDetailDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
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
                  apiService.getMenuItems().then((menuItems) {
                    filterItems(menuItems, value);
                  });
                },
              ),
              Expanded(
                child: FutureBuilder<List<MenuItem>>(
                  future: apiService.getMenuItems(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: LoadingIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      final menuItems = snapshot.data!;

                      if (filteredItems.isEmpty && selectedCategory == 'All') {
                        filteredItems = menuItems;
                      }

                      final categories = [
                        'All',
                        ...{...menuItems.map((e) => e.category)},
                      ];

                      return Column(
                        children: [
                          CategoryFilter(
                            categories: categories,
                            selectedCategory: selectedCategory,
                            isDarkMode: isDarkMode,
                            onCategorySelected:
                                (category) =>
                                    onCategorySelected(category, menuItems),
                          ),
                          Expanded(
                            child: MenuGrid(
                              filteredItems: filteredItems,
                              onItemTap:
                                  (item) => showMenuItemDetails(context, item),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
