// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../providers/auth_provider.dart';
// import '../../providers/child_provider.dart';

// class AddChildScreen extends StatefulWidget {
//   const AddChildScreen({Key? key}) : super(key: key);

//   @override
//   _AddChildScreenState createState() => _AddChildScreenState();
// }

// class _AddChildScreenState extends State<AddChildScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _ageController = TextEditingController();

//   List<Map<String, String>> _parentsList = [];
//   String? _selectedParentId;
//   bool _isLoadingParents = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadParents();
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _ageController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadParents() async {
//     setState(() {
//       _isLoadingParents = true;
//     });

//     try {
//       final authProvider = Provider.of<AuthProvider>(context, listen: false);
//       if (authProvider.user != null) {
//         final QuerySnapshot snapshot =
//             await FirebaseFirestore.instance
//                 .collection('users')
//                 .where('role', isEqualTo: 'parent')
//                 .get();

//         List<Map<String, String>> parents = [];
//         for (var doc in snapshot.docs) {
//           Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//           parents.add({
//             'id': doc.id,
//             'name': data['name'] ?? 'Nama tidak diketahui',
//           });
//         }

//         setState(() {
//           _parentsList = parents;
//           _selectedParentId = parents.isNotEmpty ? parents[0]['id'] : null;
//           _isLoadingParents = false;
//         });
//       }
//     } catch (e) {
//       print('Error loading parents: $e');
//       setState(() {
//         _isLoadingParents = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final childProvider = Provider.of<ChildProvider>(context);

//     return Scaffold(
//       appBar: AppBar(title: const Text('Tambah Anak')),
//       body:
//           _isLoadingParents
//               ? const Center(child: CircularProgressIndicator())
//               : SingleChildScrollView(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       // Name
//                       TextFormField(
//                         controller: _nameController,
//                         decoration: InputDecoration(
//                           labelText: 'Nama Anak',
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Nama wajib diisi';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 16),

//                       // Age
//                       TextFormField(
//                         controller: _ageController,
//                         decoration: InputDecoration(
//                           labelText: 'Usia',
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         keyboardType: TextInputType.number,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Usia wajib diisi';
//                           }
//                           if (int.tryParse(value) == null) {
//                             return 'Usia harus berupa angka';
//                           }
//                           final age = int.parse(value);
//                           if (age < 3 || age > 6) {
//                             return 'Usia harus antara 3-6 tahun';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 16),

//                       // Parent Dropdown
//                       if (_parentsList.isEmpty)
//                         Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.amber.shade50,
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Column(
//                             children: [
//                               const Text(
//                                 'Belum ada orangtua yang terdaftar',
//                                 style: TextStyle(fontWeight: FontWeight.bold),
//                               ),
//                               const SizedBox(height: 8),
//                               const Text(
//                                 'Tambahkan orangtua terlebih dahulu di menu Manajemen Pengguna',
//                               ),
//                               const SizedBox(height: 8),
//                               ElevatedButton(
//                                 onPressed: () {
//                                   Navigator.of(context).pop();
//                                   Navigator.of(
//                                     context,
//                                   ).pushNamed('/teacher/users');
//                                 },
//                                 child: const Text('Buat Akun Orangtua'),
//                               ),
//                             ],
//                           ),
//                         )
//                       else
//                         DropdownButtonFormField<String>(
//                           value: _selectedParentId,
//                           decoration: InputDecoration(
//                             labelText: 'Orangtua',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                           items:
//                               _parentsList
//                                   .map(
//                                     (parent) => DropdownMenuItem(
//                                       value: parent['id'],
//                                       child: Text(parent['name']!),
//                                     ),
//                                   )
//                                   .toList(),
//                           onChanged: (value) {
//                             if (value != null) {
//                               setState(() {
//                                 _selectedParentId = value;
//                               });
//                             }
//                           },
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Pilih orangtua';
//                             }
//                             return null;
//                           },
//                         ),
//                       const SizedBox(height: 24),

//                       // Notice about avatar
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.blue.shade50,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: const Text(
//                           'Avatar akan dibuat secara otomatis berdasarkan nama anak.',
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                       const SizedBox(height: 24),

//                       // Submit Button
//                       SizedBox(
//                         height: 50,
//                         child: ElevatedButton(
//                           onPressed:
//                               childProvider.isLoading || _parentsList.isEmpty
//                                   ? null
//                                   : () => _handleSubmit(context),
//                           child:
//                               childProvider.isLoading
//                                   ? const CircularProgressIndicator()
//                                   : const Text('Simpan'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//     );
//   }

//   Future<void> _handleSubmit(BuildContext context) async {
//     if (_formKey.currentState!.validate() && _selectedParentId != null) {
//       final authProvider = Provider.of<AuthProvider>(context, listen: false);
//       final childProvider = Provider.of<ChildProvider>(context, listen: false);

//       if (authProvider.user != null) {
//         final success = await childProvider.addChild(
//           name: _nameController.text.trim(),
//           age: int.parse(_ageController.text.trim()),
//           parentId: _selectedParentId!,
//           teacherId: '',
//         );

//         if (success && mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Anak berhasil ditambahkan')),
//           );
//           Navigator.pop(context);
//         }
//       }
//     }
//   }
// }
