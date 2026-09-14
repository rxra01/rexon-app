import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models/customer.dart';
import '../../data/models/product.dart';
import '../../data/models/sale.dart';
import '../../providers/auth_provider.dart';
import '../../providers/retail_provider.dart';
import 'widgets/receipt_dialog.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  // Current draft items
  final List<SaleItem> _items = [];

  // Customer state
  Customer? _selectedCustomer;
  final _walkInNameController = TextEditingController(text: 'Walk-in Customer');
  final _walkInPhoneController = TextEditingController();

  // Summary state
  final _discountController = TextEditingController(text: '0');
  bool _applyGst = false;

  // Payment state
  String _paymentStatus = 'paid'; // 'paid', 'partial', 'unpaid'
  String _paymentMethod = 'upi';
  final _amountPaidController = TextEditingController();

  bool _isBilling = false;

  @override
  void dispose() {
    _walkInNameController.dispose();
    _walkInPhoneController.dispose();
    _discountController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0.0, (acc, item) => acc + item.lineTotal);

  double get _discount => double.tryParse(_discountController.text.trim()) ?? 0.0;

  double get _tax => _applyGst ? ((_subtotal - _discount).clamp(0.0, double.infinity) * 0.18) : 0.0;

  double get _grandTotal => ((_subtotal - _discount) + _tax).clamp(0.0, double.infinity);

  double get _amountPaid {
    if (_paymentStatus == 'paid') return _grandTotal;
    if (_paymentStatus == 'unpaid') return 0.0;
    return (double.tryParse(_amountPaidController.text.trim()) ?? 0.0).clamp(0.0, _grandTotal);
  }

  double get _balanceDue => (_grandTotal - _amountPaid).clamp(0.0, double.infinity);

  void _addItem(Product product) {
    if (product.isOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} is currently OUT OF STOCK!'),
          backgroundColor: AppTheme.crimsonError,
        ),
      );
      return;
    }

    final existingIndex = _items.indexWhere((i) => i.productId == product.id);
    if (existingIndex != -1) {
      final existing = _items[existingIndex];
      if (existing.quantity >= product.currentStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot add more than available stock (${product.currentStock}).'),
            backgroundColor: AppTheme.amberWarning,
          ),
        );
        return;
      }
      setState(() {
        final newQty = existing.quantity + 1;
        _items[existingIndex] = SaleItem(
          productId: existing.productId,
          productName: existing.productName,
          sku: existing.sku,
          quantity: newQty,
          unitPrice: existing.unitPrice,
          lineTotal: newQty * existing.unitPrice,
        );
      });
    } else {
      setState(() {
        _items.add(
          SaleItem(
            productId: product.id,
            productName: product.name,
            sku: product.sku,
            quantity: 1,
            unitPrice: product.sellingPrice,
            lineTotal: product.sellingPrice,
          ),
        );
      });
    }

    if (_paymentStatus == 'paid') {
      _amountPaidController.text = _grandTotal.toStringAsFixed(2);
    }
  }

  void _updateQuantity(int index, int delta, int availableStock) {
    final item = _items[index];
    final newQty = item.quantity + delta;

    if (newQty <= 0) {
      setState(() => _items.removeAt(index));
    } else if (newQty > availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot exceed available stock ($availableStock).'),
          backgroundColor: AppTheme.amberWarning,
        ),
      );
    } else {
      setState(() {
        _items[index] = SaleItem(
          productId: item.productId,
          productName: item.productName,
          sku: item.sku,
          quantity: newQty,
          unitPrice: item.unitPrice,
          lineTotal: newQty * item.unitPrice,
        );
      });
    }
  }

  void _updateUnitPrice(int index, double newPrice) {
    final item = _items[index];
    setState(() {
      _items[index] = SaleItem(
        productId: item.productId,
        productName: item.productName,
        sku: item.sku,
        quantity: item.quantity,
        unitPrice: newPrice,
        lineTotal: item.quantity * newPrice,
      );
    });
  }

  Future<void> _handleGenerateInvoice() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one product to the invoice.'),
          backgroundColor: AppTheme.amberWarning,
        ),
      );
      return;
    }

    setState(() => _isBilling = true);
    final auth = context.read<AuthProvider>();
    final retail = context.read<RetailProvider>();

    try {
      final customerName = _selectedCustomer?.name ??
          (_walkInNameController.text.trim().isNotEmpty
              ? _walkInNameController.text.trim()
              : 'Walk-in Customer');

      final customerPhone = _selectedCustomer?.phone ??
          (_walkInPhoneController.text.trim().isNotEmpty
              ? _walkInPhoneController.text.trim()
              : null);

      final sale = await retail.createSale(
        customerId: _selectedCustomer?.id,
        customerName: customerName,
        customerPhone: customerPhone,
        items: List.from(_items),
        discount: _discount,
        tax: _tax,
        grandTotal: _grandTotal,
        paymentStatus: _paymentStatus,
        amountPaid: _amountPaid,
        paymentMethod: _paymentMethod,
        createdBy: auth.currentUserId ?? 'owner',
      );

      if (!mounted) return;
      setState(() {
        _isBilling = false;
        _items.clear();
        _selectedCustomer = null;
        _walkInNameController.text = 'Walk-in Customer';
        _walkInPhoneController.clear();
        _discountController.text = '0';
        _amountPaidController.clear();
        _paymentStatus = 'paid';
      });

      // Show receipt modal immediately
      ReceiptDialog.show(context, sale, auth.currentBusiness);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBilling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Billing failed: $e'),
          backgroundColor: AppTheme.crimsonError,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final retail = context.watch<RetailProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 900;

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
              child: const Icon(Icons.receipt_long_rounded, color: AppTheme.secondaryBlue, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales & Invoicing (POS)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  'Next: INV-${(retail.sales.length + 1).toString().padLeft(4, '0')}',
                  style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart_rounded, color: AppTheme.secondaryBlue),
            tooltip: 'Add Items to Bill',
            onPressed: () => _showProductPickerModal(context),
          ),
        ],
      ),
      body: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Items & Customer Details (flex 3)
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildCustomerCard(),
                        const SizedBox(height: 16),
                        _buildBilledItemsCard(retail),
                      ],
                    ),
                  ),
                ),

                // Right Column: Summary & Payment Box (flex 2)
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
                    child: _buildCheckoutSummaryCard(),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCustomerCard(),
                  const SizedBox(height: 16),
                  _buildBilledItemsCard(retail),
                  const SizedBox(height: 16),
                  _buildCheckoutSummaryCard(),
                ],
              ),
            ),
    );
  }

  // --- CUSTOMER CARD (PRD §6.4) ---
  Widget _buildCustomerCard() {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, color: AppTheme.secondaryBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Customer Details',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              if (_selectedCustomer == null)
                TextButton.icon(
                  icon: const Icon(Icons.contacts_rounded, size: 16),
                  label: const Text('Pick Existing'),
                  onPressed: () => _showCustomerPickerModal(context),
                )
              else
                TextButton(
                  onPressed: () => setState(() => _selectedCustomer = null),
                  child: const Text('Switch to Walk-in', style: TextStyle(color: AppTheme.crimsonError)),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (_selectedCustomer != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _selectedCustomer!.name[0].toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.secondaryBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedCustomer!.name,
                          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          _selectedCustomer!.phone ?? 'No phone',
                          style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedCustomer!.outstandingAmount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.crimsonLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.crimsonBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Khata Due',
                            style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.crimsonText),
                          ),
                          Text(
                            AppConstants.formatCurrency(_selectedCustomer!.outstandingAmount),
                            style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.crimsonError),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _walkInNameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name',
                      hintText: 'Walk-in / Cash Customer',
                      prefixIcon: Icon(Icons.badge_outlined, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _walkInPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone (Optional)',
                      hintText: '+91 98765...',
                      prefixIcon: Icon(Icons.phone_outlined, size: 18),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // --- BILLED ITEMS CARD ---
  Widget _buildBilledItemsCard(RetailProvider retail) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined, color: AppTheme.secondaryBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Billed Items (${_items.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Items'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () => _showProductPickerModal(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.add_shopping_cart_rounded, size: 48, color: AppTheme.textMuted.withOpacity(0.4)),
                  const SizedBox(height: 10),
                  Text(
                    'No items in bill yet',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "Add Items" or pick products from your store catalogue',
                    style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final item = _items[index];
                final product = retail.products.firstWhere(
                  (p) => p.id == item.productId,
                  orElse: () => Product(
                    id: '',
                    businessId: '',
                    name: item.productName,
                    sku: item.sku,
                    purchasePrice: 0,
                    sellingPrice: item.unitPrice,
                    currentStock: 999,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Item details
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'SKU: ${item.sku} • Stock: ${product.currentStock}',
                                style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textMuted),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _showPriceOverrideDialog(context, index, item),
                                child: Text(
                                  '@ ${AppConstants.formatCurrency(item.unitPrice)} [Edit Rate]',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.secondaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Quantity Stepper
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, size: 22, color: AppTheme.textMuted),
                          onPressed: () => _updateQuantity(index, -1, product.currentStock),
                        ),
                        Text(
                          '${item.quantity}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 22, color: AppTheme.secondaryBlue),
                          onPressed: () => _updateQuantity(index, 1, product.currentStock),
                        ),
                      ],
                    ),

                    // Line Total
                    SizedBox(
                      width: 80,
                      child: Text(
                        AppConstants.formatCurrency(item.lineTotal),
                        textAlign: TextAlign.right,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),

                    // Remove button
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.crimsonError),
                      onPressed: () => setState(() => _items.removeAt(index)),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // --- CHECKOUT SUMMARY & PAYMENT (PRD §6.5 & §6.6) ---
  Widget _buildCheckoutSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Invoice Summary',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 14),

          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.textMuted)),
              Text(AppConstants.formatCurrency(_subtotal),
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),

          // Discount field
          Row(
            children: [
              Text('Order Discount (₹):', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.textMuted)),
              const Spacer(),
              SizedBox(
                width: 100,
                height: 36,
                child: TextField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // GST 18% toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _applyGst,
                    activeColor: AppTheme.secondaryBlue,
                    onChanged: (v) => setState(() => _applyGst = v ?? false),
                  ),
                  Text('Apply GST (18%)', style: GoogleFonts.manrope(fontSize: 13)),
                ],
              ),
              if (_applyGst)
                Text('+ ${AppConstants.formatCurrency(_tax)}',
                    style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.textSlate)),
            ],
          ),
          const Divider(height: 24),

          // Grand Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grand Total',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Text(
                AppConstants.formatCurrency(_grandTotal),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.secondaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payment Status Segmented Control
          Text('Payment Status', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildStatusPill('Paid', 'paid', AppTheme.tertiaryEmerald),
              const SizedBox(width: 8),
              _buildStatusPill('Partial', 'partial', AppTheme.amberWarning),
              const SizedBox(width: 8),
              _buildStatusPill('Unpaid', 'unpaid', AppTheme.crimsonError),
            ],
          ),
          const SizedBox(height: 14),

          // Amount Paid (if partial)
          if (_paymentStatus == 'partial') ...[
            Text('Amount Received Now (₹) *', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            TextField(
              controller: _amountPaidController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Enter partial amount'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Balance to Khata Dues:', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.crimsonError)),
                Text(
                  AppConstants.formatCurrency(_balanceDue),
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.crimsonError),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // Payment Mode Selector
          if (_paymentStatus != 'unpaid') ...[
            Text('Payment Method', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMethodPill('UPI / QR', 'upi', Icons.qr_code_scanner_rounded),
                _buildMethodPill('Cash', 'cash', Icons.money_rounded),
                _buildMethodPill('Card', 'card', Icons.credit_card_rounded),
                _buildMethodPill('Bank Transfer', 'bank_transfer', Icons.account_balance_rounded),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Complete Billing Button
          ElevatedButton(
            onPressed: _isBilling || _items.isEmpty ? null : _handleGenerateInvoice,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isBilling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Generate Invoice & Bill',
                        style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String label, String value, Color activeColor) {
    final isSelected = _paymentStatus == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _paymentStatus = value;
            if (value == 'paid') {
              _amountPaidController.text = _grandTotal.toStringAsFixed(2);
            } else if (value == 'unpaid') {
              _amountPaidController.text = '0';
            }
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.12) : AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? activeColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? activeColor : AppTheme.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodPill(String label, String value, IconData icon) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primarySlate : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PRODUCT PICKER MODAL ---
  void _showProductPickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProductPickerSheet(onSelectProduct: _addItem),
    );
  }

  // --- CUSTOMER PICKER MODAL ---
  void _showCustomerPickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomerPickerSheet(
        onSelectCustomer: (cust) {
          setState(() {
            _selectedCustomer = cust;
          });
        },
      ),
    );
  }

  // --- EDIT RATE OVERRIDE DIALOG (PRD §6.5) ---
  void _showPriceOverrideDialog(BuildContext context, int index, SaleItem item) {
    final controller = TextEditingController(text: item.unitPrice.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Rate for ${item.productName}', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Custom Unit Price (₹)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newRate = double.tryParse(controller.text.trim());
              if (newRate != null && newRate >= 0) {
                _updateUnitPrice(index, newRate);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Apply Rate'),
          ),
        ],
      ),
    );
  }
}

// --- SUB-WIDGET: PRODUCT PICKER SHEET ---
class _ProductPickerSheet extends StatefulWidget {
  final Function(Product) onSelectProduct;

  const _ProductPickerSheet({required this.onSelectProduct});

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final retail = context.watch<RetailProvider>();

    final filtered = retail.products.where((p) {
      final matchesCat = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.barcode != null && p.barcode!.contains(_searchQuery));
      return matchesCat && matchesSearch;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: AppTheme.borderInput, borderRadius: BorderRadius.circular(2)),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Select Products to Bill',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by product name, SKU or barcode...',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Category chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: AppConstants.defaultCategories.map((cat) {
                final isSel = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSel,
                    selectedColor: AppTheme.primarySlate,
                    labelStyle: TextStyle(color: isSel ? Colors.white : AppTheme.textDark),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(),

          // Products List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('No matching products found.', style: GoogleFonts.manrope(color: AppTheme.textMuted)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final p = filtered[idx];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        title: Text(p.name, style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          'SKU: ${p.sku} • Stock: ${p.currentStock} ${p.unit}',
                          style: GoogleFonts.manrope(
                            color: p.isOutOfStock
                                ? AppTheme.crimsonError
                                : p.isLowStock
                                    ? AppTheme.amberWarning
                                    : AppTheme.textMuted,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppConstants.formatCurrency(p.sellingPrice),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.secondaryBlue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                backgroundColor: p.isOutOfStock ? AppTheme.borderSlate : AppTheme.secondaryBlue,
                              ),
                              onPressed: p.isOutOfStock
                                  ? null
                                  : () {
                                      widget.onSelectProduct(p);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Added ${p.name} to bill'),
                                          duration: const Duration(milliseconds: 800),
                                        ),
                                      );
                                    },
                              child: const Text('+ Add'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- SUB-WIDGET: CUSTOMER PICKER SHEET ---
class _CustomerPickerSheet extends StatefulWidget {
  final Function(Customer) onSelectCustomer;

  const _CustomerPickerSheet({required this.onSelectCustomer});

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final retail = context.watch<RetailProvider>();
    final filtered = retail.customers.where((c) {
      return c.name.toLowerCase().contains(_search.toLowerCase()) ||
          (c.phone != null && c.phone!.contains(_search));
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: AppTheme.borderInput, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Customer',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by customer name or phone number...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, idx) {
                final cust = filtered[idx];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.secondaryBlue.withOpacity(0.1),
                    child: Text(cust.name[0], style: const TextStyle(color: AppTheme.secondaryBlue)),
                  ),
                  title: Text(cust.name, style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                  subtitle: Text(cust.phone ?? 'No phone'),
                  trailing: cust.outstandingAmount > 0
                      ? Text(
                          'Due: ${AppConstants.formatCurrency(cust.outstandingAmount)}',
                          style: const TextStyle(color: AppTheme.crimsonError, fontWeight: FontWeight.bold),
                        )
                      : const Text('No Dues', style: TextStyle(color: AppTheme.tertiaryEmerald)),
                  onTap: () {
                    widget.onSelectCustomer(cust);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
