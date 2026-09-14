import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../data/models/product.dart';
import '../../../providers/retail_provider.dart';

class ProductHistoryDialog extends StatelessWidget {
  final Product product;

  const ProductHistoryDialog({super.key, required this.product});

  static void show(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => ProductHistoryDialog(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movements = context
        .watch<RetailProvider>()
        .movements
        .where((m) => m.productId == product.id)
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderSlate)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.history_rounded, color: AppTheme.secondaryBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stock Movement Audit Log',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${product.name} (SKU: ${product.sku})',
                          style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Stock summary pill
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Available Stock:',
                    style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.textMuted),
                  ),
                  Text(
                    '${product.currentStock} ${product.unit}',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: product.isOutOfStock
                          ? AppTheme.crimsonError
                          : product.isLowStock
                              ? AppTheme.amberWarning
                              : AppTheme.emeraldText,
                    ),
                  ),
                ],
              ),
            ),

            // Movements list
            Expanded(
              child: movements.isEmpty
                  ? Center(
                      child: Text(
                        'No movement records yet.',
                        style: GoogleFonts.manrope(color: AppTheme.textMuted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: movements.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final m = movements[idx];
                        final isPositive = m.quantityChange > 0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isPositive ? AppTheme.emeraldLight : AppTheme.crimsonLight,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPositive ? Icons.add_rounded : Icons.remove_rounded,
                                  size: 18,
                                  color: isPositive ? AppTheme.emeraldText : AppTheme.crimsonText,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          m.type.toUpperCase(),
                                          style: GoogleFonts.manrope(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                            color: isPositive ? AppTheme.emeraldText : AppTheme.crimsonText,
                                          ),
                                        ),
                                        Text(
                                          AppConstants.formatDate(m.createdAt),
                                          style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textMuted),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      m.reason ?? (m.type == 'sale' ? 'Customer Invoice Sale' : 'Inventory Change'),
                                      style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${isPositive ? "+" : ""}${m.quantityChange}',
                                style: GoogleFonts.manrope(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isPositive ? AppTheme.emeraldText : AppTheme.crimsonText,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
