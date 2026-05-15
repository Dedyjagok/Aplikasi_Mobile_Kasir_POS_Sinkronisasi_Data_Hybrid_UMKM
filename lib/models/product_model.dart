import 'package:cloud_firestore/cloud_firestore.dart';

/// Model produk untuk modul POS (barang kelontong/dagangan).
class Product {
  final String id;
  final String name;
  final String category;
  final int costPrice; // harga modal
  final int sellPrice; // harga jual
  int stock;
  final int lowStockThreshold; // default 10
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    this.category = '',
    required this.costPrice,
    required this.sellPrice,
    this.stock = 0,
    this.lowStockThreshold = 10,
    this.updatedAt,
  });

  bool get isLowStock => stock <= lowStockThreshold;

  // ── SQLite ──────────────────────────────────────────────
  Map<String, dynamic> toSqliteMap() => {
        'id': id,
        'name': name,
        'category': category,
        'cost_price': costPrice,
        'sell_price': sellPrice,
        'stock': stock,
        'low_stock_threshold': lowStockThreshold,
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory Product.fromSqliteMap(Map<String, dynamic> map) => Product(
        id: map['id'] as String,
        name: map['name'] as String,
        category: map['category'] as String? ?? '',
        costPrice: map['cost_price'] as int,
        sellPrice: map['sell_price'] as int,
        stock: map['stock'] as int,
        lowStockThreshold: map['low_stock_threshold'] as int? ?? 10,
        updatedAt: map['updated_at'] != null
            ? DateTime.tryParse(map['updated_at'] as String)
            : null,
      );

  // ── Firestore ───────────────────────────────────────────
  Map<String, dynamic> toFirestoreMap() => {
        'name': name,
        'category': category,
        'cost_price': costPrice,
        'sell_price': sellPrice,
        'stock': stock,
        'low_stock_threshold': lowStockThreshold,
        'updated_at': FieldValue.serverTimestamp(),
      };

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '',
      costPrice: data['cost_price'] as int? ?? 0,
      sellPrice: data['sell_price'] as int? ?? 0,
      stock: data['stock'] as int? ?? 0,
      lowStockThreshold: data['low_stock_threshold'] as int? ?? 10,
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Product copyWith({
    String? name,
    String? category,
    int? costPrice,
    int? sellPrice,
    int? stock,
    int? lowStockThreshold,
  }) =>
      Product(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        costPrice: costPrice ?? this.costPrice,
        sellPrice: sellPrice ?? this.sellPrice,
        stock: stock ?? this.stock,
        lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
        updatedAt: DateTime.now(),
      );
}
