import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Laravel API models and providers
import '/laravel_api/models/activity_model.dart';
import '/laravel_api/providers/auth_provider.dart';
import '/config.dart';  // Fixed import path
import '/lib/theme/app_theme.dart';

class ActivityDetailScreen extends StatefulWidget {
  final ActivityModel activity;

  const ActivityDetailScreen({super.key, required this.activity});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Aktivitas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 24),
            _buildPhotoSection(),
            const SizedBox(height: 24),
            _buildInfoSection(),
            const SizedBox(height: 24),
            _buildStepsSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.activity.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(widget.activity.difficulty).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _translateDifficultyToIndonesian(widget.activity.difficulty),
                    style: TextStyle(
                      color: _getDifficultyColor(widget.activity.difficulty),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _getEnvironmentIcon(widget.activity.environment),
                  color: _getEnvironmentColor(widget.activity.environment),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _translateEnvironmentToIndonesian(widget.activity.environment),
                  style: TextStyle(
                    color: _getEnvironmentColor(widget.activity.environment),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today,
                  color: AppTheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Usia ${widget.activity.minAge}-${widget.activity.maxAge} tahun',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.activity.description,
              style: TextStyle(fontSize: 16, color: AppTheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    // Get photos for the current teacher
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final teacherId = authProvider.userId;
    final photos = widget.activity.getPhotosForTeacher(teacherId);

    if (photos.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  size: 40,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada foto tersedia untuk aktivitas ini',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Aktivitas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            itemBuilder: (context, index) {
              // Format photo URL properly
              String photoUrl = _formatPhotoUrl(photos[index]);
              debugPrint('Loading photo from URL: $photoUrl');
              
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        _showFullScreenImage(context, photoUrl);
                      },
                      child: Image.network(
                        photoUrl,
                        width: 160,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Error loading image: $error');
                          return Container(
                            width: 160,
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 36,
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return Container(
                            width: 160,
                            height: 200,
                            color: Colors.grey[100],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper method to format photo URLs correctly with Laravel storage path
  String _formatPhotoUrl(String photoPath) {
    debugPrint('Original photo path: $photoPath');
    
    // If it's already a complete URL, return it as is
    if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
      return photoPath;
    }
    
    // If it's a path starting with /storage, append it to the base URL without /api
    // This is because storage URLs are served directly from the public directory
    if (photoPath.startsWith('/storage/')) {
      final baseUrlWithoutApi = AppConfig.apiBaseUrl.replaceFirst('/api', '');
      return '$baseUrlWithoutApi$photoPath';
    }
    
    // If photoPath starts with 'storage/', add a leading slash
    if (photoPath.startsWith('storage/')) {
      final baseUrlWithoutApi = AppConfig.apiBaseUrl.replaceFirst('/api', '');
      return '$baseUrlWithoutApi/$photoPath';
    }
    
    // Otherwise, assume it's a relative path to the API
    return '${AppConfig.apiBaseUrl}/$photoPath';
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading full-screen image: $error');
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('Gagal memuat gambar: $error', 
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.7),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi Aktivitas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  'Tingkat Kesulitan',
                  _translateDifficultyToIndonesian(widget.activity.difficulty),
                  _getDifficultyColor(widget.activity.difficulty),
                ),
                const Divider(),
                _buildInfoRow(
                  'Lingkungan',
                  _translateEnvironmentToIndonesian(widget.activity.environment),
                  _getEnvironmentColor(widget.activity.environment),
                ),
                const Divider(),
                _buildInfoRow(
                  'Rentang Usia',
                  '${widget.activity.minAge}-${widget.activity.maxAge} tahun',
                  AppTheme.primary,
                ),
                if (widget.activity.nextActivityId != null) ...[
                  const Divider(),
                  _buildInfoRow(
                    'Aktivitas Lanjutan',
                    'Tersedia',
                    AppTheme.tertiary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Langkah-Langkah',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildStepsList(),
            ),
          ),
        ),
      ],
    );
  }
  
  List<Widget> _buildStepsList() {
    // Laravel API
    if (widget.activity.activitySteps.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Belum ada langkah-langkah untuk aktivitas ini',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        )
      ];
    } else {
      final authProvider = Provider.of<AuthProvider>(
        context, 
        listen: false
      );
      final teacherId = authProvider.userId;
      final steps = widget.activity.getStepsForTeacher(teacherId);
      
      return steps.asMap().entries.map((entry) {
        return _buildStepItem(entry.key + 1, entry.value);
      }).toList();
    }
  }

  Widget _buildStepItem(int stepNumber, String step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: TextStyle(
                  color: AppTheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _translateDifficultyToIndonesian(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return 'Mudah';
      case 'Medium':
        return 'Sedang';
      case 'Hard':
        return 'Sulit';
      default:
        return difficulty;
    }
  }

  String _translateEnvironmentToIndonesian(String environment) {
    switch (environment) {
      case 'Home':
        return 'Rumah';
      case 'School':
        return 'Sekolah';
      case 'Both':
        return 'Keduanya';
      default:
        return environment;
    }
  }

  IconData _getEnvironmentIcon(String environment) {
    switch (environment) {
      case 'Home':
        return Icons.home_rounded;
      case 'School':
        return Icons.school_rounded;
      default: // Both
        return Icons.public_rounded;
    }
  }

  Color _getEnvironmentColor(String environment) {
    switch (environment) {
      case 'Home':
        return Colors.green;
      case 'School':
        return Colors.blue;
      default: // Both
        return Colors.purple;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Hard':
        return Colors.red;
      default:
        return AppTheme.primary;
    }
  }
}
