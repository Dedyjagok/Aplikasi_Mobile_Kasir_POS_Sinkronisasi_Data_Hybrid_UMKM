import 'package:cloud_firestore/cloud_firestore.dart';

/// Jenis layanan refill air RO.
enum RefillType {
  antar, // Diantar ke pelanggan — harga lebih mahal
  ambil, // Diambil sendiri oleh pelanggan — harga lebih murah
}

extension RefillTypeExt on RefillType {
  String get label => this == RefillType.antar ? 'Antar' : 'Ambil Sendiri';
  String get value => this == RefillType.antar ? 'antar' : 'ambil';

  static RefillType fromString(String s) =>
      s == 'antar' ? RefillType.antar : RefillType.ambil;
}

/// Satu record pencatatan isi ulang air RO.
class RefillRecord {
  final String id;
  final DateTime timestamp;
  final RefillType type;
  final int price; // harga saat transaksi (snapshot dari pengaturan)
  bool isSynced;

  RefillRecord({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.price,
    this.isSynced = false,
  });

  // ── SQLite ──────────────────────────────────────────────
  Map<String, dynamic> toSqliteMap() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'type': type.value,
        'price': price,
        'is_synced': isSynced ? 1 : 0,
      };

  factory RefillRecord.fromSqliteMap(Map<String, dynamic> map) => RefillRecord(
        id: map['id'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        type: RefillTypeExt.fromString(map['type'] as String),
        price: map['price'] as int,
        isSynced: (map['is_synced'] as int? ?? 0) == 1,
      );

  // ── Firestore ───────────────────────────────────────────
  Map<String, dynamic> toFirestoreMap() => {
        'timestamp': Timestamp.fromDate(timestamp),
        'type': type.value,
        'price': price,
        'is_synced': true,
      };

  factory RefillRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RefillRecord(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: RefillTypeExt.fromString(data['type'] as String? ?? 'ambil'),
      price: data['price'] as int? ?? 0,
      isSynced: true,
    );
  }
}
