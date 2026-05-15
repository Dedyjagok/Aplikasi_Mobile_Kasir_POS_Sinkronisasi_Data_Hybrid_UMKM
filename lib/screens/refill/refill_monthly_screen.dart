import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/refill_provider.dart';
import '../../providers/settings_provider.dart';

class RefillMonthlyScreen extends StatefulWidget {
  const RefillMonthlyScreen({super.key});

  @override
  State<RefillMonthlyScreen> createState() => _RefillMonthlyScreenState();
}

class _RefillMonthlyScreenState extends State<RefillMonthlyScreen> {
  DateTime _month = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<RefillProvider>().loadMonthRecords(_month.year, _month.month);
  }

  void _prevMonth() {
    setState(() =>
        _month = DateTime(_month.year, _month.month - 1));
    _load();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_month.year == now.year && _month.month == now.month) return;
    setState(() =>
        _month = DateTime(_month.year, _month.month + 1));
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

    return Scaffold(
      appBar: AppBar(title: const Text('Rekap Bulanan Refill')),
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
                          id: 'monthly_prev_month',
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
                          id: 'monthly_next_month',
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

                  // ── Daftar Record Bulan Ini ───────────
                  Text(
                    'Semua Record Bulan Ini (${refill.monthRecords.length})',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  if (refill.monthRecords.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Belum ada data refill bulan ini',
                            style: GoogleFonts.poppins(
                                color: Colors.grey)),
                      ),
                    )
                  else
                    ...refill.monthRecords.map((r) => Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
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
                          ),
                        )),
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
