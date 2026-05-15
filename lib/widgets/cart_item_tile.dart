import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';

/// Satu baris item di keranjang belanja.
class CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;
  final String currencySymbol;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    this.currencySymbol = 'Rp',
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '$currencySymbol ',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(
                    currency.format(item.product.sellPrice),
                    style: GoogleFonts.poppins(
                        color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Kontrol qty
            Row(
              children: [
                _QtyBtn(
                    icon: Icons.remove,
                    onTap: onDecrease,
                    color: Colors.red.shade400),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '${item.qty}',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                _QtyBtn(
                    icon: Icons.add,
                    onTap: onIncrease,
                    color: const Color(0xFF00695C)),
              ],
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: Text(
                currency.format(item.subtotal),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: const Color(0xFF00695C),
                ),
                textAlign: TextAlign.right,
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _QtyBtn(
      {required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
