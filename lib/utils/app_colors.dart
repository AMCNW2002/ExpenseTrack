// utils/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // ==========================================
  // PRIMARY COLORS (App එකේ main colors)
  // ==========================================
  static const Color primaryPurple =
      Color(0xFF6B4EFF); // Main purple (buttons, headers)
  static const Color primaryPurpleDark =
      Color(0xFF5A3FE0); // Darker purple (pressed states)
  static const Color primaryPurpleLight =
      Color(0xFF8B72FF); // Lighter purple (gradients)
  static const Color secondaryPurple =
      Color(0xFFEDE9FF); // Very light purple (backgrounds)

  // ==========================================
  // BACKGROUND COLORS
  // ==========================================
  static const Color background = Color(0xFFF8F9FD); // Main scaffold background
  static const Color cardWhite = Color(0xFFFFFFFF); // Card backgrounds
  static const Color splashBackground =
      Color(0xFF6B4EFF); // Splash screen background

  // ==========================================
  // TEXT COLORS
  // ==========================================
  static const Color textDark = Color(0xFF1E1E2D); // Main headings
  static const Color textMedium = Color(0xFF4A4A68); // Sub headings
  static const Color textLight = Color(0xFF8A8AA3); // Labels, hints
  static const Color textWhite = Color(0xFFFFFFFF); // Text on dark backgrounds

  // ==========================================
  // STATUS COLORS
  // ==========================================
  static const Color success = Color(0xFF00C853); // Green (income, positive)
  static const Color error =
      Color(0xFFFF5252); // Red (expense, delete, negative)
  static const Color warning = Color(0xFFFFA726); // Orange (budget warning)
  static const Color info = Color(0xFF29B6F6); // Blue (info messages)

  // ==========================================
  // CATEGORY COLORS (Expense categories සඳහා)
  // ==========================================
  static const Color categoryFood = Color(0xFFFF6B6B); // Food - Red/Pink
  static const Color categoryTransport = Color(0xFF4ECDC4); // Transport - Teal
  static const Color categoryShopping = Color(0xFFFFB84D); // Shopping - Orange
  static const Color categoryBills = Color(0xFF6B4EFF); // Bills - Purple
  static const Color categoryHealth = Color(0xFF00C853); // Health - Green
  static const Color categoryEducation = Color(0xFF29B6F6); // Education - Blue
  static const Color categoryEntertainment =
      Color(0xFFE91E63); // Entertainment - Pink
  static const Color categoryOther = Color(0xFF8A8AA3); // Other - Grey

  // ==========================================
  // CHART COLORS (Pie chart, Line chart සඳහා)
  // ==========================================
  static const List<Color> chartColors = [
    Color(0xFFFF6B6B), // Food
    Color(0xFF6B4EFF), // Bills
    Color(0xFF4ECDC4), // Transport
    Color(0xFFFFB84D), // Shopping
    Color(0xFF00C853), // Health
    Color(0xFF29B6F6), // Education
    Color(0xFFE91E63), // Entertainment
    Color(0xFF8A8AA3), // Other
  ];

  // ==========================================
  // BORDER & DIVIDER COLORS
  // ==========================================
  static const Color border = Color(0xFFE5E5EF);
  static const Color divider = Color(0xFFF0F0F7);
  static const Color shadow = Color(0x1A6B4EFF); // Purple shadow with opacity

  // ==========================================
  // GRADIENT COLORS
  // ==========================================
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6B4EFF), Color(0xFF8B72FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF6B4EFF), Color(0xFF5A3FE0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ==========================================
  // HELPER METHOD (Category එකට අදාළ color එක ගන්න)
  // ==========================================
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return categoryFood;
      case 'transport':
        return categoryTransport;
      case 'shopping':
        return categoryShopping;
      case 'bills':
        return categoryBills;
      case 'health':
        return categoryHealth;
      case 'education':
        return categoryEducation;
      case 'entertainment':
        return categoryEntertainment;
      default:
        return categoryOther;
    }
  }
}
