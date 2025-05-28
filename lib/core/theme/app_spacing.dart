import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Ekstensi untuk memudahkan penggunaan spacing dalam aplikasi
extension SpacingExtension on BuildContext {
  // Vertical spacing
  Widget get vSpaceSmall => const SizedBox(height: AppConstants.paddingSmall);
  Widget get vSpaceMedium => const SizedBox(height: AppConstants.paddingMedium);
  Widget get vSpaceLarge => const SizedBox(height: AppConstants.paddingLarge);

  // Horizontal spacing
  Widget get hSpaceSmall => const SizedBox(width: AppConstants.paddingSmall);
  Widget get hSpaceMedium => const SizedBox(width: AppConstants.paddingMedium);
  Widget get hSpaceLarge => const SizedBox(width: AppConstants.paddingLarge);

  // Custom spacing
  Widget vSpace(double height) => SizedBox(height: height);
  Widget hSpace(double width) => SizedBox(width: width);

  // Padding helpers
  EdgeInsets get paddingSmall =>
      const EdgeInsets.all(AppConstants.paddingSmall);
  EdgeInsets get paddingMedium =>
      const EdgeInsets.all(AppConstants.paddingMedium);
  EdgeInsets get paddingLarge =>
      const EdgeInsets.all(AppConstants.paddingLarge);

  // Horizontal padding
  EdgeInsets get paddingHorizontalSmall =>
      const EdgeInsets.symmetric(horizontal: AppConstants.paddingSmall);
  EdgeInsets get paddingHorizontalMedium =>
      const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium);
  EdgeInsets get paddingHorizontalLarge =>
      const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge);

  // Vertical padding
  EdgeInsets get paddingVerticalSmall =>
      const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall);
  EdgeInsets get paddingVerticalMedium =>
      const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium);
  EdgeInsets get paddingVerticalLarge =>
      const EdgeInsets.symmetric(vertical: AppConstants.paddingLarge);
}
