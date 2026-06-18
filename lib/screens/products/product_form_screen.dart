import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/tutorial_overlay.dart';
import 'product_category_screen.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product; // null = tambah baru

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  String? _selectedCategory;
  late final TextEditingController _costCtrl;
  late final TextEditingController _sellCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _thresholdCtrl;
  bool _isLoading = false;

  bool _showTutorial = false;
  String _catalogStage = 'none';

  final _keyAddCategoryButton = GlobalKey();
  final _keySaveButton = GlobalKey();

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _selectedCategory = p?.categoryId;
    _costCtrl = TextEditingController(text: p?.costPrice.toString() ?? '');
    _sellCtrl =
        TextEditingController(text: p?.sellPrice.toString() ?? '');
    _stockCtrl =
        TextEditingController(text: p?.stock.toString() ?? '0');
    _thresholdCtrl = TextEditingController(
        text: p?.lowStockThreshold.toString() ?? '10');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTutorial();
    });
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final stage = prefs.getString('tutorial_catalog_stage') ?? 'none';
    if ((stage == 'form_intro' || stage == 'form_add_product') && mounted) {
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

  List<TutorialStep> _buildFormIntroSteps() {
    return [
      const TutorialStep(
        message: 'Ini adalah formulir produk kelontong. Anda wajib mengisi Nama Produk, Harga Modal, Harga Jual, dan Kategori.',
        characterPosition: 'left',
      ),
      TutorialStep(
        message: 'Ketuk "Selesai" untuk langsung membuka halaman kelola kategori terlebih dahulu.',
        targetKey: _keyAddCategoryButton,
        characterPosition: 'left',
        verticalPosition: 'bottom',
      ),
    ];
  }

  List<TutorialStep> _buildAddProductSteps() {
    return [
      const TutorialStep(
        message: 'Bagus! Sekarang isi data produk anda',
        characterPosition: 'left',
      ),
      TutorialStep(
        message: 'Silakan ketuk "Selesai" untuk mengisi form, lalu tekan tombol "Tambah Produk" untuk menyimpannya.',
        targetKey: _keySaveButton,
        characterPosition: 'left',
        verticalPosition: 'top',
      ),
    ];
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _costCtrl,
      _sellCtrl, _stockCtrl, _thresholdCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final pp = context.read<ProductProvider>();
    final settings = context.read<SettingsProvider>().settings;

    final product = Product(
      id: widget.product?.id ?? pp.generateProductId(),
      userId: widget.product?.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '',
      name: _nameCtrl.text.trim(),
      categoryId: _selectedCategory ?? '',
      costPrice: int.parse(_costCtrl.text),
      sellPrice: int.parse(_sellCtrl.text),
      stock: int.parse(_stockCtrl.text),
      lowStockThreshold:
          int.tryParse(_thresholdCtrl.text) ?? settings.lowStockThreshold,
    );

    if (_isEdit) {
      await pp.updateProduct(product);
    } else {
      await pp.addProduct(product);
      final prefs = await SharedPreferences.getInstance();
      final stage = prefs.getString('tutorial_catalog_stage') ?? 'none';
      if (stage == 'form_add_product') {
        await prefs.setString('tutorial_catalog_stage', 'list_highlight_edit');
      }
    }

    setState(() => _isLoading = false);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _goBack() async {
    final prefs = await SharedPreferences.getInstance();
    final stage = prefs.getString('tutorial_catalog_stage') ?? 'none';
    if (stage == 'form_add_product' || stage == 'form_intro') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan tambahkan satu produk terlebih dahulu untuk melanjutkan.'),
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
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;

    // Pastikan _selectedCategory valid
    if (_selectedCategory != null && !categories.any((c) => c.id == _selectedCategory)) {
      _selectedCategory = categories.isNotEmpty ? categories.first.id : null;
    } else if (_selectedCategory == null && categories.isNotEmpty) {
      _selectedCategory = categories.first.id;
    }

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
              title: Text(_isEdit ? 'Edit Produk' : 'Tambah Produk'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              ),
            ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _field('Nama Produk *', _nameCtrl,
                    hint: 'Contoh: Snack Chitato',
                    validator: (v) =>
                        v!.isEmpty ? 'Nama wajib diisi' : null),
                const SizedBox(height: 16),
                
                // Dropdown Kategori
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(labelText: 'Kategori'),
                        items: categories.map((cat) {
                          return DropdownMenuItem(value: cat.id, child: Text(cat.name));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val),
                        validator: (v) => v == null ? 'Kategori wajib dipilih' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      key: _keyAddCategoryButton,
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final stage = prefs.getString('tutorial_catalog_stage') ?? 'none';
                        if (stage == 'form_intro') {
                          await prefs.setString('tutorial_catalog_stage', 'category_intro');
                        }
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProductCategoryScreen(),
                            ),
                          ).then((_) => _checkTutorial());
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Tambah Kategori Baru',
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _field('Harga Modal *', _costCtrl,
                            isNum: true,
                            validator: (v) =>
                                v!.isEmpty ? 'Wajib diisi' : null)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field('Harga Jual *', _sellCtrl,
                            isNum: true,
                            validator: (v) =>
                                v!.isEmpty ? 'Wajib diisi' : null)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _field('Stok Awal', _stockCtrl,
                            isNum: true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field('Batas Stok Rendah', _thresholdCtrl,
                            isNum: true,
                            hint: 'Default: 10')),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  key: _keySaveButton,
                  onPressed: _isLoading ? null : _save,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Icon(_isEdit ? Icons.save : Icons.add),
                  label: Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Produk'),
                ),
              ],
            ),
          ),
        ),
        if (_showTutorial)
          Positioned.fill(
            child: TutorialOverlay(
              tutorialKey: 'product_form_$_catalogStage',
              steps: _catalogStage == 'form_add_product'
                  ? _buildAddProductSteps()
                  : _buildFormIntroSteps(),
              onComplete: () async {
                setState(() => _showTutorial = false);
                final prefs = await SharedPreferences.getInstance();
                if (_catalogStage == 'form_intro') {
                  await prefs.setString('tutorial_catalog_stage', 'category_intro');
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProductCategoryScreen()),
                    ).then((_) {
                      _checkTutorial();
                    });
                  }
                } else if (_catalogStage == 'form_add_product') {
                  // Biarkan tetap 'form_add_product' agar saat user tekan "Tambah Produk" (_save)
                  // statusnya ter-update ke 'list_highlight_edit'
                } else {
                  await prefs.setString('tutorial_catalog_stage', 'completed');
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

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    bool isNum = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      inputFormatters:
          isNum ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      validator: validator,
    );
  }
}
