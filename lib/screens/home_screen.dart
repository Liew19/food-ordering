import 'package:flutter/material.dart';
import 'package:fyp/theme.dart';
import 'package:fyp/widgets/loading_indicator.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart';
import '../state/cart_provider.dart';
import '../state/theme_provider.dart';
import '../theme_mode/light_bulb.dart';

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

  @override
  Widget build(BuildContext context) {
    // Get the theme mode from ThemeProvider

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                pinned: true,
                elevation: 0,
                backgroundColor: Theme.of(context).primaryColor,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ThemeLightBulb(
                      onThemeChanged: (isLightMode) {
                        themeProvider.toggleTheme();
                      },
                      initialState: isDarkMode,
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Menu',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search Menu Item...',
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    apiService.getMenuItems().then((menuItems) {
                      filterItems(menuItems, value);
                    });
                  },
                ),
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
                          Container(
                            height: 50,
                            margin: const EdgeInsets.only(bottom: 8.0),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final isSelected =
                                    selectedCategory == categories[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: ChoiceChip(
                                    label: Text(categories[index]),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        selectedCategory = categories[index];
                                        filterItems(
                                          menuItems,
                                          searchController.text,
                                        );
                                      });
                                    },
                                    backgroundColor:
                                        isDarkMode
                                            ? AppTheme.cardColor
                                            : Colors.grey[200],
                                    selectedColor:
                                        Theme.of(context).primaryColor,
                                    labelStyle: TextStyle(
                                      color:
                                          isSelected
                                              ? isDarkMode
                                                  ? AppTheme.textDarkColor
                                                  : Colors.white
                                              : isDarkMode
                                              ? AppTheme.textDarkColor
                                              : AppTheme.textLightColor,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: _calculateCrossAxisCount(
                                        context,
                                      ),
                                      childAspectRatio: 0.8,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                itemCount: filteredItems.length,
                                itemBuilder: (context, index) {
                                  final item = filteredItems[index];
                                  return _buildMenuItemCard(context, item);
                                },
                              ),
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
  // In different screen sizes, adjust the number of columns in GridView.builder

  int _calculateCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return 5;
    } else if (width > 900) {
      return 4;
    } else if (width > 600) {
      return 3;
    } else {
      return 2;
    }
  }

  Widget _buildMenuItemCard(BuildContext context, MenuItem item) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image container
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Image.network(
                  item.imageUrl,
                  height: isDesktop ? 140 : 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: isDesktop ? 140 : 100,
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: isDesktop ? 40 : 30,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Image Error!',
                              style: TextStyle(
                                fontSize: isDesktop ? 14 : 12,
                                color:
                                    isDarkMode
                                        ? AppTheme.textDarkColor
                                        : AppTheme.textLightColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dish name
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: isDesktop ? 16 : 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2),
                  // Price
                  Text(
                    'RM ${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: isDesktop ? 14 : 12,
                    ),
                  ),

                  // Preparation time
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: isDesktop ? 14 : 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      SizedBox(width: isDesktop ? 4 : 2),
                      Text(
                        "${item.preparationTime}min",
                        style: TextStyle(
                          fontSize: isDesktop ? 12 : 10,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),
                  // Add to cart button
                  SizedBox(
                    width: double.infinity,
                    height: isDesktop ? 36 : 30,
                    child: ElevatedButton(
                      onPressed: () {
                        Provider.of<CartProvider>(
                          context,
                          listen: false,
                        ).addToCart(item);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Added ${item.name} to cart!',
                              style: TextStyle(
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                              ),
                            ),
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[800]
                                    : Colors.white,
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        );
                      },
                      // ElevatedButton theme customization
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_shopping_cart,
                            size: isDesktop ? 18 : 16,
                            color: Colors.white,
                          ),
                          if (isDesktop) ...[
                            const SizedBox(width: 4),
                            const Text(
                              'Add to Cart',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
