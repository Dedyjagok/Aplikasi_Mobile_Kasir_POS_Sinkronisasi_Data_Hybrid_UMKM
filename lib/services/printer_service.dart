import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import '../models/app_settings_model.dart';
import '../models/pos_transaction_model.dart';

/// Service untuk komunikasi dan pencetakan struk via Bluetooth thermal printer.
class PrinterService {
  final BlueThermalPrinter _bt = BlueThermalPrinter.instance;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Ambil daftar printer Bluetooth yang sudah di-pair.
  Future<List<BluetoothDevice>> getBondedDevices() async {
    return await _bt.getBondedDevices();
  }

  /// Sambungkan ke printer yang dipilih.
  Future<bool> connect(BluetoothDevice device) async {
    try {
      await _bt.connect(device);
      _isConnected = true;
      return true;
    } catch (_) {
      _isConnected = false;
      return false;
    }
  }

  /// Putuskan koneksi printer.
  Future<void> disconnect() async {
    try {
      final isConnected = await _bt.isConnected;
      if (isConnected == true) {
        await _bt.disconnect();
      }
    } catch (_) {
      // Abaikan error jika sudah disconnect dari sisi OS
    } finally {
      _isConnected = false;
    }
  }

  /// Cetak struk transaksi POS.
  Future<void> printReceipt(
    PosTransaction trx,
    AppSettings settings,
  ) async {
    if (!_isConnected) return;

    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '${settings.currencySymbol} ',
      decimalDigits: 0,
    );
    final dateStr =
        DateFormat('dd/MM/yyyy  HH:mm').format(trx.timestamp) + ' WIB';

    // ── Header ───────────────────────────────────────────
    _bt.printCustom(settings.storeName, 2, 1); // size 2 = besar, align 1 = center
    _bt.printCustom(settings.storeAddress, 0, 1);
    _bt.printCustom('Telp: ${settings.storePhone}', 0, 1);
    _bt.printCustom('================================', 0, 1);

    // ── Info Transaksi ───────────────────────────────────
    _bt.printCustom('No: ${trx.id.substring(0, 12).toUpperCase()}', 0, 0);
    _bt.printCustom('Tgl: $dateStr', 0, 0);
    _bt.printCustom('--------------------------------', 0, 1);

    // ── Body: Daftar Item ────────────────────────────────
    for (final item in trx.items) {
      _bt.printCustom(item.productName, 0, 0);
      _bt.printLeftRight(
        '  ${item.qty} x ${currency.format(item.unitPrice)}',
        currency.format(item.subtotal),
        0,
      );
    }
    _bt.printCustom('--------------------------------', 0, 1);

    // ── Footer: Total & Kembalian ────────────────────────
    _bt.printLeftRight('TOTAL', currency.format(trx.totalAmount), 1);
    _bt.printLeftRight('TUNAI', currency.format(trx.cashReceived), 0);
    _bt.printLeftRight('KEMBALIAN', currency.format(trx.changeAmount), 0);
    _bt.printCustom('================================', 0, 1);
    _bt.printCustom(settings.receiptFooter, 0, 1);
    _bt.printCustom('================================', 0, 1);
    _bt.printNewLine();
    _bt.printNewLine();
    _bt.paperCut();
  }
}
