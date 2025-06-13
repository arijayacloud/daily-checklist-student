// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:daily_checklist_student/laravel_api/models/activity_model.dart';
// import 'package:daily_checklist_student/laravel_api/models/checklist_item_model.dart';
// import 'package:daily_checklist_student/laravel_api/models/child_model.dart';
// import 'package:daily_checklist_student/laravel_api/providers/checklist_provider.dart';
// import 'package:daily_checklist_student/lib/theme/app_theme.dart';
// import 'package:daily_checklist_student/widgets/home/laravel_child_avatar.dart';

// class ObservationFormScreen extends StatefulWidget {
//   final ChildModel child;
//   final ChecklistItemModel item;
//   final ActivityModel activity;
//   final bool isTeacher;

//   const ObservationFormScreen({
//     super.key,
//     required this.child,
//     required this.item,
//     required this.activity,
//     required this.isTeacher,
//   });

//   @override
//   State<ObservationFormScreen> createState() => _ObservationFormScreenState();
// }

// class _ObservationFormScreenState extends State<ObservationFormScreen> {
//   final _formKey = GlobalKey<FormState>();

//   int _durationMinutes = 15;
//   int _engagement = 3;
//   final _notesController = TextEditingController();
//   final _learningOutcomesController = TextEditingController();

//   bool _isSubmitting = false;

//   @override
//   void dispose() {
//     _notesController.dispose();
//     _learningOutcomesController.dispose();
//     super.dispose();
//   }

//   Future<void> _submitObservation() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     setState(() {
//       _isSubmitting = true;
//     });

//     try {
//       final checklistProvider = Provider.of<ChecklistProvider>(
//         context,
//         listen: false,
//       );

//       if (widget.isTeacher) {
//         await checklistProvider.addSchoolObservation(
//           itemId: widget.item.id,
//           duration: _durationMinutes,
//           engagement: _engagement,
//           notes: _notesController.text,
//           learningOutcomes: _learningOutcomesController.text,
//         );
//       } else {
//         await checklistProvider.addHomeObservation(
//           itemId: widget.item.id,
//           duration: _durationMinutes,
//           engagement: _engagement,
//           notes: _notesController.text,
//         );
//       }

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Observasi berhasil dikirim'),
//           backgroundColor: AppTheme.success,
//         ),
//       );

//       Navigator.pop(context);
//     } catch (e) {
//       setState(() {
//         _isSubmitting = false;
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Selesaikan Aktivitas')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildHeader(),
//               const SizedBox(height: 24),
//               _buildActivityInfo(),
//               const SizedBox(height: 24),
//               _buildObservationForm(),
//               const SizedBox(height: 32),
//               _buildSubmitButton(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Row(
//       children: [
//         Hero(
//           tag: 'child_avatar_${widget.child.id}',
//           child: LaravelChildAvatar(child: widget.child, size: 50),
//         ),
//         const SizedBox(width: 16),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 widget.child.name,
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 '${widget.child.age} tahun',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: AppTheme.onSurfaceVariant,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildActivityInfo() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: _getDifficultyColor(
//                       widget.activity.difficulty,
//                     ).withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     _translateDifficultyToIndonesian(
//                       widget.activity.difficulty,
//                     ),
//                     style: TextStyle(
//                       color: _getDifficultyColor(widget.activity.difficulty),
//                       fontWeight: FontWeight.bold,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: _getEnvironmentColor(
//                       widget.activity.environment,
//                     ).withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     _translateEnvironmentToIndonesian(
//                       widget.activity.environment,
//                     ),
//                     style: TextStyle(
//                       color: _getEnvironmentColor(widget.activity.environment),
//                       fontWeight: FontWeight.bold,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Text(
//               widget.activity.title,
//               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               widget.activity.description,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: AppTheme.onSurfaceVariant,
//                 height: 1.5,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Langkah-langkah Instruksi:',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: AppTheme.primary,
//               ),
//             ),
//             const SizedBox(height: 8),
//             ...widget.activity.activitySteps.isNotEmpty
//                 ? _buildStepsList(widget.activity.activitySteps.first.steps)
//                 : [
//                   Text(
//                     'Tidak ada langkah instruksi yang ditetapkan',
//                     style: TextStyle(
//                       fontStyle: FontStyle.italic,
//                       color: AppTheme.onSurfaceVariant,
//                     ),
//                   ),
//                 ],
//           ],
//         ),
//       ),
//     );
//   }

//   List<Widget> _buildStepsList(List<String> steps) {
//     return steps
//         .asMap()
//         .entries
//         .map(
//           (entry) => Padding(
//             padding: const EdgeInsets.only(bottom: 8),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   width: 24,
//                   height: 24,
//                   decoration: BoxDecoration(
//                     color: AppTheme.primaryContainer,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   alignment: Alignment.center,
//                   child: Text(
//                     '${entry.key + 1}',
//                     style: TextStyle(
//                       color: AppTheme.onPrimaryContainer,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(entry.value, style: const TextStyle(height: 1.5)),
//                 ),
//               ],
//             ),
//           ),
//         )
//         .toList();
//   }

//   Widget _buildObservationForm() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Detail Observasi',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: AppTheme.primary,
//           ),
//         ),
//         const SizedBox(height: 16),
//         _buildDurationSelector(),
//         const SizedBox(height: 24),
//         _buildEngagementSelector(),
//         const SizedBox(height: 24),
//         _buildNotesField(),
//         if (widget.isTeacher) const SizedBox(height: 24),
//         if (widget.isTeacher) _buildLearningOutcomesField(),
//       ],
//     );
//   }

//   Widget _buildDurationSelector() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Durasi Aktivitas: $_durationMinutes menit',
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         Slider(
//           value: _durationMinutes.toDouble(),
//           min: 5,
//           max: 60,
//           divisions: 11,
//           label: '$_durationMinutes menit',
//           onChanged: (value) {
//             setState(() {
//               _durationMinutes = value.toInt();
//             });
//           },
//           activeColor: AppTheme.primary,
//         ),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text('5 menit', style: TextStyle(color: AppTheme.onSurfaceVariant)),
//             Text(
//               '60 menit',
//               style: TextStyle(color: AppTheme.onSurfaceVariant),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildEngagementSelector() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Tingkat Keterlibatan Anak:',
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: AppTheme.surfaceVariant.withOpacity(0.3),
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Column(
//             children: [
//               Slider(
//                 value: _engagement.toDouble(),
//                 min: 1,
//                 max: 5,
//                 divisions: 4,
//                 label: '$_engagement',
//                 onChanged: (value) {
//                   setState(() {
//                     _engagement = value.toInt();
//                   });
//                 },
//                 activeColor: AppTheme.primary,
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   _buildEngagementLevelText(1, 'Sangat Rendah'),
//                   _buildEngagementLevelText(2, 'Rendah'),
//                   _buildEngagementLevelText(3, 'Sedang'),
//                   _buildEngagementLevelText(4, 'Tinggi'),
//                   _buildEngagementLevelText(5, 'Sangat Tinggi'),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildEngagementLevelText(int level, String label) {
//     return Column(
//       children: [
//         Container(
//           width: 24,
//           height: 24,
//           decoration: BoxDecoration(
//             color:
//                 _engagement == level
//                     ? AppTheme.primary
//                     : AppTheme.surfaceVariant,
//             shape: BoxShape.circle,
//           ),
//           alignment: Alignment.center,
//           child: Text(
//             '$level',
//             style: TextStyle(
//               color: _engagement == level ? Colors.white : AppTheme.onSurface,
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 10,
//             color:
//                 _engagement == level
//                     ? AppTheme.primary
//                     : AppTheme.onSurfaceVariant,
//             fontWeight:
//                 _engagement == level ? FontWeight.bold : FontWeight.normal,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildNotesField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           widget.isTeacher ? 'Catatan Proses:' : 'Catatan Observasi:',
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           controller: _notesController,
//           maxLines: 4,
//           decoration: InputDecoration(
//             hintText:
//                 widget.isTeacher
//                     ? 'Bagaimana anak mengerjakan aktivitas ini di sekolah?'
//                     : 'Bagaimana anak mengerjakan aktivitas ini di rumah?',
//             filled: true,
//             fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide.none,
//             ),
//           ),
//           validator: (value) {
//             if (value == null || value.trim().isEmpty) {
//               return 'Silakan masukkan catatan observasi';
//             }
//             return null;
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildLearningOutcomesField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Hasil Pembelajaran:',
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           controller: _learningOutcomesController,
//           maxLines: 4,
//           decoration: InputDecoration(
//             hintText:
//                 'Apa yang dipelajari anak? Keterampilan apa yang ditunjukkan?',
//             filled: true,
//             fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide.none,
//             ),
//           ),
//           validator: (value) {
//             if (value == null || value.trim().isEmpty) {
//               return 'Silakan masukkan hasil pembelajaran';
//             }
//             return null;
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildSubmitButton() {
//     return ElevatedButton(
//       onPressed: _isSubmitting ? null : _submitObservation,
//       style: ElevatedButton.styleFrom(
//         foregroundColor: Colors.white,
//         backgroundColor: AppTheme.primary,
//         disabledBackgroundColor: AppTheme.primary.withOpacity(0.6),
//         padding: const EdgeInsets.symmetric(vertical: 16),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         minimumSize: const Size(double.infinity, 0),
//       ),
//       child:
//           _isSubmitting
//               ? const SizedBox(
//                 width: 24,
//                 height: 24,
//                 child: CircularProgressIndicator(
//                   color: Colors.white,
//                   strokeWidth: 2,
//                 ),
//               )
//               : const Text(
//                 'Kirim Observasi',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//     );
//   }

//   Color _getDifficultyColor(String difficulty) {
//     switch (difficulty) {
//       case 'Easy':
//         return Colors.green;
//       case 'Medium':
//         return Colors.orange;
//       case 'Hard':
//         return Colors.red;
//       default:
//         return Colors.blue;
//     }
//   }

//   Color _getEnvironmentColor(String environment) {
//     switch (environment) {
//       case 'Home':
//         return Colors.purple;
//       case 'School':
//         return Colors.blue;
//       case 'Both':
//         return Colors.teal;
//       default:
//         return Colors.grey;
//     }
//   }

//   String _translateDifficultyToIndonesian(String difficulty) {
//     switch (difficulty) {
//       case 'Easy':
//         return 'Mudah';
//       case 'Medium':
//         return 'Sedang';
//       case 'Hard':
//         return 'Sulit';
//       default:
//         return difficulty;
//     }
//   }

//   String _translateEnvironmentToIndonesian(String environment) {
//     switch (environment) {
//       case 'Home':
//         return 'Rumah';
//       case 'School':
//         return 'Sekolah';
//       case 'Both':
//         return 'Keduanya';
//       default:
//         return environment;
//     }
//   }
// }
