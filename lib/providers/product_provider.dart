import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';

/// Mengelola katalog produk untuk modul POS.
class ProductProvider extends ChangeNotifier {
  final DatabaseService _localDb;
  final FirestoreService _cloudDb;

  List<Product> _products = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Product> get products => _searchQuery.isEmpty
      ? _products
      : _products
          .where((p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.category.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();

  List<Product> get lowStockProducts =>
      _products.where((p) => p.isLowStock).toList();

  bool get isLoading => _isLoading;

  ProductProvider(this._localDb, this._cloudDb);

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Muat produk dari SQLite lokal. Jika online, sync dari Firestore dulu.
  Future<void> loadProducts({bool forceCloud = false}) async {
    _isLoading = true;
    notifyListeners();
    if (forceCloud) {
      try {
        final cloudProducts = await _cloudDb.getAllProducts();
        for (final p in cloudProducts) {
          await _localDb.insertProduct(p);
        }
      } catch (_) {}
    }
    _products = await _localDb.getAllProducts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    await _localDb.insertProduct(product);
    try {
      await _cloudDb.addProduct(product);
    } catch (_) {}
    _products = await _localDb.getAllProducts();
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    await _localDb.updateProduct(product);
    try {
      await _cloudDb.updateProduct(product);
    } catch (_) {}
    _products = await _localDb.getAllProducts();
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    await _localDb.deleteProduct(id);
    try {
      await _cloudDb.deleteProduct(id);
    } catch (_) {}
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  /// Kurangi stok setelah transaksi POS selesai.
  Future<void> deductStock(String productId, int qty) async {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx < 0) return;
    final newStock = (_products[idx].stock - qty).clamp(0, 9999);
    _products[idx].stock = newStock;
    await _localDb.updateProductStock(productId, newStock);
    try {
      await _cloudDb.updateProductStock(productId, newStock);
    } catch (_) {}
    notifyListeners();
  }

  String generateProductId() => const Uuid().v4();
}
