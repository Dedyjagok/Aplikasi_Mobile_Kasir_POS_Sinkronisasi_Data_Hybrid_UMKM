import 'package:flutter/foundation.dart';
import '../models/pos_transaction_model.dart';
import '../models/product_model.dart';

/// Satu item di dalam keranjang belanja (bisa berbeda dari PosTransactionItem).
class CartItem {
  final Product product;
  int qty;

  CartItem({required this.product, this.qty = 1});

  int get subtotal => product.sellPrice * qty;
}

/// Mengelola keranjang belanja aktif di layar POS.
class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => Map.unmodifiable(_items);
  List<CartItem> get itemList => _items.values.toList();
  int get itemCount => _items.values.fold(0, (sum, e) => sum + e.qty);
  int get total => _items.values.fold(0, (sum, e) => sum + e.subtotal);
  bool get isEmpty => _items.isEmpty;

  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.qty++;
    } else {
      _items[product.id] = CartItem(product: product);
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void decreaseQty(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.qty <= 1) {
      _items.remove(productId);
    } else {
      _items[productId]!.qty--;
    }
    notifyListeners();
  }

  void setQty(String productId, int qty) {
    if (qty <= 0) {
      _items.remove(productId);
    } else if (_items.containsKey(productId)) {
      _items[productId]!.qty = qty;
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  /// Konversi keranjang ke list PosTransactionItem.
  List<PosTransactionItem> toTransactionItems(String transactionId) {
    return _items.values
        .map((ci) => PosTransactionItem(
              id: '${transactionId}_${ci.product.id}',
              transactionId: transactionId,
              productId: ci.product.id,
              productName: ci.product.name,
              qty: ci.qty,
              unitPrice: ci.product.sellPrice,
              subtotal: ci.subtotal,
            ))
        .toList();
  }
}
