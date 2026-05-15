import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../services/database_service.dart';
import '../../models/pos_transaction_model.dart';

class HistoryPosScreen extends StatefulWidget {
  const HistoryPosScreen({super.key});

  @override
  State<HistoryPosScreen> createState() => _HistoryPosScreenState();
}

class _HistoryPosScreenState extends State<HistoryPosScreen> {
  DateTime _selectedDate = DateTime.now();
  List<PosTransaction> _transactions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final start = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day);
    final end = start.add(const Duration(days: 1));
    _transactions =
        await DatabaseService().getPosTransactionsByDateRange(start, end);
    setState(() => _isLoading = false);
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
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final currency = NumberFormat.currency(
        locale: 'id_ID',
        symbol: '${settings.currencySymbol} ',
        decimalDigits: 0);
    final totalHari =
        _transactions.fold(0, (s, t) => s + t.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _pickDate),
        ],
      ),
      body: Column(
        children: [
          // ── Filter Tanggal & Ringkasan ──────────────────
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF00695C).withOpacity(0.08),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: Color(0xFF00695C), size: 18),
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
                    Text(
                      '${_transactions.length} transaksi',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    Text(
                      currency.format(totalHari),
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00695C)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── List Transaksi ──────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? Center(
                        child: Text('Belum ada transaksi',
                            style: GoogleFonts.poppins(
                                color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _transactions.length,
                        itemBuilder: (_, i) {
                          final trx = _transactions[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00695C)
                                      .withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                    Icons.receipt_long,
                                    color: Color(0xFF00695C)),
                              ),
                              title: Text(
                                currency.format(trx.totalAmount),
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                '${trx.items.length} item  •  '
                                '${DateFormat('HH:mm').format(trx.timestamp)}',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              trailing: Icon(
                                trx.isSynced
                                    ? Icons.cloud_done
                                    : Icons.cloud_off,
                                color: trx.isSynced
                                    ? Colors.green
                                    : Colors.orange,
                                size: 18,
                              ),
                              onTap: () => _showDetail(context, trx, currency),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext ctx, PosTransaction trx,
      NumberFormat currency) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detail Transaksi',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            const Divider(),
            ...trx.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text('${item.productName} x${item.qty}',
                              style: GoogleFonts.poppins(fontSize: 13))),
                      Text(currency.format(item.subtotal),
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700)),
                Text(currency.format(trx.totalAmount),
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00695C))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
