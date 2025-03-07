import 'package:flutter/material.dart';
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
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ThemeLightBulb(
            onThemeChanged: onThemeChanged,
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
    );
  }
}
