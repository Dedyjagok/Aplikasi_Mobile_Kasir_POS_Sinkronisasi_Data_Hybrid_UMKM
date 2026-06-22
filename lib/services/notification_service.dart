import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handler FCM di background (top-level function — wajib di luar class).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] ${message.notification?.title}');
}

/// Service untuk inisialisasi dan handling Firebase Cloud Messaging dan Notifikasi Lokal.
class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Inisialisasi FCM, minta izin, daftarkan handler.
  Future<void> init() async {
    // 1. Inisialisasi Notifikasi Lokal (Local Notifications)
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _localNotifications.initialize(settings: initializationSettings);

    // Minta izin POST_NOTIFICATIONS untuk Android 13+
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // 2. Minta izin notifikasi (Android 13+ / iOS) via FCM
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handler notifikasi saat app di foreground (FCM)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM Foreground] ${message.notification?.title}: '
          '${message.notification?.body}');
    });

    // Handler background sudah didaftarkan di main.dart
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM Opened] ${message.notification?.title}');
    });

    final token = await _messaging.getToken();
    debugPrint('[FCM Token] $token');
  }

  /// Ambil FCM device token (untuk kirim notifikasi targeted).
  Future<String?> getToken() => _messaging.getToken();

  /// Memunculkan notifikasi peringatan stok rendah secara lokal (tanpa server).
  static Future<void> showLowStockNotification(String productName, int currentStock) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'low_stock_channel',
      'Peringatan Stok Rendah',
      channelDescription: 'Notifikasi saat stok produk hampir habis',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Stok Menipis',
      styleInformation: BigTextStyleInformation(''),
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // ID Notifikasi menggunakan hashcode dari nama produk agar notifikasi ditimpa jika produk sama
    final int notificationId = productName.hashCode;

    await _localNotifications.show(
      id: notificationId,
      title: 'Stok Menipis!',
      body: 'Stok produk $productName hanya tersisa $currentStock. Segera isi ulang!',
      notificationDetails: platformChannelSpecifics,
    );
  }
}
