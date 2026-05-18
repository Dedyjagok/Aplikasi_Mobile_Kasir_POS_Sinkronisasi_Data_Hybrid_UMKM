import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  // API Key yang diberikan
  static const _googleApiKey = 'test_xZaNXbmcLgRlIVlPdmlvxNQfBFu';

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  Future<void> initialize() async {
    try {
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      PurchasesConfiguration configuration;
      // Saat ini hanya konfigurasi untuk Android
      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(_googleApiKey);
        await Purchases.configure(configuration);
        
        // Cek status saat pertama kali aplikasi dibuka
        await checkPremiumStatus();
        
        // Daftarkan listener agar status ter-update jika terjadi pembelian baru
        Purchases.addCustomerInfoUpdateListener((customerInfo) {
          _updateStatus(customerInfo);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("RevenueCat Init Error: $e");
      }
    }
  }

  Future<void> checkPremiumStatus() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _updateStatus(customerInfo);
    } catch (e) {
      _isPremium = false;
    }
  }

  void _updateStatus(CustomerInfo customerInfo) {
    // INFO: Asumsi nama entitlement di dashboard RevenueCat adalah "premium"
    // Ganti kata "premium" ini jika di dashboard namanya berbeda (misal: "pro")
    if (customerInfo.entitlements.all["premium"]?.isActive == true) {
      _isPremium = true;
    } else {
      _isPremium = false;
    }
  }
}
