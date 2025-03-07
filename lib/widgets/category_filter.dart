import 'package:flutter/material.dart';
import '../theme.dart';

class CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final bool isDarkMode;
  final Function(String) onCategorySelected;

  const CategoryFilter({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    required this.isDarkMode,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = selectedCategory == categories[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ChoiceChip(
              label: Text(categories[index]),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onCategorySelected(categories[index]);
                }
              },
              backgroundColor:
                  isDarkMode ? AppTheme.cardColor : Colors.grey[200],
              selectedColor: Theme.of(context).primaryColor,
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            ),
          );
        },
      ),
    );
  }
}
