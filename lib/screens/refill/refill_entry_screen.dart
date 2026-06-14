import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/refill_record_model.dart';
import '../../providers/refill_provider.dart';
import '../../providers/settings_provider.dart';
import 'refill_monthly_screen.dart';

class RefillEntryScreen extends StatefulWidget {
  const RefillEntryScreen({super.key});

  @override
  State<RefillEntryScreen> createState() => _RefillEntryScreenState();
}

class _RefillEntryScreenState extends State<RefillEntryScreen> {
  RefillType _selectedType = RefillType.ambil;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final refill = context.watch<RefillProvider>();
    final settings = context.watch<SettingsProvider>().settings;
    final currency = NumberFormat.currency(
        locale: 'id_ID',
        symbol: '${settings.currencySymbol} ',
        decimalDigits: 0);

    final currentPrice = _selectedType == RefillType.antar
        ? settings.refillPriceAntar
        : settings.refillPriceAmbil;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Refill Air RO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const RefillMonthlyScreen())),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Kartu Ringkasan Hari Ini ─────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0097A7), Color(0xFF006064)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF0097A7).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.water_drop,
                      color: Colors.white, size: 36),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Refill Hari Ini',
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 13)),
                      Text('${refill.todayCount} transaksi',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total',
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 13)),
                      Text(currency.format(refill.todayIncome),
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text('Catat Isi Ulang Baru',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            // ── Pilih Tipe Layanan ───────────────────────
            Text('Jenis Layanan',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TypeButton(
                    id: 'refill_type_ambil',
                    label: '🚶 Ambil Sendiri',
                    subtitle: currency.format(settings.refillPriceAmbil),
                    isSelected: _selectedType == RefillType.ambil,
                    onTap: () =>
                        setState(() => _selectedType = RefillType.ambil),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeButton(
                    id: 'refill_type_antar',
                    label: '🛵 Diantar',
                    subtitle: currency.format(settings.refillPriceAntar),
                    isSelected: _selectedType == RefillType.antar,
                    onTap: () =>
                        setState(() => _selectedType = RefillType.antar),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Harga Terpilih ───────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00695C).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF00695C).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Harga Isi Ulang',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  Text(
                    currency.format(currentPrice),
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF00695C),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── Tombol Simpan ────────────────────────────
            ElevatedButton.icon(
              onPressed: _isSaving
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      await context
                          .read<RefillProvider>()
                          .addRecord(_selectedType, currentPrice);
                      setState(() => _isSaving = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            '✅ Refill ${_selectedType.label} dicatat — '
                            '${currency.format(currentPrice)}',
                          ),
                          backgroundColor: const Color(0xFF00695C),
                        ));
                      }
                    },
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.water_drop),
              label: Text(
                _isSaving
                    ? 'Menyimpan...'
                    : 'Catat Refill ${_selectedType.label}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0097A7)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String id;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0097A7)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0097A7)
                : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: const Color(0xFF0097A7).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Column(
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF0097A7),
                )),
          ],
        ),
      ),
    );
  }
}
