import 'package:flutter/material.dart';
import 'package:fyp/theme.dart';
import '../theme_mode/light_bulb.dart';

class MenuAppBar extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const MenuAppBar({
    Key? key,
    required this.isDarkMode,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      pinned: true,
      elevation: 8,
      backgroundColor:
          Theme.of(
            context,
          ).primaryColor, // Use theme primary color instead of transparent
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: FlexibleSpaceBar(
          title: const Text(
            'Menu',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: AppTheme.textDarkColor, // Using theme text color
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 3.0,
                  color: Color.fromARGB(80, 0, 0, 0),
                ),
              ],
            ),
          ),
          centerTitle: true, // Center the title for better aesthetics
          background: const DecoratedBox(
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0), // Increased padding
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.darkShadowColor,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ThemeLightBulb(
              onThemeChanged: onThemeChanged,
              initialState: isDarkMode,
            ),
          ),
        ),
      ],
    );
  }
}
