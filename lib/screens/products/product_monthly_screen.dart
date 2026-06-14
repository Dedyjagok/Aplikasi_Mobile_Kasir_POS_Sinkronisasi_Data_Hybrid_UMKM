import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/pos_transaction_model.dart';
import '../../providers/pos_history_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../pos/receipt_screen.dart';

class PosMonthlyScreen extends StatefulWidget {
  const PosMonthlyScreen({super.key});

  @override
  State<PosMonthlyScreen> createState() => _PosMonthlyScreenState();
}

class _PosMonthlyScreenState extends State<PosMonthlyScreen> {
  DateTime _month = DateTime.now();
  final Map<String, ExpansionTileController> _controllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<PosHistoryProvider>().loadMonthTransactions(_month.year, _month.month);
  }

  void _prevMonth() {
    setState(() => _month = DateTime(_month.year, _month.month - 1));
    _load();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_month.year == now.year && _month.month == now.month) return;
    setState(() => _month = DateTime(_month.year, _month.month + 1));
    _load();
  }

  void _confirmDeleteTransaction(BuildContext context, PosTransaction trx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus transaksi ini? Stok produk yang terjual akan dikembalikan ke dalam katalog.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              
              // 1. Kembalikan stok
              final productProvider = context.read<ProductProvider>();
              for (final item in trx.items) {
                // deductStock dengan angka negatif akan menambah stok
                await productProvider.deductStock(item.productId, -item.qty);
              }
              
              // 2. Hapus transaksi
              if (mounted) {
                await context.read<PosHistoryProvider>().deleteTransaction(trx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaksi dihapus & stok dikembalikan'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<PosHistoryProvider>();
    final settings = context.watch<SettingsProvider>().settings;
    final currency = NumberFormat.currency(
        locale: 'id_ID',
        symbol: '${settings.currencySymbol} ',
        decimalDigits: 0);
    final summary = history.monthlySummary;
    final now = DateTime.now();
    final isCurrentMonth = _month.year == now.year && _month.month == now.month;

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Bulanan POS')),
      body: history.isLoading
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
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2))
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
                                fontWeight: FontWeight.w700, fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          onPressed: isCurrentMonth ? null : _nextMonth,
                          icon: Icon(Icons.chevron_right,
                              color: isCurrentMonth ? Colors.grey : null),
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
                        colors: [Color(0xFF00695C), Color(0xFF26A69A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF26A69A).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    child: Column(
                      children: [
                        Text('Total Pendapatan POS',
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
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text('${summary.totalTransactions}',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                Text('Transaksi',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                            Container(width: 1, height: 30, color: Colors.white30),
                            Column(
                              children: [
                                Text('${summary.totalItemsSold}',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                Text('Item Terjual',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Daftar Transaksi Bulan Ini ───────────
                  Text(
                    'Riwayat Transaksi (${history.monthTransactions.length})',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  if (history.monthTransactions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Belum ada transaksi bulan ini',
                            style: GoogleFonts.poppins(color: Colors.grey)),
                      ),
                    )
                  else
                    ...history.monthTransactions.map((trx) {
                      _controllers.putIfAbsent(trx.id, () => ExpansionTileController());

                      return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              controller: _controllers[trx.id],
                              onExpansionChanged: (expanded) {
                                if (expanded) {
                                  for (final entry in _controllers.entries) {
                                    if (entry.key != trx.id && entry.value.isExpanded) {
                                      entry.value.collapse();
                                    }
                                  }
                                }
                              },
                              tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFE0F2F1),
                                child: const Icon(Icons.receipt_long,
                                    color: Color(0xFF00695C)),
                              ),
                              title: Text(
                                DateFormat('dd MMM yyyy • HH:mm', 'id_ID')
                                    .format(trx.timestamp),
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: Text(
                                '${trx.items.length} Macam Barang',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.grey.shade600),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currency.format(trx.totalAmount),
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF00695C)),
                                  ),
                                  if (trx.paymentMethod != 'Tunai')
                                    Text(
                                      trx.paymentMethod,
                                      style: GoogleFonts.poppins(
                                          fontSize: 10, color: Colors.blue),
                                    ),
                                ],
                              ),
                              children: [
                                Container(
                                  color: Colors.grey.shade50,
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      ...trx.items.map((item) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${item.qty}x  ${item.productName}',
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 13),
                                                ),
                                              ),
                                              Text(
                                                currency.format(item.subtotal),
                                                style: GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => _confirmDeleteTransaction(context, trx),
                                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                                              label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: Colors.red),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => ReceiptScreen(
                                                      transaction: trx,
                                                      settings: settings,
                                                    ),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.print),
                                              label: const Text('Cetak Struk'),
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                            ),
                                          ),
                                        ],
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
