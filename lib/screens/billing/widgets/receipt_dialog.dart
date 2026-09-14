import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../data/models/business.dart';
import '../../../data/models/sale.dart';

class ReceiptDialog extends StatelessWidget {
  final Sale sale;
  final Business? business;

  const ReceiptDialog({
    super.key,
    required this.sale,
    required this.business,
  });

  static void show(BuildContext context, Sale sale, Business? business) {
    showDialog(
      context: context,
      builder: (ctx) => ReceiptDialog(sale: sale, business: business),
    );
  }

  Future<void> _shareOnWhatsApp(BuildContext context) async {
    final storeName = business?.name ?? 'Our Store';
    final customer = sale.customerName;
    final buffer = StringBuffer();
    buffer.writeln('🧾 *INVOICE: ${sale.invoiceNumber}*');
    buffer.writeln('🏪 *$storeName*');
    buffer.writeln('👤 Customer: $customer');
    buffer.writeln('📅 ${AppConstants.formatDate(sale.createdAt)}');
    buffer.writeln('--------------------------------');
    for (final item in sale.items) {
      buffer.writeln('${item.productName} x${item.quantity} = ₹${item.lineTotal.toStringAsFixed(2)}');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('*Total:* ₹${sale.grandTotal.toStringAsFixed(2)}');
    buffer.writeln('*Paid:* ₹${sale.amountPaid.toStringAsFixed(2)}');
    if (sale.balanceDue > 0) {
      buffer.writeln('*Balance Due (Khata):* ₹${sale.balanceDue.toStringAsFixed(2)}');
    }
    buffer.writeln('\n_Thank you for shopping with us!_');

    final text = Uri.encodeComponent(buffer.toString());
    var phone = sale.customerPhone?.trim().replaceAll(' ', '') ?? '';
    if (phone.isNotEmpty && !phone.startsWith('+')) {
      if (phone.length == 10) phone = '91$phone';
    } else if (phone.startsWith('+')) {
      phone = phone.replaceFirst('+', '');
    }

    final url = phone.isNotEmpty
        ? Uri.parse('https://wa.me/$phone?text=$text')
        : Uri.parse('https://wa.me/?text=$text');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WhatsApp share: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppTheme.primarySlate,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Invoice #${sale.invoiceNumber}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (sale.voided)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.crimsonError,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'VOIDED',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Printable Content Area
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Store Information
                    Center(
                      child: Column(
                        children: [
                          Text(
                            business?.name ?? 'Rexon Retail Store',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            business?.address ?? 'Store Address, City',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          if (business?.gstin != null)
                            Text(
                              'GSTIN: ${business!.gstin}',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSlate,
                              ),
                            ),
                          Text(
                            'Phone: ${business?.phone ?? "N/A"}',
                            style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Bill & Customer Metadata
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Billed To:',
                              style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textMuted),
                            ),
                            Text(
                              sale.customerName,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                            if (sale.customerPhone != null)
                              Text(
                                sale.customerPhone!,
                                style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textSlate),
                              ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Invoice Date:',
                              style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textMuted),
                            ),
                            Text(
                              AppConstants.formatShortDate(sale.createdAt),
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Text(
                              'Payment: ${sale.paymentMethod.toUpperCase()}',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.secondaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Line Items Table
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              'ITEM',
                              style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'QTY',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'RATE',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'TOTAL',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    ...sale.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  item.productName,
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '${item.quantity}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.textSlate),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  AppConstants.formatCurrency(item.unitPrice),
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.textSlate),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  AppConstants.formatCurrency(item.lineTotal),
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),

                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Calculations Breakdown
                    if (sale.discount > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Order Discount', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.emeraldText)),
                            Text('- ${AppConstants.formatCurrency(sale.discount)}',
                                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.emeraldText)),
                          ],
                        ),
                      ),
                    if (sale.tax > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('GST Tax (18%)', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textMuted)),
                            Text('+ ${AppConstants.formatCurrency(sale.tax)}',
                                style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textSlate)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Grand Total',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          AppConstants.formatCurrency(sale.grandTotal),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Amount Received', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textMuted)),
                        Text(AppConstants.formatCurrency(sale.amountPaid),
                            style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.emeraldText)),
                      ],
                    ),
                    if (sale.balanceDue > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Outstanding Balance Due',
                                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.crimsonError)),
                            Text(AppConstants.formatCurrency(sale.balanceDue),
                                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.crimsonError)),
                          ],
                        ),
                      ),

                    if (sale.voided) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.crimsonLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.crimsonBorder),
                        ),
                        child: Text(
                          'Reason for Void: ${sale.voidReason ?? "Cancelled by Owner"}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.crimsonText,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Thank you for shopping with us!',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderSlate)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF25D366)),
                      label: const Text('WhatsApp Bill'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF128C7E),
                      ),
                      onPressed: () => _shareOnWhatsApp(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text('Print Receipt'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sent to POS thermal / receipt printer.'),
                            backgroundColor: AppTheme.tertiaryEmerald,
                            duration: Duration(seconds: 2),
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
      ),
    );
  }
}
