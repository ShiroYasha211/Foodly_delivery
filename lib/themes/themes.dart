import 'package:flutter/material.dart';

class Themes {
  static final lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepOrange,
      primary: const Color(0xFFFE6E00), // برتقالي أكثر إشراقاً
      secondary: const Color(0xFFFF9E40), // برتقالي فاتح
      tertiary: const Color(0xFFFFD166), // أصفر برتقالي
      background: const Color(0xFFFAFAFA), // خلفية فاتحة ناعمة
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    useMaterial3: true,

    // تطوير AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 1,
      shadowColor: Colors.black12,
      surfaceTintColor: Colors.white,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        fontFamily: "Poppins",
      ),
      iconTheme: IconThemeData(color: Colors.black87, size: 24),
    ),

    // تحسين النصوص
    textTheme: TextTheme(
      displayLarge: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
        fontFamily: "Poppins",
      ),
      displayMedium: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        fontFamily: "Poppins",
      ),
      displaySmall: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        fontFamily: "Poppins",
      ),
      bodyLarge: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
        fontFamily: "OpenSans",
      ),
      bodyMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: Colors.black87,
        fontFamily: "OpenSans",
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: Colors.grey[700],
        fontFamily: "OpenSans",
      ),
      labelLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        fontFamily: "Poppins",
      ),
    ),

    // تحسين الأزرار
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(const Color(0xFFFE6E00)),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        textStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: "Poppins",
          ),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        elevation: WidgetStateProperty.all(0),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
        foregroundColor: WidgetStateProperty.all(const Color(0xFFFE6E00)),
        side: WidgetStateProperty.all(
          const BorderSide(color: Color(0xFFFE6E00), width: 1.5),
        ),
        textStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: "Poppins",
          ),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),

    // تحسين حقل الإدخال
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFE6E00), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(
        color: Colors.grey[500],
        fontSize: 16,
        fontFamily: "OpenSans",
      ),
      labelStyle: TextStyle(
        color: Colors.grey[700],
        fontSize: 16,
        fontFamily: "OpenSans",
      ),
    ),

    // تحسين البطاقات
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),

    // تحسين القوائم
    listTileTheme: ListTileThemeData(
      titleTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        fontFamily: "Poppins",
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: Colors.grey[700],
        fontFamily: "OpenSans",
      ),
      leadingAndTrailingTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFFFE6E00),
        fontFamily: "Poppins",
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      minLeadingWidth: 0,
      iconColor: const Color(0xFFFE6E00),
    ),

    dividerTheme: DividerThemeData(
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.grey[200],
      space: 24,
    ),

    iconTheme: const IconThemeData(size: 24, color: Colors.black87),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFFFE6E00),
      unselectedItemColor: Colors.grey[600],
      showUnselectedLabels: true,
      elevation: 4,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: "Poppins",
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: "Poppins",
      ),
    ),

    // تأثيرات الظل
    shadowColor: Colors.black12,

    // تأثيرات أخرى
    splashColor: const Color(0x15FE6E00),
    highlightColor: const Color(0x0FFE6E00),
  );
}
