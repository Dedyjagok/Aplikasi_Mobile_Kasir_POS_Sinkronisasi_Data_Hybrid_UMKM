import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/product_card.dart';
import '../pos/cart_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchCtrl = TextEditingController();

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir Produk'),
        actions: [
          // Tombol keranjang dengan badge qty
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: cart.isEmpty
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CartScreen())),
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
                            product: p,
                            currencySymbol: settings.currencySymbol,
                            onTap: () {
                              cart.addItem(p);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text('${p.name} ditambahkan'),
                                duration:
                                    const Duration(milliseconds: 700),
                                backgroundColor:
                                    const Color(0xFF00695C),
                              ));
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
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CartScreen())),
              icon: const Icon(Icons.shopping_cart),
              label: Text(
                '${cart.itemCount} item',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFF00695C),
            ),
    );
  }
}
