import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String? _selectedCategory;
  String _stockSort = 'Semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts(forceCloud: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final categories = context.watch<CategoryProvider>().categories;
    final settings = context.watch<SettingsProvider>().settings;
    final currency = NumberFormat.currency(
        locale: 'id_ID',
        symbol: '${settings.currencySymbol} ',
        decimalDigits: 0);

    // Memproses Filter Lokal & Sorting
    var displayList = products.products.toList();

    if (_selectedCategory != null) {
      displayList.retainWhere((p) {
        final catName = categories.where((c) => c.id == p.categoryId).firstOrNull?.name ?? 'Tanpa Kategori';
        return catName == _selectedCategory;
      });
    }

    if (_stockSort == 'Terbanyak') {
      displayList.sort((a, b) => b.stock.compareTo(a.stock));
    } else if (_stockSort == 'Terdikit') {
      displayList.sort((a, b) => a.stock.compareTo(b.stock));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ProductFormScreen()),
            ).then((_) => products.loadProducts()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Cari produk...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: products.setSearchQuery,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedCategory,
                            hint: Text('Kategori', style: GoogleFonts.poppins(fontSize: 13)),
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text('Semua Kategori', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                              ...categories.map((c) => DropdownMenuItem(
                                value: c.name,
                                child: Text(c.name, style: GoogleFonts.poppins(fontSize: 13)),
                              )),
                              DropdownMenuItem(
                                value: 'Tanpa Kategori',
                                child: Text('Tanpa Kategori', style: GoogleFonts.poppins(fontSize: 13)),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedCategory = val);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _stockSort,
                            items: [
                              DropdownMenuItem(
                                value: 'Semua',
                                child: Text('Urut Stok', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                              DropdownMenuItem(
                                value: 'Terbanyak',
                                child: Text('Stok Terbanyak', style: GoogleFonts.poppins(fontSize: 13)),
                              ),
                              DropdownMenuItem(
                                value: 'Terdikit',
                                child: Text('Stok Terdikit', style: GoogleFonts.poppins(fontSize: 13)),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _stockSort = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: products.isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('Belum ada produk',
                                style: GoogleFonts.poppins()),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ProductFormScreen()),
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah Produk'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: displayList.length,
                        itemBuilder: (_, i) {
                          final p = displayList[i];
                          final catName = categories.where((c) => c.id == p.categoryId).firstOrNull?.name ?? 'Tanpa Kategori';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00695C)
                                      .withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                    Icons.inventory_2_outlined,
                                    color: Color(0xFF00695C)),
                              ),
                              title: Text(p.name,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (p.categoryId.isNotEmpty)
                                    Text(catName,
                                        style: GoogleFonts.poppins(
                                            fontSize: 12)),
                                  Row(
                                    children: [
                                      Text(
                                        currency.format(p.sellPrice),
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF00695C),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: p.isLowStock
                                              ? Colors.red.shade100
                                              : Colors.green.shade100,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Stok: ${p.stock}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: p.isLowStock
                                                ? Colors.red.shade700
                                                : Colors.green.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        color: Color(0xFF00695C)),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              ProductFormScreen(
                                                  product: p)),
                                    ).then((_) => products.loadProducts()),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () => _confirmDelete(
                                        context, products, p.id, p.name),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, ProductProvider pp,
      String id, String name) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Produk?'),
        content: Text('Produk "$name" akan dihapus permanen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          TextButton(
              onPressed: () {
                pp.deleteProduct(id);
                Navigator.pop(ctx);
              },
              child: const Text('Hapus',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
