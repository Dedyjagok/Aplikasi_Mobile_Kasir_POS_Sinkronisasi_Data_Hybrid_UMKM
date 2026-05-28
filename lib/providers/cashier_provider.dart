import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/cashier_model.dart';
import '../services/database_service.dart';

class CashierProvider extends ChangeNotifier {
  final DatabaseService _db;
  List<Cashier> _cashiers = [];
  bool _isLoading = false;

  CashierProvider(this._db);

  List<Cashier> get cashiers => _cashiers;
  bool get isLoading => _isLoading;

  Future<void> loadCashiers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final data = await _db.getCashiers(user.uid);
        _cashiers = data.map((e) => Cashier.fromMap(e)).toList();
      } else {
        _cashiers = [];
      }
    } catch (e) {
      if (kDebugMode) print("Error loading cashiers: \$e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCashier(String name, String pin) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cashier = Cashier(
      id: const Uuid().v4(),
      userId: user.uid,
      name: name,
      pin: pin,
    );

    await _db.insertCashier(cashier.toMap());
    _cashiers.add(cashier);
    notifyListeners();
  }

  Future<void> updateCashier(String id, String name, String pin) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final index = _cashiers.indexWhere((c) => c.id == id);
    if (index >= 0) {
      final updated = Cashier(
        id: id,
        userId: user.uid,
        name: name,
        pin: pin,
        isActive: _cashiers[index].isActive,
      );
      await _db.updateCashier(updated.toMap());
      _cashiers[index] = updated;
      notifyListeners();
    }
  }

  Future<void> deleteCashier(String id) async {
    await _db.deleteCashier(id);
    _cashiers.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
