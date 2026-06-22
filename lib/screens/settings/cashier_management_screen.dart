import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/cashier_model.dart';
import '../../providers/cashier_provider.dart';
import '../../widgets/tutorial_overlay.dart';

class CashierManagementScreen extends StatefulWidget {
  const CashierManagementScreen({super.key});

  @override
  State<CashierManagementScreen> createState() => _CashierManagementScreenState();
}

class _CashierManagementScreenState extends State<CashierManagementScreen> {
  bool _showTutorial = false;
  final _keyAddFab = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CashierProvider>().loadCashiers();
      _checkTutorial();
    });
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final stage = prefs.getInt('tutorial_owner_stage') ?? 0;
    if (stage == 2) {
      if (mounted) setState(() => _showTutorial = true);
    }
  }

  void _showFormDialog({Cashier? cashier}) {
    final nameCtrl = TextEditingController(text: cashier?.name);
    final pinCtrl = TextEditingController(text: cashier?.pin);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            cashier == null ? 'Tambah Kasir' : 'Edit Kasir',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Kasir'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Nama tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: pinCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'PIN (4-6 Digit)',
                    hintText: 'Contoh: 1234',
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'PIN tidak boleh kosong';
                    if (val.length < 4) return 'PIN minimal 4 digit';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final provider = context.read<CashierProvider>();
                  if (cashier == null) {
                    await provider.addCashier(nameCtrl.text, pinCtrl.text);
                  } else {
                    await provider.updateCashier(cashier.id, nameCtrl.text, pinCtrl.text);
                  }
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cashiers = context.watch<CashierProvider>().cashiers;
    final hasCashiers = cashiers.isNotEmpty;

    return PopScope(
      canPop: hasCashiers,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harap tambahkan minimal 1 akun kasir terlebih dahulu.')),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manajemen Kasir'),
        ),
        body: Stack(
          children: [
            Consumer<CashierProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.cashiers.isEmpty) {
            return Center(
              child: Text(
                'Belum ada akun kasir.\nSilakan tambah baru.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.cashiers.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final cashier = provider.cashiers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF00695C).withOpacity(0.2),
                  child: Text(
                    cashier.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        color: Color(0xFF00695C), fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  cashier.name,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('PIN Terenkripsi: ****'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showFormDialog(cashier: cashier),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Hapus Kasir?'),
                            content: Text(
                                'Apakah Anda yakin ingin menghapus akses untuk ${cashier.name}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                onPressed: () {
                                  provider.deleteCashier(cashier.id);
                                  Navigator.pop(ctx);
                                },
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      if (_showTutorial)
        Positioned.fill(
          child: TutorialOverlay(
            tutorialKey: 'owner_cashier',
            steps: [
              TutorialStep(
                message: 'Silakan tambahkan minimal 1 akun Kasir agar warung Anda bisa segera dioperasikan.',
                targetKey: _keyAddFab,
                verticalPosition: 'top',
                characterPosition: 'right',
              ),
            ],
            onComplete: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('tutorial_owner_stage', 3);
              if (mounted) setState(() => _showTutorial = false);
            },
            onSkip: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('tutorial_owner_stage', 5);
              if (mounted) setState(() => _showTutorial = false);
            },
          ),
        ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: _keyAddFab,
        onPressed: () => _showFormDialog(),
        backgroundColor: const Color(0xFF00695C),
        child: const Icon(Icons.add),
      ),
    ),
  );
  }
}
