import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    for (final c in [
      _storeNameCtrl, _addressCtrl, _phoneCtrl, _footerCtrl,
      _refillAntarCtrl, _refillAmbilCtrl, _thresholdCtrl, _currencyCtrl,
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
    );

    await context.read<SettingsProvider>().updateSettings(updated);
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Pengaturan berhasil disimpan'),
        backgroundColor: Color(0xFF00695C),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Toko')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ══════════════════════════════════════════════
            //  INFORMASI TOKO
            // ══════════════════════════════════════════════
            _SectionHeader(
              icon: Icons.store_outlined,
              title: 'Informasi Toko',
              subtitle: 'Tampil di header struk pembayaran',
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
            const SizedBox(height: 24),

            // ══════════════════════════════════════════════
            //  HARGA REFILL AIR RO
            // ══════════════════════════════════════════════
            _SectionHeader(
              icon: Icons.water_drop_outlined,
              title: 'Harga Refill Air RO',
              subtitle: 'Digunakan otomatis di modul refill',
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
                ),
              ],
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
