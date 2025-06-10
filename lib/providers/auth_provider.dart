// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/user_model.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'dart:async';

// class AuthProvider with ChangeNotifier {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   User? _firebaseUser;
//   UserModel? _user;
//   bool _isLoading = true;

//   User? get firebaseUser => _firebaseUser;
//   UserModel? get user => _user;
//   bool get isAuthenticated => _firebaseUser != null;
//   bool get isLoading => _isLoading;
//   String get userRole => _user?.role ?? 'parent';
//   String get userId => _firebaseUser?.uid ?? '';

//   AuthProvider() {
//     _auth.authStateChanges().listen((User? user) {
//       _firebaseUser = user;
//       if (user != null) {
//         _fetchUserData(user.uid);
//       } else {
//         _user = null;
//         _isLoading = false;
//         notifyListeners();
//       }
//     });
//   }

//   Future<void> checkAuthStatus() async {
//     try {
//       _firebaseUser = _auth.currentUser;
//       if (_firebaseUser != null) {
//         await _fetchUserData(_firebaseUser!.uid);
//       } else {
//         _isLoading = false;
//         notifyListeners();
//       }
//     } catch (e) {
//       debugPrint('Error checking auth status: $e');
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> _fetchUserData(String uid) async {
//     try {
//       final docSnapshot = await _firestore.collection('users').doc(uid).get();

//       if (docSnapshot.exists) {
//         final data = docSnapshot.data() as Map<String, dynamic>;
//         _user = UserModel.fromJson({'id': uid, ...data});
//       } else {
//         _user = null;
//       }
//     } catch (e) {
//       debugPrint('Error fetching user data: $e');
//       _user = null;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> signIn(String email, String password) async {
//     try {
//       final userCredential = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       if (userCredential.user != null) {
//         await _fetchUserData(userCredential.user!.uid);
//       }
//     } catch (e) {
//       debugPrint('Sign in error: $e');
//       throw _handleAuthError(e);
//     }
//   }

//   Future<void> signOut() async {
//     await _auth.signOut();
//     _user = null;
//     notifyListeners();
//   }

//   Future<void> createParentAccount(
//     String email,
//     String name,
//     String password, {
//     String phoneNumber = '',
//     String address = '',
//   }) async {
//     if (_user == null || _user!.role != 'teacher') {
//       throw 'Hanya guru yang dapat membuat akun orang tua';
//     }

//     try {
//       final String docId = _firestore.collection('users').doc().id;

//       // Simpan referensi user guru saat ini
//       final currentUser = _auth.currentUser;
//       final currentUserEmail = currentUser?.email;
//       final currentUserId = currentUser?.uid;

//       // Inisialisasi Firebase App terpisah untuk mencegah logout
//       final parentApp = await Firebase.initializeApp(
//         name: 'parentAuthApp-${DateTime.now().millisecondsSinceEpoch}',
//         options: Firebase.app().options,
//       );

//       try {
//         // Gunakan instance terpisah untuk membuat akun parent
//         final parentAuth = FirebaseAuth.instanceFor(app: parentApp);
//         final parentCredential = await parentAuth
//             .createUserWithEmailAndPassword(email: email, password: password);

//         final newUserId = parentCredential.user?.uid;

//         // Simpan data orang tua di Firestore
//         await _firestore.collection('users').doc(newUserId).set({
//           'id': newUserId,
//           'email': email,
//           'name': name,
//           'role': 'parent',
//           'createdBy': _user!.id,
//           'isTempPassword': true,
//           'createdAt': FieldValue.serverTimestamp(),
//           'phoneNumber': phoneNumber,
//           'address': address,
//           'profilePicture': '',
//           'status': 'active',
//         });

//         // Hapus Firebase App terpisah
//         await parentApp.delete();
//       } catch (authError) {
//         // Hapus app terpisah jika terjadi error
//         await parentApp.delete();

//         // Hapus dokumen yang telah dibuat jika gagal
//         if (docId.isNotEmpty) {
//           await _firestore.collection('users').doc(docId).delete();
//         }

//         debugPrint('Error creating parent account: $authError');
//         throw _handleAuthError(authError);
//       }
//     } catch (e) {
//       debugPrint('Create parent account error: $e');
//       throw _handleAuthError(e);
//     }
//   }

//   String _handleAuthError(dynamic e) {
//     if (e is FirebaseAuthException) {
//       switch (e.code) {
//         case 'user-not-found':
//           return 'No user found with this email.';
//         case 'wrong-password':
//           return 'Wrong password. Please try again.';
//         case 'invalid-email':
//           return 'The email address is not valid.';
//         case 'user-disabled':
//           return 'This user account has been disabled.';
//         case 'email-already-in-use':
//           return 'This email is already registered.';
//         case 'operation-not-allowed':
//           return 'This operation is not allowed.';
//         case 'weak-password':
//           return 'The password is too weak.';
//         case 'too-many-requests':
//           return 'Too many failed login attempts. Please try again later.';
//         default:
//           return 'An error occurred. Please try again.';
//       }
//     }
//     return e.toString();
//   }

//   Future<void> changePassword({
//     required String currentPassword,
//     required String newPassword,
//   }) async {
//     if (_firebaseUser == null) {
//       throw 'Pengguna tidak login';
//     }

//     try {
//       final credential = EmailAuthProvider.credential(
//         email: _firebaseUser!.email!,
//         password: currentPassword,
//       );

//       await _firebaseUser!.reauthenticateWithCredential(credential);

//       await _firebaseUser!.updatePassword(newPassword);

//       if (_user?.isTempPassword == true) {
//         await _firestore.collection('users').doc(_firebaseUser!.uid).update({
//           'isTempPassword': false,
//         });

//         if (_user != null) {
//           _user = _user!.copyWith(isTempPassword: false);
//           notifyListeners();
//         }
//       }
//     } catch (e) {
//       debugPrint('Change password error: $e');
//       throw _handleAuthError(e);
//     }
//   }

//   Future<void> createTeacherAccount(
//     String email,
//     String name,
//     String password, {
//     String phoneNumber = '',
//     String address = '',
//   }) async {
//     try {
//       final userCredential = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       final uid = userCredential.user!.uid;

//       await _firestore.collection('users').doc(uid).set({
//         'email': email,
//         'name': name,
//         'role': 'teacher',
//         'createdAt': FieldValue.serverTimestamp(),
//         'phoneNumber': phoneNumber,
//         'address': address,
//         'profilePicture': '',
//         'status': 'active',
//         'isTempPassword': false,
//       });

//       _firebaseUser = userCredential.user;
//       await _fetchUserData(uid);
//     } catch (e) {
//       debugPrint('Create teacher account error: $e');
//       throw _handleAuthError(e);
//     }
//   }

//   Future<String?> getChildId() async {
//     if (_user == null || _user!.role != 'parent') return null;

//     try {
//       final snapshot =
//           await _firestore
//               .collection('children')
//               .where('parentId', isEqualTo: _user!.id)
//               .limit(1)
//               .get();

//       if (snapshot.docs.isNotEmpty) {
//         return snapshot.docs.first.id;
//       }
//       return null;
//     } catch (e) {
//       debugPrint('Error getting child id: $e');
//       return null;
//     }
//   }
// }
