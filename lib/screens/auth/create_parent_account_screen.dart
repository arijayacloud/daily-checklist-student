// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import '../../core/theme/app_colors_compat.dart';
// import '../../models/user_model.dart';
// import '../../providers/auth_provider.dart';

// class CreateParentAccountScreen extends StatefulWidget {
//   const CreateParentAccountScreen({Key? key}) : super(key: key);

//   @override
//   State<CreateParentAccountScreen> createState() =>
//       _CreateParentAccountScreenState();
// }

// class _CreateParentAccountScreenState extends State<CreateParentAccountScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   String _errorMessage = '';
//   String? _generatedPassword;
//   bool _accountCreated = false;

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     super.dispose();
//   }

//   Future<void> _createAccount() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     setState(() {
//       _errorMessage = '';
//       _generatedPassword = null;
//       _accountCreated = false;
//     });

//     final authProvider = Provider.of<AuthProvider>(context, listen: false);

//     if (!authProvider.isTeacher || authProvider.user == null) {
//       setState(() {
//         _errorMessage =
//             'Anda harus login sebagai guru untuk membuat akun orangtua';
//       });
//       return;
//     }

//     try {
//       final String? tempPassword = await authProvider.createParentAccount(
//         name: _nameController.text.trim(),
//         email: _emailController.text.trim(),
//         teacherId: authProvider.user!.uid,
//         shouldAutoLogin: false,
//       );

//       if (tempPassword != null) {
//         setState(() {
//           _generatedPassword = tempPassword;
//           _accountCreated = true;
//         });
//       } else {
//         setState(() {
//           _errorMessage = 'Gagal membuat akun: data tidak lengkap';
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = e.toString();
//       });
//     }
//   }

//   void _copyPasswordToClipboard() {
//     if (_generatedPassword != null) {
//       Clipboard.setData(ClipboardData(text: _generatedPassword!));
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Password disalin ke clipboard'),
//           duration: Duration(seconds: 2),
//         ),
//       );
//     }
//   }

//   void _resetForm() {
//     _formKey.currentState?.reset();
//     _nameController.clear();
//     _emailController.clear();
//     setState(() {
//       _errorMessage = '';
//       _generatedPassword = null;
//       _accountCreated = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = Provider.of<AuthProvider>(context);
//     final isLoading = authProvider.isLoading;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Buat Akun Orangtua'),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Info Card
//                 Card(
//                   color: AppColors.primary.withOpacity(0.1),
//                   margin: const EdgeInsets.only(bottom: 24),
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           children: [
//                             Icon(Icons.info_outline, color: AppColors.primary),
//                             const SizedBox(width: 8),
//                             Text(
//                               'Informasi',
//                               style: Theme.of(
//                                 context,
//                               ).textTheme.titleMedium?.copyWith(
//                                 color: AppColors.primary,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Akun yang dibuat akan memiliki peran sebagai Orangtua. '
//                           'Password sementara akan digenerate secara otomatis dan hanya '
//                           'ditampilkan sekali. Harap salin dan bagikan kepada orangtua.',
//                           style: Theme.of(context).textTheme.bodyMedium,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),

//                 // Success Card
//                 if (_accountCreated)
//                   Card(
//                     color: AppColors.complete.withOpacity(0.1),
//                     margin: const EdgeInsets.only(bottom: 24),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Icon(
//                                 Icons.check_circle_outline,
//                                 color: AppColors.complete,
//                               ),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: Text(
//                                   'Akun Berhasil Dibuat',
//                                   style: Theme.of(
//                                     context,
//                                   ).textTheme.titleMedium?.copyWith(
//                                     color: AppColors.complete,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           Text(
//                             'Informasi Akun:',
//                             style: Theme.of(context).textTheme.titleSmall,
//                           ),
//                           const SizedBox(height: 8),
//                           _infoRow('Nama', _nameController.text),
//                           _infoRow('Email', _emailController.text),
//                           _infoRow('Peran', 'Orangtua'),
//                           _infoRow(
//                             'Password Sementara',
//                             _generatedPassword ?? '',
//                             canCopy: true,
//                           ),
//                           const SizedBox(height: 16),
//                           SizedBox(
//                             width: double.infinity,
//                             child: OutlinedButton.icon(
//                               onPressed: _resetForm,
//                               icon: const Icon(Icons.add),
//                               label: const Text('Buat Akun Lainnya'),
//                               style: OutlinedButton.styleFrom(
//                                 foregroundColor: AppColors.primary,
//                                 side: BorderSide(color: AppColors.primary),
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 12,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   )
//                 else ...[
//                   // Error Message
//                   if (_errorMessage.isNotEmpty)
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       margin: const EdgeInsets.only(bottom: 20),
//                       decoration: BoxDecoration(
//                         color: AppColors.error.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: AppColors.error),
//                       ),
//                       child: Text(
//                         _errorMessage,
//                         style: TextStyle(
//                           color: AppColors.error,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),

//                   // Name Field
//                   Text(
//                     'Nama Lengkap',
//                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   TextFormField(
//                     controller: _nameController,
//                     decoration: const InputDecoration(
//                       hintText: 'Masukkan nama orangtua',
//                       prefixIcon: Icon(Icons.person_outline),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Nama tidak boleh kosong';
//                       }
//                       return null;
//                     },
//                     enabled: !isLoading,
//                   ),

//                   const SizedBox(height: 24),

//                   // Email Field
//                   Text(
//                     'Email',
//                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   TextFormField(
//                     controller: _emailController,
//                     keyboardType: TextInputType.emailAddress,
//                     decoration: const InputDecoration(
//                       hintText: 'Masukkan email orangtua',
//                       prefixIcon: Icon(Icons.email_outlined),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Email tidak boleh kosong';
//                       }
//                       if (!RegExp(
//                         r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
//                       ).hasMatch(value)) {
//                         return 'Masukkan format email yang valid';
//                       }
//                       return null;
//                     },
//                     enabled: !isLoading,
//                   ),

//                   const SizedBox(height: 32),

//                   // Create Account Button
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: isLoading ? null : _createAccount,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.primary,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         textStyle: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       child:
//                           isLoading
//                               ? const SizedBox(
//                                 width: 24,
//                                 height: 24,
//                                 child: CircularProgressIndicator(
//                                   color: Colors.white,
//                                   strokeWidth: 2,
//                                 ),
//                               )
//                               : const Text('Buat Akun Orangtua'),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _infoRow(String label, String value, {bool canCopy = false}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.textSecondary,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     value,
//                     style: TextStyle(
//                       fontWeight: FontWeight.w500,
//                       color:
//                           canCopy
//                               ? AppColors.primary
//                               : AppColors.textPrimaryLight,
//                     ),
//                   ),
//                 ),
//                 if (canCopy && value.isNotEmpty)
//                   IconButton(
//                     onPressed: _copyPasswordToClipboard,
//                     icon: Icon(Icons.copy, color: AppColors.primary, size: 20),
//                     splashRadius: 20,
//                     tooltip: 'Salin password',
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
