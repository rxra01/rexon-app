import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models/sale.dart';
import '../../providers/auth_provider.dart';
import '../../providers/retail_provider.dart';
import '../billing/widgets/receipt_dialog.dart';
import '../billing/widgets/void_dialog.dart';
import '../inventory/widgets/add_edit_product_dialog.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int tabIndex)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final retail = context.watch<RetailProvider>();
    final business = auth.currentBusiness;

    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Welcome & Store Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSlate),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppTheme.secondaryBlue,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              business?.name ?? 'Rexon Store',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.emeraldLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.emeraldBorder),
                              ),
                              child: Text(
                                'OPEN FOR BILLING',
                                style: GoogleFonts.manrope(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.emeraldText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Owner: ${business?.ownerName ?? "Shop Owner"} • Currency: ${business?.currency ?? "₹"} INR',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDesktop)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                      label: const Text('Quick Bill (POS)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => onNavigateTab?.call(1),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Executive KPI Cards Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 1000
                    ? 4
                    : constraints.maxWidth >= 600
                        ? 2
                        : 2;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: isDesktop ? 1.7 : 1.35,
                  children: [
                    // Card 1: Today's Sales
                    _buildKpiCard(
                      title: "Today's Sales",
                      value: AppConstants.formatCurrency(retail.todaySalesTotal),
                      subtitle: "${retail.todaySalesCount} bills today",
                      icon: Icons.payments_rounded,
                      iconBg: AppTheme.secondaryBlue.withOpacity(0.1),
                      iconColor: AppTheme.secondaryBlue,
                      badgeText: '+ Live',
                      badgeColor: AppTheme.secondaryBlue,
                    ),

                    // Card 2: Outstanding Receivables (Khata)
                    _buildKpiCard(
                      title: "Receivables (Khata)",
                      value: AppConstants.formatCurrency(retail.totalOutstandingReceivables),
                      subtitle: "Pending from credit clients",
                      icon: Icons.account_balance_wallet_rounded,
                      iconBg: AppTheme.crimsonLight,
                      iconColor: AppTheme.crimsonError,
                      badgeText: retail.totalOutstandingReceivables > 0 ? 'Dues Owed' : 'All Clear',
                      badgeColor: retail.totalOutstandingReceivables > 0 ? AppTheme.crimsonError : AppTheme.tertiaryEmerald,
                      onTap: () => onNavigateTab?.call(3), // Jump to Customers/Khata
                    ),

                    // Card 3: Low Stock Alerts
                    _buildKpiCard(
                      title: "Low Stock Items",
                      value: "${retail.lowStockCount}",
                      subtitle: retail.outOfStockCount > 0
                          ? "${retail.outOfStockCount} items out of stock"
                          : "Items needing restock",
                      icon: Icons.warning_amber_rounded,
                      iconBg: AppTheme.amberLight,
                      iconColor: AppTheme.amberWarning,
                      badgeText: retail.lowStockCount > 0 ? 'Restock Req.' : 'Stock Healthy',
                      badgeColor: retail.lowStockCount > 0 ? AppTheme.amberWarning : AppTheme.tertiaryEmerald,
                      onTap: () => onNavigateTab?.call(2), // Jump to Inventory
                    ),

                    // Card 4: Total Inventory
                    _buildKpiCard(
                      title: "Active Products",
                      value: "${retail.products.length}",
                      subtitle: "Value: ${AppConstants.formatCurrency(retail.totalInventoryRetailValue)}",
                      icon: Icons.inventory_2_rounded,
                      iconBg: AppTheme.emeraldLight,
                      iconColor: AppTheme.tertiaryEmerald,
                      badgeText: '${retail.products.length} SKUs',
                      badgeColor: AppTheme.tertiaryEmerald,
                      onTap: () => onNavigateTab?.call(2),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Quick Actions Ribbon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderSlate),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      label: Text(
                        'Start Billing (POS)',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => onNavigateTab?.call(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_box_rounded, size: 18),
                      label: Text(
                        'Add Product',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => AddEditProductDialog.show(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      label: Text(
                        'View Reports',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => onNavigateTab?.call(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent Transactions (PRD §6.7: "last 5-10 sales")
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSlate),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.history_rounded, size: 20, color: AppTheme.secondaryBlue),
                            const SizedBox(width: 8),
                            Text(
                              'Recent Invoices & Bills',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => onNavigateTab?.call(4),
                          child: const Text('View All Invoices →'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  if (retail.recentSales.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.receipt_outlined, size: 40, color: AppTheme.textMuted.withOpacity(0.5)),
                            const SizedBox(height: 8),
                            Text(
                              'No invoices billed yet.',
                              style: GoogleFonts.manrope(color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: retail.recentSales.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final sale = retail.recentSales[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.receipt_rounded, color: AppTheme.secondaryBlue, size: 20),
                          ),
                          title: Row(
                            children: [
                              Text(
                                '#${sale.invoiceNumber}',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusChip(sale),
                            ],
                          ),
                          subtitle: Text(
                            '${sale.customerName} • ${AppConstants.formatShortDate(sale.createdAt)}',
                            style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    AppConstants.formatCurrency(sale.grandTotal),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: sale.voided ? AppTheme.textMuted : AppTheme.textDark,
                                    ),
                                  ),
                                  if (sale.balanceDue > 0 && !sale.voided)
                                    Text(
                                      'Due: ${AppConstants.formatCurrency(sale.balanceDue)}',
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.crimsonError,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppTheme.textMuted),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                onSelected: (val) {
                                  if (val == 'view') {
                                    ReceiptDialog.show(context, sale, business);
                                  } else if (val == 'void' && !sale.voided) {
                                    VoidInvoiceDialog.show(context, sale);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(Icons.receipt_long_rounded, size: 18),
                                        SizedBox(width: 8),
                                        Text('View Receipt'),
                                      ],
                                    ),
                                  ),
                                  if (!sale.voided)
                                    const PopupMenuItem(
                                      value: 'void',
                                      child: Row(
                                        children: [
                                          Icon(Icons.cancel_outlined, size: 18, color: AppTheme.crimsonError),
                                          SizedBox(width: 8),
                                          Text('Void Invoice', style: TextStyle(color: AppTheme.crimsonError)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => ReceiptDialog.show(context, sale, business),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String badgeText,
    required Color badgeColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSlate),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(Sale sale) {
    if (sale.voided) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: AppTheme.crimsonLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.crimsonBorder),
        ),
        child: Text(
          'VOID',
          style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.crimsonText),
        ),
      );
    }

    if (sale.paymentStatus == 'paid') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: AppTheme.emeraldLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.emeraldBorder),
        ),
        child: Text(
          'PAID',
          style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.emeraldText),
        ),
      );
    } else if (sale.paymentStatus == 'partial') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: AppTheme.amberLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.amberBorder),
        ),
        child: Text(
          'PARTIAL',
          style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.amberText),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: AppTheme.crimsonLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.crimsonBorder),
        ),
        child: Text(
          'UNPAID',
          style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.crimsonText),
        ),
      );
    }
  }
}
