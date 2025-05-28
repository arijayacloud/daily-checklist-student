import 'package:flutter/material.dart';

/// Ekstensi untuk memudahkan penggunaan style teks dalam aplikasi
extension TextStyleExtension on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;

  // Heading styles
  TextStyle get headingLarge => textTheme.headlineLarge!;
  TextStyle get headingMedium => textTheme.headlineMedium!;
  TextStyle get headingSmall => textTheme.headlineSmall!;

  // Title styles
  TextStyle get titleLarge => textTheme.titleLarge!;
  TextStyle get titleMedium => textTheme.titleMedium!;
  TextStyle get titleSmall => textTheme.titleSmall!;

  // Body styles
  TextStyle get bodyLarge => textTheme.bodyLarge!;
  TextStyle get bodyMedium => textTheme.bodyMedium!;
  TextStyle get bodySmall => textTheme.bodySmall!;

  // Helper untuk mengubah warna teks
  TextStyle textColor(TextStyle style, Color color) =>
      style.copyWith(color: color);

  // Helper untuk teks bold
  TextStyle bold(TextStyle style) =>
      style.copyWith(fontWeight: FontWeight.bold);
}
