import 'package:buku_raya/favorite_page.dart';
import 'package:buku_raya/home_page.dart';
import 'package:buku_raya/login.dart';
import 'package:buku_raya/profil_page.dart';
import 'package:buku_raya/service/firebase_auth_service.dart';
import 'package:buku_raya/service/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      routes: {
        '/login': (context) => const Login(),
        '/home': (context) => const HomePage(),
        '/profil': (context) => const ProfilePage(),
        '/favorite': (context) => const FavoritePage(),
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData) {
            return const HomePage();
          } else {
            return const Login();
          }
        },
      ),
    );
  }
}
