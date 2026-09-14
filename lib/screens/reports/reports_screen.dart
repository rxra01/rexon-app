import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models/sale.dart';
import '../../providers/auth_provider.dart';
import '../../providers/retail_provider.dart';
import '../billing/widgets/receipt_dialog.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _dateFilter = 'all'; // 'today', '7days', 'month', 'all'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Sale> _getFilteredSales(List<Sale> allSales) {
    final now = DateTime.now();
    return allSales.where((s) {
      if (s.voided) return false;
      if (_dateFilter == 'today') {
        return s.createdAt.year == now.year &&
            s.createdAt.month == now.month &&
            s.createdAt.day == now.day;
      } else if (_dateFilter == '7days') {
        return s.createdAt.isAfter(now.subtract(const Duration(days: 7)));
      } else if (_dateFilter == 'month') {
        return s.createdAt.year == now.year && s.createdAt.month == now.month;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final retail = context.watch<RetailProvider>();
    final auth = context.watch<AuthProvider>();

    final sales = _getFilteredSales(retail.sales);
    final totalRevenue = sales.fold(0.0, (acc, s) => acc + s.grandTotal);
    final totalCollected = sales.fold(0.0, (acc, s) => acc + s.amountPaid);
    final totalDiscounts = sales.fold(0.0, (acc, s) => acc + s.discount);

    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.analytics_rounded, color: AppTheme.secondaryBlue, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Reports & Ledger',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.secondaryBlue,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.secondaryBlue,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Sales Report'),
            Tab(text: 'Inventory Valuation'),
            Tab(text: 'Receivables Khata'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: SALES REPORT (PRD §6.7)
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date Filter Chips
                Row(
                  children: [
                    Text('Date Period: ', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    _buildDateChip('Today', 'today'),
                    const SizedBox(width: 6),
                    _buildDateChip('Last 7 Days', '7days'),
                    const SizedBox(width: 6),
                    _buildDateChip('This Month', 'month'),
                    const SizedBox(width: 6),
                    _buildDateChip('All Time', 'all'),
                  ],
                ),
                const SizedBox(height: 16),

                // Financial Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Total Billed Revenue',
                        AppConstants.formatCurrency(totalRevenue),
                        '${sales.length} invoices generated',
                        AppTheme.secondaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Cash Collected',
                        AppConstants.formatCurrency(totalCollected),
                        'Received via UPI / Cash / Card',
                        AppTheme.tertiaryEmerald,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Total Discounts Given',
                        AppConstants.formatCurrency(totalDiscounts),
                        'Savings passed to buyers',
                        AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Sales Data Table
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderSlate),
                  ),
                  child: sales.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('No sales found for selected period.')),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sales.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, idx) {
                            final s = sales[idx];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.surfaceContainerLow,
                                child: const Icon(Icons.receipt_rounded, size: 20, color: AppTheme.secondaryBlue),
                              ),
                              title: Text('#${s.invoiceNumber} — ${s.customerName}',
                                  style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                              subtitle: Text('${AppConstants.formatDate(s.createdAt)} • ${s.items.length} items • ${s.paymentMethod.toUpperCase()}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        AppConstants.formatCurrency(s.grandTotal),
                                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        s.paymentStatus.toUpperCase(),
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: s.paymentStatus == 'paid' ? AppTheme.emeraldText : AppTheme.crimsonError,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.visibility_outlined, size: 20),
                                    onPressed: () => ReceiptDialog.show(context, s, auth.currentBusiness),
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

          // TAB 2: INVENTORY REPORT (PRD §6.7)
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Total Retail Stock Value',
                        AppConstants.formatCurrency(retail.totalInventoryRetailValue),
                        'Potential selling revenue',
                        AppTheme.secondaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Total Purchase Investment',
                        AppConstants.formatCurrency(retail.totalInventoryCostValue),
                        'Total capital tied in stock',
                        AppTheme.primarySlate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Projected Gross Profit',
                        AppConstants.formatCurrency(retail.totalInventoryRetailValue - retail.totalInventoryCostValue),
                        'Gross margin potential',
                        AppTheme.tertiaryEmerald,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderSlate),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: retail.products.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final p = retail.products[idx];
                      final stockCost = p.purchasePrice * p.currentStock;
                      final stockRetail = p.sellingPrice * p.currentStock;

                      return ListTile(
                        title: Text(p.name, style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                        subtitle: Text('SKU: ${p.sku} • In Stock: ${p.currentStock} ${p.unit} • Category: ${p.category}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppConstants.formatCurrency(stockRetail),
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'Cost: ${AppConstants.formatCurrency(stockCost)}',
                              style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textMuted),
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

          // TAB 3: RECEIVABLES KHATA REPORT (PRD §6.7)
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMetricCard(
                  'Total Outstanding Receivables Due',
                  AppConstants.formatCurrency(retail.totalOutstandingReceivables),
                  'From credit bills across all customers',
                  AppTheme.crimsonError,
                ),
                const SizedBox(height: 20),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderSlate),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: retail.customers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final c = retail.customers[idx];
                      return ListTile(
                        title: Text(c.name, style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                        subtitle: Text('${c.phone ?? "No phone"} • ${c.address ?? ""}'),
                        trailing: Text(
                          AppConstants.formatCurrency(c.outstandingAmount),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: c.outstandingAmount > 0 ? AppTheme.crimsonError : AppTheme.tertiaryEmerald,
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

  Widget _buildDateChip(String label, String value) {
    final isSel = _dateFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      selectedColor: AppTheme.primarySlate,
      labelStyle: TextStyle(color: isSel ? Colors.white : AppTheme.textDark, fontWeight: FontWeight.w600),
      onSelected: (_) => setState(() => _dateFilter = value),
    );
  }

  Widget _buildMetricCard(String title, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(sub, style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
