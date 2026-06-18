import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/tutorial_overlay.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/refill_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/connectivity_badge.dart';
import '../../widgets/module_card.dart';
import '../pos/pos_screen.dart';
import '../products/product_list_screen.dart';
import '../products/product_monthly_screen.dart';
import '../refill/refill_entry_screen.dart';
import '../refill/refill_monthly_screen.dart';
import '../settings/settings_screen.dart';
import '../statistic_pos/statistic_screen.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../../services/revenuecat_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showTutorial = false;
  String _catalogStage = 'none';

  // GlobalKeys untuk tutorial highlight
  final _keyStokChip = GlobalKey();
  final _keyRefillChip = GlobalKey();
  final _keyModulPOS = GlobalKey();
  final _keyModulRefill = GlobalKey();
  final _keyMenuKatalog = GlobalKey();
  final _keyMenuLaporanPOS = GlobalKey();
  final _keyMenuLaporanRefill = GlobalKey();
  final _keyMenuStatistik = GlobalKey();
  final _keyMenuPengaturan = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
      _checkTutorial();
    });
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final stage = prefs.getString('tutorial_catalog_stage') ?? 'none';
    
    final shown = await TutorialOverlay.hasBeenShown('home_screen');
    if (!shown && mounted) {
      setState(() {
        _showTutorial = true;
        _catalogStage = 'home_intro';
      });
      return;
    }

    if (stage == 'home_pos_intro' && mounted) {
      setState(() {
        _showTutorial = true;
        _catalogStage = stage;
      });
    } else {
      if (mounted) {
        setState(() {
          _showTutorial = false;
          _catalogStage = 'none';
        });
      }
    }
  }

  List<TutorialStep> _buildTutorialSteps(String stage) {
    if (stage == 'home_pos_intro') {
      return [
        const TutorialStep(
          message: 'Sekarang, mari kita coba modul Kasir Produk untuk melakukan transaksi penjualan barang kelontong.',
          characterPosition: 'left',
        ),
        TutorialStep(
          message: 'Ketuk "Selesai" untuk membuka modul Kasir Produk.',
          targetKey: _keyModulPOS,
          characterPosition: 'left',
          verticalPosition: 'bottom',
        ),
      ];
    }

    return [
      const TutorialStep(
        message: 'Halo!  Saya RO Man, asisten virtual Anda!\n\nSaya akan memandu Anda mengenal fitur-fitur aplikasi kasir ini. Ketuk layar untuk mempercepat teks, atau tekan "Skip Tutorial" untuk melewati.',
        characterPosition: 'left',
      ),
      TutorialStep(
        message: 'Ini adalah panel Ringkasan Cepat.\n\nDi sini Anda bisa melihat berapa produk yang stoknya menipis agar bisa segera diisi ulang.',
        targetKey: _keyStokChip,
        characterPosition: 'left',
      ),
      TutorialStep(
        message: 'Panel ini menampilkan jumlah transaksi Refill Air RO hari ini beserta total pendapatannya secara real-time.',
        targetKey: _keyRefillChip,
        characterPosition: 'right',
      ),
      TutorialStep(
        message: ' Ini adalah modul Kasir Produk!\n\nDi sini Anda bisa menjual barang kelontong, mengelola keranjang belanja, dan mencetak struk melalui printer Bluetooth.',
        targetKey: _keyModulPOS,
        characterPosition: 'left',
      ),
      TutorialStep(
        message: ' Modul Refill Air RO\n\nGunakan modul ini untuk mencatat setiap transaksi isi ulang air RO. Cukup pilih jenis layanan dan jumlah galon, lalu simpan!',
        targetKey: _keyModulRefill,
        characterPosition: 'right',
        verticalPosition: 'top',
      ),
      TutorialStep(
        message: ' Menu Katalog Produk\n\nDi sini Anda bisa menambah, mengedit, dan menghapus produk. Anda juga bisa memfilter berdasarkan kategori dan mengurutkan berdasarkan stok.\n\nSetelah tutorial ini selesai, kita akan langsung ke sana!',
        targetKey: _keyMenuKatalog,
        characterPosition: 'left',
        verticalPosition: 'top',
      ),
      TutorialStep(
        message: ' Di baris ini juga ada menu Laporan POS, Laporan Refill, dan Statistik POS untuk melihat rekap penjualan bulanan, riwayat transaksi, dan grafik produk terlaris.',
        targetKey: _keyMenuLaporanPOS,
        characterPosition: 'left',
        verticalPosition: 'top',
      ),
      TutorialStep(
        message: 'Tutorial Dashboard selesai! \n\nSekarang saya akan membawa Anda ke halaman Katalog Produk untuk mulai mengelola barang dagangan.',
        targetKey: _keyMenuKatalog,
        characterPosition: 'left',
        verticalPosition: 'top',
      ),
    ];
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<SettingsProvider>().loadSettings(),
      context.read<CategoryProvider>().loadCategories(),
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
    final session = context.watch<SessionProvider>();
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Stack(
      children: [
        Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(settings.storeName),
        actions: [
          IconButton(
            icon: Icon(
              RevenueCatService().isPremium
                  ? Icons.cloud_done
                  : Icons.cloud_upload,
              color: RevenueCatService().isPremium
                  ? Colors.green
                  : Colors.orange,
            ),
            tooltip: RevenueCatService().isPremium
                ? 'Cloud Backup Aktif'
                : 'Upgrade ke Premium',
            onPressed: () async {
              if (RevenueCatService().isPremium) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Akun Anda sudah Premium. Auto-Sync aktif!'),
                  ),
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
              if (session.isOwner)
                PopupMenuItem(
                  child: const Text('Pengaturan'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              PopupMenuItem(
                child: const Text('Kunci Layar'),
                onTap: () => context.read<SessionProvider>().lockScreen(),
              ),
              PopupMenuItem(
                child: const Text('Mulai Ulang Tutorial'),
                onTap: () async {
                  await TutorialOverlay.reset('home_screen');
                  if (mounted) {
                    setState(() => _showTutorial = true);
                  }
                },
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
                DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Dashboard',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),

              // ── Ringkasan Cepat ──────────────────────────
              Row(
                children: [
                  _SummaryChip(
                    key: _keyStokChip,
                    label: 'Stok Menipis',
                    value: '${products.lowStockProducts.length} produk',
                    icon: Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  _SummaryChip(
                    key: _keyRefillChip,
                    label: 'Refill Hari Ini',
                    value:
                        '${refill.todayCount}x  •  '
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // 🛒 POS Produk
              ModuleCard(
                key: _keyModulPOS,
                title: 'Kasir Produk',
                subtitle: 'Jual barang & kelola stok',
                icon: Icons.point_of_sale,
                color: const Color(0xFF00695C),
                badge: products.lowStockProducts.isNotEmpty
                    ? '⚠️ ${products.lowStockProducts.length} stok tipis'
                    : null,
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final stage = prefs.getString('tutorial_catalog_stage') ?? 'none';
                  if (stage == 'home_pos_intro') {
                    await prefs.setString('tutorial_catalog_stage', 'pos_intro');
                  }
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PosScreen()),
                    ).then((_) => _checkTutorial());
                  }
                },
              ),
              const SizedBox(height: 16),

              // 💧 Refill Air RO
              ModuleCard(
                key: _keyModulRefill,
                title: 'Refill Air RO',
                subtitle: 'Catat isi ulang air',
                icon: Icons.water_drop,
                color: const Color(0xFF0097A7),
                badge: '${refill.todayCount} hari ini',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RefillEntryScreen()),
                ),
              ),
              const SizedBox(height: 28),

              // ── Menu Cepat ───────────────────────────────
              Text(
                'Menu Lainnya',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _QuickMenu(
                      key: _keyMenuKatalog,
                      icon: Icons.inventory_2_outlined,
                      label: 'Katalog\nProduk',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductListScreen(),
                        ),
                      ).then((_) => _checkTutorial()),
                    ),
                    const SizedBox(width: 12),
                    _QuickMenu(
                      key: _keyMenuLaporanPOS,
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
                      key: _keyMenuLaporanRefill,
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
                      key: _keyMenuStatistik,
                      icon: Icons.pie_chart,
                      label: 'Statistik\nPOS',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StatisticScreen(),
                        ),
                      ),
                    ),
                    if (session.isOwner) ...[
                      const SizedBox(width: 12),
                      _QuickMenu(
                        key: _keyMenuPengaturan,
                        icon: Icons.settings_outlined,
                        label: 'Peng-\naturan',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),

    // ── Tutorial Overlay ──────────────────────────────
    if (_showTutorial)
      Positioned.fill(
        child: TutorialOverlay(
          tutorialKey: _catalogStage == 'home_pos_intro' ? 'home_pos_intro' : 'home_screen',
          steps: _buildTutorialSteps(_catalogStage),
          onComplete: () async {
            setState(() => _showTutorial = false);
            final prefs = await SharedPreferences.getInstance();
            if (_catalogStage == 'home_pos_intro') {
              await prefs.setString('tutorial_catalog_stage', 'pos_intro'); // use the correct key
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PosScreen()),
                ).then((_) => _checkTutorial());
              }
            } else {
              await prefs.setString('tutorial_catalog_stage', 'list_intro');
              if (mounted) {
                // Navigasi ke Katalog Produk setelah tutorial selesai
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProductListScreen(),
                  ),
                ).then((_) => _checkTutorial());
              }
            }
          },
          onSkip: () async {
            setState(() => _showTutorial = false);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('tutorial_catalog_stage', 'completed');
          },
        ),
      ),
    ],
  );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryChip({
    super.key,
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
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
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
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
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

  const _QuickMenu({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 85,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
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
    );
  }
}
