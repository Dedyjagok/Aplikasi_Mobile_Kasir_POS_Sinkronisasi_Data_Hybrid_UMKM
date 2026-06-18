import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/refill_record_model.dart';
import '../../providers/refill_provider.dart';
import '../../providers/settings_provider.dart';

class RefillMonthlyScreen extends StatefulWidget {
  const RefillMonthlyScreen({super.key});

  @override
  State<RefillMonthlyScreen> createState() => _RefillMonthlyScreenState();
}

class _RefillMonthlyScreenState extends State<RefillMonthlyScreen> {
  DateTime _month = DateTime.now();
  DateTime? _selectedDay;
  String _selectedFilter = 'Semua';
  final Map<String, ExpansionTileController> _controllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<RefillProvider>().loadMonthRecords(_month.year, _month.month, forceCloud: true);
  }

  void _prevMonth() {
    setState(() {
      _month = DateTime(_month.year, _month.month - 1);
      _selectedDay = null;
    });
    _load();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_month.year == now.year && _month.month == now.month) return;
    setState(() {
      _month = DateTime(_month.year, _month.month + 1);
      _selectedDay = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final refill = context.watch<RefillProvider>();
    final settings = context.watch<SettingsProvider>().settings;
    final currency = NumberFormat.currency(
        locale: 'id_ID',
        symbol: '${settings.currencySymbol} ',
        decimalDigits: 0);
    final summary = refill.monthlySummary;
    final now = DateTime.now();
    final isCurrentMonth =
        _month.year == now.year && _month.month == now.month;

    // Terapkan Filter
    var filteredRecords = refill.monthRecords.where((r) {
      bool passDay = true;
      if (_selectedDay != null) {
        passDay = r.timestamp.year == _selectedDay!.year &&
            r.timestamp.month == _selectedDay!.month &&
            r.timestamp.day == _selectedDay!.day;
      }
      bool passType = true;
      if (_selectedFilter == 'Ambil Sendiri') {
        passType = r.type.value == 'ambil';
      } else if (_selectedFilter == 'Diantar') {
        passType = r.type.value == 'antar';
      }
      return passDay && passType;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat & Rekap Refill')),
      body: refill.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Navigasi Bulan ────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _prevMonth,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Text(
                            DateFormat('MMMM yyyy', 'id_ID').format(_month),
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          onPressed: isCurrentMonth ? null : _nextMonth,
                          icon: Icon(Icons.chevron_right,
                              color: isCurrentMonth
                                  ? Colors.grey
                                  : null),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Total Pendapatan ──────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF006064), Color(0xFF0097A7)],
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
                    child: Column(
                      children: [
                        Text('Total Pendapatan Refill',
                            style: GoogleFonts.poppins(
                                color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(
                          currency.format(summary.totalIncome),
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${summary.totalCount} total transaksi',
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Rincian per Tipe ──────────────────
                  _StatCard(
                    icon: Icons.directions_walk,
                    label: 'Ambil Sendiri',
                    count: summary.totalAmbil,
                    income: currency.format(summary.incomeAmbil),
                    color: const Color(0xFF0097A7),
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.delivery_dining,
                    label: 'Diantar',
                    count: summary.totalAntar,
                    income: currency.format(summary.incomeAntar),
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(height: 20),

                  // ── Filter Riwayat ────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _selectedDay == null
                                ? 'Pilih Hari'
                                : DateFormat('dd MMM').format(_selectedDay!),
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          onPressed: () async {
                            // Mencari batas hari pada bulan yang dipilih
                            final lastDayOfMonth = DateTime(_month.year, _month.month + 1, 0).day;
                            
                            // Jika bulan saat ini, batasi sampai hari ini
                            final maxDay = isCurrentMonth ? now.day : lastDayOfMonth;
                            
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDay ?? DateTime(_month.year, _month.month, isCurrentMonth ? now.day : 1),
                              firstDate: DateTime(_month.year, _month.month, 1),
                              lastDate: DateTime(_month.year, _month.month, maxDay),
                            );
                            if (picked != null) {
                              setState(() => _selectedDay = picked);
                            }
                          },
                        ),
                      ),
                      if (_selectedDay != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _selectedDay = null),
                          tooltip: 'Hapus filter hari',
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedFilter,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(),
                          ),
                          items: ['Semua', 'Ambil Sendiri', 'Diantar']
                              .map((f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(f,
                                      style: GoogleFonts.poppins(
                                          fontSize: 13))))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedFilter = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Daftar Record Bulan Ini ───────────
                  Text(
                    _selectedDay == null
                        ? 'Semua Record Bulan Ini (${filteredRecords.length})'
                        : 'Record Tgl ${DateFormat('dd MMM').format(_selectedDay!)} (${filteredRecords.length})',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  if (filteredRecords.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Belum ada data untuk filter ini',
                            style: GoogleFonts.poppins(
                                color: Colors.grey)),
                      ),
                    )
                  else
                    ...filteredRecords.map((r) {
                      _controllers.putIfAbsent(r.id, () => ExpansionTileController());

                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            controller: _controllers[r.id],
                            onExpansionChanged: (expanded) {
                              if (expanded) {
                                for (final entry in _controllers.entries) {
                                  if (entry.key != r.id && entry.value.isExpanded) {
                                    entry.value.collapse();
                                  }
                                }
                              }
                            },
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                            leading: Icon(
                              r.type.value == 'antar'
                                  ? Icons.delivery_dining
                                  : Icons.directions_walk,
                              color: r.type.value == 'antar'
                                  ? Colors.orange.shade700
                                  : const Color(0xFF0097A7),
                            ),
                            title: Text(
                              DateFormat('dd MMM yyyy  HH:mm', 'id_ID')
                                  .format(r.timestamp),
                              style:
                                  GoogleFonts.poppins(fontSize: 12),
                            ),
                            subtitle: Text(r.type.label,
                                style: GoogleFonts.poppins(
                                    fontSize: 11)),
                            trailing: Text(
                              currency.format(r.price),
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                            children: [
                              Container(
                                color: Colors.grey.shade50,
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Hapus Riwayat?'),
                                            content: const Text(
                                                'Anda yakin ingin menghapus data isi ulang ini? Aksi ini akan mengurangi total pendapatan bulanan.'),
                                            actions: [
                                              TextButton(
                                                  onPressed: () => Navigator.pop(ctx),
                                                  child: const Text('Batal')),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red),
                                                onPressed: () {
                                                  context
                                                      .read<RefillProvider>()
                                                      .deleteRecord(r.id);
                                                  Navigator.pop(ctx);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Riwayat berhasil dihapus'),
                                                      backgroundColor: Colors.red,
                                                    )
                                                  );
                                                },
                                                child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      label: const Text('Hapus Riwayat', style: TextStyle(color: Colors.red)),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final String income;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.income,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600)),
                Text('$count transaksi',
                    style: GoogleFonts.poppins(
                        color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Text(income,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: color)),
        ],
      ),
    );
  }
}
