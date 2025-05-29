import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Kelas kompatibilitas untuk mendukung kode lama yang masih menggunakan AppColors
class AppColors {
  // Primary dan Secondary Colors
  static const Color primary = AppTheme.primaryColor;
  static const Color primaryLight = Color(0xFFBB86FC);
  static const Color primaryDark = Color(0xFF3700B3);

  static const Color secondary = AppTheme.secondaryColor;
  static const Color secondaryLight = Color(0xFF66FFF8);
  static const Color secondaryDark = Color(0xFF00A895);

  static const Color accentColor = AppTheme.accentColor;

  // Environment Colors
  static const Color home = Color(0xFF7E57C2); // Ungu untuk rumah
  static const Color school = Color(0xFF26C6DA); // Biru untuk sekolah
  static const Color both = Color(0xFF66BB6A); // Hijau untuk keduanya

  // Status Colors
  static const Color pending = AppTheme.todoColor;
  static const Color partial = AppTheme.inProgressColor;
  static const Color complete = AppTheme.doneColor;
  static const Color overdue = Color(0xFFEF5350);

  // Neutral Colors
  static const Color backgroundLight = AppTheme.backgroundLight;
  static const Color backgroundDark = AppTheme.backgroundDark;
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E1E1E);

  static const Color error = Color(0xFFB00020);

  static const Color textPrimaryLight = AppTheme.textDark;
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textPrimaryDark = AppTheme.textLight;
  static const Color textSecondaryDark = Color(0xFFBDBDBD);

  static const Color textSecondary = Color(0xFF757575);

  static const Color divider = Color(0xFFBDBDBD);

  /// Warna warning
  static const Color warning = Color(0xFFF57C00);

  /// Warna info
  static const Color info = Color(0xFF2196F3);
}
