import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/database_service.dart';
import '../../services/firestore_service.dart';
import '../../models/pos_transaction_model.dart';
import 'receipt_screen.dart';

class HistoryPosScreen extends StatefulWidget {
  const HistoryPosScreen({super.key});

  @override
  State<HistoryPosScreen> createState() => _HistoryPosScreenState();
}

class _HistoryPosScreenState extends State<HistoryPosScreen> {
  DateTime _selectedDate = DateTime.now();
  List<PosTransaction> _transactions = [];
  bool _isLoading = false;
  final Map<String, ExpansionTileController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final end = start.add(const Duration(days: 1));
    _transactions = await DatabaseService().getPosTransactionsByDateRange(
      start,
      end,
    );
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
                await DatabaseService().deletePosTransaction(trx.id);
                FirestoreService().deletePosTransaction(trx.id).catchError((_) {});
                
                setState(() {
                  _transactions.removeWhere((t) => t.id == trx.id);
                });

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
    final settings = context.watch<SettingsProvider>().settings;
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '${settings.currencySymbol} ',
      decimalDigits: 0,
    );
    final totalHari = _transactions.fold(0, (s, t) => s + t.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate,
          ),
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
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF00695C),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
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
                        color: const Color(0xFF00695C),
                      ),
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
                    child: Text(
                      'Belum ada transaksi',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    itemBuilder: (_, i) {
                      final trx = _transactions[i];
                      _controllers.putIfAbsent(
                        trx.id,
                        () => ExpansionTileController(),
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          controller: _controllers[trx.id],
                          onExpansionChanged: (expanded) {
                            if (expanded) {
                              // Tutup yang lain
                              for (final entry in _controllers.entries) {
                                if (entry.key != trx.id &&
                                    entry.value.isExpanded) {
                                  entry.value.collapse();
                                }
                              }
                            }
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00695C).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.receipt_long,
                              color: Color(0xFF00695C),
                            ),
                          ),
                          title: Text(
                            currency.format(trx.totalAmount),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            '${trx.items.length} item  •  ${DateFormat('HH:mm').format(trx.timestamp)}',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          trailing: Icon(
                            trx.isSynced ? Icons.cloud_done : Icons.cloud_off,
                            color: trx.isSynced ? Colors.green : Colors.orange,
                            size: 18,
                          ),
                          children: [
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Rincian Belanja:',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...trx.items.map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 3,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${item.productName} x${item.qty}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            currency.format(item.subtotal),
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
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
                            ),
                          ],
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
