import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/database_service.dart';
import '../models/app_settings_model.dart';

/// Mengelola state autentikasi di seluruh aplikasi.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _authService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.signIn(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String storeName, String phone, String ownerPin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final credential = await _authService.signUp(email, password);
      final user = credential.user;
      if (user != null) {
        // Simpan profile ke Firestore
        await FirestoreService().createOwnerProfile(user.uid, email, storeName, phone);
        
        // Simpan settings ke SQLite lokal
        final localDb = DatabaseService();
        final settings = await localDb.getSettings();
        final updatedSettings = AppSettings(
          storeName: storeName,
          storePhone: phone,
          storeAddress: settings.storeAddress,
          refillPriceAntar: settings.refillPriceAntar,
          refillPriceAmbil: settings.refillPriceAmbil,
          currencySymbol: settings.currencySymbol,
          ownerPin: ownerPin,
        );
        await localDb.saveSettings(updatedSettings);
        // Simpan juga ke Firestore agar saat LockScreen memuat dari cloud, data PIN tidak tertimpa default
        await FirestoreService().saveSettings(updatedSettings);
      }

      // Logout langsung agar user harus login manual (untuk mencegah state bentrok)
      await _authService.signOut();

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapSignUpError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email tidak terdaftar.';
      case 'wrong-password':
        return 'Password salah.';
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      default:
        return 'Login gagal. Coba lagi.';
    }
  }

  String _mapSignUpError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password terlalu lemah (minimal 6 karakter).';
      default:
        return 'Pendaftaran gagal. Silakan coba lagi.';
    }
  }
}
