import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_settings_model.dart';
import '../../providers/session_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/tutorial_overlay.dart';
import '../products/product_category_screen.dart';
import 'cashier_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _storeNameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _footerCtrl;
  late TextEditingController _refillAntarCtrl;
  late TextEditingController _refillAmbilCtrl;
  late TextEditingController _thresholdCtrl;
  late TextEditingController _currencyCtrl;
  late TextEditingController _ownerPinCtrl;
  bool _isSaving = false;

  bool _showTutorial = false;
  int _tutorialStage = 1;
  final _scrollCtrl = ScrollController();
  final _keyBackButton = GlobalKey();
  final _keyStoreInfo = GlobalKey();
  final _keyROPrice = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.read<SessionProvider>().isOwner) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Akses Ditolak')));
      }
      _checkTutorial();
    });

    final s = context.read<SettingsProvider>().settings;
    _storeNameCtrl = TextEditingController(text: s.storeName);
    _addressCtrl = TextEditingController(text: s.storeAddress);
    _phoneCtrl = TextEditingController(text: s.storePhone);
    _footerCtrl = TextEditingController(text: s.receiptFooter);
    _refillAntarCtrl =
        TextEditingController(text: s.refillPriceAntar.toString());
    _refillAmbilCtrl =
        TextEditingController(text: s.refillPriceAmbil.toString());
    _thresholdCtrl =
        TextEditingController(text: s.lowStockThreshold.toString());
    _currencyCtrl = TextEditingController(text: s.currencySymbol);
    _ownerPinCtrl = TextEditingController(text: s.ownerPin);
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final stage = prefs.getInt('tutorial_owner_stage') ?? 0;
    if (stage == 1) {
      if (mounted) setState(() { _showTutorial = true; _tutorialStage = 1; });
    } else if (stage == 3) {
      if (mounted) setState(() { _showTutorial = true; _tutorialStage = 3; });
    }
  }

  List<TutorialStep> _buildTutorialSteps() {
    if (_tutorialStage == 3) {
      return [
        TutorialStep(
          message: 'Silakan tekan tombol Kembali untuk menutup halaman pengaturan ini dan kembali ke Dashboard.',
          targetKey: _keyBackButton,
          verticalPosition: 'bottom',
          characterPosition: 'left',
        ),
      ];
    }
    
    return [
      TutorialStep(
        message: 'Di form ini, Anda bisa mengubah Nama Warung, Alamat, dan Nomor Telepon. Data ini akan otomatis tercetak di bagian atas (header) setiap struk kasir.',
        verticalPosition: 'bottom',
        characterPosition: 'left',
        onStart: () async {
          await _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
      ),
      TutorialStep(
        message: 'Di bagian ini, Anda bisa mengatur Harga Dasar Refill Air RO (baik Antar maupun Ambil Sendiri) yang akan dipakai secara otomatis di Modul Refill.',
        verticalPosition: 'top',
        characterPosition: 'right',
        onStart: () async {
          await _scrollCtrl.animateTo(150, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
      ),
    ];
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    for (final c in [
      _storeNameCtrl, _addressCtrl, _phoneCtrl, _footerCtrl,
      _refillAntarCtrl, _refillAmbilCtrl, _thresholdCtrl, _currencyCtrl, _ownerPinCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final current = context.read<SettingsProvider>().settings;
    final updated = current.copyWith(
      storeName: _storeNameCtrl.text.trim(),
      storeAddress: _addressCtrl.text.trim(),
      storePhone: _phoneCtrl.text.trim(),
      receiptFooter: _footerCtrl.text.trim(),
      refillPriceAntar: int.tryParse(_refillAntarCtrl.text) ?? 5000,
      refillPriceAmbil: int.tryParse(_refillAmbilCtrl.text) ?? 4000,
      lowStockThreshold: int.tryParse(_thresholdCtrl.text) ?? 10,
      currencySymbol: _currencyCtrl.text.trim(),
      ownerPin: _ownerPinCtrl.text.trim().isEmpty ? '123456' : _ownerPinCtrl.text.trim(),
    );

    await context.read<SettingsProvider>().updateSettings(updated);
    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Pengaturan berhasil disimpan'),
        backgroundColor: Color(0xFF00695C),
      ));
  }

  Future<void> _changePassword() async {
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool isLoading = false;
    String? errorMsg;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Ganti Password Akun'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password Baru'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password',
                  errorText: errorMsg,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (passCtrl.text.length < 6) {
                        setStateDialog(() => errorMsg = 'Password minimal 6 karakter');
                        return;
                      }
                      if (passCtrl.text != confirmCtrl.text) {
                        setStateDialog(() => errorMsg = 'Password tidak cocok');
                        return;
                      }
                      setStateDialog(() {
                        isLoading = true;
                        errorMsg = null;
                      });
                      try {
                        await FirebaseAuth.instance.currentUser?.updatePassword(passCtrl.text);
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password berhasil diubah')),
                          );
                        }
                      } catch (e) {
                        setStateDialog(() {
                          isLoading = false;
                          errorMsg = 'Gagal mengubah password. Anda mungkin perlu login ulang.';
                        });
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(key: _keyBackButton),
        title: const Text('Pengaturan Toko'),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(20),
              children: [
            // ══════════════════════════════════════════════
            //  INFORMASI TOKO
            // ══════════════════════════════════════════════
            Container(
              key: _keyStoreInfo,
              child: _SectionHeader(
                icon: Icons.store_outlined,
                title: 'Informasi Toko',
                subtitle: 'Tampil di header struk pembayaran',
              ),
            ),
            const SizedBox(height: 12),
            _field(
              label: 'Nama Toko / Warung *',
              ctrl: _storeNameCtrl,
              hint: 'Contoh: Warung 3D Water RO',
              validator: (v) =>
                  v!.isEmpty ? 'Nama toko wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            _field(
              label: 'Alamat Lengkap',
              ctrl: _addressCtrl,
              hint: 'Contoh: Jl. Merdeka No. 123, Kota',
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            _field(
              label: 'Nomor Telepon / WhatsApp',
              ctrl: _phoneCtrl,
              hint: 'Contoh: 0812-3456-7890',
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _field(
              label: 'Pesan Footer Struk',
              ctrl: _footerCtrl,
              hint: 'Contoh: Terima Kasih! Silakan Datang Kembali.',
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            _field(
              label: 'PIN Owner (Akses Offline)',
              ctrl: _ownerPinCtrl,
              hint: '123456',
              keyboard: TextInputType.number,
              isNum: true,
            ),
            const SizedBox(height: 24),

            // ══════════════════════════════════════════════
            //  HARGA REFILL AIR RO
            // ══════════════════════════════════════════════
            Container(
              key: _keyROPrice,
              child: _SectionHeader(
                icon: Icons.water_drop_outlined,
                title: 'Harga Refill Air RO',
                subtitle: 'Digunakan otomatis di modul refill',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(
                    label: '🛵 Harga Antar',
                    ctrl: _refillAntarCtrl,
                    isNum: true,
                    hint: '5000',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    label: '🚶 Harga Ambil Sendiri',
                    ctrl: _refillAmbilCtrl,
                    isNum: true,
                    hint: '4000',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ══════════════════════════════════════════════
            //  PENGATURAN PRODUK
            // ══════════════════════════════════════════════
            _SectionHeader(
              icon: Icons.inventory_2_outlined,
              title: 'Pengaturan Produk',
              subtitle: 'Konfigurasi stok dan mata uang',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(
                    label: 'Batas Stok Rendah (default)',
                    ctrl: _thresholdCtrl,
                    isNum: true,
                    hint: '10',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    label: 'Simbol Mata Uang',
                    ctrl: _currencyCtrl,
                    hint: 'Rp',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductCategoryScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.category_outlined, color: Color(0xFF00695C)),
                label: const Text(
                  'Kelola Kategori Produk',
                  style: TextStyle(color: Color(0xFF00695C)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF00695C)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ══════════════════════════════════════════════
            //  MANAJEMEN KASIR
            // ══════════════════════════════════════════════
            _SectionHeader(
              icon: Icons.people_outline,
              title: 'Akun Staf Kasir',
              subtitle: 'Buat PIN khusus untuk karyawan',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CashierManagementScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.manage_accounts, color: Color(0xFF00695C)),
                label: const Text(
                  'Kelola Kasir',
                  style: TextStyle(color: Color(0xFF00695C)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF00695C)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _changePassword,
                icon: const Icon(Icons.lock_reset, color: Color(0xFF00695C)),
                label: const Text(
                  'Ganti Password Akun',
                  style: TextStyle(color: Color(0xFF00695C)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF00695C)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Tombol Simpan ─────────────────────────────
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(
                _isSaving ? 'Menyimpan...' : 'Simpan Pengaturan',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 40),
              ],
            ),
          ),
          if (_showTutorial)
            Positioned.fill(
              child: TutorialOverlay(
                tutorialKey: 'owner_settings',
                steps: _buildTutorialSteps(),
                onComplete: () async {
                  final prefs = await SharedPreferences.getInstance();
                  if (_tutorialStage == 1) {
                    await prefs.setInt('tutorial_owner_stage', 2);
                    if (mounted) {
                      setState(() => _showTutorial = false);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CashierManagementScreen()),
                      ).then((_) => _checkTutorial());
                    }
                  } else if (_tutorialStage == 3) {
                    await prefs.setInt('tutorial_owner_stage', 4);
                    if (mounted) {
                      setState(() => _showTutorial = false);
                      Navigator.pop(context);
                    }
                  }
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
    );
  }

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    String? hint,
    int maxLines = 1,
    bool isNum = false,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNum
          ? TextInputType.number
          : (keyboard ?? TextInputType.text),
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

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00695C).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF00695C), size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 15)),
            Text(subtitle,
                style: GoogleFonts.poppins(
                    color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
