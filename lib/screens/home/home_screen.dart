import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/refill_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/connectivity_badge.dart';
import '../../widgets/module_card.dart';
import '../pos/pos_screen.dart';
import '../products/product_list_screen.dart';
import '../refill/refill_entry_screen.dart';
import '../refill/refill_history_screen.dart';
import '../refill/refill_monthly_screen.dart';
import '../settings/settings_screen.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../../services/revenuecat_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<SettingsProvider>().loadSettings(),
      context.read<ProductProvider>().loadProducts(),
      context.read<RefillProvider>().loadTodayRecords(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final isOnline = context.watch<ConnectivityProvider>().isOnline;
    final products = context.watch<ProductProvider>();
    final refill = context.watch<RefillProvider>();
    final currency = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(settings.storeName),
        actions: [
          IconButton(
            icon: Icon(
              RevenueCatService().isPremium ? Icons.cloud_done : Icons.cloud_upload,
              color: RevenueCatService().isPremium ? Colors.green : Colors.orange,
            ),
            tooltip: RevenueCatService().isPremium ? 'Cloud Backup Aktif' : 'Upgrade ke Premium',
            onPressed: () async {
              if (RevenueCatService().isPremium) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Akun Anda sudah Premium. Auto-Sync aktif!'))
                );
              } else {
                // Tampilkan UI Paywall dari RevenueCat
                await RevenueCatUI.presentPaywallIfNeeded("premium");
                // Refresh UI setelah paywall ditutup (untuk melihat perubahan icon)
                setState(() {});
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ConnectivityBadge(isOnline: isOnline),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) => [
              PopupMenuItem(
                child: const Text('Pengaturan'),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const SettingsScreen())),
              ),
              PopupMenuItem(
                child: const Text('Kunci Layar'),
                onTap: () => context.read<SessionProvider>().lockScreen(),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Tanggal Hari Ini ─────────────────────────
              Text(
                DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                    .format(DateTime.now()),
                style: GoogleFonts.poppins(
                    color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Dashboard',
                style: GoogleFonts.poppins(
                    fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),

              // ── Ringkasan Cepat ──────────────────────────
              Row(
                children: [
                  _SummaryChip(
                    label: 'Stok Menipis',
                    value: '${products.lowStockProducts.length} produk',
                    icon: Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  _SummaryChip(
                    label: 'Refill Hari Ini',
                    value: '${refill.todayCount}x  •  '
                        '${currency.format(refill.todayIncome)}',
                    icon: Icons.water_drop_outlined,
                    color: const Color(0xFF0097A7),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Modul Utama ──────────────────────────────
              Text(
                'Pilih Modul',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              // 🛒 POS Produk
              ModuleCard(
                title: 'Kasir Produk',
                subtitle: 'Jual barang & kelola stok',
                icon: Icons.point_of_sale,
                color: const Color(0xFF00695C),
                badge: products.lowStockProducts.isNotEmpty
                    ? '⚠️ ${products.lowStockProducts.length} stok tipis'
                    : null,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PosScreen())),
              ),
              const SizedBox(height: 16),

              // 💧 Refill Air RO
              ModuleCard(
                title: 'Refill Air RO',
                subtitle: 'Catat isi ulang air',
                icon: Icons.water_drop,
                color: const Color(0xFF0097A7),
                badge: '${refill.todayCount} hari ini',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RefillEntryScreen())),
              ),
              const SizedBox(height: 28),

              // ── Menu Cepat ───────────────────────────────
              Text(
                'Menu Lainnya',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _QuickMenu(
                    icon: Icons.inventory_2_outlined,
                    label: 'Katalog\nProduk',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProductListScreen())),
                  ),
                  const SizedBox(width: 12),
                  _QuickMenu(
                    icon: Icons.history,
                    label: 'Riwayat\nRefill',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RefillHistoryScreen())),
                  ),
                  const SizedBox(width: 12),
                  _QuickMenu(
                    icon: Icons.bar_chart_rounded,
                    label: 'Rekap\nBulanan',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RefillMonthlyScreen())),
                  ),
                  const SizedBox(width: 12),
                  _QuickMenu(
                    icon: Icons.settings_outlined,
                    label: 'Peng-\naturan',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                  color: Colors.grey.shade600, fontSize: 11),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickMenu extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickMenu(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF00695C), size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.poppins(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
