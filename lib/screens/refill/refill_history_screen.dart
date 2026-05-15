import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/refill_record_model.dart';
import '../../providers/refill_provider.dart';
import '../../providers/settings_provider.dart';

class RefillHistoryScreen extends StatefulWidget {
  const RefillHistoryScreen({super.key});

  @override
  State<RefillHistoryScreen> createState() => _RefillHistoryScreenState();
}

class _RefillHistoryScreenState extends State<RefillHistoryScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RefillProvider>().loadTodayRecords();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      // Load records untuk tanggal yang dipilih
      final refill = context.read<RefillProvider>();
      await refill.loadMonthRecords(picked.year, picked.month);
    }
  }

  @override
  Widget build(BuildContext context) {
    final refill = context.watch<RefillProvider>();
    final settings = context.watch<SettingsProvider>().settings;
    final currency = NumberFormat.currency(
        locale: 'id_ID',
        symbol: '${settings.currencySymbol} ',
        decimalDigits: 0);

    // Filter hanya hari yang dipilih dari monthRecords
    final records = refill.monthRecords.where((r) {
      return r.timestamp.year == _selectedDate.year &&
          r.timestamp.month == _selectedDate.month &&
          r.timestamp.day == _selectedDate.day;
    }).toList();

    final totalHari = records.fold(0, (s, r) => s + r.price);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Refill'),
        actions: [
          IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _pickDate),
        ],
      ),
      body: Column(
        children: [
          // ── Header Tanggal & Total ────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0097A7).withOpacity(0.08),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: Color(0xFF0097A7), size: 18),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMMM yyyy', 'id_ID')
                      .format(_selectedDate),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${records.length} refill',
                        style: GoogleFonts.poppins(fontSize: 12)),
                    Text(
                      currency.format(totalHari),
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0097A7)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Daftar Record ─────────────────────────────
          Expanded(
            child: refill.isLoading
                ? const Center(child: CircularProgressIndicator())
                : records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.water_drop_outlined,
                                size: 64,
                                color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('Belum ada refill hari ini',
                                style: GoogleFonts.poppins(
                                    color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: records.length,
                        itemBuilder: (_, i) {
                          final r = records[i];
                          final isAntar =
                              r.type == RefillType.antar;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (isAntar
                                          ? Colors.orange
                                          : const Color(0xFF0097A7))
                                      .withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isAntar
                                      ? Icons.delivery_dining
                                      : Icons.directions_walk,
                                  color: isAntar
                                      ? Colors.orange.shade700
                                      : const Color(0xFF0097A7),
                                ),
                              ),
                              title: Text(
                                r.type.label,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                DateFormat('HH:mm').format(r.timestamp),
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              trailing: Text(
                                currency.format(r.price),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF00695C),
                                ),
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
}
