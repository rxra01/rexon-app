import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models/customer.dart';
import '../../providers/retail_provider.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final retail = context.watch<RetailProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final filtered = retail.customers.where((c) {
      return c.name.toLowerCase().contains(_search.toLowerCase()) ||
          (c.phone != null && c.phone!.contains(_search));
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
              child: const Icon(Icons.people_alt_rounded, color: AppTheme.secondaryBlue, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Customers & Khata Ledger',
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
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Add Customer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: () => _showAddCustomerDialog(context),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Outstanding Receivables Hero Card
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
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.crimsonLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppTheme.crimsonError,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Khata Receivables',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppConstants.formatCurrency(retail.totalOutstandingReceivables),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: retail.totalOutstandingReceivables > 0
                                ? AppTheme.crimsonError
                                : AppTheme.tertiaryEmerald,
                          ),
                        ),
                        Text(
                          '${retail.customers.where((c) => c.outstandingAmount > 0).length} customers currently owe balance',
                          style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderSlate),
              ),
              child: TextField(
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintText: 'Search customer by name or phone number...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppTheme.textMuted),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const SizedBox(height: 16),

            // Customer Directory List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSlate),
              ),
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'No customers found matching search.',
                          style: GoogleFonts.manrope(color: AppTheme.textMuted),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final c = filtered[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppTheme.secondaryBlue.withOpacity(0.1),
                                child: Text(
                                  c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.secondaryBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Name & contact
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${c.phone ?? "No phone"} • ${c.address ?? "No address"}',
                                      style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),

                              // Outstanding Amount
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    AppConstants.formatCurrency(c.outstandingAmount),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: c.outstandingAmount > 0
                                          ? AppTheme.crimsonError
                                          : AppTheme.tertiaryEmerald,
                                    ),
                                  ),
                                  Text(
                                    c.outstandingAmount > 0 ? 'Pending Due' : 'All Clear',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: c.outstandingAmount > 0
                                          ? AppTheme.crimsonText
                                          : AppTheme.emeraldText,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),

                              // Collect Payment Button
                              ElevatedButton(
                                onPressed: c.outstandingAmount > 0
                                    ? () => _showRecordPaymentDialog(context, c)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.emeraldText,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                child: const Text('Record Payment'),
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

  void _showAddCustomerDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addrCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add New Customer', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *')),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number *')),
            const SizedBox(height: 12),
            TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address (Optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final retail = context.read<RetailProvider>();
              retail.addCustomer(
                Customer(
                  id: const Uuid().v4(),
                  businessId: retail.businessId ?? '',
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
                  outstandingAmount: 0.0,
                  createdAt: DateTime.now(),
                ),
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Add Customer'),
          ),
        ],
      ),
    );
  }

  void _showRecordPaymentDialog(BuildContext context, Customer customer) {
    final amountCtrl = TextEditingController(text: customer.outstandingAmount.toStringAsFixed(0));
    final noteCtrl = TextEditingController();
    String method = 'upi';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            'Record Payment from ${customer.name}',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Outstanding Due: ${AppConstants.formatCurrency(customer.outstandingAmount)}',
                  style: GoogleFonts.manrope(color: AppTheme.crimsonError, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount Received (₹) *'),
              ),
              const SizedBox(height: 14),
              Text('Payment Method', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: method,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'upi', child: Text('UPI / QR Code')),
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer / NEFT')),
                  DropdownMenuItem(value: 'card', child: Text('Debit / Credit Card')),
                  DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => method = v);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Note / Reference (Optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldText, foregroundColor: Colors.white),
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                if (amt <= 0) return;

                final retail = context.read<RetailProvider>();
                await retail.recordPayment(
                  customerId: customer.id,
                  customerName: customer.name,
                  amount: amt,
                  method: method,
                  note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                );

                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Recorded payment of ${AppConstants.formatCurrency(amt)} from ${customer.name}.'),
                    backgroundColor: AppTheme.tertiaryEmerald,
                  ),
                );
              },
              child: const Text('Confirm Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
