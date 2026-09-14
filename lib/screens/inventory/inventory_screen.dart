import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models/product.dart';
import '../../providers/retail_provider.dart';
import 'widgets/add_edit_product_dialog.dart';
import 'widgets/adjust_stock_dialog.dart';
import 'widgets/product_history_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'all'; // 'all', 'in-stock', 'low-stock', 'out-of-stock'

  @override
  Widget build(BuildContext context) {
    final retail = context.watch<RetailProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final filteredProducts = retail.products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.barcode != null && p.barcode!.contains(_searchQuery));

      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;

      bool matchesStatus = true;
      if (_selectedStatus == 'in-stock') {
        matchesStatus = !p.isLowStock && !p.isOutOfStock;
      } else if (_selectedStatus == 'low-stock') {
        matchesStatus = p.isLowStock;
      } else if (_selectedStatus == 'out-of-stock') {
        matchesStatus = p.isOutOfStock;
      }

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();

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
              child: const Icon(Icons.inventory_2_rounded, color: AppTheme.secondaryBlue, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Inventory Management',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: () => AddEditProductDialog.show(context),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Executive KPI Metric Cards (from Stitch DESIGN.md)
            LayoutBuilder(
              builder: (ctx, constraints) {
                final count = constraints.maxWidth >= 900
                    ? 4
                    : constraints.maxWidth >= 550
                        ? 2
                        : 2;

                return GridView.count(
                  crossAxisCount: count,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isDesktop ? 2.0 : 1.5,
                  children: [
                    _buildKpiCard(
                      'Total Items',
                      '${retail.products.length}',
                      'Active Products in Catalogue',
                      Icons.inventory_2_outlined,
                      AppTheme.secondaryBlue,
                      AppTheme.surfaceContainerLow,
                    ),
                    _buildKpiCard(
                      'Stock Valuation',
                      AppConstants.formatCurrency(retail.totalInventoryRetailValue),
                      'Cost: ${AppConstants.formatCurrency(retail.totalInventoryCostValue)}',
                      Icons.payments_outlined,
                      AppTheme.tertiaryEmerald,
                      AppTheme.emeraldLight,
                    ),
                    _buildKpiCard(
                      'Low Stock Alert',
                      '${retail.lowStockCount}',
                      'Items below min threshold',
                      Icons.warning_amber_rounded,
                      AppTheme.amberWarning,
                      AppTheme.amberLight,
                      onTap: () => setState(() => _selectedStatus = 'low-stock'),
                    ),
                    _buildKpiCard(
                      'Out of Stock',
                      '${retail.outOfStockCount}',
                      'Urgent restock needed',
                      Icons.remove_shopping_cart_outlined,
                      AppTheme.crimsonError,
                      AppTheme.crimsonLight,
                      onTap: () => setState(() => _selectedStatus = 'out-of-stock'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Search & Filter Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSlate),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      // Search Input
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search product by name, SKU or barcode...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () => setState(() => _searchQuery = ''),
                                  )
                                : null,
                          ),
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Status Dropdown Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderInput),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            icon: const Icon(Icons.filter_list_rounded, size: 18),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                              DropdownMenuItem(value: 'in-stock', child: Text('In Stock')),
                              DropdownMenuItem(value: 'low-stock', child: Text('Low Stock Alert')),
                              DropdownMenuItem(value: 'out-of-stock', child: Text('Out of Stock')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedStatus = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Category Chips Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: AppConstants.defaultCategories.map((cat) {
                        final isSel = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat),
                            selected: isSel,
                            selectedColor: AppTheme.primarySlate,
                            backgroundColor: AppTheme.surfaceContainerLow,
                            labelStyle: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                              color: isSel ? Colors.white : AppTheme.textDark,
                            ),
                            onSelected: (_) => setState(() => _selectedCategory = cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Products Table / List Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSlate),
              ),
              child: filteredProducts.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No products match your search or filter.',
                              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _selectedCategory = 'All';
                                  _selectedStatus = 'all';
                                });
                              },
                              child: const Text('Reset Filters'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredProducts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final p = filteredProducts[idx];
                        return _buildProductRow(context, p);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, String sub, IconData icon, Color color, Color bg, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderSlate),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 18),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductRow(BuildContext context, Product p) {
    final marginPct = p.purchasePrice > 0
        ? (((p.sellingPrice - p.purchasePrice) / p.purchasePrice) * 100).toStringAsFixed(1)
        : '0';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Category Icon Container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getCategoryIcon(p.category), color: AppTheme.secondaryBlue, size: 22),
          ),
          const SizedBox(width: 14),

          // Name, SKU & Barcode
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        p.name,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStockChip(p),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'SKU: ${p.sku} ${p.barcode != null ? "• Barcode: ${p.barcode}" : ""} • Category: ${p.category}',
                  style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),

          // Price & Margin
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppConstants.formatCurrency(p.sellingPrice),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  'Cost: ${AppConstants.formatCurrency(p.purchasePrice)} (+$marginPct%)',
                  style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Stock Available Count
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${p.currentStock} ${p.unit}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: p.isOutOfStock
                        ? AppTheme.crimsonError
                        : p.isLowStock
                            ? AppTheme.amberWarning
                            : AppTheme.textDark,
                  ),
                ),
                Text(
                  'Min: ${p.minStockLevel}',
                  style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Action Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted, size: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onSelected: (val) {
              if (val == 'adjust') {
                AdjustStockDialog.show(context, p);
              } else if (val == 'history') {
                ProductHistoryDialog.show(context, p);
              } else if (val == 'edit') {
                AddEditProductDialog.show(context, productToEdit: p);
              } else if (val == 'delete') {
                _confirmDelete(context, p);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'adjust',
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 18, color: AppTheme.secondaryBlue),
                    SizedBox(width: 8),
                    Text('Adjust Stock (+/-)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Stock Audit Trail'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Product Details'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.crimsonError),
                    SizedBox(width: 8),
                    Text('Delete Product', style: TextStyle(color: AppTheme.crimsonError)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockChip(Product p) {
    if (p.isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.crimsonLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.crimsonBorder),
        ),
        child: Text(
          'OUT OF STOCK',
          style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.crimsonText),
        ),
      );
    } else if (p.isLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.amberLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.amberBorder),
        ),
        child: Text(
          'LOW STOCK (${p.currentStock})',
          style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.amberText),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.emeraldLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.emeraldBorder),
        ),
        child: Text(
          'IN STOCK',
          style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.emeraldText),
        ),
      );
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.devices_other_rounded;
      case 'apparel':
        return Icons.checkroom_rounded;
      case 'groceries':
        return Icons.local_grocery_store_rounded;
      case 'hardware':
        return Icons.build_rounded;
      case 'footwear':
        return Icons.roller_skating_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  void _confirmDelete(BuildContext context, Product p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${p.name}?'),
        content: const Text('Are you sure? This will remove this item from your store catalogue.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimsonError, foregroundColor: Colors.white),
            onPressed: () {
              context.read<RetailProvider>().deleteProduct(p.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
