import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';

class ProductCategoryScreen extends StatefulWidget {
  const ProductCategoryScreen({super.key});

  @override
  State<ProductCategoryScreen> createState() => _ProductCategoryScreenState();
}

class _ProductCategoryScreenState extends State<ProductCategoryScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _addCategory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kategori Baru'),
        content: TextField(
          controller: _ctrl,
          decoration: const InputDecoration(
            labelText: 'Nama Kategori',
            hintText: 'Misal: Snack',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newCat = _ctrl.text.trim();
              if (newCat.isNotEmpty) {
                final settingsProvider = context.read<SettingsProvider>();
                final currentCats = List<String>.from(settingsProvider.settings.productCategories);
                
                // Cek duplikat case-insensitive
                final isExist = currentCats.any((c) => c.toLowerCase() == newCat.toLowerCase());
                
                if (isExist) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kategori sudah ada!')),
                  );
                } else {
                  currentCats.add(newCat);
                  final updated = settingsProvider.settings.copyWith(productCategories: currentCats);
                  await settingsProvider.updateSettings(updated);
                  if (mounted) Navigator.pop(ctx);
                  _ctrl.clear();
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(String cat) async {
    final settingsProvider = context.read<SettingsProvider>();
    final currentCats = List<String>.from(settingsProvider.settings.productCategories);
    
    if (currentCats.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus ada 1 kategori tersisa!')),
      );
      return;
    }

    currentCats.remove(cat);
    final updated = settingsProvider.settings.copyWith(productCategories: currentCats);
    await settingsProvider.updateSettings(updated);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final categories = settings.productCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori Produk'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.category, color: Color(0xFF00695C)),
              ),
              title: Text(
                cat,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hapus Kategori?'),
                      content: Text('Anda yakin ingin menghapus kategori "$cat"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () {
                            _deleteCategory(cat);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCategory,
        icon: const Icon(Icons.add),
        label: const Text('Kategori'),
      ),
    );
  }
}
