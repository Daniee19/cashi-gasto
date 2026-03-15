import 'package:flutter/material.dart';

/// Paleta de colores de Cashi Gasto
abstract final class AppColors {
  // Primary
  static const Color primary = Color(0xFF5F32FA);
  static const Color primaryLight = Color(0xFF8A6AFB);
  static const Color primaryDark = Color(0xFF4A1FD6);

  // Secondary
  static const Color secondary = Color(0xFF7C4DFF);
  static const Color secondaryLight = Color(0xFFB47CFF);
  static const Color secondaryDark = Color(0xFF3F1DCB);

  // Background
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F0FF);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Income & Expense
  static const Color income = Color(0xFF10B981);
  static const Color expense = Color(0xFFEF4444);

  // Neutral
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);

  // Shadows
  static const Color shadowLight = Color(0x1A5F32FA);
  static const Color shadowMedium = Color(0x335F32FA);
}
