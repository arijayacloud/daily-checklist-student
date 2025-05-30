import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/models/child_model.dart';
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
          child: CachedNetworkImage(
            imageUrl: avatarUrl,
            placeholder:
                (context, url) => CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary.withOpacity(0.5),
                ),
            errorWidget:
                (context, url, error) => CircleAvatar(
                  backgroundColor: AppTheme.primaryContainer,
                  child: Text(
                    child.name[0].toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: size * 0.4,
                    ),
                  ),
                ),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
