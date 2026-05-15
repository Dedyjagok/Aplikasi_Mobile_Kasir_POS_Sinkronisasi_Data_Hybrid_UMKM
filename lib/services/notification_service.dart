import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Handler FCM di background (top-level function — wajib di luar class).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] ${message.notification?.title}');
}

/// Service untuk inisialisasi dan handling Firebase Cloud Messaging.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Inisialisasi FCM, minta izin, daftarkan handler.
  Future<void> init() async {
    // Minta izin notifikasi (Android 13+ / iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handler notifikasi saat app di foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM Foreground] ${message.notification?.title}: '
          '${message.notification?.body}');
      // TODO: Tampilkan local notification / snackbar di UI
    });

    // Handler background sudah didaftarkan di main.dart
    // Handler saat notifikasi ditekan (app di background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM Opened] ${message.notification?.title}');
    });

    final token = await _messaging.getToken();
    debugPrint('[FCM Token] $token');
  }

  /// Ambil FCM device token (untuk kirim notifikasi targeted).
  Future<String?> getToken() => _messaging.getToken();
}
