import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/category_model.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';

class CategoryProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final FirestoreService _firestore = FirestoreService();

  List<CategoryModel> _categories = [];
  bool _isLoading = false;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _db.getAllCategories();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CategoryModel?> addCategory(String name, String userId) async {
    // Cek apakah kategori dengan nama yang sama sudah ada
    if (_categories.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
      return _categories.firstWhere((c) => c.name.toLowerCase() == name.toLowerCase());
    }

    final newCategory = CategoryModel(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      updatedAt: DateTime.now(),
    );

    try {
      await _db.insertCategory(newCategory);
      _categories.add(newCategory);
      _categories.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();

      // Sinkronisasi ke Firestore tanpa memblokir UI
      _firestore.addCategory(newCategory).catchError((e) {
        debugPrint('Error syncing new category to Firestore: $e');
      });

      return newCategory;
    } catch (e) {
      debugPrint('Error adding category: $e');
      return null;
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      final updated = CategoryModel(
        id: category.id,
        userId: category.userId,
        name: category.name,
        updatedAt: DateTime.now(),
      );
      await _db.updateCategory(updated);
      final index = _categories.indexWhere((c) => c.id == updated.id);
      if (index != -1) {
        _categories[index] = updated;
        _categories.sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
      }

      _firestore.updateCategory(updated).catchError((e) {
        debugPrint('Error syncing updated category to Firestore: $e');
      });
    } catch (e) {
      debugPrint('Error updating category: $e');
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _db.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();

      _firestore.deleteCategory(id).catchError((e) {
        debugPrint('Error syncing deleted category to Firestore: $e');
      });
    } catch (e) {
      debugPrint('Error deleting category: $e');
    }
  }
}
