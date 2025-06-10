import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/laravel_api/models/child_model.dart';
import '/lib/theme/app_theme.dart';

class ChildAvatar extends StatelessWidget {
  final ChildModel child;
  final double size;
  final VoidCallback? onTap;

  const ChildAvatar({
    super.key,
    required this.child,
    this.size = 50,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = child.getAvatarUrl();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.primaryContainer,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: _buildAvatarImage(avatarUrl),
        ),
      ),
    );
  }

  Widget _buildAvatarImage(String primaryUrl) {
    // Pertama coba gunakan URL utama (yang diberikan dari getAvatarUrl)
    return CachedNetworkImage(
      imageUrl: primaryUrl,
      placeholder:
          (context, url) => Center(
            child: SizedBox(
              width: size / 3,
              height: size / 3,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primary.withOpacity(0.5),
              ),
            ),
          ),
      // Jika URL utama gagal, coba gunakan DiceBear URL (jika URL utama bukan DiceBear)
      errorWidget: (context, url, error) {
        // Jika URL yang gagal adalah URL user, coba gunakan DiceBear sebagai fallback
        if (child.avatarUrl != null && url == child.avatarUrl) {
          final diceBearUrl = child.getDiceBearUrl();
          return CachedNetworkImage(
            imageUrl: diceBearUrl,
            placeholder:
                (context, url) => Center(
                  child: SizedBox(
                    width: size / 3,
                    height: size / 3,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary.withOpacity(0.5),
                    ),
                  ),
                ),
            // Jika DiceBear juga gagal, gunakan fallback inisial
            errorWidget: (context, url, error) => _buildFallbackAvatar(),
            fit: BoxFit.cover,
          );
        }
        // Jika URL yang gagal adalah DiceBear atau URL lain, langsung gunakan fallback inisial
        return _buildFallbackAvatar();
      },
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 300),
      memCacheWidth: (size * 2).toInt(),
    );
  }

  Widget _buildFallbackAvatar() {
    return CircleAvatar(
      backgroundColor: AppTheme.primaryContainer,
      child: Text(
        child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: AppTheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
