import 'package:flutter/material.dart';

class AppConstants {
  // URL API DiceBear untuk avatar
  static const String diceBearApiUrl =
      'https://api.dicebear.com/9.x/thumbs/svg';

  // Range usia anak
  static const List<String> ageRanges = ['3-4', '4-5', '5-6'];

  // Kategori aktivitas
  static const List<String> categories = [
    'Keterampilan Motorik',
    'Kognitif',
    'Sosial',
    'Kreatif',
    'Bahasa',
  ];

  // Level kesulitan
  static const List<String> difficulties = ['Pemula', 'Menengah', 'Lanjutan'];

  // Status tugas
  static const List<String> assignmentStatus = ['Todo', 'In Progress', 'Done'];

  // Level keterlibatan (untuk observasi)
  static const int maxEngagementLevel = 5;

  // Format tanggal standar
  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'HH:mm';

  // Ukuran padding standar
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Ukuran radius border standar
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
}
