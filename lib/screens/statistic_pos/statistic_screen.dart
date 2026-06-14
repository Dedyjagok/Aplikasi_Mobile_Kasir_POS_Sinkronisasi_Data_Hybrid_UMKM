import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../providers/pos_history_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';

class ProductStat {
  final String productName;
  final int qty;
  final String categoryName;

  ProductStat(this.productName, this.qty, this.categoryName);
}

class StatisticScreen extends StatefulWidget {
  const StatisticScreen({super.key});

  @override
  State<StatisticScreen> createState() => _StatisticScreenState();
}

class _StatisticScreenState extends State<StatisticScreen> {
  DateTime _selectedDate = DateTime.now();
  String _filterType = 'Bulanan'; // 'Bulanan' atau 'Harian'
  String? _selectedCategory; // null = Semua Kategori

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    context.read<PosHistoryProvider>().loadMonthTransactions(
      _selectedDate.year,
      _selectedDate.month,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month + 1, 0),
      // Jika bulanan, biasanya mode year, kalau harian mode day
      initialDatePickerMode: _filterType == 'Bulanan' ? DatePickerMode.year : DatePickerMode.day,
    );
    if (date != null) {
      setState(() => _selectedDate = date);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final posHistory = context.watch<PosHistoryProvider>();
    final products = context.watch<ProductProvider>().products;
    final categories = context.watch<CategoryProvider>().categories;

    // 1. Agregasi penjualan
    final Map<String, int> salesMap = {};
    for (final trx in posHistory.monthTransactions) {
      // Lewati jika filter harian dan tanggalnya tidak cocok
      if (_filterType == 'Harian' && trx.timestamp.day != _selectedDate.day) {
        continue;
      }
      for (final item in trx.items) {
        salesMap[item.productId] = (salesMap[item.productId] ?? 0) + item.qty;
      }
    }

    // 2. Petakan ke ProductStat
    List<ProductStat> allStats = [];
    salesMap.forEach((productId, qty) {
      final product = products.where((p) => p.id == productId).firstOrNull;
      final productName = product?.name ?? 'Produk Dihapus';
      final catId = product?.categoryId ?? '';
      final category = categories.where((c) => c.id == catId).firstOrNull;
      final categoryName = category?.name ?? 'Tanpa Kategori';

      if (_selectedCategory == null || _selectedCategory == categoryName) {
        allStats.add(ProductStat(productName, qty, categoryName));
      }
    });

    // 3. Data untuk Chart (Semua barang, sort by Kategori)
    List<ProductStat> chartStats = List.from(allStats);
    chartStats.sort((a, b) {
      int catCmp = a.categoryName.compareTo(b.categoryName);
      if (catCmp != 0) return catCmp;
      return b.qty.compareTo(a.qty);
    });

    // 4. Data untuk List (Terlaris berdasarkan qty)
    List<ProductStat> topStats = List.from(allStats);
    topStats.sort((a, b) => b.qty.compareTo(a.qty));

    // Menentukan lebar chart agar bisa discroll jika data banyak
    final double chartWidth =
        chartStats.length * 40.0 > MediaQuery.of(context).size.width
        ? chartStats.length * 40.0
        : MediaQuery.of(context).size.width - 64;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Statistik POS')),
      body: Column(
        children: [
          // Filter Tanggal & Kategori
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _filterType == 'Bulanan'
                          ? DateFormat('MMMM yyyy', 'id_ID').format(_selectedDate)
                          : DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month),
                      label: Text(_filterType == 'Bulanan' ? 'Pilih Bulan' : 'Pilih Hari', style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _filterType,
                            items: ['Bulanan', 'Harian'].map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _filterType = val);
                                _loadData();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedCategory,
                            hint: Text(
                              'Semua Kategori',
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text(
                                  'Semua Kategori',
                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                              ...categories.map(
                                (cat) => DropdownMenuItem(
                                  value: cat.name,
                                  child: Text(
                                    cat.name,
                                    style: GoogleFonts.poppins(fontSize: 13),
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Tanpa Kategori',
                                child: Text(
                                  'Tanpa Kategori',
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: posHistory.isLoading
                ? const Center(child: CircularProgressIndicator())
                : allStats.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada data penjualan pada $_filterType ini',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  )
                : Column(
                    children: [
                      const SizedBox(height: 16),
                      // ── GRAFIK ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Grafik Penjualan (Grup Kategori)',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF00695C),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 250,
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: chartWidth,
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    barTouchData: BarTouchData(
                                      enabled: true,
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipColor: (group) =>
                                            Colors.black87,
                                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                          return BarTooltipItem(
                                            '${chartStats[group.x.toInt()].productName}\n',
                                            const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            children: <TextSpan>[
                                              TextSpan(
                                                text:
                                                    '${rod.toY.toInt()} terjual\n',
                                                style: const TextStyle(
                                                  color: Colors.yellow,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    '(${chartStats[group.x.toInt()].categoryName})',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            if (index < 0 ||
                                                index >= chartStats.length) {
                                              return const SizedBox.shrink();
                                            }
                                            // Batasi panjang string
                                            String name =
                                                chartStats[index].productName;
                                            if (name.length > 8) {
                                              name =
                                                  '${name.substring(0, 6)}..';
                                            }
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8.0,
                                              ),
                                              child: Text(
                                                name,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          getTitlesWidget: (value, meta) {
                                            if (value == value.toInt()) {
                                              return Text(
                                                value.toInt().toString(),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: 1,
                                    ),
                                    barGroups: List.generate(
                                      chartStats.length,
                                      (index) => BarChartGroupData(
                                        x: index,
                                        barRods: [
                                          BarChartRodData(
                                            toY: chartStats[index].qty
                                                .toDouble(),
                                            color: const Color(0xFF0097A7),
                                            width: 20,
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(4),
                                                  topRight: Radius.circular(4),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── LIST TERLARIS ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Produk Terlaris (Kuantitas)',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF00695C),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: topStats.length,
                          itemBuilder: (context, index) {
                            final stat = topStats[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(
                                    0xFF00695C,
                                  ).withValues(alpha: 0.1),
                                  child: Text(
                                    '#${index + 1}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF00695C),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  stat.productName,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  stat.categoryName,
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                                trailing: Text(
                                  '${stat.qty} terjual',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
