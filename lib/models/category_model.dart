import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String userId;
  final String name;
  final DateTime? updatedAt;

  CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    this.updatedAt,
  });

  // ── SQLite ──────────────────────────────────────────────
  Map<String, dynamic> toSqliteMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory CategoryModel.fromSqliteMap(Map<String, dynamic> map) => CategoryModel(
        id: map['id'] as String,
        userId: map['user_id'] as String? ?? '',
        name: map['name'] as String,
        updatedAt: map['updated_at'] != null
            ? DateTime.tryParse(map['updated_at'] as String)
            : null,
      );

  // ── Firestore ───────────────────────────────────────────
  Map<String, dynamic> toFirestoreMap() => {
        'name': name,
        'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CategoryModel(
      id: doc.id,
      userId: '', // Diisi nanti saat sync jika perlu, biasanya ditaruh di path doc
      name: data['name'] as String? ?? '',
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as Timestamp).toDate()
          : null,
    );
  }
}
