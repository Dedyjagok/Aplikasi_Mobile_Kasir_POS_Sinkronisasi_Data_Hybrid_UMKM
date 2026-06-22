import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../widgets/tutorial_overlay.dart';

class ProductCategoryScreen extends StatefulWidget {
  const ProductCategoryScreen({super.key});

  @override
  State<ProductCategoryScreen> createState() => _ProductCategoryScreenState();
}

class _ProductCategoryScreenState extends State<ProductCategoryScreen> {
  final _ctrl = TextEditingController();
  final _keyAddCategoryFab = GlobalKey();

  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTutorial();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final stage = prefs.getString('tutorial_catalog_stage') ?? 'none';
    if (stage == 'category_intro' && mounted) {
      setState(() {
        _showTutorial = true;
      });
    } else {
      if (mounted) {
        setState(() {
          _showTutorial = false;
        });
      }
    }
  }

  List<TutorialStep> _buildCategorySteps() {
    return [
      const TutorialStep(
        message: 'Di sini Anda dapat mengelola kategori produk Anda. Kategori membantu mengelompokkan barang dagangan agar rapi.',
        characterPosition: 'left',
      ),
      TutorialStep(
        message: 'Silakan ketuk "Selesai" untuk menambahkan kategori baru.',
        targetKey: _keyAddCategoryFab,
        characterPosition: 'right',
        verticalPosition: 'top',
      ),
    ];
  }

  Future<void> _goBack() async {
    final prefs = await SharedPreferences.getInstance();
    final stage = prefs.getString('tutorial_catalog_stage') ?? 'none';
    if (stage == 'category_intro') {
      final categoryProvider = context.read<CategoryProvider>();
      if (categoryProvider.categories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan tambahkan minimal satu kategori terlebih dahulu, atau lewati tutorial di balon petunjuk.'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      await prefs.setString('tutorial_catalog_stage', 'form_add_product');
      if (mounted) {
        Navigator.pop(context, 'go_to_form');
      }
    } else {
      if (mounted) {
        Navigator.pop(context);
      }
    }
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
                final categoryProvider = context.read<CategoryProvider>();
                final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
                
                // Cek duplikat case-insensitive
                final isExist = categoryProvider.categories.any(
                    (c) => c.name.toLowerCase() == newCat.toLowerCase());
                
                if (isExist) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kategori sudah ada!')),
                  );
                } else {
                  await categoryProvider.addCategory(newCat, userId);
                  if (mounted) Navigator.pop(ctx);
                  _ctrl.clear();

                  final prefs = await SharedPreferences.getInstance();
                  final stage = prefs.getString('tutorial_catalog_stage') ?? 'none';
                  if (stage == 'category_intro') {
                    await prefs.setString('tutorial_catalog_stage', 'form_add_product');
                    if (mounted) {
                      Navigator.pop(context, 'go_to_form');
                    }
                  }
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _editCategory(CategoryModel category) {
    final editCtrl = TextEditingController(text: category.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Kategori'),
        content: TextField(
          controller: editCtrl,
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
              final newName = editCtrl.text.trim();
              if (newName.isNotEmpty && newName != category.name) {
                final categoryProvider = context.read<CategoryProvider>();
                
                final isExist = categoryProvider.categories.any(
                    (c) => c.name.toLowerCase() == newName.toLowerCase());
                
                if (isExist) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kategori sudah ada!')),
                  );
                } else {
                  final updatedCategory = CategoryModel(
                    id: category.id,
                    userId: category.userId,
                    name: newName,
                    updatedAt: category.updatedAt,
                  );
                  await categoryProvider.updateCategory(updatedCategory);
                  if (mounted) Navigator.pop(ctx);
                }
              } else if (newName == category.name) {
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(String id) async {
    final categoryProvider = context.read<CategoryProvider>();
    
    if (categoryProvider.categories.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus ada 1 kategori tersisa!')),
      );
      return;
    }

    await categoryProvider.deleteCategory(id);
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;

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
              title: const Text('Kategori Produk'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              ),
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
                        color: const Color(0xFF00695C).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.category, color: Color(0xFF00695C)),
                    ),
                    title: Text(
                      cat.name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                          onPressed: () => _editCategory(cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Hapus Kategori?'),
                                content: Text('Anda yakin ingin menghapus kategori "${cat.name}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _deleteCategory(cat.id);
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            floatingActionButton: FloatingActionButton.extended(
              key: _keyAddCategoryFab,
              onPressed: _addCategory,
              icon: const Icon(Icons.add),
              label: const Text('Kategori'),
            ),
          ),
          if (_showTutorial)
            Positioned.fill(
              child: TutorialOverlay(
                tutorialKey: 'product_category_intro',
                steps: _buildCategorySteps(),
                onComplete: () async {
                  setState(() => _showTutorial = false);
                  _addCategory();
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
