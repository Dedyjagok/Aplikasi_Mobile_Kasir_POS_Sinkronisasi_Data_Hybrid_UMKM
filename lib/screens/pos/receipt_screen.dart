import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
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
  final PrinterService _printerService = PrinterService();
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isScanning = false;
  bool _isPrinting = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    await _requestPermissions();
    _checkConnection();
    _getBondedDevices();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> _checkConnection() async {
    bool? isConnected = await bluetooth.isConnected;
    if (mounted) {
      setState(() {
        _isConnected = isConnected ?? false;
      });
    }
  }

  Future<void> _getBondedDevices() async {
    setState(() {
      _isScanning = true;
    });

    try {
      List<BluetoothDevice> devices = await _printerService.getBondedDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        _showError('Gagal mendapatkan daftar perangkat Bluetooth');
      }
    }
  }

  Future<void> _connectToDevice() async {
    if (_selectedDevice == null) {
      _showError('Pilih printer terlebih dahulu');
      return;
    }

    try {
      bool connected = await _printerService.connect(_selectedDevice!);
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });

        if (connected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terhubung ke printer'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showError('Gagal terhubung ke printer');
        }
      }
    } catch (e) {
      _showError('Gagal terhubung: $e');
    }
  }

  Future<void> _printReceipt() async {
    if (_selectedDevice == null) {
      _showError('Pilih printer terlebih dahulu');
      return;
    }

    if (!_isConnected) {
      await _connectToDevice();
      await Future.delayed(const Duration(seconds: 1));
      if (!_isConnected) return; // Jika masih gagal connect, hentikan
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      // Gunakan PrinterService untuk mencetak struk sesuai format yang ada
      await _printerService.printReceipt(widget.transaction, widget.settings);

      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Struk berhasil dicetak!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Kembali ke riwayat POS
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
        _showError('Gagal mencetak: $e');
      }
    }
  }

  Future<void> _disconnect() async {
    try {
      await _printerService.disconnect();
      if (mounted) {
        setState(() {
          _isConnected = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Printer terputus'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _showError('Gagal memutus koneksi: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _printerService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cetak Struk'),
        actions: [
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.bluetooth_connected),
              onPressed: _disconnect,
              tooltip: 'Putuskan Koneksi',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildReceiptPreview(),
                  // Connection Status
          Container(
            padding: const EdgeInsets.all(16),
            color: _isConnected
                ? Colors.green.shade100
                : const Color(0xFF00695C).withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  _isConnected
                      ? Icons.bluetooth_connected
                      : Icons.info_outline,
                  color: _isConnected
                      ? Colors.green.shade700
                      : const Color(0xFF00695C),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isConnected
                        ? 'Terhubung ke ${_selectedDevice?.name ?? "Printer"}'
                        : 'Pastikan printer Bluetooth Anda menyala dan sudah dipairing (disandingkan) dengan perangkat ini',
                    style: TextStyle(
                      color: _isConnected
                          ? Colors.green.shade900
                          : const Color(0xFF00695C),
                      fontWeight: _isConnected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Refresh Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? null : _getBondedDevices,
                icon: _isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isScanning ? 'Mencari...' : 'Segarkan Daftar Perangkat'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          // Devices List
          _devices.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isScanning
                              ? 'Mencari printer Bluetooth...'
                              : 'Tidak ada printer yang ditemukan',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (!_isScanning) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Silakan pairing printer Anda di Pengaturan Bluetooth HP/Tablet terlebih dahulu',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final isSelected = _selectedDevice?.address == device.address;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isSelected ? const Color(0xFFE0F2F1) : Colors.white,
                        child: ListTile(
                          leading: Icon(
                            Icons.print,
                            color: isSelected ? const Color(0xFF00695C) : Colors.grey,
                          ),
                          title: Text(
                            device.name ?? 'Perangkat Tidak Dikenal',
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(device.address ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected && _isConnected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                              if (isSelected && !_isConnected)
                                const Icon(
                                  Icons.radio_button_checked,
                                  color: Color(0xFF00695C),
                                ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _selectedDevice = device;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                if (!_isConnected && _selectedDevice != null)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _connectToDevice,
                      icon: const Icon(Icons.bluetooth),
                      label: const Text('Sambungkan ke Printer'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF00695C)),
                        foregroundColor: const Color(0xFF00695C),
                      ),
                    ),
                  ),
                if (!_isConnected && _selectedDevice != null)
                  const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: (_selectedDevice != null && !_isPrinting)
                        ? _printReceipt
                        : null,
                    icon: _isPrinting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.print),
                    label: Text(
                      _isPrinting ? 'Mencetak...' : 'Cetak Struk',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00695C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptPreview() {
    final s = widget.settings;
    final t = widget.transaction;
    final formatter = NumberFormat.currency(
        locale: 'id_ID', symbol: '${s.currencySymbol} ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text(s.storeName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          if (s.storeAddress.isNotEmpty)
            Text(s.storeAddress,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12)),
          if (s.storePhone.isNotEmpty)
            Text(s.storePhone, style: const TextStyle(fontSize: 12)),
          const Divider(height: 24, thickness: 1, color: Colors.black54),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Waktu:'),
              Text(DateFormat('dd-MM-yyyy HH:mm').format(t.timestamp)),
            ],
          ),
          const SizedBox(height: 8),
          ...t.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${item.productName} x${item.qty}')),
                    Text(formatter.format(item.subtotal)),
                  ],
                ),
              )),
          const Divider(height: 24, thickness: 1, color: Colors.black54),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(formatter.format(t.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bayar:', style: TextStyle(color: Colors.grey)),
              Text(formatter.format(t.cashReceived),
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kembali:', style: TextStyle(color: Colors.grey)),
              Text(formatter.format(t.changeAmount),
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('--- Terima Kasih ---',
              style: TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}