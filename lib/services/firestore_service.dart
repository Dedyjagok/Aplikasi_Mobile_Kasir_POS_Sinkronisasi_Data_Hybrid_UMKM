import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_settings_model.dart';
import '../models/pos_transaction_model.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/refill_record_model.dart';

/// Service untuk semua operasi CRUD ke Cloud Firestore.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collections ──────────────────────────────────────────
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _categories => _db.collection('product_categories');
  CollectionReference get _products => _db.collection('products');
  CollectionReference get _posTransactions => _db.collection('pos_transactions');
  CollectionReference get _refillRecords => _db.collection('refill_records');
  DocumentReference? get _settings {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return _db.collection('app_settings').doc(user.uid);
  }
  // ═══════════════════════════════════════════════════════
  //  USER PROFILE
  // ═══════════════════════════════════════════════════════
  Future<void> createOwnerProfile(String uid, String email, String storeName, String phone) async {
    await _users.doc(uid).set({
      'email': email,
      'store_name': storeName,
      'phone': phone,
      'created_at': FieldValue.serverTimestamp(),
      'role': 'owner',
    }, SetOptions(merge: true));
  }

  // ═══════════════════════════════════════════════════════
  //  KATEGORI
  // ═══════════════════════════════════════════════════════

  Future<List<CategoryModel>> getAllCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final snapshot = await _categories.where('user_id', isEqualTo: user.uid).get();
    final list = snapshot.docs.map((d) => CategoryModel.fromFirestore(d)).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<void> addCategory(CategoryModel category) async {
    await _categories.doc(category.id).set(category.toFirestoreMap());
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _categories.doc(category.id).update(category.toFirestoreMap());
  }

  Future<void> deleteCategory(String id) async {
    await _categories.doc(id).delete();
  }

  // ═══════════════════════════════════════════════════════
  //  PRODUK
  // ═══════════════════════════════════════════════════════

  Future<List<Product>> getAllProducts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final snapshot = await _products.where('user_id', isEqualTo: user.uid).get();
    final list = snapshot.docs.map((d) => Product.fromFirestore(d)).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<void> addProduct(Product product) async {
    await _products.doc(product.id).set(product.toFirestoreMap());
  }

  Future<void> updateProduct(Product product) async {
    await _products.doc(product.id).update(product.toFirestoreMap());
  }

  Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
  }

  Future<void> updateProductStock(String id, int newStock) async {
    await _products.doc(id).update({
      'stock': newStock,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════
  //  TRANSAKSI POS
  // ═══════════════════════════════════════════════════════

  Future<void> addPosTransaction(PosTransaction trx) async {
    await _posTransactions.doc(trx.id).set(trx.toFirestoreMap());
  }

  Future<void> batchAddPosTransactions(List<PosTransaction> transactions) async {
    final batch = _db.batch();
    for (final trx in transactions) {
      batch.set(_posTransactions.doc(trx.id), trx.toFirestoreMap());
    }
    await batch.commit();
  }

  Future<void> deletePosTransaction(String id) async {
    await _posTransactions.doc(id).delete();
  }

  Future<List<PosTransaction>> getPosTransactionsByMonth(
      int year, int month) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    
    // Fetch all user transactions to bypass composite index requirement
    final snapshot = await _posTransactions
        .where('user_id', isEqualTo: user.uid)
        .get();
        
    final allTransactions = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>? ?? [])
          .map((i) => PosTransactionItem(
                id: '',
                transactionId: doc.id,
                productId: i['product_id'] ?? '',
                productName: i['product_name'] ?? '',
                qty: i['qty'] ?? 0,
                unitPrice: i['unit_price'] ?? 0,
                subtotal: i['subtotal'] ?? 0,
              ))
          .toList();
      return PosTransaction(
        id: doc.id,
        userId: data['user_id'] as String? ?? '',
        timestamp: (data['timestamp'] as Timestamp).toDate(),
        totalAmount: data['total_amount'] ?? 0,
        cashReceived: data['cash_received'] ?? 0,
        changeAmount: data['change_amount'] ?? 0,
        paymentMethod: data['payment_method'] ?? 'Tunai',
        isSynced: true,
        items: items,
      );
    }).toList();

    // Local filtering by date range
    final filtered = allTransactions.where((t) {
      return !t.timestamp.isBefore(start) && t.timestamp.isBefore(end);
    }).toList();

    // Local sorting (descending)
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return filtered;
  }

  // ═══════════════════════════════════════════════════════
  //  REFILL AIR RO
  // ═══════════════════════════════════════════════════════

  Future<void> addRefillRecord(RefillRecord record) async {
    await _refillRecords.doc(record.id).set(record.toFirestoreMap());
  }

  Future<void> batchAddRefillRecords(List<RefillRecord> records) async {
    final batch = _db.batch();
    for (final r in records) {
      batch.set(_refillRecords.doc(r.id), r.toFirestoreMap());
    }
    await batch.commit();
  }

  Future<void> deleteRefillRecord(String id) async {
    await _refillRecords.doc(id).delete();
  }

  Future<List<RefillRecord>> getRefillRecordsByMonth(
      int year, int month) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    
    // Fetch all user records to bypass composite index requirement
    final snapshot = await _refillRecords
        .where('user_id', isEqualTo: user.uid)
        .get();
        
    final allRecords = snapshot.docs.map(RefillRecord.fromFirestore).toList();

    // Local filtering by date range
    final filtered = allRecords.where((r) {
      return !r.timestamp.isBefore(start) && r.timestamp.isBefore(end);
    }).toList();

    // Local sorting (descending)
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return filtered;
  }

  // ═══════════════════════════════════════════════════════
  //  PENGATURAN CMS
  // ═══════════════════════════════════════════════════════

  Future<AppSettings?> getSettings() async {
    final ref = _settings;
    if (ref == null) return null;
    final doc = await ref.get();
    if (!doc.exists) return null;
    return AppSettings.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final ref = _settings;
    if (ref != null) {
      final user = FirebaseAuth.instance.currentUser;
      final map = settings.toMap();
      if (user != null) {
        map['user_id'] = user.uid;
      }
      await ref.set(map, SetOptions(merge: true));
    }
  }
}
