import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/app_settings_model.dart';
import '../../models/pos_transaction_model.dart';
import '../../services/printer_service.dart';

class ReceiptScreen extends StatefulWidget {
  final PosTransaction transaction;
  final AppSettings settings;

  const ReceiptScreen({
    super.key,
    required this.transaction,
    required this.settings,
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final _printerService = PrinterService();
  bool _isPrinting = false;

  Future<void> _printReceipt() async {
    setState(() => _isPrinting = true);

    try {
      await _printerService.printReceipt(widget.transaction, widget.settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Struk berhasil dicetak'),
            backgroundColor: Color(0xFF00695C),
            duration: Duration(milliseconds: 1500),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal cetak: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '${widget.settings.currencySymbol} ',
      decimalDigits: 0,
    );
    final dateStr =
        DateFormat('dd/MM/yyyy  HH:mm').format(widget.transaction.timestamp);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Struk Pembayaran'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Receipt Card ──────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Store Name (Large & Bold)
                  Text(
                    widget.settings.storeName,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF00695C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Store Address
                  Text(
                    widget.settings.storeAddress,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),

                  // Store Phone
                  Text(
                    'Telp: ${widget.settings.storePhone}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),

                  // Transaction No & Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No. Transaksi',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.transaction.id.substring(0, 12).toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Tanggal & Jam',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),

                  // Items List
                  ...widget.transaction.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${item.qty} x ${currency.format(item.unitPrice)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  currency.format(item.subtotal),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 12),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),

                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        currency.format(widget.transaction.totalAmount),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00695C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Cash Received
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TUNAI',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        currency.format(widget.transaction.cashReceived),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Change
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'KEMBALIAN',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        currency.format(widget.transaction.changeAmount),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),

                  // Footer Message
                  Text(
                    widget.settings.receiptFooter,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Action Buttons ────────────────────────────
            ElevatedButton.icon(
              onPressed: _isPrinting ? null : _printReceipt,
              icon: _isPrinting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.print),
              label: Text(
                _isPrinting ? 'Sedang Mencetak...' : 'Cetak Struk',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0097A7),
              ),
            ),
            const SizedBox(height: 12),

            // Back to POS Button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) =>
                    route.settings.name == '/' ||
                    route.isFirst);
              },
              icon: const Icon(Icons.home_outlined),
              label: const Text('Kembali ke POS'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}