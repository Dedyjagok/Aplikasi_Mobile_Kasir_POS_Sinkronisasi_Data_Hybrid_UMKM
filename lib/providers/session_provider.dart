import 'package:flutter/foundation.dart';
import '../models/cashier_model.dart';

class SessionProvider extends ChangeNotifier {
  bool _isActive = false;
  String? _activeRole; // 'owner' atau 'kasir'
  String? _activeName; // Nama owner atau nama kasir
  String? _cashierId; // ID kasir jika yang login adalah kasir

  bool get isActive => _isActive;
  String? get activeRole => _activeRole;
  String? get activeName => _activeName;
  String? get cashierId => _cashierId;
  
  bool get isOwner => _activeRole == 'owner';

  void loginAsOwner(String name) {
    _isActive = true;
    _activeRole = 'owner';
    _activeName = name;
    _cashierId = null;
    notifyListeners();
  }

  void loginAsCashier(Cashier cashier) {
    _isActive = true;
    _activeRole = 'kasir';
    _activeName = cashier.name;
    _cashierId = cashier.id;
    notifyListeners();
  }

  void lockScreen() {
    _isActive = false;
    _activeRole = null;
    _activeName = null;
    _cashierId = null;
    notifyListeners();
  }
}
