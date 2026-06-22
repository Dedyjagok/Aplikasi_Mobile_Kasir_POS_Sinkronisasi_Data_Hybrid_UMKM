import 'package:flutter/foundation.dart';
import '../models/app_settings_model.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';

/// Mengelola pengaturan CMS aplikasi (nama toko, harga refill, dll).
class SettingsProvider extends ChangeNotifier {
  final DatabaseService _localDb;
  final FirestoreService _cloudDb;

  AppSettings _settings = const AppSettings();
  bool _isLoading = false;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  SettingsProvider(this._localDb, this._cloudDb);

  /// Muat pengaturan — prioritas: Firestore → SQLite → default.
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    try {
      final cloud = await _cloudDb.getSettings();
      if (cloud != null) {
        _settings = cloud;
        await _localDb.saveSettings(cloud); // cache lokal
      } else {
        // Jika dokumen cloud belum ada (misal: migrasi user lama), ambil dari lokal lalu sinkronkan ke cloud
        _settings = await _localDb.getSettings();
        _cloudDb.saveSettings(_settings).catchError((_) {});
      }
    } catch (_) {
      // Offline: pakai dari SQLite
      _settings = await _localDb.getSettings();
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Simpan pengaturan ke SQLite (lokal) dan Firestore (cloud).
  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();
    await _localDb.saveSettings(newSettings);
    // Sinkronkan ke cloud tanpa memblokir (fire and forget)
    _cloudDb.saveSettings(newSettings).catchError((_) {});
  }
}
