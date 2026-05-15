import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/pos_transaction_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/database_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/cart_item_tile.dart';
import 'receipt_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cashCtrl = TextEditingController();
  int _cashAmount = 0;

  @override
  void dispose() {
    _cashCtrl.dispose();
    super.dispose();
  }

  int get _change => (_cashAmount - context.read<CartProvider>().total)
      .clamp(0, 9999999);

  bool get _canPay =>
      _cashAmount >= context.read<CartProvider>().total &&
      !context.read<CartProvider>().isEmpty;

  Future<void> _processPayment() async {
    final cart = context.read<CartProvider>();
    final settings = context.read<SettingsProvider>().settings;
    final productProvider = context.read<ProductProvider>();

    final trxId = const Uuid().v4();
    final trx = PosTransaction(
      id: trxId,
      timestamp: DateTime.now(),
      totalAmount: cart.total,
      cashReceived: _cashAmount,
      changeAmount: _change,
      items: cart.toTransactionItems(trxId),
    );

    // Simpan ke SQLite
    await DatabaseService().insertPosTransaction(trx);

    // Coba sync ke Firestore
    try {
      await FirestoreService().addPosTransaction(trx);
      await DatabaseService().markPosTransactionSynced(trxId);
    } catch (_) {}

    // Kurangi stok setiap produk
    for (final item in cart.itemList) {
      await productProvider.deductStock(item.product.id, item.qty);
    }

    cart.clearCart();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(transaction: trx, settings: settings),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final settings = context.watch<SettingsProvider>().settings;
    final currency = NumberFormat.currency(
        locale: 'id_ID', symbol: '${settings.currencySymbol} ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Belanja'),
        actions: [
          TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Kosongkan Keranjang?'),
                  content: const Text('Semua item akan dihapus.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal')),
                    TextButton(
                        onPressed: () {
                          cart.clearCart();
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('Kosongkan',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            label: Text('Kosongkan',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Daftar Item ──────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: cart.itemList.length,
              itemBuilder: (_, i) {
                final item = cart.itemList[i];
                return CartItemTile(
                  item: item,
                  currencySymbol: settings.currencySymbol,
                  onIncrease: () => cart.addItem(item.product),
                  onDecrease: () => cart.decreaseQty(item.product.id),
                  onRemove: () => cart.removeItem(item.product.id),
                );
              },
            ),
          ),

          // ── Panel Pembayaran ─────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: const Offset(0, -4))
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total',
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(
                      currency.format(cart.total),
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00695C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Input uang diterima
                TextField(
                  id: 'cart_cash_input',
                  controller: _cashCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Uang Diterima',
                    prefixIcon: Icon(Icons.payments_outlined),
                    helperText: 'Masukkan jumlah uang tunai dari pelanggan',
                  ),
                  onChanged: (v) =>
                      setState(() => _cashAmount = int.tryParse(v) ?? 0),
                ),
                const SizedBox(height: 12),

                // Kembalian
                if (_cashAmount > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _change >= 0
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _change >= 0
                              ? Colors.green.shade200
                              : Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Kembalian',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600)),
                        Text(
                          currency.format(_change),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: _change >= 0
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Tombol Bayar
                ElevatedButton.icon(
                  id: 'cart_pay_button',
                  onPressed: _canPay ? _processPayment : null,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Proses Pembayaran'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
