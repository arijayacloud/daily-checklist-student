import 'package:flutter/material.dart';

/// Ekstensi untuk memudahkan penggunaan warna dalam aplikasi
extension ColorExtension on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  // Warna utama
  Color get primary => colorScheme.primary;
  Color get secondary => colorScheme.secondary;
  Color get tertiary => colorScheme.tertiary;

  // Warna latar
  Color get background => colorScheme.background;
  Color get surface => colorScheme.surface;
  Color get surfaceVariant => colorScheme.surfaceVariant;

  // Warna teks
  Color get onPrimary => colorScheme.onPrimary;
  Color get onSecondary => colorScheme.onSecondary;
  Color get onBackground => colorScheme.onBackground;
  Color get onSurface => colorScheme.onSurface;

  // Warna status
  Color get todoColor => const Color(0xFFFF9800);
  Color get inProgressColor => const Color(0xFF2196F3);
  Color get doneColor => const Color(0xFF4CAF50);

  // Warna error
  Color get error => colorScheme.error;
  Color get onError => colorScheme.onError;
}
