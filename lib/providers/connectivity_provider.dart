import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Mengelola status koneksi internet secara reaktif.
class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    // Cek status awal
    final result = await Connectivity().checkConnectivity();
    _isOnline = result.any((r) =>
        r == ConnectivityResult.mobile || r == ConnectivityResult.wifi);
    notifyListeners();

    // Dengarkan perubahan
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final online = results.any((r) =>
          r == ConnectivityResult.mobile || r == ConnectivityResult.wifi);
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
    });
  }
}
