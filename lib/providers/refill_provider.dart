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

  /// Tambah satu record refill baru.
  Future<void> addRecord(RefillType type, int price) async {
    final record = RefillRecord(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      type: type,
      price: price,
    );
    await _localDb.insertRefillRecord(record);
    // Coba langsung sync ke cloud
    try {
      await _cloudDb.addRefillRecord(record);
      await _localDb.markRefillRecordSynced(record.id);
      record.isSynced = true;
    } catch (_) {}
    _todayRecords.insert(0, record);
    notifyListeners();
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
