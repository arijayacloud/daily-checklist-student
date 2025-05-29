import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart' as app_auth;

class FirebaseTestPage extends StatefulWidget {
  const FirebaseTestPage({super.key});

  @override
  State<FirebaseTestPage> createState() => _FirebaseTestPageState();
}

class _FirebaseTestPageState extends State<FirebaseTestPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _connectionStatus = 'Belum diuji';
  String _firestoreStatus = 'Belum diuji';
  String _authStatus = 'Belum diuji';

  // Controller untuk login test
  final _emailController = TextEditingController(text: 'test@example.com');
  final _passwordController = TextEditingController(text: 'password123');
  final _nameController = TextEditingController(text: 'Test User');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Koneksi Firebase:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor(_connectionStatus),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _connectionStatus,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Status Firestore:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor(_firestoreStatus),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _firestoreStatus,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Status Autentikasi:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor(_authStatus),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _authStatus,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _testFirebaseConnection,
                  child: const Text('Uji Koneksi'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _testFirestoreWrite,
                  child: const Text('Uji Firestore'),
                ),
              ],
            ),
            const Divider(height: 32),

            // Form testing autentikasi
            Text(
              'Pengujian Autentikasi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Email field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            // Password field
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            // Name field (for registration)
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama (untuk pendaftaran)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Auth testing buttons
            Row(
              children: [
                ElevatedButton(
                  onPressed: _testRegister,
                  child: const Text('Uji Register'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _testLogin,
                  child: const Text('Uji Login'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _testLogout,
                  child: const Text('Uji Logout'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('Berhasil')) {
      return Colors.green;
    } else if (status.contains('Gagal')) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  Future<void> _testFirebaseConnection() async {
    setState(() {
      _connectionStatus = 'Menguji...';
    });

    try {
      // Uji koneksi dengan mencoba mendapatkan nilai isSignInWithEmailLink
      await _auth.isSignInWithEmailLink('test@test.com');
      setState(() {
        _connectionStatus = 'Berhasil terhubung ke Firebase';
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Gagal terhubung: ${e.toString()}';
      });
    }
  }

  Future<void> _testFirestoreWrite() async {
    setState(() {
      _firestoreStatus = 'Menguji...';
    });

    try {
      // Uji tulis ke Firestore
      final docRef = await _firestore.collection('test_connection').add({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Tes koneksi dari Flutter',
      });

      setState(() {
        _firestoreStatus =
            'Berhasil menulis ke Firestore dengan ID: ${docRef.id}';
      });
    } catch (e) {
      setState(() {
        _firestoreStatus = 'Gagal menulis ke Firestore: ${e.toString()}';
      });
    }
  }

  Future<void> _testRegister() async {
    setState(() {
      _authStatus = 'Mendaftarkan user...';
    });

    try {
      final authProvider = Provider.of<app_auth.AuthProvider>(
        context,
        listen: false,
      );

      bool success = await authProvider.createTeacherAccount(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (success) {
        setState(() {
          _authStatus =
              'Berhasil mendaftarkan pengguna: ${_emailController.text}';
        });
      } else {
        setState(() {
          _authStatus = 'Gagal mendaftar: ${authProvider.errorMessage}';
        });
      }
    } catch (e) {
      setState(() {
        _authStatus = 'Gagal mendaftar: ${e.toString()}';
      });
    }
  }

  Future<void> _testLogin() async {
    setState(() {
      _authStatus = 'Login...';
    });

    try {
      final authProvider = Provider.of<app_auth.AuthProvider>(
        context,
        listen: false,
      );

      bool success = await authProvider.login(
        _emailController.text,
        _passwordController.text,
      );

      if (success) {
        setState(() {
          _authStatus = 'Berhasil login sebagai: ${_emailController.text}';
        });

        // Tampilkan info user
        User? user = _auth.currentUser;
        if (user != null) {
          setState(() {
            _authStatus += '\nUID: ${user.uid}';
            _authStatus +=
                '\nRole: ${authProvider.isTeacher ? 'Guru' : 'Orangtua'}';
          });
        }
      } else {
        setState(() {
          _authStatus = 'Gagal login: ${authProvider.errorMessage}';
        });
      }
    } catch (e) {
      setState(() {
        _authStatus = 'Gagal login: ${e.toString()}';
      });
    }
  }

  Future<void> _testLogout() async {
    setState(() {
      _authStatus = 'Logout...';
    });

    try {
      final authProvider = Provider.of<app_auth.AuthProvider>(
        context,
        listen: false,
      );
      await authProvider.signOut();

      setState(() {
        _authStatus = 'Berhasil logout';
      });
    } catch (e) {
      setState(() {
        _authStatus = 'Gagal logout: ${e.toString()}';
      });
    }
  }
}
