import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';

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
    }

    setState(() => _isLoading = false);
    if (mounted) Navigator.pop(context);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Produk' : 'Tambah Produk'),
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
                  onPressed: _showAddCategoryDialog,
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

  void _showAddCategoryDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kategori'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Nama Kategori',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                final cp = context.read<CategoryProvider>();
                final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
                final newCat = await cp.addCategory(ctrl.text.trim(), userId);
                if (newCat != null) {
                  setState(() => _selectedCategory = newCat.id);
                }
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
