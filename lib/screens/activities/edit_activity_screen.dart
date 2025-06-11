import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import '/config.dart';
import 'dart:convert';

// Laravel API models and providers
import '/laravel_api/models/activity_model.dart';
import '/laravel_api/providers/activity_provider.dart';
import '/laravel_api/providers/api_provider.dart';
import '/laravel_api/providers/auth_provider.dart';

import '/lib/theme/app_theme.dart';

class EditActivityScreen extends StatefulWidget {
  final ActivityModel activity;
  
  const EditActivityScreen({super.key, required this.activity});

  @override
  State<EditActivityScreen> createState() => _EditActivityScreenState();
}

class _EditActivityScreenState extends State<EditActivityScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  String _environment = 'Both';
  String _difficulty = 'Medium';
  double _minAge = 3.0;
  double _maxAge = 6.0;
  List<String> _steps = [''];
  final List<File> _photos = [];
  List<String> _existingPhotos = [];
  final ImagePicker _picker = ImagePicker();

  bool _isSubmitting = false;
  bool _uploadingPhotos = false;

  @override
  void initState() {
    super.initState();
    // Initialize form with existing activity data
    _titleController.text = widget.activity.title;
    _descriptionController.text = widget.activity.description;
    _durationController.text = widget.activity.duration?.toString() ?? '';
    _environment = widget.activity.environment;
    _difficulty = widget.activity.difficulty;
    _minAge = widget.activity.minAge;
    _maxAge = widget.activity.maxAge;
    
    // Get existing steps from the activity
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final steps = widget.activity.getStepsForTeacher(authProvider.userId);
    _steps = steps.isEmpty ? [''] : List<String>.from(steps);
    
    // Get existing photos
    _existingPhotos = List<String>.from(
      widget.activity.getPhotosForTeacher(authProvider.userId)
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200, // Optimize image size
      maxHeight: 1200,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _photos.add(File(image.path));
      });
    }
  }

  Future<void> _captureImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _photos.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _removeExistingPhoto(int index) {
    setState(() {
      _existingPhotos.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages() async {
    if (_photos.isEmpty) return [];
    
    final List<String> uploadedUrls = [];
    final apiProvider = Provider.of<ApiProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() {
      _uploadingPhotos = true;
    });
    
    try {
      for (var photoFile in _photos) {
        final fileName = path.basename(photoFile.path);
        final mimeType = 'image/${path.extension(fileName).replaceFirst('.', '')}';
        
        // Create multipart request
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${AppConfig.apiBaseUrl}/upload-photo'),
        );
        
        // Add authorization header
        request.headers['Authorization'] = 'Bearer ${apiProvider.token}';
        
        // Add file to request
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          photoFile.path,
          contentType: MediaType.parse(mimeType),
        ));
        
        // Add additional fields if needed
        request.fields['type'] = 'activity';
        
        // Send request
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        
        // Process response
        if (response.statusCode == 200 || response.statusCode == 201) {
          try {
            final responseData = json.decode(response.body);
            if (responseData != null && responseData['url'] != null) {
              // Store the URL exactly as returned by the server
              String url = responseData['url'];
              uploadedUrls.add(url);
              
              debugPrint('Photo uploaded successfully: $url');
              debugPrint('Response data: ${json.encode(responseData)}');
            } else {
              debugPrint('Failed to parse upload response: ${response.body}');
            }
          } catch (e) {
            debugPrint('Error parsing response: $e');
            debugPrint('Response body: ${response.body}');
          }
        } else {
          debugPrint('Failed to upload image: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('Error uploading images: $e');
    } finally {
      setState(() {
        _uploadingPhotos = false;
      });
    }
    
    return uploadedUrls;
  }

  Future<void> _updateActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Filter out empty steps
    final steps = _steps.where((step) => step.trim().isNotEmpty).toList();

    if (steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan tambahkan minimal satu langkah instruksi'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // First upload new images (if any)
      final newPhotoUrls = await _uploadImages();
      
      // Combine existing and new photos
      final allPhotos = [..._existingPhotos, ...newPhotoUrls];
      
      // Parse duration
      int? duration;
      if (_durationController.text.isNotEmpty) {
        duration = int.tryParse(_durationController.text);
      }
      
      // First update the activity details
      final success = await Provider.of<ActivityProvider>(context, listen: false).updateActivity(
        id: widget.activity.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        environment: _environment,
        difficulty: _difficulty,
        minAge: _minAge,
        maxAge: _maxAge,
        duration: duration,
      );
      
      if (success) {
        // Then update the steps and photos
        await Provider.of<ActivityProvider>(context, listen: false).addCustomSteps(
          activityId: widget.activity.id,
          steps: steps,
          photos: allPhotos,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aktivitas berhasil diperbarui'),
          backgroundColor: AppTheme.success,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  void _addStep() {
    setState(() {
      _steps.add('');
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  void _updateStep(int index, String value) {
    setState(() {
      _steps[index] = value;
    });
  }

  String _getTranslatedEnvironment(String env) {
    switch (env) {
      case 'Home':
        return 'Rumah';
      case 'School':
        return 'Sekolah';
      case 'Both':
        return 'Keduanya';
      default:
        return env;
    }
  }

  String _getEnvironmentValue(String translatedEnv) {
    switch (translatedEnv) {
      case 'Rumah':
        return 'Home';
      case 'Sekolah':
        return 'School';
      case 'Keduanya':
        return 'Both';
      default:
        return translatedEnv;
    }
  }

  String _getTranslatedDifficulty(String diff) {
    switch (diff) {
      case 'Easy':
        return 'Mudah';
      case 'Medium':
        return 'Sedang';
      case 'Hard':
        return 'Sulit';
      default:
        return diff;
    }
  }

  String _getDifficultyValue(String translatedDiff) {
    switch (translatedDiff) {
      case 'Mudah':
        return 'Easy';
      case 'Sedang':
        return 'Medium';
      case 'Sulit':
        return 'Hard';
      default:
        return translatedDiff;
    }
  }
  
  String _formatAgeValue(double value) {
    if (value == value.truncate()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Aktivitas')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Aktivitas',
                  hintText: 'Masukkan judul untuk aktivitas',
                  filled: true,
                  fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Silakan masukkan judul';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Masukkan deskripsi untuk aktivitas',
                  filled: true,
                  fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Silakan masukkan deskripsi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Duration
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Durasi (menit)',
                  hintText: 'Masukkan durasi aktivitas dalam menit',
                  filled: true,
                  fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixText: 'menit',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final duration = int.tryParse(value);
                    if (duration == null || duration <= 0) {
                      return 'Durasi harus berupa angka positif';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Environment selection
              Text(
                'Lingkungan:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: ['Home', 'School', 'Both'].map((env) {
                  final label = _getTranslatedEnvironment(env);
                  return ChoiceChip(
                    label: Text(label),
                    selected: _environment == env,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _environment = env;
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Difficulty selection
              Text(
                'Tingkat Kesulitan:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: ['Easy', 'Medium', 'Hard'].map((diff) {
                  final label = _getTranslatedDifficulty(diff);
                  return ChoiceChip(
                    label: Text(label),
                    selected: _difficulty == diff,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _difficulty = diff;
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Age range
              Text(
                'Rentang Usia:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Usia Minimum: ${_formatAgeValue(_minAge)} tahun',
                          style: TextStyle(color: AppTheme.onSurfaceVariant),
                        ),
                        Slider(
                          value: _minAge,
                          min: 0,
                          max: 6,
                          divisions: 12, // 0.5 increment steps
                          label: _formatAgeValue(_minAge),
                          onChanged: (value) {
                            setState(() {
                              _minAge = value;
                              if (_maxAge < _minAge) {
                                _maxAge = _minAge;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Usia Maksimum: ${_formatAgeValue(_maxAge)} tahun',
                          style: TextStyle(color: AppTheme.onSurfaceVariant),
                        ),
                        Slider(
                          value: _maxAge,
                          min: 0,
                          max: 6,
                          divisions: 12, // 0.5 increment steps
                          label: _formatAgeValue(_maxAge),
                          onChanged: (value) {
                            setState(() {
                              _maxAge = value;
                              if (_minAge > _maxAge) {
                                _minAge = _maxAge;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Photo instructions
              Text(
                'Foto Instruksi:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: _photos.isEmpty ? 120 : 160,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_photos.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _photos.length,
                          padding: const EdgeInsets.all(8),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                alignment: AlignmentDirectional.topEnd,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _photos[index],
                                      height: 120,
                                      width: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    margin: const EdgeInsets.all(4),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 24,
                                        minHeight: 24,
                                      ),
                                      padding: EdgeInsets.zero,
                                      onPressed: () => _removeImage(index),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Galeri'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _captureImage,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Kamera'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.tertiary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_uploadingPhotos)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16, 
                              height: 16, 
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Mengunggah foto...',
                              style: TextStyle(color: AppTheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Steps
              Text(
                'Langkah-langkah Instruksi:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          radius: 16,
                          child: Text('${index + 1}'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: _steps[index],
                            decoration: InputDecoration(
                              hintText: 'Masukkan instruksi',
                              filled: true,
                              fillColor:
                                  AppTheme.surfaceVariant.withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (value) => _updateStep(index, value),
                            validator: (value) {
                              if (index == 0 &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Masukkan minimal satu langkah';
                              }
                              return null;
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.remove_circle,
                            color: index == 0 && _steps.length == 1
                                ? Colors.grey
                                : Colors.red,
                          ),
                          onPressed: index == 0 && _steps.length == 1
                              ? null
                              : () => _removeStep(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _addStep,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Langkah'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Existing Photos Section
              if (_existingPhotos.isNotEmpty) ...[
                const Text('Foto yang Ada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingPhotos.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: NetworkImage(_formatPhotoUrl(_existingPhotos[index])),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _removeExistingPhoto(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _updateActivity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(_uploadingPhotos ? 'Mengupload Foto...' : 'Menyimpan...'),
                          ],
                        )
                      : const Text('Simpan Perubahan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to format photo URLs correctly
  String _formatPhotoUrl(String photoPath) {
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
}
