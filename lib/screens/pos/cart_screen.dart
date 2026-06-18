import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/pos_transaction_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/database_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/cart_item_tile.dart';
import '../../widgets/tutorial_overlay.dart';
import 'receipt_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cashCtrl = TextEditingController();
  int _cashAmount = 0;

  bool _showTutorial = false;
  String _catalogStage = 'none';

  final _keyFirstCartItem = GlobalKey();
  final _keyTotalRow = GlobalKey();
  final _keyCashField = GlobalKey();
  final _keyPayButton = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTutorial();
    });
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final stage = prefs.getString('tutorial_catalog_stage') ?? 'none';
    if ((stage == 'cart_intro' || stage == 'cart_payment_active') && mounted) {
      setState(() {
        _showTutorial = true;
        _catalogStage = stage;
      });
    } else {
      if (mounted) {
        setState(() {
          _showTutorial = false;
          _catalogStage = 'none';
        });
      }
    }
  }

  List<TutorialStep> _buildCartSteps() {
    return [
      const TutorialStep(
        message: 'Ini adalah halaman Keranjang Belanja.',
        characterPosition: 'left',
        verticalPosition: 'top',
      ),
      TutorialStep(
        message: 'Di sini Anda bisa melihat daftar item, menambah/mengurangi kuantitas, atau menghapus item.',
        targetKey: _keyFirstCartItem,
        characterPosition: 'left',
        verticalPosition: 'top',
      ),
      TutorialStep(
        message: 'Ini adalah detail total harga belanjaan yang harus dibayar.',
        targetKey: _keyTotalRow,
        characterPosition: 'left',
        verticalPosition: 'top',
      ),
      TutorialStep(
        message: 'Silakan ketuk "Selesai" untuk mengisi kolom Uang Diterima secara manual (misal: ketik 50000).',
        targetKey: _keyCashField,
        characterPosition: 'left',
        verticalPosition: 'top',
      ),
    ];
  }

  List<TutorialStep> _buildPaymentActiveSteps() {
    return [
      TutorialStep(
        message: 'Bagus! Uang yang diterima sudah cukup. Sekarang ketuk "Selesai" untuk langsung memproses transaksi secara otomatis.',
        targetKey: _keyPayButton,
        characterPosition: 'left',
        verticalPosition: 'top',
      ),
    ];
  }

  Future<void> _onCashChanged() async {
    final prefs = await SharedPreferences.getInstance();
    final stage = prefs.getString('tutorial_catalog_stage') ?? 'none';
    if (stage == 'cart_intro' && _cashAmount >= context.read<CartProvider>().total) {
      await prefs.setString('tutorial_catalog_stage', 'cart_payment_active');
      _checkTutorial();
    }
  }

  Future<void> _goBack() async {
    final prefs = await SharedPreferences.getInstance();
    final stage = prefs.getString('tutorial_catalog_stage') ?? 'none';
    if (stage == 'cart_intro' || stage == 'cart_payment_active') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan pembayaran dan selesaikan transaksi, atau lewati tutorial di balon petunjuk.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

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
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      timestamp: DateTime.now(),
      totalAmount: cart.total,
      cashReceived: _cashAmount,
      changeAmount: _change,
      items: cart.toTransactionItems(trxId),
    );

    // Simpan ke SQLite
    await DatabaseService().insertPosTransaction(trx);

    // Jalankan sync ke Firestore tanpa memblokir UI (fire and forget)
    FirestoreService().addPosTransaction(trx).then((_) {
      DatabaseService().markPosTransactionSynced(trxId);
    }).catchError((_) {});

    // Kurangi stok setiap produk
    for (final item in cart.itemList) {
      await productProvider.deductStock(item.product.id, item.qty);
    }

    final prefs = await SharedPreferences.getInstance();
    final stage = prefs.getString('tutorial_catalog_stage') ?? 'none';
    if (stage == 'cart_payment_active') {
      await prefs.setString('tutorial_catalog_stage', 'receipt_intro');
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _goBack();
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text('Keranjang Belanja'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              ),
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
                        key: i == 0 ? _keyFirstCartItem : null,
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
                        key: _keyTotalRow,
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
                        key: _keyCashField,
                        controller: _cashCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Uang Diterima',
                          prefixIcon: Icon(Icons.payments_outlined),
                          helperText: 'Masukkan jumlah uang tunai dari pelanggan',
                        ),
                        onChanged: (v) {
                          setState(() => _cashAmount = int.tryParse(v) ?? 0);
                          _onCashChanged();
                        },
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
                        key: _keyPayButton,
                        onPressed: _canPay ? _processPayment : null,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Proses Pembayaran'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_showTutorial)
            Positioned.fill(
              child: TutorialOverlay(
                tutorialKey: 'cart_screen_$_catalogStage',
                steps: _catalogStage == 'cart_payment_active'
                    ? _buildPaymentActiveSteps()
                    : _buildCartSteps(),
                onComplete: () async {
                  setState(() => _showTutorial = false);
                  if (_catalogStage == 'cart_payment_active') {
                    if (_canPay) {
                      _processPayment();
                    }
                  }
                },
                onSkip: () async {
                  setState(() => _showTutorial = false);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('tutorial_catalog_stage', 'completed');
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
