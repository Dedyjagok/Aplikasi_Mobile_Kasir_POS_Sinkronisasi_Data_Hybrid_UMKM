import 'package:firebase_auth/firebase_auth.dart';

/// Wrapper Firebase Auth untuk login & logout pemilik/kasir.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream status autentikasi — digunakan oleh AuthProvider
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Login dengan email dan password.
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  /// Logout dari aplikasi.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Registrasi akun baru (Owner).
  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }
}
