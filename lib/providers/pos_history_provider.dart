import 'package:flutter/foundation.dart';
import '../models/pos_transaction_model.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';

class PosMonthlySummary {
  final int totalIncome;
  final int totalTransactions;
  final int totalItemsSold;

  const PosMonthlySummary({
    required this.totalIncome,
    required this.totalTransactions,
    required this.totalItemsSold,
  });
}

class PosHistoryProvider extends ChangeNotifier {
  final DatabaseService _localDb;
  final FirestoreService _cloudDb;

  List<PosTransaction> _monthTransactions = [];
  bool _isLoading = false;

  PosHistoryProvider(this._localDb, this._cloudDb);

  List<PosTransaction> get monthTransactions => _monthTransactions;
  bool get isLoading => _isLoading;

  Future<void> loadMonthTransactions(int year, int month, {bool forceCloud = false}) async {
    _isLoading = true;
    notifyListeners();

    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);

    if (forceCloud) {
      try {
        final cloudData = await _cloudDb.getPosTransactionsByMonth(year, month);
        for (final trx in cloudData) {
          await _localDb.insertPosTransaction(trx);
        }
      } catch (e) {
        debugPrint('Error syncing POS transactions from cloud: $e');
      }
    }
    
    // Tarik data transaksi yang ada di lokal (SQLite)
    _monthTransactions = await _localDb.getPosTransactionsByDateRange(start, end);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteTransaction(PosTransaction trx) async {
    // 1. Hapus dari SQLite
    await _localDb.deletePosTransaction(trx.id);
    
    // 2. Hapus dari Firestore (fire and forget)
    _cloudDb.deletePosTransaction(trx.id).catchError((_) {});
    
    // 3. Update memory list
    _monthTransactions.removeWhere((t) => t.id == trx.id);
    notifyListeners();
  }

  PosMonthlySummary get monthlySummary {
    int income = 0;
    int itemsSold = 0;

    for (final trx in _monthTransactions) {
      income += trx.totalAmount;
      for (final item in trx.items) {
        itemsSold += item.qty;
      }
    }

    return PosMonthlySummary(
      totalIncome: income,
      totalTransactions: _monthTransactions.length,
      totalItemsSold: itemsSold,
    );
  }

  /// Mendapatkan daftar produk terlaris berdasarkan Kuantitas
  List<MapEntry<String, int>> get topSellingProducts {
    final Map<String, int> productSales = {};

    for (final trx in _monthTransactions) {
      for (final item in trx.items) {
        final currentQty = productSales[item.productName] ?? 0;
        productSales[item.productName] = currentQty + item.qty;
      }
    }

    final sortedEntries = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Ambil top 5 terlaris
    return sortedEntries.take(5).toList();
  }
}
