import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';

/// Kartu produk yang ditampilkan di layar POS kasir.
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final String currencySymbol;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.currencySymbol = 'Rp',
  });

  @override
  Widget build(BuildContext context) {
    final priceStr = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '$currencySymbol ',
      decimalDigits: 0,
    ).format(product.sellPrice);

    final isLow = product.isLowStock;

    return GestureDetector(
      onTap: product.stock > 0 ? onTap : null,
      child: AnimatedOpacity(
        opacity: product.stock > 0 ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon kategori
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00695C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      color: Color(0xFF00695C), size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  product.name,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.category.isNotEmpty)
                  Text(
                    product.category,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade600),
                  ),
                const Spacer(),
                Text(
                  priceStr,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF00695C),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: isLow ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Stok: ${product.stock}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isLow ? Colors.red : Colors.grey.shade700,
                        fontWeight:
                            isLow ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
