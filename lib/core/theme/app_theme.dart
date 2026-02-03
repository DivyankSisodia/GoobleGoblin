import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized theme configuration for the app
class AppTheme {
  // Private constructor
  AppTheme._();

  /// Get the dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryNeon,
        secondary: AppColors.primaryNeonDark,
        surface: AppColors.surface,
        error: AppColors.errorRed,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onError: Colors.white,
      ),

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // Text theme
      textTheme: _buildTextTheme(),

      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNeon,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryNeon,
          side: const BorderSide(color: AppColors.primaryNeon),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.primaryNeon.withValues(alpha: 0.5),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),

      // Bottom sheet theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryNeon,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.primaryNeon,
        labelStyle: GoogleFonts.montserrat(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.1),
        thickness: 1,
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryNeon,
      ),
    );
  }

  /// Build custom text theme
  static TextTheme _buildTextTheme() {
    return TextTheme(
      // Display styles
      displayLarge: GoogleFonts.montserrat(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      displayMedium: GoogleFonts.montserrat(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      displaySmall: GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),

      // Headline styles
      headlineLarge: GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineMedium: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      headlineSmall: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),

      // Title styles
      titleLarge: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleMedium: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleSmall: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),

      // Body styles
      bodyLarge: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: Colors.white,
      ),
      bodyMedium: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: Colors.white,
      ),
      bodySmall: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      ),

      // Label styles
      labelLarge: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      labelMedium: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      labelSmall: GoogleFonts.montserrat(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }
}

/// Updated AppColors with additional utility colors
class AppColors {
  // Private constructor
  AppColors._();

  // --- Background & Surfaces ---
  static const Color background = Color(0xFF0D0B14);
  static const Color surface = Color(0xFF1E1B29);
  static const Color surfaceLight = Color(0xFF2A263D);
  static const Color surfaceLighter = Color(0xFF3A3650);

  // --- Primary Neon Green ---
  static const Color primaryNeon = Color(0xFFB0FF38);
  static const Color primaryNeonDark = Color(0xFF76CC00);
  static const Color primaryNeonLight = Color(0xFFD4FF7A);

  // --- Accent Colors for Analytics ---
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentMagenta = Color(0xFFFF00E5);
  static const Color accentOrange = Color(0xFFFF8A00);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentTeal = Color(0xFF14B8A6);

  // --- Semantic Colors ---
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color errorRed = Color(0xFFFF4B4B);
  static const Color successGreen = Color(0xFF4ADE80);
  static const Color warningYellow = Color(0xFFFBBF24);
  static const Color infoBlue = Color(0xFF3B82F6);

  // --- Category Colors ---
  static const List<Color> categoryColors = [
    primaryNeon,
    accentCyan,
    accentMagenta,
    accentOrange,
    accentPurple,
    accentBlue,
    accentTeal,
    Color(0xFFEC4899), // Pink
    Color(0xFFF43F5E), // Rose
    Color(0xFF84CC16), // Lime
  ];

  // --- Heatmap Colors (for spending intensity) ---
  static const List<Color> heatmapColors = [
    Color(0xFF1E1B29), // Very low
    Color(0xFF2D3B3A), // Low
    Color(0xFF3D5A4C), // Medium-low
    Color(0xFF4D7A5E), // Medium
    Color(0xFF6B9B5A), // Medium-high
    Color(0xFF89BC56), // High
    Color(0xFFA7DD52), // Very high
    primaryNeon, // Maximum
  ];

  // --- Gradients ---
  static const LinearGradient neonGradient = LinearGradient(
    colors: [primaryNeon, primaryNeonDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient progressGradient = LinearGradient(
    colors: [primaryNeon, Color(0xFF22FF00)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [surfaceLight, surface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient analyticsGradient = LinearGradient(
    colors: [accentPurple, accentCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Get color for category by index
  static Color getCategoryColor(int index) {
    return categoryColors[index % categoryColors.length];
  }

  /// Get heatmap color based on intensity (0.0 to 1.0)
  static Color getHeatmapColor(double intensity) {
    intensity = intensity.clamp(0.0, 1.0);
    final index = (intensity * (heatmapColors.length - 1)).round();
    return heatmapColors[index];
  }

  /// Create gradient from two colors
  static LinearGradient createGradient(
    Color start,
    Color end, {
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry endAlignment = Alignment.bottomRight,
  }) {
    return LinearGradient(
      colors: [start, end],
      begin: begin,
      end: endAlignment,
    );
  }
}

/// Spacing constants
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Border radius constants
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double circular = 100;
}

/// Animation duration constants
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 400);
}
