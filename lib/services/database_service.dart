import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/app_settings_model.dart';
import '../models/pos_transaction_model.dart';
import '../models/product_model.dart';
import '../models/refill_record_model.dart';

/// Singleton service untuk semua operasi database SQLite lokal.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kasir_umkm.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabel Produk
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT,
        cost_price INTEGER NOT NULL,
        sell_price INTEGER NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        low_stock_threshold INTEGER DEFAULT 10,
        updated_at TEXT
      )
    ''');

    // Tabel Header Transaksi POS
    await db.execute('''
      CREATE TABLE pos_transactions (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        total_amount INTEGER NOT NULL,
        cash_received INTEGER NOT NULL,
        change_amount INTEGER NOT NULL,
        payment_method TEXT DEFAULT 'Tunai',
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Tabel Item Transaksi POS
    await db.execute('''
      CREATE TABLE pos_transaction_items (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        qty INTEGER NOT NULL,
        unit_price INTEGER NOT NULL,
        subtotal INTEGER NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES pos_transactions(id)
      )
    ''');

    // Tabel Record Refill Air RO
    await db.execute('''
      CREATE TABLE refill_records (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        type TEXT NOT NULL,
        price INTEGER NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Tabel Pengaturan CMS (key-value)
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ═══════════════════════════════════════════════════════
  //  PRODUK
  // ═══════════════════════════════════════════════════════

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final rows = await db.query('products', orderBy: 'name ASC');
    return rows.map(Product.fromSqliteMap).toList();
  }

  Future<void> insertProduct(Product product) async {
    final db = await database;
    await db.insert('products', product.toSqliteMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update('products', product.toSqliteMap(),
        where: 'id = ?', whereArgs: [product.id]);
  }

  Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateProductStock(String id, int newStock) async {
    final db = await database;
    await db.update(
      'products',
      {'stock': newStock, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Product>> getLowStockProducts(int threshold) async {
    final db = await database;
    final rows = await db.query('products',
        where: 'stock <= low_stock_threshold', orderBy: 'stock ASC');
    return rows.map(Product.fromSqliteMap).toList();
  }

  // ═══════════════════════════════════════════════════════
  //  TRANSAKSI POS
  // ═══════════════════════════════════════════════════════

  Future<void> insertPosTransaction(PosTransaction trx) async {
    final db = await database;
    await db.insert('pos_transactions', trx.toSqliteMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    for (final item in trx.items) {
      await db.insert('pos_transaction_items', item.toSqliteMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<PosTransaction>> getUnsyncedPosTransactions() async {
    final db = await database;
    final rows = await db
        .query('pos_transactions', where: 'is_synced = 0', orderBy: 'timestamp ASC');
    return Future.wait(rows.map((row) async {
      final items = await _getItemsForTransaction(row['id'] as String, db);
      return PosTransaction.fromSqliteMap(row, items);
    }));
  }

  Future<List<PosTransaction>> getPosTransactionsByDateRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final rows = await db.query(
      'pos_transactions',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp DESC',
    );
    return Future.wait(rows.map((row) async {
      final items = await _getItemsForTransaction(row['id'] as String, db);
      return PosTransaction.fromSqliteMap(row, items);
    }));
  }

  Future<void> markPosTransactionSynced(String id) async {
    final db = await database;
    await db.update('pos_transactions', {'is_synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<PosTransactionItem>> _getItemsForTransaction(
      String transactionId, Database db) async {
    final rows = await db.query('pos_transaction_items',
        where: 'transaction_id = ?', whereArgs: [transactionId]);
    return rows.map(PosTransactionItem.fromSqliteMap).toList();
  }

  // ═══════════════════════════════════════════════════════
  //  REFILL AIR RO
  // ═══════════════════════════════════════════════════════

  Future<void> insertRefillRecord(RefillRecord record) async {
    final db = await database;
    await db.insert('refill_records', record.toSqliteMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<RefillRecord>> getUnsyncedRefillRecords() async {
    final db = await database;
    final rows = await db
        .query('refill_records', where: 'is_synced = 0', orderBy: 'timestamp ASC');
    return rows.map(RefillRecord.fromSqliteMap).toList();
  }

  Future<List<RefillRecord>> getRefillRecordsByDateRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final rows = await db.query(
      'refill_records',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp DESC',
    );
    return rows.map(RefillRecord.fromSqliteMap).toList();
  }

  Future<void> markRefillRecordSynced(String id) async {
    final db = await database;
    await db.update('refill_records', {'is_synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════════════
  //  PENGATURAN CMS
  // ═══════════════════════════════════════════════════════

  Future<AppSettings> getSettings() async {
    final db = await database;
    final rows = await db.query('app_settings');
    if (rows.isEmpty) return const AppSettings();
    final map = {for (final r in rows) r['key'] as String: r['value'] as String};
    return AppSettings.fromMap({
      'store_name': map['store_name'],
      'store_address': map['store_address'],
      'store_phone': map['store_phone'],
      'receipt_footer': map['receipt_footer'],
      'refill_price_antar': int.tryParse(map['refill_price_antar'] ?? '5000'),
      'refill_price_ambil': int.tryParse(map['refill_price_ambil'] ?? '4000'),
      'low_stock_threshold': int.tryParse(map['low_stock_threshold'] ?? '10'),
      'currency_symbol': map['currency_symbol'],
    });
  }

  Future<void> saveSettings(AppSettings settings) async {
    final db = await database;
    final batch = db.batch();
    settings.toMap().forEach((key, value) {
      batch.insert(
        'app_settings',
        {'key': key, 'value': value.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    await batch.commit(noResult: true);
  }
}
