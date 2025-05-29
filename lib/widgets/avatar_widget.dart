import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AvatarWidget extends StatelessWidget {
  final String avatarUrl;
  final double size;

  const AvatarWidget({super.key, required this.avatarUrl, this.size = 50});

  @override
  Widget build(BuildContext context) {
    // Periksa apakah URL adalah SVG dari DiceBear
    final bool isSvgUrl =
        avatarUrl.contains('dicebear') && avatarUrl.endsWith('.svg') ||
        avatarUrl.contains('dicebear') && avatarUrl.contains('/svg');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child:
            isSvgUrl
                ? SvgPicture.network(
                  avatarUrl,
                  placeholderBuilder:
                      (context) =>
                          const Center(child: CircularProgressIndicator()),
                  height: size,
                  width: size,
                  fit: BoxFit.cover,
                )
                : Image.network(
                  avatarUrl,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person,
                      size: size * 0.6,
                      color: Colors.grey[600],
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                      ),
                    );
                  },
                  fit: BoxFit.cover,
                ),
      ),
    );
  }
}

// Class khusus untuk avatar anak
class ChildAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;

  const ChildAvatar({Key? key, this.avatarUrl, this.radius = 50})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Jika tidak ada URL, gunakan avatar default
    final String url =
        avatarUrl ??
        'https://api.dicebear.com/7.x/fun-emoji/svg?seed=child&backgroundColor=ffb300';

    return AvatarWidget(avatarUrl: url, size: radius * 2);
  }
}
