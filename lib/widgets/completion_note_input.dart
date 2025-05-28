import 'package:flutter/material.dart';
import '../core/theme.dart';

class CompletionNoteInput extends StatelessWidget {
  final TextEditingController controller;
  final String? photoUrl;
  final Function()? onAddPhoto;
  final Function()? onRemovePhoto;
  final Function(String) onSubmit;
  final String environment;
  final bool isLoading;

  const CompletionNoteInput({
    Key? key,
    required this.controller,
    this.photoUrl,
    this.onAddPhoto,
    this.onRemovePhoto,
    required this.onSubmit,
    required this.environment,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color environmentColor =
        environment == 'home' ? AppColors.home : AppColors.school;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          'Catatan Penyelesaian',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: environmentColor,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        // Environment indication
        Row(
          children: [
            Icon(
              environment == 'home' ? Icons.home_rounded : Icons.school_rounded,
              color: environmentColor,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              environment == 'home'
                  ? 'Diselesaikan di Rumah'
                  : 'Diselesaikan di Sekolah',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: environmentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Text input
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Tambahkan catatan singkat tentang aktivitas ini...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: environmentColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: environmentColor, width: 2),
            ),
          ),
          maxLines: 3,
          textInputAction: TextInputAction.done,
        ),

        const SizedBox(height: 16),

        // Photo preview or add photo button
        if (photoUrl != null && photoUrl!.isNotEmpty)
          Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                  image: DecorationImage(
                    image: NetworkImage(photoUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onRemovePhoto,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          OutlinedButton.icon(
            onPressed: onAddPhoto,
            icon: const Icon(Icons.photo_camera),
            label: const Text('Tambahkan Foto'),
            style: OutlinedButton.styleFrom(
              foregroundColor: environmentColor,
              side: BorderSide(color: environmentColor),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),

        const SizedBox(height: 24),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : () => onSubmit(controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: environmentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              disabledBackgroundColor: environmentColor.withOpacity(0.6),
            ),
            child:
                isLoading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Text(
                      'Tandai Selesai',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
          ),
        ),
      ],
    );
  }
}
