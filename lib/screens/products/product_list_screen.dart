import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/tutorial_overlay.dart';
import 'product_category_screen.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String? _selectedCategory;
  String _stockSort = 'Semua';

  bool _showTutorial = false;
  String _catalogStage = 'none';

  final _keySearchFilterRow = GlobalKey();
  final _keyAddButton = GlobalKey();
  final _keyEditButton = GlobalKey();
  final _keyBackButton = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories(forceCloud: true);
      context.read<ProductProvider>().loadProducts(forceCloud: true);
      _checkTutorial();
    });
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final stage = prefs.getString('tutorial_catalog_stage') ?? 'none';
    if (stage != 'none' && stage != 'completed' && mounted) {
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

  /// Navigasi ke ProductFormScreen dan set stage ke 'form_intro' terlebih dahulu.
  /// Ini memastikan ProductFormScreen langsung menampilkan tutorial saat dibuka.
  Future<void> _navigateToFormWithTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tutorial_catalog_stage', 'form_intro');
    if (!mounted) return;
    setState(() => _showTutorial = false);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductFormScreen()),
    );
    if (!mounted) return;
    context.read<ProductProvider>().loadProducts();
    _checkTutorial();
  }

  /// Navigasi biasa ke ProductFormScreen tanpa mengubah tutorial stage.
  Future<void> _navigateToForm() async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductFormScreen()),
    );
    if (!mounted) return;
    context.read<ProductProvider>().loadProducts();
    _checkTutorial();
  }

  List<TutorialStep> _buildListSteps() {
    return [
      const TutorialStep(
        message:
            'Selamat datang di Katalog Produk! \n\nDi sini Anda bisa mengelola semua barang dagangan kelontong Anda.',
        characterPosition: 'left',
      ),
      TutorialStep(
        message:
            'Gunakan kolom Cari Produk untuk mencari barang secara instan, serta dropdown Kategori dan Urutan Stok untuk memfilter list.',
        targetKey: _keySearchFilterRow,
        characterPosition: 'left',
        verticalPosition: 'bottom',
      ),
      TutorialStep(
        message: 'Mari kita coba menambahkan produk baru. Ketuk "Selesai" untuk langsung membuka formulir.',
        targetKey: _keyAddButton,
        characterPosition: 'right',
        verticalPosition: 'bottom',
      ),
    ];
  }

  List<TutorialStep> _buildEditSteps() {
    return [
      const TutorialStep(
        message:
            'Luar biasa!  Produk baru Anda sekarang sudah terdaftar di sistem.',
        characterPosition: 'left',
      ),
      TutorialStep(
        message:
            'Jika ingin mengubah informasi produk (seperti mengoreksi stok atau harga), Anda bisa menekan tombol Edit di kartu produk ini.',
        targetKey: _keyEditButton,
        characterPosition: 'left',
        verticalPosition: 'bottom',
      ),
      const TutorialStep(
        message:
            'Tutorial manajemen barang selesai! \n\nSekarang Anda sudah siap mengisi barang dagangan Anda. Selanjutnya, silakan kembali ke Dashboard untuk mencoba transaksi POS!',
        characterPosition: 'left',
      ),
      TutorialStep(
        message:
            'Ketuk "Selesai" untuk kembali ke Dashboard.',
        targetKey: _keyBackButton,
        characterPosition: 'left',
        verticalPosition: 'bottom',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final categories = context.watch<CategoryProvider>().categories;
    final settings = context.watch<SettingsProvider>().settings;
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '${settings.currencySymbol} ',
      decimalDigits: 0,
    );

    var displayList = products.products.toList();

    if (_selectedCategory != null) {
      displayList.retainWhere((p) {
        final catName =
            categories.where((c) => c.id == p.categoryId).firstOrNull?.name ??
            'Tanpa Kategori';
        return catName == _selectedCategory;
      });
    }

    if (_stockSort == 'Terbanyak') {
      displayList.sort((a, b) => b.stock.compareTo(a.stock));
    } else if (_stockSort == 'Terdikit') {
      displayList.sort((a, b) => a.stock.compareTo(b.stock));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final prefs = await SharedPreferences.getInstance();
        final stage = prefs.getString('tutorial_catalog_stage') ?? 'none';
        if (stage == 'list_highlight_edit') {
          await prefs.setString('tutorial_catalog_stage', 'home_pos_intro');
        }
        if (mounted) Navigator.pop(context);
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text('Katalog Produk'),
              leading: IconButton(
                key: _keyBackButton,
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final stage =
                      prefs.getString('tutorial_catalog_stage') ?? 'none';
                  if (stage == 'list_highlight_edit') {
                    await prefs.setString(
                      'tutorial_catalog_stage',
                      'home_pos_intro',
                    );
                  }
                  if (mounted) Navigator.pop(context);
                },
              ),
              actions: [
                IconButton(
                  key: _keyAddButton,
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final stage =
                        prefs.getString('tutorial_catalog_stage') ?? 'none';

                    // ─── PERBAIKAN UTAMA ───────────────────────────────────
                    // Jika sedang di tahap 'list_intro', set stage ke 'form_intro'
                    // SEBELUM navigasi agar ProductFormScreen langsung memunculkan
                    // tutorial saat pertama kali dibuka.
                    if (stage == 'list_intro') {
                      await _navigateToFormWithTutorial();
                    } else {
                      await _navigateToForm();
                    }
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                // Search & Filter
                Padding(
                  key: _keySearchFilterRow,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedCategory,
                                  hint: Text(
                                    'Kategori',
                                    style: GoogleFonts.poppins(fontSize: 13),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: null,
                                      child: Text(
                                        'Semua Kategori',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    ...categories.map(
                                      (c) => DropdownMenuItem(
                                        value: c.name,
                                        child: Text(
                                          c.name,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Tanpa Kategori',
                                      child: Text(
                                        'Tanpa Kategori',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                        ),
                                      ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
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
                                      child: Text(
                                        'Urut Stok',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Terbanyak',
                                      child: Text(
                                        'Stok Terbanyak',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Terdikit',
                                      child: Text(
                                        'Stok Terdikit',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                        ),
                                      ),
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
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada produk',
                                style: GoogleFonts.poppins(),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final stage =
                                      prefs.getString(
                                        'tutorial_catalog_stage',
                                      ) ??
                                      'none';
                                  if (stage == 'list_intro') {
                                    await _navigateToFormWithTutorial();
                                  } else {
                                    await _navigateToForm();
                                  }
                                },
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
                            final catName =
                                categories
                                    .where((c) => c.id == p.categoryId)
                                    .firstOrNull
                                    ?.name ??
                                'Tanpa Kategori';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF00695C,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_outlined,
                                    color: Color(0xFF00695C),
                                  ),
                                ),
                                title: Text(
                                  p.name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (p.categoryId.isNotEmpty)
                                      Text(
                                        catName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                        ),
                                      ),
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
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: p.isLowStock
                                                ? Colors.red.shade100
                                                : Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
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
                                      key: i == 0 ? _keyEditButton : null,
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: Color(0xFF00695C),
                                      ),
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ProductFormScreen(product: p),
                                        ),
                                      ).then((_) {
                                        products.loadProducts();
                                        _checkTutorial();
                                      }),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _confirmDelete(
                                        context,
                                        products,
                                        p.id,
                                        p.name,
                                      ),
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
          ),
          if (_showTutorial)
            Positioned.fill(
              child: TutorialOverlay(
                tutorialKey: 'product_list_$_catalogStage',
                steps: _catalogStage == 'list_highlight_edit'
                    ? _buildEditSteps()
                    : _buildListSteps(),
                onComplete: () async {
                  setState(() => _showTutorial = false);
                  final prefs = await SharedPreferences.getInstance();
                  if (_catalogStage == 'list_intro') {
                    // onComplete di sini berarti user skip semua step tanpa
                    // menekan tombol "+", jadi kita tetap arahkan ke form.
                    await _navigateToFormWithTutorial();
                  } else {
                    await prefs.setString(
                      'tutorial_catalog_stage',
                      'home_pos_intro',
                    );
                    if (mounted) {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  }
                },
                onSkip: () async {
                  setState(() => _showTutorial = false);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('tutorial_catalog_stage', 'completed');
                },
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext ctx,
    ProductProvider pp,
    String id,
    String name,
  ) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Produk?'),
        content: Text('Produk "$name" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              pp.deleteProduct(id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}