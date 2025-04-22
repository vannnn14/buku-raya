import 'package:buku_raya/service/firebase_options.dart';
import 'package:buku_raya/service/firebase_auth_service.dart';
import 'package:buku_raya/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pastikan Firebase diinisialisasi dengan konfigurasi yang sesuai
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Buku Raya',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // ✅ Tambahkan ini:
      routes: {
        '/login': (context) => const Login(),
        '/home': (context) => HomePage(),
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuthService().authState,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Menampilkan loading jika data masih dalam proses
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.connectionState == ConnectionState.done ||
              snapshot.connectionState == ConnectionState.active) {
            // Jika ada data (pengguna sudah login), arahkan ke HomePage
            if (snapshot.hasData) {
              return HomePage();
            } else {
              // Jika belum login, arahkan ke halaman login
              return const Login();
            }
          } else {
            // Jika terjadi kesalahan, tampilkan status koneksi
            return Center(child: Text('State: ${snapshot.connectionState}'));
          }
        },
      ),
    );
  }
}
