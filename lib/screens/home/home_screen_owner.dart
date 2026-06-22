import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/pos_history_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/refill_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/settings_provider.dart';

import '../../widgets/connectivity_badge.dart';
import '../../widgets/tutorial_overlay.dart';
import '../auth/login_screen.dart';
import '../products/product_list_screen.dart';
import '../products/product_monthly_screen.dart';
import '../refill/refill_monthly_screen.dart';
import '../settings/settings_screen.dart';
import '../statistic_pos/statistic_screen.dart';

class HomeScreenOwner extends StatefulWidget {
  const HomeScreenOwner({super.key});

  @override
  State<HomeScreenOwner> createState() => _HomeScreenOwnerState();
}

class _HomeScreenOwnerState extends State<HomeScreenOwner> {
  int _currentPage = 0;

  final _keyTodaySales = GlobalKey();
  final _keyTopProducts = GlobalKey();
  final _keyRefillRO = GlobalKey();
  final _keySettingsMenu = GlobalKey();

  final _keyMoreMenu = GlobalKey();

  final _mainScrollCtrl = ScrollController();
  final _quickMenuScrollCtrl = ScrollController();

  bool _showTutorial = false;
  int _tutorialStage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      context.read<PosHistoryProvider>().loadMonthTransactions(
            now.year,
            now.month,
            forceCloud: true,
          );
      context.read<ProductProvider>().loadProducts();
      context.read<RefillProvider>().loadTodayRecords();
      _checkTutorial();
    });
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Migrasi state lama jika ada
    if (prefs.getBool('tutorial_owner_dashboard') == true && prefs.getInt('tutorial_owner_stage') == null) {
      await prefs.setInt('tutorial_owner_stage', 5); // completed
    }

    final stage = prefs.getInt('tutorial_owner_stage') ?? 0;
    if (stage == 0) {
      if (mounted) setState(() { _showTutorial = true; _tutorialStage = 0; });
    } else if (stage == 4) {
      if (mounted) setState(() { _showTutorial = true; _tutorialStage = 4; });
    }
  }

  @override
  void dispose() {
    _mainScrollCtrl.dispose();
    _quickMenuScrollCtrl.dispose();
    super.dispose();
  }

  List<TutorialStep> _buildTutorialSteps() {
    if (_tutorialStage == 4) {
      return [
        TutorialStep(
          message: 'Tutorial selesai! Anda kini siap menggunakan aplikasi secara mandiri. Selamat berjualan!',
          verticalPosition: 'top',
          characterPosition: 'left',
        ),
      ];
    }
    
    return [
      TutorialStep(
        message: 'Di bagian atas adalah ringkasan pendapatan dan transaksi Anda hari ini dari penjualan POS kelontong.',
        verticalPosition: 'bottom',
        characterPosition: 'left',
        onStart: () async {
          await _mainScrollCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
      ),
      TutorialStep(
        message: 'Di bawahnya, Anda bisa melihat produk apa saja yang paling laris terjual hari ini.',
        verticalPosition: 'bottom',
        characterPosition: 'right',
        onStart: () async {
           await _mainScrollCtrl.animateTo(180, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
      ),
      TutorialStep(
        message: 'Di bagian paling bawah merekap total penjualan Air RO khusus hari ini saja.',
        verticalPosition: 'top',
        characterPosition: 'left',
        onStart: () async {
           await _mainScrollCtrl.animateTo(_mainScrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
      ),
      TutorialStep(
        message: 'Menu Cepat Pengaturan Sistem. Mari kita atur profil warung dan harga dasar air RO Anda. Klik tombol ini!',
        targetKey: _keySettingsMenu,
        verticalPosition: 'top',
        characterPosition: 'right',
        onStart: () async {
           await _mainScrollCtrl.animateTo(_mainScrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
           await _quickMenuScrollCtrl.animateTo(_quickMenuScrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
      ),
    ];
  }

  void _logout(BuildContext context) async {
    await context.read<AuthProvider>().signOut();
    if (context.mounted) {
      context.read<SessionProvider>().lockScreen();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final auth = context.watch<AuthProvider>();
    final posHistory = context.watch<PosHistoryProvider>();
    final settings = context.watch<SettingsProvider>().settings;
    final products = context.watch<ProductProvider>().products;
    final refill = context.watch<RefillProvider>();
    final isOnline = context.watch<ConnectivityProvider>().isOnline;

    final currency = NumberFormat.currency(
        locale: 'id_ID', symbol: '${settings.currencySymbol} ', decimalDigits: 0);

    final now = DateTime.now();
    int todayIncome = 0;
    int todayTrxCount = 0;
    final Map<String, int> productSales = {};

    for (final trx in posHistory.monthTransactions) {
      if (trx.timestamp.year == now.year &&
          trx.timestamp.month == now.month &&
          trx.timestamp.day == now.day) {
        todayIncome += trx.totalAmount;
        todayTrxCount++;
        for (final item in trx.items) {
          productSales[item.productId] =
              (productSales[item.productId] ?? 0) + item.qty;
        }
      }
    }

    final sortedSales = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    final int itemsPerPage = 5;
    final int totalPages = (sortedSales.isEmpty) ? 1 : (sortedSales.length / itemsPerPage).ceil();
    final paginatedSales = sortedSales.skip(_currentPage * itemsPerPage).take(itemsPerPage).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(settings.storeName, style: const TextStyle(fontSize: 18)),
            Text(
              'Dashboard Owner',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ConnectivityBadge(isOnline: isOnline),
          ),
          PopupMenuButton(
            key: _keyMoreMenu,
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) => [
              PopupMenuItem(
                child: const Text('Pengaturan'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ).then((_) => _checkTutorial()),
              ),
              PopupMenuItem(
                child: const Text('Kunci Layar'),
                onTap: () => context.read<SessionProvider>().lockScreen(),
              ),
              PopupMenuItem(
                child: const Text('Mulai Ulang Tutorial'),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('tutorial_owner_stage');
                  await TutorialOverlay.reset('owner_dashboard');
                  await TutorialOverlay.reset('owner_settings');
                  await TutorialOverlay.reset('owner_settings_done');
                  if (mounted) {
                    setState(() { _showTutorial = true; _tutorialStage = 0; });
                  }
                },
              ),
              PopupMenuItem(
                child: const Text('Logout Akun'),
                onTap: () => _logout(context),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
            final date = DateTime.now();
            await context.read<PosHistoryProvider>().loadMonthTransactions(
                  date.year,
                  date.month,
                  forceCloud: true,
                );
            await context.read<ProductProvider>().loadProducts();
            await context.read<RefillProvider>().loadTodayRecords();
          },
          child: SingleChildScrollView(
            controller: _mainScrollCtrl,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Statistik Penjualan Hari Ini ─────────────────────
                Text(
                  'Penjualan Hari Ini',
                  key: _keyTodaySales,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Pendapatan',
                        value: currency.format(todayIncome),
                        icon: Icons.account_balance_wallet,
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Transaksi',
                        value: todayTrxCount.toString(),
                        icon: Icons.receipt,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Produk Terlaris Hari Ini ─────────────────────────
                Text(
                  'Produk Terlaris Hari Ini',
                  key: _keyTopProducts,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (posHistory.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (sortedSales.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Text(
                      'Belum ada penjualan hari ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: paginatedSales.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final productId = paginatedSales[index].key;
                      final qty = paginatedSales[index].value;
                      final product = products
                          .where((p) => p.id == productId)
                          .firstOrNull;
                      final productName = product?.name ?? 'Produk Dihapus';

                      final rankIndex = (_currentPage * itemsPerPage) + index + 1;

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF00695C).withOpacity(0.1),
                            child: Text(
                              '$rankIndex',
                              style: const TextStyle(
                                  color: Color(0xFF00695C),
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            productName,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          trailing: Text(
                            '$qty terjual',
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      );
                    },
                  ),
                  if (totalPages > 1) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _currentPage > 0
                              ? () => setState(() => _currentPage--)
                              : null,
                          icon: const Icon(Icons.arrow_back_ios, size: 14),
                          label: const Text('Sebelumnya'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF00695C),
                            elevation: 0,
                            side: BorderSide(color: Colors.grey.shade300),
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Halaman ${_currentPage + 1} dari $totalPages',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _currentPage < totalPages - 1
                              ? () => setState(() => _currentPage++)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF00695C),
                            elevation: 0,
                            side: BorderSide(color: Colors.grey.shade300),
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('Selanjutnya'),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
                const SizedBox(height: 32),

                // ── Refill Air RO Hari Ini ─────────────────────────
                Text(
                  'Refill Air RO Hari Ini',
                  key: _keyRefillRO,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Galon',
                        value: refill.todayCount.toString(),
                        icon: Icons.water_drop,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Pendapatan',
                        value: currency.format(refill.todayIncome),
                        icon: Icons.monetization_on,
                        color: Colors.teal.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Menu Cepat ───────────────────────────────
                Text(
                  'Menu Cepat',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  controller: _quickMenuScrollCtrl,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _QuickMenu(
                        icon: Icons.inventory_2_outlined,
                        label: 'Katalog\nProduk',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProductListScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _QuickMenu(
                        icon: Icons.receipt_long,
                        label: 'Laporan\nPOS',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PosMonthlyScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _QuickMenu(
                        icon: Icons.bar_chart_rounded,
                        label: 'Laporan\nRefill',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RefillMonthlyScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _QuickMenu(
                        icon: Icons.pie_chart,
                        label: 'Statistik\nPOS',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StatisticScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _QuickMenu(
                        key: _keySettingsMenu,
                        icon: Icons.settings_outlined,
                        label: 'Pengaturan\nSistem',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ).then((_) => _checkTutorial()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        if (_showTutorial)
          Positioned.fill(
            child: TutorialOverlay(
              tutorialKey: 'owner_dashboard',
              steps: _buildTutorialSteps(),
              onComplete: () async {
                final prefs = await SharedPreferences.getInstance();
                if (_tutorialStage == 0) {
                  await prefs.setInt('tutorial_owner_stage', 1);
                  if (mounted) {
                    setState(() => _showTutorial = false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ).then((_) => _checkTutorial());
                  }
                } else if (_tutorialStage == 4) {
                  await prefs.setInt('tutorial_owner_stage', 5); // completed
                  if (mounted) setState(() => _showTutorial = false);
                }
              },
              onSkip: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('tutorial_owner_stage', 5); // force complete on skip
                if (mounted) setState(() => _showTutorial = false);
              },
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickMenu extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickMenu({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF00695C), size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
