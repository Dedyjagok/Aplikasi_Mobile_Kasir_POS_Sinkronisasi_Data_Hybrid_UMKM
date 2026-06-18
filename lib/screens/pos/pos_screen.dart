import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/tutorial_overlay.dart';
import '../pos/cart_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchCtrl = TextEditingController();

  bool _showTutorial = false;
  String _catalogStage = 'none';

  final _keySearchCtrl = GlobalKey();
  final _keyFirstProductCard = GlobalKey();
  final _keyCartFab = GlobalKey();

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
    if ((stage == 'pos_intro' || stage == 'pos_cart_highlight') && mounted) {
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

  List<TutorialStep> _buildPosSteps() {
    return [
      const TutorialStep(
        message: 'Selamat datang di Kasir Produk! \n\nDi sini Anda bisa memproses transaksi penjualan barang kelontong dengan mudah.',
        characterPosition: 'left',
      ),
      TutorialStep(
        message: 'Gunakan kolom "Cari produk" untuk mencari barang secara instan.',
        targetKey: _keySearchCtrl,
        characterPosition: 'left',
        verticalPosition: 'bottom',
      ),
      TutorialStep(
        message: 'Sekarang, ketuk "Selesai" lalu ketuk kartu produk pertama anda untuk menambahkannya ke keranjang.',
        targetKey: _keyFirstProductCard,
        characterPosition: 'left',
        verticalPosition: 'bottom',
      ),
    ];
  }

  List<TutorialStep> _buildCartHighlightSteps() {
    return [
      TutorialStep(
        message: 'Bagus! Produk sudah masuk keranjang. Sekarang ketuk "Selesai" untuk langsung membuka Keranjang dan melanjutkan transaksi.',
        targetKey: _keyCartFab,
        characterPosition: 'right',
        verticalPosition: 'top',
      ),
    ];
  }

  Future<void> _goBack() async {
    final prefs = await SharedPreferences.getInstance();
    final stage = prefs.getString('tutorial_catalog_stage') ?? 'none';
    if (stage == 'pos_intro' || stage == 'pos_cart_highlight') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan selesaikan transaksi atau lewati tutorial di balon petunjuk.'),
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
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final cart = context.watch<CartProvider>();
    final settings = context.watch<SettingsProvider>().settings;

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
              title: const Text('Kasir Produk'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              ),
              actions: [
                // Tombol keranjang dengan badge qty
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined),
                      onPressed: cart.isEmpty
                          ? null
                          : () async {
                              final prefs = await SharedPreferences.getInstance();
                              final stage = prefs.getString('tutorial_catalog_stage') ?? 'none';
                              if (stage == 'pos_cart_highlight') {
                                await prefs.setString('tutorial_catalog_stage', 'cart_intro');
                              }
                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const CartScreen()),
                                ).then((_) => _checkTutorial());
                              }
                            },
                    ),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          child: Text(
                            '${cart.itemCount}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            body: Column(
              children: [
                // ── Search Bar ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    key: _keySearchCtrl,
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Cari produk...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                products.setSearchQuery('');
                              })
                          : null,
                    ),
                    onChanged: products.setSearchQuery,
                  ),
                ),

                // ── Grid Produk ──────────────────────────────────
                Expanded(
                  child: products.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : products.products.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory_2_outlined,
                                      size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text('Tidak ada produk',
                                      style: GoogleFonts.poppins(
                                          color: Colors.grey.shade600)),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.78,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: products.products.length,
                              itemBuilder: (_, i) {
                                final p = products.products[i];
                                return ProductCard(
                                  key: i == 0 ? _keyFirstProductCard : null,
                                  product: p,
                                  currencySymbol: settings.currencySymbol,
                                  onTap: () async {
                                    cart.addItem(p);
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text('${p.name} ditambahkan'),
                                      duration:
                                          const Duration(milliseconds: 700),
                                      backgroundColor:
                                          const Color(0xFF00695C),
                                    ));
                                    final prefs = await SharedPreferences.getInstance();
                                    final stage = prefs.getString('tutorial_catalog_stage') ?? 'none';
                                    if (stage == 'pos_intro') {
                                      await prefs.setString('tutorial_catalog_stage', 'pos_cart_highlight');
                                      _checkTutorial();
                                    }
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),

            // ── FAB: Buka Keranjang ──────────────────────────────
            floatingActionButton: cart.isEmpty
                ? null
                : FloatingActionButton.extended(
                    key: _keyCartFab,
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final stage = prefs.getString('tutorial_catalog_stage') ?? 'none';
                      if (stage == 'pos_cart_highlight') {
                        await prefs.setString('tutorial_catalog_stage', 'cart_intro');
                      }
                      if (mounted) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CartScreen()),
                        ).then((_) => _checkTutorial());
                      }
                    },
                    icon: const Icon(Icons.shopping_cart),
                    label: Text(
                      '${cart.itemCount} item',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: const Color(0xFF00695C),
                  ),
          ),
          if (_showTutorial)
            Positioned.fill(
              child: TutorialOverlay(
                tutorialKey: 'pos_screen_$_catalogStage',
                steps: _catalogStage == 'pos_cart_highlight'
                    ? _buildCartHighlightSteps()
                    : _buildPosSteps(),
                onComplete: () async {
                  setState(() => _showTutorial = false);
                  if (_catalogStage == 'pos_cart_highlight') {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('tutorial_catalog_stage', 'cart_intro');
                    if (mounted) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CartScreen()),
                      ).then((_) => _checkTutorial());
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
