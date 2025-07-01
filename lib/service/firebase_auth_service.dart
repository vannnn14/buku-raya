import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get user => _auth.currentUser; // Perbaiki agar return null jika user belum login

  Stream<User?> get authState => _auth.authStateChanges();

  // Fungsi login menggunakan Google
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      if (googleAuth?.accessToken != null && googleAuth?.idToken != null) {
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth?.accessToken,
          idToken: googleAuth?.idToken,
        );
        await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      print(e.stackTrace.toString());
      throw e; // lempar exception agar bisa di-handle di login page
    }
  }

  // Fungsi logout
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut(); // logout from Google as well
  }

  // Fungsi register menggunakan email dan password
  Future<UserCredential> registerWithEmailPassword(String email, String password) async {
  try {
    return await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  } on FirebaseAuthException catch (e) {
    throw Exception("Firebase error: ${e.message}");
  } catch (e) {
    throw Exception("Unexpected error: $e");
  }
}

  // Fungsi login menggunakan email dan password
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Login error: ${e.message}');
      throw e.message ?? 'Gagal login';
    } catch (e) {
      print('Error: $e');
      throw 'Gagal login: $e';
    }
  }  
}
