import 'package:flutter/material.dart';
import 'package:fyp/theme.dart';

class AdvancedMenuAppBar extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final String title;
  final List<Widget>? extraActions;

  const AdvancedMenuAppBar({
    Key? key,
    required this.isDarkMode,
    required this.onThemeChanged,
    this.title = 'Menu',
    this.extraActions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      elevation: 0, // No elevation as we're using custom shadows
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBarSettings(
        toolbarOpacity: 1.0,
        minExtent: kToolbarHeight,
        maxExtent: 140,
        currentExtent: 140,
        child: Stack(
          children: [
            // Background gradient layer
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
              ),
            ),

            // Decorative pattern layer - adds subtle texture
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: Image.asset(
                  'assets/images/pattern.png', // You'll need to add this asset
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Bottom shadow layer
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 20,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppTheme.darkShadowColor.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            FlexibleSpaceBar(
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: 0.5,
                  color: AppTheme.textDarkColor,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 4.0,
                      color: Color.fromARGB(100, 0, 0, 0),
                    ),
                  ],
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
          ],
        ),
      ),
      actions: [
        // Optional extra actions
        if (extraActions != null) ...extraActions!,

        // Theme toggle with enhanced styling
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: _buildThemeToggle(),
        ),
      ],
    );
  }

  Widget _buildThemeToggle() {
    return Builder(
      builder: (context) {
        return Hero(
          tag: 'theme_toggle', // Enables animation between screens
          child: Container(
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? AppTheme.cardColor
                      : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.darkShadowColor,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(4),
            child: Material(color: Colors.transparent),
          ),
        );
      },
    );
  }
}

// Optional extension for advanced menu items
class GradientMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isActive;

  const GradientMenuItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: isActive ? AppTheme.primaryGradient : null,
        color: isActive ? null : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isActive ? AppTheme.shadowColor : AppTheme.darkShadowColor,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppTheme.primaryColor.withOpacity(0.3),
          highlightColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color:
                      isActive ? AppTheme.textDarkColor : AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color:
                        isActive
                            ? AppTheme.textDarkColor
                            : AppTheme.textLightColor,
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color:
                      isActive
                          ? AppTheme.textDarkColor.withOpacity(0.7)
                          : AppTheme.textMutedColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
