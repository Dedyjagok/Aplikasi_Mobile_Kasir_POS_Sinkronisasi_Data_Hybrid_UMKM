import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_service.dart';
import 'firestore_service.dart';

/// Service sinkronisasi data hybrid (SQLite ↔ Firestore).
/// Dipanggil otomatis saat koneksi internet pulih.
class SyncService {
  final DatabaseService _localDb;
  final FirestoreService _cloudDb;
  StreamSubscription? _connectivitySub;

  SyncService(this._localDb, this._cloudDb);

  /// Mulai mendengarkan perubahan koneksi dan sync otomatis.
  void startListening() {
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final isOnline = results.any((r) =>
          r == ConnectivityResult.mobile || r == ConnectivityResult.wifi);
      if (isOnline) syncAll();
    });
  }

  void stopListening() => _connectivitySub?.cancel();

  /// Sinkronisasi semua data yang belum ter-upload ke cloud.
  Future<void> syncAll() async {
    await Future.wait([
      _syncPosTransactions(),
      _syncRefillRecords(),
    ]);
  }

  Future<void> _syncPosTransactions() async {
    try {
      final pending = await _localDb.getUnsyncedPosTransactions();
      if (pending.isEmpty) return;
      await _cloudDb.batchAddPosTransactions(pending);
      for (final trx in pending) {
        await _localDb.markPosTransactionSynced(trx.id);
      }
    } catch (_) {
      // Abaikan error — akan dicoba lagi saat koneksi berikutnya
    }
  }

  Future<void> _syncRefillRecords() async {
    try {
      final pending = await _localDb.getUnsyncedRefillRecords();
      if (pending.isEmpty) return;
      await _cloudDb.batchAddRefillRecords(pending);
      for (final r in pending) {
        await _localDb.markRefillRecordSynced(r.id);
      }
    } catch (_) {
      // Abaikan error — akan dicoba lagi saat koneksi berikutnya
    }
  }
}
