import 'package:cloud_firestore/cloud_firestore.dart';

/// Satu item di dalam keranjang / transaksi POS.
class PosTransactionItem {
  final String id;
  final String transactionId;
  final String productId;
  final String productName;
  final int qty;
  final int unitPrice;
  final int subtotal;

  PosTransactionItem({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.unitPrice,
    required this.subtotal,
  });

  Map<String, dynamic> toSqliteMap() => {
        'id': id,
        'transaction_id': transactionId,
        'product_id': productId,
        'product_name': productName,
        'qty': qty,
        'unit_price': unitPrice,
        'subtotal': subtotal,
      };

  factory PosTransactionItem.fromSqliteMap(Map<String, dynamic> map) =>
      PosTransactionItem(
        id: map['id'] as String,
        transactionId: map['transaction_id'] as String,
        productId: map['product_id'] as String,
        productName: map['product_name'] as String,
        qty: map['qty'] as int,
        unitPrice: map['unit_price'] as int,
        subtotal: map['subtotal'] as int,
      );

  Map<String, dynamic> toFirestoreItemMap() => {
        'product_id': productId,
        'product_name': productName,
        'qty': qty,
        'unit_price': unitPrice,
        'subtotal': subtotal,
      };
}

/// Header transaksi POS (satu kali bayar).
class PosTransaction {
  final String id;
  final String userId;
  final DateTime timestamp;
  final int totalAmount;
  final int cashReceived;
  final int changeAmount;
  final String paymentMethod;
  bool isSynced;
  final List<PosTransactionItem> items;

  PosTransaction({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.totalAmount,
    required this.cashReceived,
    required this.changeAmount,
    this.paymentMethod = 'Tunai',
    this.isSynced = false,
    this.items = const [],
  });

  Map<String, dynamic> toSqliteMap() => {
        'id': id,
        'user_id': userId,
        'timestamp': timestamp.toIso8601String(),
        'total_amount': totalAmount,
        'cash_received': cashReceived,
        'change_amount': changeAmount,
        'payment_method': paymentMethod,
        'is_synced': isSynced ? 1 : 0,
      };

  factory PosTransaction.fromSqliteMap(
    Map<String, dynamic> map,
    List<PosTransactionItem> items,
  ) =>
      PosTransaction(
        id: map['id'] as String,
        userId: map['user_id'] as String? ?? '',
        timestamp: DateTime.parse(map['timestamp'] as String),
        totalAmount: map['total_amount'] as int,
        cashReceived: map['cash_received'] as int,
        changeAmount: map['change_amount'] as int,
        paymentMethod: map['payment_method'] as String? ?? 'Tunai',
        isSynced: (map['is_synced'] as int? ?? 0) == 1,
        items: items,
      );

  Map<String, dynamic> toFirestoreMap() => {
        'user_id': userId,
        'timestamp': Timestamp.fromDate(timestamp),
        'total_amount': totalAmount,
        'cash_received': cashReceived,
        'change_amount': changeAmount,
        'payment_method': paymentMethod,
        'is_synced': true,
        'items': items.map((e) => e.toFirestoreItemMap()).toList(),
      };
}
