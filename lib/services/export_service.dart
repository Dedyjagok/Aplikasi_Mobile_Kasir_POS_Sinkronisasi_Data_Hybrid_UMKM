import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../screens/statistic_pos/statistic_screen.dart';

class ExportService {
  static final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Export data ke format Excel (.xlsx) dan langsung share
  static Future<void> exportToExcel({
    required String storeName,
    required List<ProductStat> stats,
    required int totalModal,
    required int totalIncome,
    required int totalLaba,
    required String periodName,
  }) async {
    final excel = Excel.createExcel();
    final String sheetName = 'Laporan';
    final sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);

    // Header Laporan
    sheet.appendRow([TextCellValue(storeName)]);
    sheet.appendRow([TextCellValue('LAPORAN PENJUALAN - $periodName')]);
    sheet.appendRow([TextCellValue('')]);

    // Ringkasan Keuangan
    sheet.appendRow([TextCellValue('Ringkasan Keuangan')]);
    sheet.appendRow([TextCellValue('Total Modal'), TextCellValue(_currency.format(totalModal))]);
    sheet.appendRow([TextCellValue('Total Penjualan'), TextCellValue(_currency.format(totalIncome))]);
    sheet.appendRow([TextCellValue('Laba Bersih'), TextCellValue(_currency.format(totalLaba))]);
    sheet.appendRow([TextCellValue('')]);

    // Header Tabel Produk
    sheet.appendRow([
      TextCellValue('Peringkat'),
      TextCellValue('Nama Produk'),
      TextCellValue('Kategori'),
      TextCellValue('Terjual (Qty)'),
    ]);

    // Data Produk
    for (int i = 0; i < stats.length; i++) {
      final stat = stats[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(stat.productName),
        TextCellValue(stat.categoryName),
        IntCellValue(stat.qty),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final directory = await getTemporaryDirectory();
      final sanitizedPeriod = periodName.replaceAll(' ', '_');
      final filePath = '${directory.path}/Laporan_Penjualan_$sanitizedPeriod.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      await Share.shareXFiles([XFile(filePath)], text: 'Berikut adalah Laporan Penjualan $periodName.');
    }
  }

  /// Export data ke format PDF dan langsung share
  static Future<void> exportToPdf({
    required String storeName,
    required List<ProductStat> stats,
    required int totalModal,
    required int totalIncome,
    required int totalLaba,
    required String periodName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Judul
            pw.Text(
              storeName,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'LAPORAN PENJUALAN',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
            ),
            pw.Text(
              'Periode: $periodName',
              style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 20),

            // Ringkasan Keuangan
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Ringkasan Keuangan', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.SizedBox(height: 8),
                  _buildPdfSummaryRow('Total Modal', _currency.format(totalModal)),
                  _buildPdfSummaryRow('Total Penjualan', _currency.format(totalIncome)),
                  pw.Divider(color: PdfColors.grey300),
                  _buildPdfSummaryRow('Laba Bersih', _currency.format(totalLaba), isBold: true),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Tabel Produk
            pw.Text('Rincian Penjualan Produk', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              border: pw.TableBorder.all(color: PdfColors.grey400),
              headers: ['Peringkat', 'Nama Produk', 'Kategori', 'Terjual'],
              data: List.generate(stats.length, (index) {
                final stat = stats[index];
                return [
                  '${index + 1}',
                  stat.productName,
                  stat.categoryName,
                  '${stat.qty}',
                ];
              }),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final directory = await getTemporaryDirectory();
    final sanitizedPeriod = periodName.replaceAll(' ', '_');
    final filePath = '${directory.path}/Laporan_Penjualan_$sanitizedPeriod.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(filePath)], text: 'Berikut adalah Laporan Penjualan $periodName.');
  }

  static pw.Widget _buildPdfSummaryRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }
}
