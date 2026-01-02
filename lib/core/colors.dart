import 'package:flutter/material.dart';

class AppColors {
  // --- Background & Surfaces ---
  // The deep, near-black background of the app
  static const Color background = Color(0xFF0D0B14); 
  
  // The slightly lighter card/surface color
  static const Color surface = Color(0xFF1E1B29); 
  
  // Secondary surface for nested items or slightly different contrast
  static const Color surfaceLight = Color(0xFF2A263D);

  // --- Neon Green Accents (Replacing the Purple) ---
  // The main vibrant neon green
  static const Color primaryNeon = Color(0xFFB0FF38); 
  
  // A slightly darker green for gradients or less intense highlights
  static const Color primaryNeonDark = Color(0xFF76CC00);

  // --- Functional Colors ---
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color errorRed = Color(0xFFFF4B4B);

  // --- Gradients ---
  // Use this for the Floating Action Button or highlighted Tabs
  static const LinearGradient neonGradient = LinearGradient(
    colors: [Color.fromARGB(255, 157, 252, 14), Color.fromARGB(255, 97, 167, 0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Use this for the progress bars (like the Car Fund bar)
  static const LinearGradient progressGradient = LinearGradient(
    colors: [primaryNeon, Color(0xFF22FF00)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}