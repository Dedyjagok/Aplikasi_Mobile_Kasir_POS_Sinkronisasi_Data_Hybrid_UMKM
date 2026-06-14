import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/refill_record_model.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';

/// Rekap bulanan refill per tipe.
class RefillMonthlySummary {
  final int totalAntar;
  final int totalAmbil;
  final int incomeAntar;
  final int incomeAmbil;

  const RefillMonthlySummary({
    required this.totalAntar,
    required this.totalAmbil,
    required this.incomeAntar,
    required this.incomeAmbil,
  });

  int get totalCount => totalAntar + totalAmbil;
  int get totalIncome => incomeAntar + incomeAmbil;
}

/// Mengelola state modul Refill Air RO.
class RefillProvider extends ChangeNotifier {
  final DatabaseService _localDb;
  final FirestoreService _cloudDb;

  List<RefillRecord> _todayRecords = [];
  List<RefillRecord> _monthRecords = [];
  bool _isLoading = false;

  List<RefillRecord> get todayRecords => _todayRecords;
  List<RefillRecord> get monthRecords => _monthRecords;
  bool get isLoading => _isLoading;

  RefillProvider(this._localDb, this._cloudDb);

  /// Muat record refill hari ini dari SQLite.
  Future<void> loadTodayRecords() async {
    _isLoading = true;
    notifyListeners();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    _todayRecords = await _localDb.getRefillRecordsByDateRange(start, end);
    _isLoading = false;
    notifyListeners();
  }

  /// Muat record refill bulan tertentu.
  Future<void> loadMonthRecords(int year, int month) async {
    _isLoading = true;
    notifyListeners();
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    _monthRecords = await _localDb.getRefillRecordsByDateRange(start, end);
    _isLoading = false;
    notifyListeners();
  }

  /// Tambah record refill baru sekaligus sesuai kuantitas.
  Future<void> addRecords(RefillType type, int price, int qty) async {
    final newRecords = <RefillRecord>[];
    
    for (int i = 0; i < qty; i++) {
      final record = RefillRecord(
        id: const Uuid().v4(),
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        timestamp: DateTime.now(),
        type: type,
        price: price,
      );
      newRecords.add(record);
      await _localDb.insertRefillRecord(record);
      // Sinkronisasi ke cloud (fire and forget) agar UI tidak ngehang saat offline
      _cloudDb.addRefillRecord(record).then((_) {
        _localDb.markRefillRecordSynced(record.id);
        record.isSynced = true;
        notifyListeners();
      }).catchError((_) {});
    }
    
    _todayRecords.insertAll(0, newRecords);
    notifyListeners();
  }

  /// Menghapus satu record refill
  Future<void> deleteRecord(String id) async {
    // Optimistic UI update
    _todayRecords.removeWhere((r) => r.id == id);
    _monthRecords.removeWhere((r) => r.id == id);
    notifyListeners();

    // Hapus di SQLite
    await _localDb.deleteRefillRecord(id);

    // Hapus di Firestore
    _cloudDb.deleteRefillRecord(id).catchError((_) {});
  }

  /// Hitung rekap bulanan dari data yang sudah dimuat.
  RefillMonthlySummary get monthlySummary {
    int ta = 0, tb = 0, ia = 0, ib = 0;
    for (final r in _monthRecords) {
      if (r.type == RefillType.antar) {
        ta++;
        ia += r.price;
      } else {
        tb++;
        ib += r.price;
      }
    }
    return RefillMonthlySummary(
      totalAntar: ta,
      totalAmbil: tb,
      incomeAntar: ia,
      incomeAmbil: ib,
    );
  }

  /// Jumlah refill hari ini (untuk ditampilkan di Home).
  int get todayCount => _todayRecords.length;
  int get todayIncome =>
      _todayRecords.fold(0, (sum, r) => sum + r.price);
}
