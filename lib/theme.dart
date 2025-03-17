import 'package:flutter/material.dart';

class AppTheme {
  // Main color palette
  static const Color primaryColor = Color.fromARGB(255, 12, 7, 0); // Orange
  static const Color primaryDarkColor = Color(0xFFFF5722); // Dark orange
  static const Color accentColor = Color.fromARGB(
    255,
    28,
    9,
    3,
  ); // Accent color

  // Background colors
  static const Color backgroundColor = Color(0xFF212121); // Dark gray
  static const Color backgroundLightColor = Colors.white; // White

  // Text colors
  static const Color textDarkColor = Color.fromARGB(255, 0, 0, 0); // White text
  static const Color textLightColor = Color(0xFF212121); // Dark gray text
  static const Color textMutedColor = Color(0xFFBDBDBD); // Light gray text

  // Shadow colors
  static final Color shadowColor = primaryColor.withOpacity(0.4);
  static final Color darkShadowColor = Colors.black.withOpacity(0.2);

  // Card colors
  static final Color cardColor = Colors.white.withOpacity(0.05);
  static const Color cardLightColor = Colors.white;

  // Button styles
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: const Color.fromARGB(255, 255, 255, 255),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    padding: const EdgeInsets.symmetric(vertical: 16),
    elevation: 5,
    shadowColor: shadowColor,
  );

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryDarkColor],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white, Color(0xFF212121)],
  );

  // Application theme
  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: primaryColor,
      primaryColorDark: primaryDarkColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        background: backgroundColor,
        surface: cardColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textDarkColor),
        titleTextStyle: TextStyle(
          color: textDarkColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: textDarkColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: textDarkColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: textDarkColor, fontSize: 16),
        bodyMedium: TextStyle(color: textMutedColor, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 20,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      // Dialog theme settings
      dialogTheme: DialogTheme(
        backgroundColor: Color(0xFF333333),
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        titleTextStyle: TextStyle(
          color: textDarkColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(color: textDarkColor, fontSize: 16),
      ),
      // Ensure AlertDialog uses correct colors
      dialogBackgroundColor: Color(0xFF333333),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.all(primaryColor),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: backgroundColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textMutedColor,
      ),
      // Bottom sheet colors
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: backgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
      ),
    );
  }

  // Light theme (if needed)
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      primaryColorDark: primaryDarkColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        background: Colors.white,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textDarkColor),
        titleTextStyle: TextStyle(
          color: textDarkColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: textDarkColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: textDarkColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: textDarkColor, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.grey, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
      cardTheme: CardTheme(
        color: cardLightColor,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[600],
      ),
    );
  }

  // Helper method: Create gradient button
  static Container gradientButton({
    required String text,
    required VoidCallback onTap,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: primaryGradient,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method: Create gradient app bar
  static PreferredSizeWidget gradientAppBar({
    required String title,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
    double? toolbarHeight,
    bool automaticallyImplyLeading = true,
  }) {
    return AppBar(
      title: Text(title),
      actions: actions,
      bottom: bottom,
      toolbarHeight: toolbarHeight,
      automaticallyImplyLeading: automaticallyImplyLeading,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: primaryGradient),
      ),
    );
  }

  // Helper method: Create background decoration
  static BoxDecoration get backgroundDecoration {
    return const BoxDecoration(gradient: backgroundGradient);
  }

  // Helper method: Create semi-transparent container decoration
  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
    );
  }

  // Helper method: Create bottom sheet decoration
  static BoxDecoration get bottomSheetDecoration {
    return BoxDecoration(
      color: cardColor,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      boxShadow: [
        BoxShadow(
          color: darkShadowColor,
          blurRadius: 20,
          offset: const Offset(0, -5),
        ),
      ],
    );
  }
}
